import SwiftUI
import SceneKit

// MARK: - メイン画面

struct EvolutionView: View {
    @EnvironmentObject private var workoutStore: WorkoutStore

    // 記録済みの総回数から部位ごとの成長度を計算
    private var growthWeights: [BodyPart: CGFloat] {
        Dictionary(
            uniqueKeysWithValues: BodyPart.allCases.map { part in
                let totalReps = workoutStore.records.reduce(0) { total, record in
                    guard record.targetParts.contains(part) else {
                        return total
                    }
                    return total + max(0, record.count) * max(0, record.sets)
                }

                let weight = 1.0 - exp(-Double(totalReps) / 500.0)

                return (
                    part,
                    CGFloat(min(max(weight, 0), 1))
                )
            }
        )
    }

    var body: some View {
        ThreeDModelContainerView(
            modelFileName: "musle",
            growthWeights: growthWeights
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - SceneKitによる成長モデル表示

struct ThreeDModelContainerView: UIViewRepresentable {
    var modelFileName: String
    var growthWeights: [BodyPart: CGFloat]

    final class Coordinator {
        var targetIndices: [BodyPart: Int] = [:]
        var cameraNode: SCNNode?
        var centerTargetNode: SCNNode?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()

        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.backgroundColor = UIColor.clear

        do {
            guard let baseURL = Bundle.main.url(
                forResource: modelFileName,
                withExtension: "obj"
            ) else {
                throw modelError("基本モデル \(modelFileName).obj が見つかりません")
            }

            let baseScene = try SCNScene(
                url: baseURL,
                options: nil
            )

            // 背景画像の読み込み設定
            if let bgImage = UIImage(named: "gym_background")
                ?? loadImageFromBundle(name: "gym_background", ext: "jpeg")
                ?? loadImageFromBundle(name: "gym_background", ext: "jpg") {
                baseScene.background.contents = bgImage
            } else {
                print("⚠️ 背景画像 gym_background が見つかりません")
            }

            guard let baseNode = findGeometryNode(in: baseScene.rootNode),
                  let baseGeometry = baseNode.geometry else {
                throw modelError("基本モデルのジオメトリが見つかりません")
            }

            let morpher = SCNMorpher()
            morpher.calculationMode = .normalized

            let baseVertexCount = baseGeometry.sources(for: .vertex).first?.vectorCount

            // 成長モデルを読み込む
            for part in BodyPart.allCases {
                let fileName = part.growthFileName

                guard let url = Bundle.main.url(
                    forResource: fileName,
                    withExtension: "obj"
                ) else {
                    print("⚠️ 成長モデルがありません: \(fileName).obj")
                    continue
                }

                let growthScene = try SCNScene(
                    url: url,
                    options: nil
                )

                guard let growthNode = findGeometryNode(in: growthScene.rootNode),
                      let growthGeometry = growthNode.geometry else {
                    print("⚠️ ジオメトリがありません: \(fileName)")
                    continue
                }

                let targetVertexCount = growthGeometry.sources(for: .vertex).first?.vectorCount

                guard let baseVertexCount, baseVertexCount == targetVertexCount else {
                    print("⚠️ 頂点数が一致しません: \(fileName)")
                    continue
                }

                context.coordinator.targetIndices[part] = morpher.targets.count
                morpher.targets.append(growthGeometry)

                print("✅ 成長モデル読込: \(fileName)")
            }

            let modelNode = SCNNode(geometry: baseGeometry)
            modelNode.name = "growthModel"
            modelNode.position = baseNode.position
            modelNode.rotation = baseNode.rotation
            modelNode.scale = baseNode.scale
            modelNode.morpher = morpher

            baseScene.rootNode.childNodes.forEach {
                $0.removeFromParentNode()
            }

            baseScene.rootNode.addChildNode(modelNode)

            for material in baseGeometry.materials {
                material.isDoubleSided = true
                material.lightingModel = .blinn
            }

            // 注視用ターゲットノードの設置
            let (minVec, maxVec) = modelNode.boundingBox
            let centerPos = SCNVector3(
                x: (minVec.x + maxVec.x) / 2.0,
                y: (minVec.y + maxVec.y) / 2.0,
                z: (minVec.z + maxVec.z) / 2.0
            )
            let centerTargetNode = SCNNode()
            centerTargetNode.position = centerPos
            modelNode.addChildNode(centerTargetNode)
            context.coordinator.centerTargetNode = centerTargetNode

            // カメラノードのセットアップ
            let camera = SCNCamera()
            camera.zNear = 0.01
            camera.zFar = 100.0
            
            let cameraNode = SCNNode()
            cameraNode.camera = camera
            cameraNode.name = "mainCamera"
            baseScene.rootNode.addChildNode(cameraNode)
            context.coordinator.cameraNode = cameraNode

            view.scene = baseScene
            view.pointOfView = cameraNode

            applyGrowthWeights(
                growthWeights,
                to: morpher,
                indices: context.coordinator.targetIndices
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.adjustCamera(in: view, coordinator: context.coordinator, targetNode: modelNode)
            }

        } catch {
            print("❌ 3Dモデル読み込みエラー: " + error.localizedDescription)

            let fallbackScene = SCNScene()
            let box = SCNBox(
                width: 1,
                height: 1,
                length: 1,
                chamferRadius: 0.1
            )

            box.firstMaterial?.diffuse.contents = UIColor.systemRed

            fallbackScene.rootNode.addChildNode(
                SCNNode(geometry: box)
            )

            view.scene = fallbackScene
        }

        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        guard let modelNode = view.scene?.rootNode.childNode(
            withName: "growthModel",
            recursively: true
        ), let morpher = modelNode.morpher else {
            return
        }

        applyGrowthWeights(
            growthWeights,
            to: morpher,
            indices: context.coordinator.targetIndices
        )

        DispatchQueue.main.async {
            self.adjustCamera(in: view, coordinator: context.coordinator, targetNode: modelNode)
        }
    }

    // MARK: - カメラ自動調整

    private func adjustCamera(in view: SCNView, coordinator: Coordinator, targetNode: SCNNode) {
        guard let cameraNode = coordinator.cameraNode,
              let centerTargetNode = coordinator.centerTargetNode,
              let camera = cameraNode.camera else { return }

        let (minVec, maxVec) = targetNode.boundingBox
        let height = abs(maxVec.y - minVec.y)
        let width = abs(maxVec.x - minVec.x)
        let depth = abs(maxVec.z - minVec.z)

        guard height > 0 && width > 0 else { return }

        let centerPos = SCNVector3(
            x: (minVec.x + maxVec.x) / 2.0,
            y: (minVec.y + maxVec.y) / 2.0,
            z: (minVec.z + maxVec.z) / 2.0
        )
        centerTargetNode.position = centerPos
        let worldCenter = centerTargetNode.worldPosition

        let bounds = view.bounds
        let widthBounds = bounds.width > 0 ? bounds.width : 390
        let heightBounds = bounds.height > 0 ? bounds.height : 844
        let aspectRatio = Float(widthBounds / heightBounds)

        let vFovDegrees = Float(camera.fieldOfView > 0 ? camera.fieldOfView : 60.0)
        let vFovRad = vFovDegrees * .pi / 180.0
        let hFovRad = 2.0 * atan(tan(vFovRad / 2.0) * aspectRatio)

        let distForHeight = (height / 2.0) / tan(vFovRad / 2.0)
        let distForWidth = (width / 2.0) / tan(hFovRad / 2.0)

        let requiredDistance = max(distForHeight, distForWidth) * 1.3 + (depth / 2.0)

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        cameraNode.position = SCNVector3(
            x: worldCenter.x,
            y: worldCenter.y,
            z: worldCenter.z + requiredDistance
        )

        let lookAt = SCNLookAtConstraint(target: centerTargetNode)
        lookAt.isGimbalLockEnabled = true
        cameraNode.constraints = [lookAt]

        SCNTransaction.commit()
    }

    // MARK: - 成長度の反映

    private func applyGrowthWeights(
        _ weights: [BodyPart: CGFloat],
        to morpher: SCNMorpher,
        indices: [BodyPart: Int]
    ) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.6
        SCNTransaction.animationTimingFunction =
            CAMediaTimingFunction(name: .easeInEaseOut)

        for part in BodyPart.allCases {
            guard let index = indices[part],
                  index < morpher.targets.count else {
                continue
            }

            morpher.setWeight(
                weights[part, default: 0],
                forTargetAt: index
            )
        }

        SCNTransaction.commit()
    }

    // MARK: - ヘルパーメソッド

    private func loadImageFromBundle(name: String, ext: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return UIImage(data: data)
    }

    private func findGeometryNode(in node: SCNNode) -> SCNNode? {
        if node.geometry != nil {
            return node
        }

        for child in node.childNodes {
            if let found = findGeometryNode(in: child) {
                return found
            }
        }

        return nil
    }

    private func modelError(_ message: String) -> NSError {
        NSError(
            domain: "WorkoutApp.GrowthModel",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: message
            ]
        )
    }
}

import SwiftUI
import SceneKit

// MARK: - 1. 部位の定義

enum BodyPart: String, CaseIterable, Hashable {
    case arm = "腕"
    case chest = "胸"
    case shoulder = "肩"
    case abs = "腹筋"
    case back = "背中"
    case legs = "脚"

    var growthFileName: String {
        switch self {
        case .arm:      return "arm_growth"
        case .chest:    return "chest_growth"
        case .shoulder: return "shoulder_growth"
        case .abs:      return "abs_growth"
        case .back:     return "back_growth"
        case .legs:     return "legs_growth"
        }
    }

    // 記録メニューと鍛えられる部位を対応させる
    static func parts(for menu: String) -> [BodyPart] {
        switch menu {
        case "腕立て伏せ":
            return [.arm, .chest, .shoulder]

        case "腹筋":
            return [.abs]

        case "スクワット":
            return [.legs]

        default:
            return []
        }
    }
}

// MARK: - 2. メイン画面

struct EvolutionView: View {
    @EnvironmentObject private var workoutStore: WorkoutStore

    // 記録済みの総回数から部位ごとの成長度を計算
    private var growthWeights: [BodyPart: CGFloat] {
        Dictionary(
            uniqueKeysWithValues: BodyPart.allCases.map { part in
                let totalReps = workoutStore.records.reduce(0) { total, record in
                    guard BodyPart.parts(for: record.menu).contains(part) else {
                        return total
                    }
                    return total + max(0, record.count) * max(0, record.sets)
                }

                // 回数が増えるほど成長形状に近づく
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

// MARK: - 3. SceneKitによる成長モデル表示

struct ThreeDModelContainerView: UIViewRepresentable {
    var modelFileName: String
    var growthWeights: [BodyPart: CGFloat]

    final class Coordinator {
        // 実際に読み込めた成長モデルのインデックス
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
        view.backgroundColor = UIColor.systemBackground

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

            guard let baseNode = findGeometryNode(in: baseScene.rootNode),
                  let baseGeometry = baseNode.geometry else {
                throw modelError("基本モデルのジオメトリが見つかりません")
            }

            // 【修正ポイント】加算(additive)ではなく正規化(normalized)にして巨大化を防ぐ
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

            // 元のモデル階層を置き換える
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

            // 初期状態の成長度を適用
            applyGrowthWeights(
                growthWeights,
                to: morpher,
                indices: context.coordinator.targetIndices
            )

            // カメラ初期位置の調整
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

    // MARK: - モデル検索

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

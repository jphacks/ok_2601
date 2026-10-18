import SwiftUI
import SceneKit

// MARK: - 1. 部位の定義
enum BodyPart: String, CaseIterable {
    case arm = "腕"
    case chest = "胸"
    case shoulder = "肩"
    case abs = "腹筋"
    case back = "背中"
    case legs = "脚"
    
    var nodeNames: [String] {
        switch self {
        case .arm:      return ["J_Bip_L_UpperArm", "J_Bip_R_UpperArm", "J_Bip_L_Forearm", "J_Bip_R_Forearm", "L_UpperArm", "R_UpperArm"]
        case .chest:    return ["J_Sec_L_Bust1", "J_Sec_R_Bust1", "J_Bip_C_Chest", "Chest", "UpperChest"]
        case .shoulder: return ["J_Bip_L_Shoulder", "J_Bip_R_Shoulder", "L_Shoulder", "R_Shoulder"]
        case .abs:      return ["J_Bip_C_Spine", "Spine", "Abdomen"]
        case .back:     return ["J_Bip_C_UpperChest", "UpperChest", "Spine1"]
        case .legs:     return ["J_Bip_L_UpperLeg", "J_Bip_R_UpperLeg", "J_Bip_L_LowerLeg", "J_Bip_R_LowerLeg", "L_Thigh", "R_Thigh"]
        }
    }
}

// MARK: - 2. メイン画面（変化タブ）
struct EvolutionView: View {
    @State private var scales: [BodyPart: Float] = [
        .arm: 1.0, .chest: 1.0, .shoulder: 1.0,
        .abs: 1.0, .back: 1.0, .legs: 1.0
    ]
    
    let growthAmount: Float = 0.08
    let cardioShrinkAmount: Float = 0.03
    let minScale: Float = 0.8
    let maxScale: Float = 2.0

    var body: some View {
        VStack(spacing: 0) {
            // 3Dモデル表示エリア
            ThreeDModelContainerView(
                modelFileName: "musle.obj",
                scales: scales
            )
            .frame(height: 350)
            
            Divider()
            
            // 動作テスト用UI
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("筋トレ記録・連携テスト (仮)")
                        .font(.headline)
                        .padding(.top)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(BodyPart.allCases, id: \.self) { part in
                            Button(action: {
                                recordWorkout(part: part)
                            }) {
                                HStack {
                                    Text("\(part.rawValue)トレ")
                                    Spacer()
                                    Text(String(format: "x%.2f", scales[part] ?? 1.0))
                                        .font(.caption2)
                                        .bold()
                                }
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    Button(action: {
                        recordCardio()
                    }) {
                        Label("🏃 有酸素運動を行う (微減)", systemImage: "figure.run")
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(10)
                    }
                    .padding(.top, 5)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("3D成長変化")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 筋トレ記録処理
    private func recordWorkout(part: BodyPart) {
        let current = scales[part] ?? 1.0
        scales[part] = min(current + growthAmount, maxScale)
    }

    // 有酸素運動記録処理
    private func recordCardio() {
        for part in BodyPart.allCases {
            let current = scales[part] ?? 1.0
            scales[part] = max(current - cardioShrinkAmount, minScale)
        }
    }
}

// MARK: - 3. SceneKit 描画 ＆ スケール適用ビュー
struct ThreeDModelContainerView: UIViewRepresentable {
    var modelFileName: String
    var scales: [BodyPart: Float]
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.backgroundColor = UIColor.systemGroupedBackground
        
        if let scene = SCNScene(named: modelFileName) {
            scnView.scene = scene
            
            // 💡 追加: 読み込んだモデルのマテリアルを明示的に最適化する処理
            scene.rootNode.enumerateChildNodes { (node, _) in
                if let geometry = node.geometry {
                    for material in geometry.materials {
                        // テクスチャが裏面にも描画されるようにする（服や髪の欠け防止）
                        material.isDoubleSided = true
                        // アニメ調モデル（MToon等）の影が黒潰れしないようにBlinnシェーダーを指定
                        material.lightingModel = .blinn
                        print("🎨 マテリアル検出: \(material.name ?? "不明")")
                    }
                }
            }
        } else {
            let fallbackScene = SCNScene()
            let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.1)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.systemRed
            box.materials = [material]
            fallbackScene.rootNode.addChildNode(SCNNode(geometry: box))
            scnView.scene = fallbackScene
            print("⚠️ \(modelFileName) の読み込みに失敗しました。")
        }
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let scene = uiView.scene else { return }
        
        for part in BodyPart.allCases {
            let scaleValue = scales[part] ?? 1.0
            for nodeName in part.nodeNames {
                scene.rootNode.enumerateChildNodes { (node, _) in
                    if node.name == nodeName {
                        node.simdScale = SIMD3<Float>(scaleValue, scaleValue, scaleValue)
                    }
                }
            }
        }
    }
}

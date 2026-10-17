import SwiftUI

struct EvolutionView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)

            Text("成長・進化")

            Text("数値・ビジュアル機能を実装予定")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("変化")
    }
}

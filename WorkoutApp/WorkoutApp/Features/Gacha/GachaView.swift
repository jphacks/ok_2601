import SwiftUI

struct GachaView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.largeTitle)

            Text("スキンガチャ")

            Text("ガチャ機能を実装予定")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("ガチャ")
    }
}

import SwiftUI

struct RecordView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.clipboard")
                .font(.largeTitle)

            Text("トレーニング記録")

            Text("記録入力機能を実装予定")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("記録")
    }
}

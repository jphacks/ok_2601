import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 60))

            Text("筋トレアプリ")
                .font(.largeTitle.bold())

            Text("運動不足を解消しよう！")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle("ホーム")
    }
}

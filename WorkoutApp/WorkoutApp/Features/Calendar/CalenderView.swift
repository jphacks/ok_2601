import SwiftUI

struct CalendarView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.largeTitle)

            Text("トレーニングカレンダー")

            Text("カレンダー機能を実装予定")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("カレンダー")
    }
}

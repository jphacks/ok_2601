
import SwiftUI

struct WorkoutMotionView: View {
    @EnvironmentObject private var workoutStore: WorkoutStore
    @StateObject private var motion = WorkoutMotion()

    @State private var isMonitoring = false
    @State private var savedCount: Int? = nil
    @State private var message = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("腹筋 自動計測")
                .font(.title2)
                .fontWeight(.bold)

            Text(motion.status)
                .font(.headline)

            VStack(spacing: 8) {
                Text("現在のPitch")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(String(format: "%.3f rad", motion.pitch))
                    .font(.system(size: 24, weight: .medium))
                    .monospacedDigit()
            }

            VStack(spacing: 8) {
                Text("腹筋カウント")
                    .font(.headline)

                Text("\(motion.count) 回")
                    .font(.system(size: 48, weight: .bold))
                    .monospacedDigit()
            }

            Button("センサーを確認") {
                motion.checkAvailability()
            }
            .buttonStyle(.bordered)
            .disabled(isMonitoring)

            Button("計測開始") {
                savedCount = nil
                message = ""
                isMonitoring = true
                motion.startMonitoring()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isMonitoring)

            Button("計測停止・記録") {
                motion.stopMonitoring()
                isMonitoring = false

                let count = motion.count

                guard count > 0 else {
                    message = "回数が0のため，記録しませんでした"
                    return
                }

                let record = WorkoutRecord(
                    menu: "腹筋",
                    count: count,
                    sets: 1,
                    weight: 0
                )

                workoutStore.add(record)
                savedCount = count
                message = "\(count)回の腹筋を記録しました"
            }
            .buttonStyle(.bordered)
            .disabled(!isMonitoring)

            if !message.isEmpty {
                Text(message)
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }

            if let savedCount {
                Text("記録回数：\(savedCount)回")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .onDisappear {
            motion.stopMonitoring()
            isMonitoring = false
        }
    }
}

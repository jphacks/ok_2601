
import SwiftUI

// MARK: - ホーム画面

struct HomeView: View {
    @State private var showingWorkoutAlert = false
    @State private var selectedDate = Calendar.current.startOfDay(
        for: Date()
    )

    // 仮の記録データ
    private let workoutLogs = WorkoutLog.samples

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // 1. 育成モデル
                modelSection

                // 2. 筋トレ開始ボタン
                Button {
                    showingWorkoutAlert = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("筋トレを始める")
                            .fontWeight(.bold)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                // 3. 今週の記録
                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle(
                        "今週の記録",
                        subtitle: "運動した日を確認しよう"
                    )

                    WeeklyRecordCalendar(
                        selectedDate: $selectedDate,
                        workoutLogs: workoutLogs
                    )
                }

                // 4. 筋トレログ
                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle(
                        "筋トレログ",
                        subtitle: "最近のトレーニング"
                    )

                    workoutLogSection
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("ホーム")
        .navigationBarTitleDisplayMode(.large)
        .alert("筋トレ", isPresented: $showingWorkoutAlert) {
            Button("閉じる", role: .cancel) { }
        } message: {
            Text("筋トレ実行画面は今後実装します。")
        }
    }

    // MARK: 育成モデル

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR MODEL")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)

                    Text("トレーニングモデル")
                        .font(.title3.bold())

                    Text("Lv. 1")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .foregroundStyle(.secondary)
            }

            // 仮のモデル表示
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.accentColor.opacity(0.10))

                Image(
                    systemName: "figure.strengthtraining.traditional"
                )
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.accentColor)
                .frame(height: 100)
            }
            .frame(height: 160)

            HStack {
                Text("次の成長まで")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("25%")
                    .font(.caption.bold())
            }

            ProgressView(value: 0.25)
                .tint(.accentColor)

            Text("筋トレを続けてモデルを成長させよう！")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: 筋トレログ

    private var workoutLogSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(workoutLogs.prefix(5).enumerated()), id: \.element.id) {
                index, log in

                HStack(spacing: 12) {
                    Image(systemName: "dumbbell.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 44, height: 44)
                        .background(
                            Color.accentColor.opacity(0.10)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.menu)
                            .font(.subheadline.bold())

                        Text(log.date.formatted(
                            .dateTime.month().day()
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(log.count)回")
                            .font(.subheadline.bold())

                        Text("\(log.sets)セット")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 12)

                if index < min(workoutLogs.count, 5) - 1 {
                    Divider()
                }
            }
        }
        .padding(.horizontal)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: 共通見出し

    private func sectionTitle(
        _ title: String,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.bold())

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 仮の筋トレ記録

private struct WorkoutLog: Identifiable {
    let id = UUID()
    let date: Date
    let menu: String
    let count: Int
    let sets: Int

    static var samples: [WorkoutLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return [
            WorkoutLog(
                date: today,
                menu: "腕立て伏せ",
                count: 10,
                sets: 3
            ),
            WorkoutLog(
                date: calendar.date(
                    byAdding: .day, value: -1, to: today
                ) ?? today,
                menu: "スクワット",
                count: 20,
                sets: 2
            ),
            WorkoutLog(
                date: calendar.date(
                    byAdding: .day, value: -3, to: today
                ) ?? today,
                menu: "腹筋",
                count: 15,
                sets: 3
            )
        ]
    }
}

// MARK: - 週表示カレンダー

private struct WeeklyRecordCalendar: View {
    @Binding var selectedDate: Date
    let workoutLogs: [WorkoutLog]

    private let calendar = Calendar.current
    private let weekdays = ["月", "火", "水", "木", "金", "土", "日"]

    private var weekDates: [Date] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let offset = (weekday + 5) % 7

        guard let monday = calendar.date(
            byAdding: .day,
            value: -offset,
            to: today
        ) else {
            return [today]
        }

        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: monday)
        }
    }

    private func hasRecord(on date: Date) -> Bool {
        workoutLogs.contains {
            calendar.isDate($0.date, inSameDayAs: date)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(Date.now.formatted(.dateTime.year().month()))
                    .font(.headline)

                Spacer()

                Text("月〜日")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                ForEach(Array(weekDates.enumerated()), id: \.offset) {
                    index, date in

                    let isSelected = calendar.isDate(
                        date,
                        inSameDayAs: selectedDate
                    )

                    Button {
                        selectedDate = date
                    } label: {
                        VStack(spacing: 8) {
                            Text(weekdays[index])
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(date.formatted(.dateTime.day()))
                                .font(.subheadline.bold())
                                .foregroundStyle(
                                    isSelected ? .white : .primary
                                )
                                .frame(width: 34, height: 34)
                                .background {
                                    Circle()
                                        .fill(
                                            isSelected
                                            ? Color.accentColor
                                            : Color.clear
                                        )
                                }

                            Circle()
                                .fill(
                                    hasRecord(on: date)
                                    ? Color.green
                                    : Color.clear
                                )
                                .frame(width: 5, height: 5)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            HStack {
                Text(selectedDate.formatted(
                    .dateTime.month().day().weekday()
                ))
                .font(.subheadline.bold())

                Spacer()

                let count = workoutLogs.filter {
                    calendar.isDate(
                        $0.date,
                        inSameDayAs: selectedDate
                    )
                }.count

                Text(count == 0 ? "記録なし" : "\(count)件の記録")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            Color(uiColor: .secondarySystemGroupedBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

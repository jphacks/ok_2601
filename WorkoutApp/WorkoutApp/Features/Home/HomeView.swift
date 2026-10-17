
import SwiftUI

// MARK: - ホーム画面

struct HomeView: View {
    @EnvironmentObject private var workoutStore: WorkoutStore

    @State private var showingWorkoutSheet = false

    @State private var selectedDate =
        Calendar.current.startOfDay(for: Date())


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // 1. 育成モデル
                pointsSection

                // 2. 筋トレ開始ボタン
                Button {
                    showingWorkoutSheet = true
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
                
                .sheet(isPresented: $showingWorkoutSheet) {
                    WorkoutStartView { record in
                        workoutStore.add(record)
                    }
                }


                // 3. 今週の記録
                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle(
                        "今週の記録",
                        subtitle: "運動した日を確認しよう"
                    )

                    WeeklyRecordCalendar(
                        selectedDate: $selectedDate,
                        workoutLogs: workoutStore.records
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
    }

    // MARK: 筋トレポイントカード

    private var pointsSection: some View {
        let totalMultiplier = PointMultiplier.totalRecord(
            days: workoutStore.totalRecordDays
        )

        let streakMultiplier = PointMultiplier.streak(
            days: workoutStore.consecutiveRecordDays
        )

        let totalMultiplierValue = totalMultiplier * streakMultiplier


        return VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Label("MUSCLE POINT", systemImage: "bolt.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(workoutStore.musclePoints.formatted())
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())

                    Text("pt")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Text("筋トレを続けてポイントを増やそう！")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                Text("ポイント倍率")
                    .font(.headline)

                multiplierRow(
                    title: "総記録日数ボーナス",
                    subtitle: "\(workoutStore.totalRecordDays)日記録",
                    multiplier: totalMultiplier,
                    icon: "calendar"
                )

                multiplierRow(
                    title: "連続記録ボーナス",
                    subtitle: "\(workoutStore.consecutiveRecordDays)日連続",
                    multiplier: streakMultiplier,
                    icon: "flame.fill"
                )

                Divider()

                HStack {
                    Text("合計倍率")
                        .font(.subheadline.bold())

                    Spacer()

                    Text(
                        "× \(totalMultiplierValue, specifier: "%.2f")"
                    )
                    .font(.title2.bold())
                    .foregroundStyle(.orange)
                }
            }

            Text("筋トレの記録を保存すると，自動でポイントが加算されます。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: 倍率表示

    private func multiplierRow(
        title: String,
        subtitle: String,
        multiplier: Double,
        icon: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 40, height: 40)
                .background(Color.orange.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("× \(multiplier, specifier: "%.2f")")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.orange)
        }
    }
    // MARK: 筋トレログ

    private var workoutLogSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(workoutStore.records.prefix(5).enumerated()), id: \.element.id) {
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

                if index < min(workoutStore.records.count, 5) - 1 {
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


// MARK: - 週表示カレンダー

private struct WeeklyRecordCalendar: View {
    @Binding var selectedDate: Date
    let workoutLogs: [WorkoutRecord]

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
private struct WorkoutStartView: View {
    let onSave: (WorkoutRecord) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedMenu = "腕立て伏せ"
    @State private var count = 10
    @State private var sets = 3

    private let menus = [
        "腕立て伏せ",
        "腹筋",
        "スクワット"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("トレーニングメニュー") {
                    Picker("種目", selection: $selectedMenu) {
                        ForEach(menus, id: \.self) { menu in
                            Text(menu).tag(menu)
                        }
                    }

                    Stepper(
                        "1セットの回数：\(count)回",
                        value: $count,
                        in: 1...500
                    )

                    Stepper(
                        "セット数：\(sets)セット",
                        value: $sets,
                        in: 1...20
                    )
                }

                Section {
                    Button("記録を保存") {
                        let record = WorkoutRecord(
                            date: Date(),
                            menu: selectedMenu,
                            count: count,
                            sets: sets
                        )

                        onSave(record)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("筋トレを記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

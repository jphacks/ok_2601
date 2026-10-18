
import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject private var workoutStore: WorkoutStore

    @State private var selectedPeriod: ActivityPeriod = .week

    private let calendar = Calendar.current

    // MARK: - 期間設定

    private var currentPeriodInterval: DateInterval {
        calendar.dateInterval(
            of: selectedPeriod.calendarComponent,
            for: Date()
        )!
    }

    private var previousPeriodInterval: DateInterval {
        let previousDate = currentPeriodInterval.start
            .addingTimeInterval(-1)

        return calendar.dateInterval(
            of: selectedPeriod.calendarComponent,
            for: previousDate
        )!
    }

    // 比較対象の日数。今週なら月曜日から今日まで，
    // 今月なら1日から今日までを対象にする。
    private var elapsedDays: Int {
        let start = currentPeriodInterval.start
        let today = calendar.startOfDay(for: Date())

        return (calendar.dateComponents(
            [.day],
            from: start,
            to: today
        ).day ?? 0) + 1
    }

    private var currentComparisonEnd: Date {
        min(
            calendar.date(
                byAdding: .day,
                value: elapsedDays,
                to: currentPeriodInterval.start
            )!,
            currentPeriodInterval.end
        )
    }

    private var previousComparisonEnd: Date {
        min(
            calendar.date(
                byAdding: .day,
                value: elapsedDays,
                to: previousPeriodInterval.start
            )!,
            previousPeriodInterval.end
        )
    }

    // MARK: - 集計

    private func records(
        from start: Date,
        to end: Date
    ) -> [WorkoutRecord] {
        workoutStore.records.filter {
            $0.date >= start && $0.date < end
        }
    }

    private func totalReps(
        from start: Date,
        to end: Date
    ) -> Int {
        records(from: start, to: end).reduce(0) {
            $0 + $1.count * $1.sets
        }
    }

    private func workoutDays(
        from start: Date,
        to end: Date
    ) -> Int {
        Set(
            records(from: start, to: end).map {
                calendar.startOfDay(for: $0.date)
            }
        ).count
    }

    private var totalWorkoutDays: Int {
        workoutDays(
            from: .distantPast,
            to: .distantFuture
        )
    }

    private var menuStatistics: [MenuStatistic] {
        let grouped = Dictionary(
            grouping: workoutStore.records,
            by: \.menu
        )

        return grouped.map { menu, items in
            MenuStatistic(
                menu: menu,
                totalReps: items.reduce(0) {
                    $0 + $1.count * $1.sets
                },
                maxReps: items.map {
                    $0.count * $0.sets
                }.max() ?? 0
            )
        }
        .sorted {
            if $0.totalReps == $1.totalReps {
                return $0.menu < $1.menu
            }
            return $0.totalReps > $1.totalReps
        }
    }

    // MARK: - グラフデータ

    private var chartEntries: [ActivityEntry] {
        let interval = currentPeriodInterval
        let numberOfDays = selectedPeriod == .week ? 7 :
            (calendar.range(
                of: .day,
                in: .month,
                for: interval.start
            )?.count ?? 30)

        return (0..<numberOfDays).compactMap { offset in
            guard let date = calendar.date(
                byAdding: .day,
                value: offset,
                to: interval.start
            ) else {
                return nil
            }

            let nextDate = calendar.date(
                byAdding: .day,
                value: 1,
                to: date
            )!

            return ActivityEntry(
                date: date,
                reps: totalReps(from: date, to: nextDate)
            )
        }
    }

    // MARK: - 画面

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // 累計データ
                HStack(spacing: 12) {
                    summaryCard(
                        title: "総筋トレPt",
                        value: workoutStore.totalEarnedPoints.formatted(),
                        unit: "Pt",
                        symbol: "star.fill",
                        tint: .orange
                    )

                    summaryCard(
                        title: "筋トレした日数",
                        value: totalWorkoutDays.formatted(),
                        unit: "日",
                        symbol: "calendar",
                        tint: .green
                    )
                }

                // ① 活動履歴
                VStack(alignment: .leading, spacing: 14) {
                    Text("活動履歴")
                        .font(.headline)

                    Picker("表示期間", selection: $selectedPeriod) {
                        ForEach(ActivityPeriod.allCases) { period in
                            Text(period.title)
                                .tag(period)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text(
                            selectedPeriod == .week
                                ? "日ごとの総回数（今週）"
                                : "日ごとの総回数（今月）"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        Spacer()

                        let currentTotal = totalReps(
                            from: currentPeriodInterval.start,
                            to: currentComparisonEnd
                        )

                        Text("\(currentTotal.formatted()) 回")
                            .font(.subheadline.bold())
                    }

                    Chart {
                        ForEach(chartEntries) { entry in
                            BarMark(
                                x: .value("日付", entry.date),
                                y: .value("回数", entry.reps)
                            )
                            .foregroundStyle(
                                entry.reps > 0
                                ? Color.blue
                                : Color.gray.opacity(0.25)
                            )
                            .cornerRadius(4)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(
                            values: .stride(
                                by: .day,
                                count: selectedPeriod == .week ? 1 : 5
                            )
                        ) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.day())
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 220)

                    Text("横軸：日付 ／ 縦軸：筋トレ総回数")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // ② 前週・前月との比較
                VStack(alignment: .leading, spacing: 14) {
                    Text("前期間との比較")
                        .font(.headline)

                    Text(selectedPeriod == .week
                         ? "今週と先週"
                         : "今月と先月")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("両期間とも同じ日数分を比較します。")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    comparisonRow(
                        title: "総回数",
                        current: totalReps(
                            from: currentPeriodInterval.start,
                            to: currentComparisonEnd
                        ),
                        previous: totalReps(
                            from: previousPeriodInterval.start,
                            to: previousComparisonEnd
                        ),
                        unit: "回",
                        symbol: "repeat"
                    )

                    Divider()

                    comparisonRow(
                        title: "筋トレした日数",
                        current: workoutDays(
                            from: currentPeriodInterval.start,
                            to: currentComparisonEnd
                        ),
                        previous: workoutDays(
                            from: previousPeriodInterval.start,
                            to: previousComparisonEnd
                        ),
                        unit: "日",
                        symbol: "calendar"
                    )
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // 種目別の累計と最高記録
                VStack(alignment: .leading, spacing: 14) {
                    Text("種目別の記録")
                        .font(.headline)

                    if menuStatistics.isEmpty {
                        ContentUnavailableView(
                            "統計データはありません",
                            systemImage: "chart.bar",
                            description: Text(
                                "筋トレを記録すると，ここに実績が表示されます"
                            )
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(menuStatistics) { statistic in
                            menuRow(statistic)

                            if statistic.id != menuStatistics.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(
                    "総回数は「回数 × セット数」の累計です。" +
                    "最高回数は1回の記録における「回数 × セット数」の最大値です。"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("統計")
        .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            WorkoutMotionView()
                        } label: {
                            Image(systemName: "figure.mixed.cardio")
                        }
                        .accessibilityLabel("モーション検知テスト")
                    }
                }
    }

    // MARK: - 累計カード

    private func summaryCard(
        title: String,
        value: String,
        unit: String,
        symbol: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(tint)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 比較行

    private func comparisonRow(
        title: String,
        current: Int,
        previous: Int,
        unit: String,
        symbol: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.subheadline)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("今期間")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(current.formatted()) \(unit)")
                    .font(.title3.bold())

                Spacer()

                Text("前期間")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(previous.formatted()) \(unit)")
                    .font(.subheadline)
            }

            HStack {
                Text("前期間比")

                Spacer()

                Text(changeDescription(
                    current: current,
                    previous: previous,
                    unit: unit
                ))
                .fontWeight(.semibold)
                .foregroundStyle(
                    current > previous ? .green :
                    current < previous ? .red : .secondary
                )
            }
            .font(.subheadline)
        }
        .padding(.vertical, 4)
    }

    
    private func changeDescription(
        current: Int,
        previous: Int,
        unit: String
    ) -> String {
        let difference = current - previous

        let differenceText: String
        if difference > 0 {
            differenceText = "+\(difference.formatted()) \(unit)"
        } else {
            differenceText = "\(difference.formatted()) \(unit)"
        }

        guard previous > 0 else {
            if difference == 0 {
                return "±0 \(unit)"
            }
            return "\(differenceText)（比較元なし）"
        }

        let percentage = Double(difference) / Double(previous) * 100
        let sign = percentage > 0 ? "+" : ""
        let percentageText = percentage.formatted(
            .number.precision(.fractionLength(0))
        )

        return "\(differenceText)（\(sign)\(percentageText)%）"
    }

    // MARK: - 種目別表示

    private func menuRow(_ statistic: MenuStatistic) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName(for: statistic.menu))
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 42, height: 42)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 5) {
                Text(statistic.menu)
                    .font(.headline)

                Text("\(statistic.totalReps.formatted()) 回")
                    .font(.title3.bold())

                Text("(最高 \(statistic.maxReps.formatted()) 回)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private func iconName(for menu: String) -> String {
        switch menu {
        case "腹筋":
            return "figure.core.training"
        case "腕立て伏せ":
            return "figure.strengthtraining.traditional"
        case "スクワット":
            return "figure.strengthtraining.functional"
        default:
            return "dumbbell.fill"
        }
    }
}

// MARK: - 集計用モデル

private enum ActivityPeriod: String, CaseIterable, Identifiable {
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return "週"
        case .month: return "月"
        }
    }

    var calendarComponent: Calendar.Component {
        switch self {
        case .week: return .weekOfYear
        case .month: return .month
        }
    }
}

private struct ActivityEntry: Identifiable {
    let date: Date
    let reps: Int

    var id: Date { date }
}

private struct MenuStatistic: Identifiable {
    let menu: String
    let totalReps: Int
    let maxReps: Int

    var id: String { menu }
}


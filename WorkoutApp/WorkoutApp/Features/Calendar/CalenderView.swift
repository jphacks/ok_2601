import SwiftUI

struct CalendarView: View {
    // 記録画面と同じデータを使う
    @EnvironmentObject private var workoutStore: WorkoutStore

    @State private var currentMonth = Date()
    @State private var selectedDate = Calendar.current.startOfDay(
        for: Date()
    )

    private let calendar = Calendar.current

    private let weekdays = [
        "日", "月", "火", "水", "木", "金", "土"
    ]

    // 表示する年月
    private var monthTitle: String {
        currentMonth.formatted(
            .dateTime.locale(Locale(identifier: "ja_JP"))
                .year()
                .month()
        )
    }

    // その月の日付一覧
    private var days: [Date?] {
        guard
            let interval = calendar.dateInterval(
                of: .month,
                for: currentMonth
            ),
            let range = calendar.range(
                of: .day,
                in: .month,
                for: currentMonth
            )
        else {
            return []
        }

        let firstWeekday = calendar.component(
            .weekday,
            from: interval.start
        )

        let emptyDays = firstWeekday - 1

        var result: [Date?] = Array(
            repeating: nil,
            count: emptyDays
        )

        for day in range {
            if let date = calendar.date(
                byAdding: .day,
                value: day - 1,
                to: interval.start
            ) {
                result.append(date)
            }
        }

        return result
    }

    // 選択した日に保存されている記録
    private var selectedRecords: [WorkoutRecord] {
        workoutStore.records.filter {
            calendar.isDate(
                $0.date,
                inSameDayAs: selectedDate
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                monthNavigation
                calendarGrid
                selectedDaySection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("カレンダー")
        .navigationBarTitleDisplayMode(.inline)
    }

    // 月の切り替え
    private var monthNavigation: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .frame(width: 40, height: 40)
            }

            Spacer()

            Text(monthTitle)
                .font(.title2.bold())

            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 8)
    }

    // カレンダー全体
    private var calendarGrid: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible()),
                count: 7
            ),
            spacing: 10
        ) {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption.bold())
                    .foregroundStyle(
                        weekday == "日" ? .red :
                        weekday == "土" ? .blue :
                        .secondary
                    )
            }

            ForEach(days.indices, id: \.self) { index in
                if let date = days[index] {
                    dayCell(date)
                } else {
                    Color.clear
                        .frame(height: 44)
                }
            }
        }
        .padding()
        .background(
            Color(uiColor: .secondarySystemGroupedBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // 日付の表示
    private func dayCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(
            date,
            inSameDayAs: selectedDate
        )

        // この日に実際の記録があるか確認する
        let hasRecord = workoutStore.records.contains {
            calendar.isDate(
                $0.date,
                inSameDayAs: date
            )
        }

        return Button {
            selectedDate = calendar.startOfDay(for: date)
        } label: {
            VStack(spacing: 4) {
                Text(
                    "\(calendar.component(.day, from: date))"
                )
                .font(
                    .subheadline.weight(
                        isSelected ? .bold : .regular
                    )
                )

                // 記録がある日は緑色の点
                Circle()
                    .fill(
                        hasRecord ? Color.green : Color.clear
                    )
                    .frame(width: 5, height: 5)
            }
            .foregroundStyle(
                isSelected ? .white : .primary
            )
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // 選択した日の記録
    private var selectedDaySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(
                selectedDate.formatted(
                    .dateTime.locale(
                        Locale(identifier: "ja_JP")
                    )
                    .year()
                    .month()
                    .day()
                    .weekday(.wide)
                ) + " の記録"
            )
            .font(.headline)

            if selectedRecords.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)

                    Text("この日の記録はありません")
                        .font(.subheadline.bold())

                    Text("トレーニングした日は記録を残そう！")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(selectedRecords) { record in
                    recordCard(record)
                }
            }
        }
    }

    // 記録内容のカード
    private func recordCard(
        _ record: WorkoutRecord
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                record.menu,
                systemImage: "dumbbell.fill"
            )
            .font(.headline)
            .foregroundStyle(.blue)

            Text("\(record.count) 回 × \(record.sets) セット")
                .font(.subheadline)

            if record.weight > 0 {
                Text(
                    "重量：\(record.weight.formatted()) kg"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Text(
                record.date.formatted(
                    .dateTime.hour().minute()
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            Color(uiColor: .secondarySystemGroupedBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // 月を切り替える
    private func changeMonth(by amount: Int) {
        guard let nextMonth = calendar.date(
            byAdding: .month,
            value: amount,
            to: currentMonth
        ) else {
            return
        }

        currentMonth = nextMonth

        // 切り替えた月の1日を選択する
        if let firstDay = calendar.date(
            from: calendar.dateComponents(
                [.year, .month],
                from: nextMonth
            )
        ) {
            selectedDate = calendar.startOfDay(
                for: firstDay
            )
        }
    }
}
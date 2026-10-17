import SwiftUI

struct CalendarView: View {
    @State private var currentMonth = Date()
    @State private var selectedDate: Date? = nil

    private let calendar = Calendar.current

    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentMonth)
    }

    private var days: [Date?] {
        guard let interval = calendar.dateInterval(
            of: .month,
            for: currentMonth
        ),
        let numberOfDays = calendar.range(
            of: .day,
            in: .month,
            for: currentMonth
        ) else {
            return []
        }

        let firstWeekday = calendar.component(
            .weekday,
            from: interval.start
        )

        let leadingEmptyDays = firstWeekday - 1

        var result = Array<Date?>(
            repeating: nil,
            count: leadingEmptyDays
        )

        for day in numberOfDays {
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

    var body: some View {
        VStack(spacing: 20) {
            // 月の切り替え
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }

                Spacer()

                Text(monthTitle)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                }
            }
            .padding(.horizontal)

            // 曜日の表示
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible()),
                    count: 7
                ),
                spacing: 12
            ) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            weekday == "日" ? .red :
                            weekday == "土" ? .blue :
                            .primary
                        )
                }

                // 日付の表示
                ForEach(days.indices, id: \.self) { index in
                    if let date = days[index] {
                        let day = calendar.component(
                            .day,
                            from: date
                        )

                        let isSelected = selectedDate.map {
                            calendar.isDate($0, inSameDayAs: date)
                        } ?? false

                        Button {
                            selectedDate = date
                        } label: {
                            Text("\(day)")
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .foregroundStyle(
                                    isSelected ? .white :
                                    index % 7 == 0 ? .red :
                                    index % 7 == 6 ? .blue :
                                    .primary
                                )
                                .background {
                                    if isSelected {
                                        Circle()
                                            .fill(Color.green)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal)

            // 選択した日付
            if let selectedDate {
                VStack(spacing: 8) {
                    Text(
                        selectedDate.formatted(
                            .dateTime
                                .locale(Locale(identifier: "ja_JP"))
                                .year()
                                .month()
                                .day()
                                .weekday(.wide)
                        )
                    )
                    .font(.headline)

                    Text("この日の筋トレ記録はまだありません")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    Color.green.opacity(0.1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top)
        .navigationTitle("カレンダー")
    }

    private func changeMonth(by value: Int) {
        guard let newMonth = calendar.date(
            byAdding: .month,
            value: value,
            to: currentMonth
        ) else {
            return
        }

        currentMonth = newMonth
        selectedDate = nil
    }
}




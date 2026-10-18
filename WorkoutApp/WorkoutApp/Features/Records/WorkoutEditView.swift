
import SwiftUI

struct WorkoutEditView: View {
    @Environment(\.dismiss) private var dismiss

    let record: WorkoutRecord
    let onSave: (WorkoutRecord) -> Void

    @State private var selectedDate: Date
    @State private var selectedMenu: String
    @State private var reps: Int
    @State private var sets: Int
    @State private var weight: Double

    private let menus = [
        "腹筋",
        "腕立て伏せ",
        "スクワット",
        "その他"
    ]

    init(
        record: WorkoutRecord,
        onSave: @escaping (WorkoutRecord) -> Void
    ) {
        self.record = record
        self.onSave = onSave

        _selectedDate = State(initialValue: record.date)
        _selectedMenu = State(initialValue: record.menu)
        _reps = State(initialValue: record.count)
        _sets = State(initialValue: record.sets)
        _weight = State(initialValue: record.weight)
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    "日付",
                    selection: $selectedDate,
                    displayedComponents: .date
                )

                Picker("メニュー", selection: $selectedMenu) {
                    ForEach(menus, id: \.self) { menu in
                        Text(menu).tag(menu)
                    }
                }

                Stepper(
                    "回数：\(reps) 回",
                    value: $reps,
                    in: 1...1000
                )

                Stepper(
                    "セット数：\(sets) セット",
                    value: $sets,
                    in: 1...100
                )

                HStack {
                    Text("重量")

                    Spacer()

                    TextField(
                        "0",
                        value: $weight,
                        format: .number
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)

                    Text("kg")
                }
            }
            .navigationTitle("記録を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let updatedRecord = WorkoutRecord(
                            id: record.id,
                            date: selectedDate,
                            menu: selectedMenu,
                            count: reps,
                            sets: sets,
                            weight: max(0, weight)
                        )

                        onSave(updatedRecord)
                        dismiss()
                    }
                }
            }
        }
    }
}

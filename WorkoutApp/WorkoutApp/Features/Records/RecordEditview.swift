
import SwiftUI

struct WorkoutEditView: View {
    let record: WorkoutRecord
    let onSave: (WorkoutRecord) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var menu: String
    @State private var countText: String
    @State private var setsText: String
    @State private var weightText: String

    @State private var showError = false

    init(
        record: WorkoutRecord,
        onSave: @escaping (WorkoutRecord) -> Void
    ) {
        self.record = record
        self.onSave = onSave

        _date = State(initialValue: record.date)
        _menu = State(initialValue: record.menu)
        _countText = State(initialValue: String(record.count))
        _setsText = State(initialValue: String(record.sets))
        _weightText = State(initialValue: String(record.weight))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("トレーニング記録") {
                    DatePicker(
                        "日付",
                        selection: $date,
                        displayedComponents: .date
                    )

                    TextField("メニュー", text: $menu)

                    TextField("回数", text: $countText)
                        .keyboardType(.numberPad)

                    TextField("セット数", text: $setsText)
                        .keyboardType(.numberPad)

                    TextField("重量（kg）", text: $weightText)
                        .keyboardType(.decimalPad)
                }

                Section {
                    Button("変更を保存") {
                        saveRecord()
                    }
                    .frame(maxWidth: .infinity)
                    .fontWeight(.bold)
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
            }
            .alert("入力内容を確認してください", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("回数とセット数には整数、重量には数値を入力してください。")
            }
        }
    }

    private func saveRecord() {
        guard
            !menu.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let count = Int(countText),
            count > 0,
            let sets = Int(setsText),
            sets > 0,
            let weight = Double(weightText),
            weight >= 0
        else {
            showError = true
            return
        }

        var updatedRecord = record
        updatedRecord.date = date
        updatedRecord.menu = menu
        updatedRecord.count = count
        updatedRecord.sets = sets
        updatedRecord.weight = weight

        onSave(updatedRecord)
        dismiss()
    }
}

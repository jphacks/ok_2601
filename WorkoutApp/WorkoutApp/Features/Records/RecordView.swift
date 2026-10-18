
import SwiftUI

struct RecordView: View {
    @EnvironmentObject private var workoutStore: WorkoutStore

    @State private var selectedDate = Date()
    @State private var selectedMenu = "腹筋"
    @State private var reps = 20
    @State private var sets = 3
    @State private var weight = 0.0

    //編集・削除用の状態
    @State private var editingRecord: WorkoutRecord?
    @State private var deletingRecord: WorkoutRecord?
    @State private var showDeleteConfirmation = false

    private let menus = [
        "腹筋",
        "腕立て伏せ",
        "スクワット",
        "その他"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // 入力フォーム
                VStack(alignment: .leading, spacing: 16) {
                    Label(
                        "トレーニングを記録",
                        systemImage: "plus.circle.fill"
                    )
                    .font(.headline)

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
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        addRecord()
                    } label: {
                        Label(
                            "記録を追加",
                            systemImage: "plus"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // 記録一覧
                VStack(alignment: .leading, spacing: 12) {
                    Text("記録一覧")
                        .font(.headline)

                    if workoutStore.records.isEmpty {
                        ContentUnavailableView(
                            "記録はありません",
                            systemImage: "list.clipboard",
                            description: Text(
                                "トレーニング内容を入力して記録しましょう"
                            )
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(
                            workoutStore.records.sorted {
                                $0.date > $1.date
                            }
                        ) { record in
                            recordRow(record)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("記録")
        
        .confirmationDialog(
            "この記録を削除しますか？",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                if let record = deletingRecord {
                    workoutStore.delete(record)
                }
                deletingRecord = nil
            }

            Button("キャンセル", role: .cancel) {
                deletingRecord = nil
            }
        }
        .sheet(item: $editingRecord) { record in
            WorkoutEditView(record: record) { updatedRecord in
                workoutStore.update(updatedRecord)
            }
        }
    }

        // 記録カード
        private func recordRow(_ record: WorkoutRecord) -> some View {
            HStack(spacing: 12) {
                Image(systemName: "dumbbell.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 5) {
                    Text(record.menu)
                        .font(.headline)

                    Text(record.date.formatted(date: .numeric, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(record.count) 回 × \(record.sets) セット")

                    if record.weight > 0 {
                        Text("重量：\(record.weight, specifier: "%.1f") kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        editingRecord = record
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .tint(.blue)

                    Button(role: .destructive) {
                        deletingRecord = record
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }

    // 記録追加
    private func addRecord() {
        let record = WorkoutRecord(
            date: selectedDate,
            menu: selectedMenu,
            count: reps,
            sets: sets,
            weight: max(0, weight)
        )

        workoutStore.add(record)

        // 次の入力に備えて初期値に戻す
        reps = 20
        sets = 3
        weight = 0
    }
}

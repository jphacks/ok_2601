
import SwiftUI

struct RecordView: View {
    @EnvironmentObject private var workoutStore: WorkoutStore

    @State private var selectedDate = Date()
    @State private var selectedMenu = "腹筋"
    @State private var reps = 20
    @State private var sets = 3
    @State private var weight = 0.0

    @State private var editingRecord: WorkoutRecord?
    @State private var deletingRecord: WorkoutRecord?
    @State private var showDeleteAlert = false

    private let menus = [
        "腹筋",
        "腕立て伏せ",
        "スクワット",
        "その他"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 新しい記録を追加
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
                        Label("記録を追加", systemImage: "plus")
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
        .sheet(item: $editingRecord) { record in
            WorkoutEditView(record: record) { updatedRecord in
                workoutStore.update(updatedRecord)
            }
        }
        .alert(
            "記録を削除しますか？",
            isPresented: $showDeleteAlert
        ) {
            Button("キャンセル", role: .cancel) {
                deletingRecord = nil
            }

            Button("削除", role: .destructive) {
                if let record = deletingRecord {
                    workoutStore.delete(record)
                }
                deletingRecord = nil
            }
        } message: {
            Text("削除した記録は元に戻せません。")
        }
    }

    // 記録カード
    private func recordRow(_ record: WorkoutRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 5) {
                Text(record.menu)
                    .font(.headline)

                Text(
                    record.date.formatted(
                        date: .numeric,
                        time: .omitted
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("\(record.count) 回 × \(record.sets) セット")
                    .font(.subheadline)

                if record.weight > 0 {
                    Text(
                        "重量：\(record.weight, specifier: "%.1f") kg"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 4)

            // 編集ボタン
            Button {
                editingRecord = record
            } label: {
                Image(systemName: "pencil")
                    .foregroundStyle(.blue)
                    .padding(8)
            }
            .buttonStyle(.borderless)

            // 削除ボタン
            Button {
                deletingRecord = record
                showDeleteAlert = true
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
                    .padding(8)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // 記録を追加
    private func addRecord() {
        let record = WorkoutRecord(
            date: selectedDate,
            menu: selectedMenu,
            count: reps,
            sets: sets,
            weight: max(0, weight)
        )

        workoutStore.add(record)

        reps = 20
        sets = 3
        weight = 0
    }
}

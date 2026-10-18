import SwiftUI

struct RecordView: View {
    @EnvironmentObject private var workoutStore: WorkoutStore
    
    @State private var showDeleteConfirmation = false
    @State private var deletingRecord: WorkoutRecord? = nil
    @State private var editingRecord: WorkoutRecord? = nil
    
    @State private var selectedDate = Date()
    @State private var selectedMenu = "腹筋"
    @State private var reps = 20
    @State private var sets = 3
    @State private var weight = 0.0
    @State private var selectedParts: Set<BodyPart> = [.abs]

    private let defaultMenus = ["腹筋", "腕立て伏せ", "スクワット", "ベンチプレス", "懸垂", "その他"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - 入力フォーム
                VStack(alignment: .leading, spacing: 16) {
                    Label("トレーニングを記録", systemImage: "plus.circle.fill")
                        .font(.headline)

                    DatePicker("日付", selection: $selectedDate, displayedComponents: .date)

                    // メニュー選択（変更時に部位を自動プリセット）
                    Picker("メニュー", selection: $selectedMenu) {
                        ForEach(defaultMenus, id: \.self) { menu in
                            Text(menu).tag(menu)
                        }
                    }
                    .onChange(of: selectedMenu) { _, newMenu in
                        updateDefaultParts(for: newMenu)
                    }

                    // 鍛える部位の選択（複数選択チップ）
                    VStack(alignment: .leading, spacing: 8) {
                        Text("鍛える部位")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 8) {
                            ForEach(BodyPart.allCases, id: \.self) { part in
                                let isSelected = selectedParts.contains(part)
                                Button {
                                    if isSelected {
                                        selectedParts.remove(part)
                                    } else {
                                        selectedParts.insert(part)
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        Text(part.rawValue)
                                    }
                                    .font(.caption)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(isSelected ? Color.accentColor : Color(uiColor: .tertiarySystemFill))
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Stepper("回数：\(reps) 回", value: $reps, in: 1...1000)
                    Stepper("セット数：\(sets) セット", value: $sets, in: 1...100)

                    HStack {
                        Text("重量")
                        Spacer()
                        TextField("0", value: $weight, format: .number)
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
                    .disabled(selectedParts.isEmpty) // 部位未選択時は押せない
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // MARK: - 記録一覧
                VStack(alignment: .leading, spacing: 12) {
                    Text("記録一覧")
                        .font(.headline)

                    if workoutStore.records.isEmpty {
                        ContentUnavailableView(
                            "記録はありません",
                            systemImage: "list.clipboard",
                            description: Text("トレーニング内容を入力して記録しましょう")
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(
                            workoutStore.records.sorted { $0.date > $1.date }
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
            Button("削除する", role: .destructive) {
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
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(record.menu)
                        .font(.headline)

                    // 登録されている部位バッジを表示
                    ForEach(record.targetParts, id: \.self) { part in
                        Text(part.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }

                Text(record.date.formatted(date: .numeric, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Text(record.date.formatted(date: .numeric, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                if record.weight > 0 {
                    Text("重量：\(record.weight, specifier: "%.1f") kg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // メニュー変更時の部位自動反映
    private func updateDefaultParts(for menu: String) {
        switch menu {
        case "腹筋":
            selectedParts = [.abs]
        case "腕立て伏せ":
            selectedParts = [.arm, .chest, .shoulder]
        case "スクワット":
            selectedParts = [.legs]
        case "ベンチプレス":
            selectedParts = [.chest, .shoulder, .arm]
        case "懸垂":
            selectedParts = [.back, .arm]
        default:
            break
        }
    }

    // 記録追加
    private func addRecord() {
        let record = WorkoutRecord(
            date: selectedDate,
            menu: selectedMenu,
            count: reps,
            sets: sets,
            weight: max(0, weight),
            targetParts: Array(selectedParts)
        )

        workoutStore.add(record)

        // 初期化
        reps = 20
        sets = 3
        weight = 0
    }
}

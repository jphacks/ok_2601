
import SwiftUI

struct GachaView: View {
    @EnvironmentObject var workoutStore: WorkoutStore

    @State private var resultMessage = ""
    @State private var showResult = false

    private let skinPool = [
        "トレーニングウェア",
        "ゴールドウェア",
        "レインボーウェア"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // ポイント残高
                    VStack(spacing: 8) {
                        Text("筋トレポイント")
                            .font(.headline)

                        Text("\(workoutStore.musclePoints) pt")
                            .font(.largeTitle.bold())

                        Text(
                            "獲得倍率："
                            + String(
                                format: "%.2f",
                                workoutStore.gachaPointMultiplier
                            )
                            + "倍"
                        )
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // ガチャ本体
                    VStack(spacing: 14) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 55))
                            .foregroundStyle(.orange)

                        Text("筋トレガチャ")
                            .font(.title.bold())

                        Text(
                            "1回 \(workoutStore.currentGachaCost) pt"
                        )
                        .font(.title2.bold())

                        Text(
                            "累計 \(workoutStore.totalGachaRolls) 回"
                        )
                        .foregroundStyle(.secondary)

                        Button(action: drawGacha) {
                            Text("ガチャを回す")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    workoutStore.musclePoints
                                    >= workoutStore.currentGachaCost
                                    ? Color.orange
                                    : Color.gray
                                )
                                .foregroundStyle(.white)
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 12)
                                )
                        }
                        .disabled(
                            workoutStore.musclePoints
                            < workoutStore.currentGachaCost
                        )
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        Color(.secondarySystemBackground)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // 排出率
                    VStack(alignment: .leading, spacing: 10) {
                        Text("排出率")
                            .font(.headline)

                        prizeRow("キャラスキン", rate: "15%")
                        prizeRow("ステロイド", rate: "5%")
                        prizeRow("プロテイン", rate: "80%")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Color(.secondarySystemBackground)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // 所持アイテム
                    VStack(alignment: .leading, spacing: 14) {
                        Text("所持アイテム")
                            .font(.title2.bold())

                        inventoryRow(
                            name: "プロテイン",
                            count: workoutStore.proteinCount,
                            effect: "+0.05倍 / 個",
                            icon: "pills.fill"
                        )

                        inventoryRow(
                            name: "ステロイド",
                            count: workoutStore.steroidCount,
                            effect: "+0.20倍 / 個",
                            icon: "bolt.fill"
                        )

                        Divider()

                        Text("獲得済みスキン")
                            .font(.headline)

                        if workoutStore.ownedSkins.isEmpty {
                            Text("まだスキンを持っていません")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(
                                workoutStore.ownedSkins,
                                id: \.self
                            ) { skin in
                                Label(
                                    skin,
                                    systemImage: "person.fill"
                                )
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Color(.secondarySystemBackground)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("ガチャ")
            .alert(
                "ガチャ結果",
                isPresented: $showResult
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resultMessage)
            }
        }
    }

    // MARK: - 抽選処理

    private func drawGacha() {
        let cost = workoutStore.currentGachaCost

        guard workoutStore.musclePoints >= cost else {
            resultMessage = "ポイントが不足しています。"
            showResult = true
            return
        }

        guard workoutStore.spendGachaPoints(cost) else {
            resultMessage = "ポイントが不足しています。"
            showResult = true
            return
        }

        workoutStore.totalGachaRolls += 1
        
        // 抽選回数を増加
        workoutStore.totalGachaRolls += 1

        let random = Int.random(in: 1...100)

        if random <= 15 {
            drawSkin()
        } else if random <= 20 {
            workoutStore.steroidCount += 1

            resultMessage = """
            ステロイドを獲得！

            筋トレポイントの獲得倍率が
            +0.20倍されました。
            """
        } else {
            workoutStore.proteinCount += 1

            resultMessage = """
            プロテインを獲得！

            筋トレポイントの獲得倍率が
            +0.05倍されました。
            """
        }

        resultMessage += """

        現在のポイント獲得倍率：
        \(String(
            format: "%.2f",
            workoutStore.gachaPointMultiplier
        ))倍
        """

        showResult = true
    }

    // MARK: - スキン抽選

    private func drawSkin() {
        let availableSkins = skinPool.filter {
            !workoutStore.ownedSkins.contains($0)
        }

        guard let skin = availableSkins.randomElement() else {
            // 全スキン獲得後はプロテインに変換
            workoutStore.proteinCount += 1

            resultMessage = """
            スキンはすべて獲得済みです。

            代わりにプロテインを獲得しました。
            """
            return
        }

        workoutStore.ownedSkins.append(skin)

        resultMessage = """
        新しいスキンを獲得！

        \(skin)
        """
    }

    // MARK: - 表示用パーツ

    private func prizeRow(
        _ name: String,
        rate: String
    ) -> some View {
        HStack {
            Text(name)
            Spacer()
            Text(rate)
                .fontWeight(.semibold)
        }
    }

    private func inventoryRow(
        name: String,
        count: Int,
        effect: String,
        icon: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 35)

            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)

                Text(effect)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(count)個")
                .fontWeight(.semibold)
        }
    }
}

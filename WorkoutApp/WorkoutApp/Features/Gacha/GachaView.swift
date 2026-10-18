
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
    private var gacha10Cost: Int {
        Int(ceil(Double(workoutStore.currentGachaCost) * 10 * 0.9))
    }

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
                        Button(action: drawGacha10) {
                            VStack(spacing: 4) {
                                Text("10連ガチャ")
                                    .font(.headline)

                                Text("\(gacha10Cost) pt（10% OFF）")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                workoutStore.musclePoints >= gacha10Cost
                                ? Color.purple
                                : Color.gray
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(workoutStore.musclePoints < gacha10Cost)
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

        guard workoutStore.spendGachaPoints(cost) else {
            resultMessage = "ポイントが不足しています。"
            showResult = true
            return
        }

        let prize = drawPrize()
        workoutStore.totalGachaRolls += 1

        resultMessage = """
        \(prize)

        現在のポイント獲得倍率：
        \(String(
            format: "%.2f",
            workoutStore.gachaPointMultiplier
        ))倍
        """

        showResult = true
    }

    private func drawGacha10() {
        // 購入時点の単発価格を使って10連価格を計算する
        let singleCost = workoutStore.currentGachaCost
        let cost = Int(ceil(Double(singleCost) * 10 * 0.9))

        guard workoutStore.spendGachaPoints(cost) else {
            resultMessage = "ポイントが不足しています。"
            showResult = true
            return
        }

        var results: [String] = []

        for _ in 0..<10 {
            results.append(drawPrize())
        }

        // 累計ガチャ回数を10回増やす
        workoutStore.totalGachaRolls += 10

        // 同じ結果をまとめて表示する
        var counts: [String: Int] = [:]
        var order: [String] = []

        for prize in results {
            if counts[prize] == nil {
                order.append(prize)
                counts[prize] = 0
            }
            counts[prize, default: 0] += 1
        }

        let summary = order.map { prize in
            "\(prize) × \(counts[prize]!)"
        }.joined(separator: "\n")

        resultMessage = """
        10連ガチャ結果！

        \(summary)

        消費ポイント：\(cost) pt
        割引前：\(singleCost * 10) pt
        割引：10%

        現在のポイント獲得倍率：
        \(String(
            format: "%.2f",
            workoutStore.gachaPointMultiplier
        ))倍
        """

        showResult = true
    }

    // MARK: - 1回分の抽選

    private func drawPrize() -> String {
        let random = Int.random(in: 1...100)

        if random <= 15 {
            return drawSkin()
        } else if random <= 20 {
            workoutStore.steroidCount += 1
            return "ステロイド"
        } else {
            workoutStore.proteinCount += 1
            return "プロテイン"
        }
    }

    // MARK: - スキン抽選

    private func drawSkin() -> String {
        let availableSkins = skinPool.filter {
            !workoutStore.ownedSkins.contains($0)
        }

        guard let skin = availableSkins.randomElement() else {
            // 全スキン獲得後はプロテインに変換
            workoutStore.proteinCount += 1
            return "プロテイン（スキン重複分の変換）"
        }

        workoutStore.ownedSkins.append(skin)
        return "新しいスキン：\(skin)"
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

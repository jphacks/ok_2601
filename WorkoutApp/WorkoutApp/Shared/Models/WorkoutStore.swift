
import Foundation
import Combine

@MainActor
final class WorkoutStore: ObservableObject {
    @Published private(set) var records: [WorkoutRecord] = []
    @Published private(set) var musclePoints = 0

    // 現在は仮の記録実績
    let totalRecordDays = 12
    let consecutiveRecordDays = 3

    // 記録追加とポイント加算を共通化
    func add(_ record: WorkoutRecord) {
        records.insert(record, at: 0)

        let basePoints = record.count * record.sets

        let multiplier =
            PointMultiplier.totalRecord(days: totalRecordDays)
            * PointMultiplier.streak(days: consecutiveRecordDays)

        let earnedPoints = Int(
            (Double(basePoints) * multiplier).rounded()
        )

        musclePoints += earnedPoints
    }
}

// ポイント倍率計算
enum PointMultiplier {
    // 総記録日数：5日ごとに +0.20倍
    static func totalRecord(days: Int) -> Double {
        let bonusSteps = max(0, days) / 5
        return 1.0 + Double(bonusSteps) * 0.20
    }

    // 連続記録日数：3日目から3日ごとに +0.25倍
    static func streak(days: Int) -> Double {
        guard days >= 3 else {
            return 1.0
        }

        let bonusSteps = (days - 1) / 3
        return 1.0 + Double(bonusSteps) * 0.25
    }
}

import Foundation
import Combine

@MainActor
final class WorkoutStore: ObservableObject {
    @Published private(set) var records: [WorkoutRecord] = []

    // 筋トレ記録を追加する
    func add(_ record: WorkoutRecord) {
        records.insert(record, at: 0)
    }
}

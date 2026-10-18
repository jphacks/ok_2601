
import Foundation

struct WorkoutRecord: Identifiable {
    let id: UUID
    var date: Date
    var menu: String
    var count: Int
    var sets: Int
    var weight: Double

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        menu: String,
        count: Int,
        sets: Int,
        weight: Double = 0
    ) {
        self.id = id
        self.date = date
        self.menu = menu
        self.count = count
        self.sets = sets
        self.weight = weight
    }
}


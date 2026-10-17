import Foundation

struct WorkoutRecord: Identifiable {
    let id: UUID
    let date: Date
    let menu: String
    let count: Int
    let sets: Int

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        menu: String,
        count: Int,
        sets: Int
    ) {
        self.id = id
        self.date = date
        self.menu = menu
        self.count = count
        self.sets = sets
    }
}

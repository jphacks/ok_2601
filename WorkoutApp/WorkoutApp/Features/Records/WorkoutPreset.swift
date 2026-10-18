
import Foundation

// 保存するトレーニング全体
struct WorkoutPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var exercises: [PresetExercise]

    init(
        id: UUID = UUID(),
        name: String,
        exercises: [PresetExercise] = []
    ) {
        self.id = id
        self.name = name
        self.exercises = exercises
    }
}

// マイセット内の種目
struct PresetExercise: Identifiable, Codable {
    let id: UUID
    var menuName: String
    var sets: [PresetSet]

    init(
        id: UUID = UUID(),
        menuName: String,
        sets: [PresetSet] = []
    ) {
        self.id = id
        self.menuName = menuName
        self.sets = sets
    }
}

// 1セットごとの重量と回数
struct PresetSet: Identifiable, Codable {
    let id: UUID
    var weight: Double
    var reps: Int

    init(
        id: UUID = UUID(),
        weight: Double,
        reps: Int
    ) {
        self.id = id
        self.weight = weight
        self.reps = reps
    }
}

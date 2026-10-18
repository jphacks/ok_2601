import Foundation

// MARK: - 部位の定義

enum BodyPart: String, CaseIterable, Hashable, Codable {
    case arm = "腕"
    case chest = "胸"
    case shoulder = "肩"
    case abs = "腹筋"
    case back = "背中"
    case legs = "脚"

    var growthFileName: String {
        switch self {
        case .arm:      return "arm_growth"
        case .chest:    return "chest_growth"
        case .shoulder: return "shoulder_growth"
        case .abs:      return "abs_growth"
        case .back:     return "back_growth"
        case .legs:     return "legs_growth"
        }
    }

    static func parts(for menu: String) -> [BodyPart] {
        switch menu {
        case "腕立て伏せ":
            return [.arm, .chest, .shoulder]
        case "腹筋":
            return [.abs]
        case "スクワット":
            return [.legs]
        case "ベンチプレス":
            return [.chest, .shoulder, .arm]
        case "懸垂":
            return [.back, .arm]
        default:
            return []
        }
    }
}

// MARK: - トレーニング記録モデル

struct WorkoutRecord: Identifiable, Codable {
    var id: UUID
    var date: Date
    var menu: String
    var count: Int
    var sets: Int
    var weight: Double
    var targetParts: [BodyPart]

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        menu: String,
        count: Int,
        sets: Int,
        weight: Double = 0.0,
        targetParts: [BodyPart]? = nil
    ) {
        self.id = id
        self.date = date
        self.menu = menu
        self.count = count
        self.sets = sets
        self.weight = weight
        self.targetParts = targetParts ?? BodyPart.parts(for: menu)
    }
}

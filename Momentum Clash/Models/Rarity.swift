import Foundation

/// 카드 레어리티
enum Rarity: Int, CaseIterable, Codable, Comparable {
    case normal = 0      // N
    case rare = 1        // R
    case superRare = 2   // SR
    case ultraRare = 3   // UR

    static func < (lhs: Rarity, rhs: Rarity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .normal:    return "N"
        case .rare:      return "R"
        case .superRare: return "SR"
        case .ultraRare: return "UR"
        }
    }
}

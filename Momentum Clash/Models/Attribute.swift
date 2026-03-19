import Foundation

/// 7가지 속성 (화/수/풍/지/뇌/암/광)
enum Attribute: String, CaseIterable, Codable {
    case fire    // 🔥 화
    case water   // 💧 수
    case wind    // 🌿 풍
    case earth   // ⛰️ 지
    case thunder // ⚡ 뇌
    case dark    // 🌑 암
    case light   // ✨ 광

    /// 이 속성이 유리한 상대 속성
    var strongAgainst: Attribute {
        switch self {
        case .fire:    return .wind
        case .water:   return .fire
        case .wind:    return .earth
        case .earth:   return .thunder
        case .thunder: return .water
        case .dark:    return .light
        case .light:   return .dark
        }
    }

    /// 이 속성이 불리한 상대 속성
    var weakAgainst: Attribute {
        switch self {
        case .fire:    return .water
        case .water:   return .thunder
        case .wind:    return .fire
        case .earth:   return .wind
        case .thunder: return .earth
        case .dark:    return .light
        case .light:   return .dark
        }
    }

    /// 공격 시 상성 배율 계산
    func damageMultiplier(against defender: Attribute) -> Double {
        // 광 ↔ 암: 서로 1.5배
        if (self == .dark && defender == .light) || (self == .light && defender == .dark) {
            return 1.5
        }
        if defender == strongAgainst {
            return 1.3
        }
        if defender == weakAgainst {
            return 0.7
        }
        return 1.0
    }

    var displayName: String {
        switch self {
        case .fire:    return "화(火)"
        case .water:   return "수(水)"
        case .wind:    return "풍(風)"
        case .earth:   return "지(地)"
        case .thunder: return "뇌(雷)"
        case .dark:    return "암(闇)"
        case .light:   return "광(光)"
        }
    }

    var emoji: String {
        switch self {
        case .fire:    return "🔥"
        case .water:   return "💧"
        case .wind:    return "🌿"
        case .earth:   return "⛰️"
        case .thunder: return "⚡"
        case .dark:    return "🌑"
        case .light:   return "✨"
        }
    }
}

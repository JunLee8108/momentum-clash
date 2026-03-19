import Foundation

/// 몬스터 타입
enum MonsterType: String, CaseIterable, Codable {
    case warrior  // 전사
    case mage     // 마법사
    case dragon   // 드래곤
    case machine  // 기계
    case spirit   // 정령
    case undead   // 언데드

    var displayName: String {
        switch self {
        case .warrior: return "전사"
        case .mage:    return "마법사"
        case .dragon:  return "드래곤"
        case .machine: return "기계"
        case .spirit:  return "정령"
        case .undead:  return "언데드"
        }
    }
}

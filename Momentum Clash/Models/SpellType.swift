import Foundation

/// 마법 카드 유형
enum SpellType: String, CaseIterable, Codable {
    case normal      // 일반 마법: 즉시 발동 후 묘지, 슬롯 차지 안 함
    case continuous  // 지속 마법: 슬롯에 배치, 매 턴 효과
    case equipment   // 장착 마법: 몬스터에 장착, 슬롯 차지 안 함
    case terrain     // 지형 마법: 지형 변경 후 묘지, 슬롯 차지 안 함

    /// 이 마법이 필드 슬롯을 차지하는지
    var occupiesSlot: Bool {
        switch self {
        case .continuous: return true
        case .normal, .equipment, .terrain: return false
        }
    }

    var displayName: String {
        switch self {
        case .normal:     return "일반 마법"
        case .continuous: return "지속 마법"
        case .equipment:  return "장착 마법"
        case .terrain:    return "지형 마법"
        }
    }
}

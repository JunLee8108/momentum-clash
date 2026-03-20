import Foundation

/// 기세(Momentum) 시스템
/// - 기세는 전투와 행동으로 쌓이며, 기세 스킬 전용 자원
/// - 기력(Energy)은 카드 소환/마법 발동 전용 자원
/// - 최대 10, 턴 간 누적
struct MomentumSystem {
    static let maxMomentum = 10
    static let baseEnergy = 3

    /// LP 비율에 따른 위기 보정 기본 기력 계산
    static func baseEnergy(currentLP: Int, maxLP: Int) -> Int {
        let ratio = Double(currentLP) / Double(maxLP)
        if ratio <= 0.25 {
            return 5
        } else if ratio <= 0.5 {
            return 4
        }
        return baseEnergy
    }
}

/// 기세 스킬
enum MomentumSkill: CaseIterable {
    case fighting       // 투지: 몬스터 1체 전투력 +500
    case terrainMastery // 지형 장악: 이번 턴 지형 보너스 2배 (+600)
    case doubleAttack   // 연속 공격: 몬스터 1체 2회 공격
    case breakthrough   // 전선 돌파: 이번 턴 모든 몬스터 전투력 +300
    case explosion      // 기세 폭발: 상대 전체에 기세 × 100 데미지
    case fullAwakening  // 완전 각성: 몬스터 1체 각성 형태로 변환 (Phase 5)

    var cost: Int {
        switch self {
        case .fighting:       return 3
        case .terrainMastery: return 4
        case .doubleAttack:   return 5
        case .breakthrough:   return 6
        case .explosion:      return 8
        case .fullAwakening:  return 10
        }
    }

    var displayName: String {
        switch self {
        case .fighting:       return "투지"
        case .terrainMastery: return "지형 장악"
        case .doubleAttack:   return "연속 공격"
        case .breakthrough:   return "전선 돌파"
        case .explosion:      return "기세 폭발"
        case .fullAwakening:  return "완전 각성"
        }
    }

    var description: String {
        switch self {
        case .fighting:       return "이번 턴 몬스터 1체 전투력 +500"
        case .terrainMastery: return "이번 턴 지형 보너스 2배 (+600)"
        case .doubleAttack:   return "몬스터 1체가 이번 턴 2회 공격 가능"
        case .breakthrough:   return "이번 턴 모든 몬스터 전투력 +300"
        case .explosion:      return "상대 필드 몬스터 전체에 기세 수 × 100 데미지"
        case .fullAwakening:  return "필드 위 몬스터 1체를 각성 형태로 변환"
        }
    }
}

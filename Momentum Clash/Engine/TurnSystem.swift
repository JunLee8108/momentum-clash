import Foundation

/// 턴 페이즈
enum TurnPhase: String {
    case draw       // 드로우 페이즈: 2장 중 1장 선택
    case standby    // 스탠바이 페이즈: 기력 수령, 지속 효과, 기세 처리
    case main       // 메인 페이즈: 소환, 마법 사용, 기세 스킬
    case battle     // 배틀 페이즈: 공격 선언
    case end        // 엔드 페이즈: 정리

    var displayName: String {
        switch self {
        case .draw:    return "드로우 페이즈"
        case .standby: return "스탠바이 페이즈"
        case .main:    return "메인 페이즈"
        case .battle:  return "배틀 페이즈"
        case .end:     return "엔드 페이즈"
        }
    }
}

/// 턴 관리 시스템
struct TurnSystem {
    static let maxHandSize = 8
    static let startingLP = 8000
    static let startingHandSize = 5
    static let deckMinSize = 30
    static let deckMaxSize = 50
    static let sameCardLimit = 3

    /// 선택 드로우: 덱에서 2장을 뽑아 선택지 제공
    /// 둘 다 마법이면 덱에서 가장 가까운 몬스터를 찾아 교체
    static func selectiveDraw(player: inout Player) -> (choice1: AnyCard, choice2: AnyCard)? {
        guard player.deck.count >= 2 else { return nil }
        let card1 = player.deck.removeFirst()
        var card2 = player.deck.removeFirst()

        // 둘 다 마법이면 → 덱에서 가장 가까운 몬스터를 찾아 card2와 교체
        if card1.isSpell && card2.isSpell {
            if let monsterIdx = player.deck.firstIndex(where: { !$0.isSpell }) {
                let monsterCard = player.deck.remove(at: monsterIdx)
                player.deck.insert(card2, at: monsterIdx) // 마법을 원래 위치에 되돌림
                card2 = monsterCard
            }
        }

        return (card1, card2)
    }

    /// 선택 드로우 결과 처리: 선택한 카드를 패에, 나머지를 덱 맨 아래로
    static func resolveSelectiveDraw(
        chosen: AnyCard,
        rejected: AnyCard,
        player: inout Player
    ) {
        player.hand.append(chosen)
        player.deck.append(rejected) // 덱 맨 아래로
    }

    /// 카드 소환 비용 지불 가능 여부
    static func canPayCost(
        cost: Int,
        currentEnergy: Int,
        currentMomentum: Int
    ) -> Bool {
        return currentEnergy + currentMomentum >= cost
    }

    /// 비용 지불 (기력 우선 소모, 부족하면 기세 소모)
    /// - Returns: (소모된 기력, 소모된 기세)
    static func payCost(
        cost: Int,
        player: inout Player
    ) -> (energySpent: Int, momentumSpent: Int)? {
        guard canPayCost(cost: cost, currentEnergy: player.energy, currentMomentum: player.momentum) else {
            return nil
        }

        let energySpent = min(player.energy, cost)
        let momentumSpent = cost - energySpent

        player.energy -= energySpent
        player.momentum -= momentumSpent

        return (energySpent, momentumSpent)
    }

    /// 엔드 페이즈 패 제한 확인
    static func excessCards(handSize: Int) -> Int {
        return max(0, handSize - maxHandSize)
    }
}

import Foundation

/// AI 덱 아키타입 정의 (각 몬스터 20장 + 마법 10장 = 30장)
enum AIDeckTemplates {

    struct DeckTemplate {
        let name: String
        let monsters: [(MonsterCard, Int)]  // (카드, 장수)
        let spells: [(SpellCard, Int)]

        func build() -> [AnyCard] {
            var deck: [AnyCard] = []
            for (card, count) in monsters {
                for _ in 0..<count { deck.append(.monster(card)) }
            }
            for (card, count) in spells {
                for _ in 0..<count { deck.append(.spell(card)) }
            }
            deck.shuffle()
            return deck
        }
    }

    /// 화염 러시 — 화+풍+뇌 공격형
    static let fireRush = DeckTemplate(
        name: "화염 러시",
        monsters: [
            (SampleCards.fireImp, 3),
            (SampleCards.fireSlasher, 3),
            (SampleCards.flameDragon, 2),
            (SampleCards.infernoKnight, 2),
            (SampleCards.galeAssassin, 3),
            (SampleCards.stormHawk, 2),
            (SampleCards.sparkSoldier, 2),
            (SampleCards.shadowRogue, 3),
        ],  // 20장
        spells: [
            (SampleCards.fireStorm, 3),
            (SampleCards.thunderJudgment, 2),
            (SampleCards.windStorm, 2),
            (SampleCards.darkVeil, 3),
        ]  // 10장
    )

    /// 대지 요새 — 지+수+광 방어형
    static let earthFortress = DeckTemplate(
        name: "대지 요새",
        monsters: [
            (SampleCards.earthGuard, 3),
            (SampleCards.rockGolem, 3),
            (SampleCards.mountainGiant, 2),
            (SampleCards.waterShield, 3),
            (SampleCards.tidalSerpent, 2),
            (SampleCards.mistSpirit, 2),
            (SampleCards.holyPriest, 2),
            (SampleCards.oceanLord, 1),
            (SampleCards.archangel, 2),
        ],  // 20장
        spells: [
            (SampleCards.earthEcho, 3),
            (SampleCards.healingRain, 3),
            (SampleCards.holyLight, 2),
            (SampleCards.darkVeil, 2),
        ]  // 10장
    )

    /// 뇌광 폭풍 — 뇌+광+풍 균형형
    static let thunderStorm = DeckTemplate(
        name: "뇌광 폭풍",
        monsters: [
            (SampleCards.sparkSoldier, 3),
            (SampleCards.thunderBeast, 3),
            (SampleCards.raijuEmperor, 1),
            (SampleCards.holyPriest, 3),
            (SampleCards.archangel, 1),
            (SampleCards.windFairy, 3),
            (SampleCards.stormHawk, 3),
            (SampleCards.galeAssassin, 3),
        ],  // 20장
        spells: [
            (SampleCards.thunderJudgment, 3),
            (SampleCards.holyLight, 3),
            (SampleCards.windStorm, 2),
            (SampleCards.darkVeil, 2),
        ]  // 10장
    )

    /// 암흑 지배 — 암+화+지 디버프형
    static let darkDominion = DeckTemplate(
        name: "암흑 지배",
        monsters: [
            (SampleCards.shadowRogue, 3),
            (SampleCards.deathKnight, 3),
            (SampleCards.fireSlasher, 3),
            (SampleCards.fireImp, 2),
            (SampleCards.flameDragon, 2),
            (SampleCards.earthGuard, 3),
            (SampleCards.rockGolem, 2),
            (SampleCards.mountainGiant, 2),
        ],  // 20장
        spells: [
            (SampleCards.darkVeil, 3),
            (SampleCards.fireStorm, 3),
            (SampleCards.earthEcho, 2),
            (SampleCards.thunderJudgment, 2),
        ]  // 10장
    )

    /// 모든 아키타입
    static let all: [DeckTemplate] = [fireRush, earthFortress, thunderStorm, darkDominion]

    /// 랜덤 AI 덱 선택
    static func randomDeck() -> (name: String, deck: [AnyCard]) {
        let template = all.randomElement()!
        return (template.name, template.build())
    }
}

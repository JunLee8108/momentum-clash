import Foundation

/// AI 덱 아키타입 정의 (각 몬스터 20장 + 마법 10장 = 30장, ★5 최대 2장)
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

    /// 화염 러시 — 화+풍 공격형
    static let fireRush = DeckTemplate(
        name: "화염 러시",
        monsters: [
            (SampleCards.fireImp, 3),          // ★1 화
            (SampleCards.windFairy, 2),         // ★1 풍
            (SampleCards.fireSlasher, 3),       // ★2 화
            (SampleCards.galeAssassin, 3),      // ★2 풍
            (SampleCards.volcanoMage, 2),       // ★3 화
            (SampleCards.stormHawk, 2),         // ★3 풍
            (SampleCards.flameDragon, 2),       // ★4 화
            (SampleCards.forestSage, 2),        // ★4 풍
            (SampleCards.infernoKnight, 1),     // ★5 화
        ],  // 20장, ★5: 1장
        spells: [
            (SampleCards.fireStorm, 3),
            (SampleCards.windStorm, 3),
            (SampleCards.thunderJudgment, 2),
            (SampleCards.darkVeil, 2),
        ]  // 10장
    )

    /// 대지 요새 — 지+수 방어형
    static let earthFortress = DeckTemplate(
        name: "대지 요새",
        monsters: [
            (SampleCards.pebbleFairy, 2),       // ★1 지
            (SampleCards.mistSpirit, 2),        // ★1 수
            (SampleCards.earthGuard, 3),        // ★2 지
            (SampleCards.waterShield, 3),       // ★2 수
            (SampleCards.rockGolem, 2),         // ★3 지
            (SampleCards.tidalSerpent, 2),      // ★3 수
            (SampleCards.mountainGiant, 2),     // ★4 지
            (SampleCards.iceWarrior, 2),        // ★4 수
            (SampleCards.earthEmperor, 1),      // ★5 지
            (SampleCards.oceanLord, 1),         // ★5 수
        ],  // 20장, ★5: 2장
        spells: [
            (SampleCards.earthEcho, 3),
            (SampleCards.healingRain, 3),
            (SampleCards.holyLight, 2),
            (SampleCards.darkVeil, 2),
        ]  // 10장
    )

    /// 뇌광 폭풍 — 뇌+광 콤보형
    static let thunderStorm = DeckTemplate(
        name: "뇌광 폭풍",
        monsters: [
            (SampleCards.sparkSoldier, 3),      // ★1 뇌
            (SampleCards.lightFirefly, 2),      // ★1 광
            (SampleCards.thunderFox, 3),        // ★2 뇌
            (SampleCards.holyPriest, 3),        // ★2 광
            (SampleCards.thunderBeast, 2),      // ★3 뇌
            (SampleCards.holyKnight, 2),        // ★3 광
            (SampleCards.lightningGeneral, 2),  // ★4 뇌
            (SampleCards.judgeAngel, 2),        // ★4 광
            (SampleCards.raijuEmperor, 1),      // ★5 뇌
        ],  // 20장, ★5: 1장
        spells: [
            (SampleCards.thunderJudgment, 3),
            (SampleCards.holyLight, 3),
            (SampleCards.healingRain, 2),
            (SampleCards.windStorm, 2),
        ]  // 10장
    )

    /// 암흑 지배 — 암+화 디버프형
    static let darkDominion = DeckTemplate(
        name: "암흑 지배",
        monsters: [
            (SampleCards.darkBat, 3),           // ★1 암
            (SampleCards.fireImp, 2),           // ★1 화
            (SampleCards.shadowRogue, 3),       // ★2 암
            (SampleCards.fireSlasher, 3),       // ★2 화
            (SampleCards.curseMage, 2),         // ★3 암
            (SampleCards.volcanoMage, 2),       // ★3 화
            (SampleCards.deathKnight, 2),       // ★4 암
            (SampleCards.flameDragon, 1),       // ★4 화
            (SampleCards.darkDragon, 1),        // ★5 암
            (SampleCards.infernoKnight, 1),     // ★5 화
        ],  // 20장, ★5: 2장
        spells: [
            (SampleCards.darkVeil, 3),
            (SampleCards.fireStorm, 3),
            (SampleCards.earthEcho, 2),
            (SampleCards.thunderJudgment, 2),
        ]  // 10장
    )

    /// 심해의 저주 — 수+암 컨트롤형
    static let deepSeaCurse = DeckTemplate(
        name: "심해의 저주",
        monsters: [
            (SampleCards.mistSpirit, 3),        // ★1 수
            (SampleCards.darkBat, 2),           // ★1 암
            (SampleCards.waterShield, 3),       // ★2 수
            (SampleCards.shadowRogue, 3),       // ★2 암
            (SampleCards.tidalSerpent, 2),      // ★3 수
            (SampleCards.curseMage, 2),         // ★3 암
            (SampleCards.iceWarrior, 2),        // ★4 수
            (SampleCards.deathKnight, 2),       // ★4 암
            (SampleCards.oceanLord, 1),         // ★5 수
        ],  // 20장, ★5: 1장
        spells: [
            (SampleCards.healingRain, 3),
            (SampleCards.darkVeil, 3),
            (SampleCards.holyLight, 2),
            (SampleCards.earthEcho, 2),
        ]  // 10장
    )

    /// 질풍노도 — 풍+뇌 속공형
    static let galeThunder = DeckTemplate(
        name: "질풍노도",
        monsters: [
            (SampleCards.windFairy, 3),         // ★1 풍
            (SampleCards.sparkSoldier, 3),      // ★1 뇌
            (SampleCards.galeAssassin, 3),      // ★2 풍
            (SampleCards.thunderFox, 3),        // ★2 뇌
            (SampleCards.stormHawk, 2),         // ★3 풍
            (SampleCards.thunderBeast, 2),      // ★3 뇌
            (SampleCards.forestSage, 2),        // ★4 풍
            (SampleCards.lightningGeneral, 1),  // ★4 뇌
            (SampleCards.typhoonDragon, 1),     // ★5 풍
        ],  // 20장, ★5: 1장
        spells: [
            (SampleCards.windStorm, 3),
            (SampleCards.thunderJudgment, 3),
            (SampleCards.fireStorm, 2),
            (SampleCards.darkVeil, 2),
        ]  // 10장
    )

    /// 모든 아키타입
    static let all: [DeckTemplate] = [
        fireRush, earthFortress, thunderStorm,
        darkDominion, deepSeaCurse, galeThunder
    ]

    /// 랜덤 AI 덱 선택
    static func randomDeck() -> (name: String, deck: [AnyCard]) {
        let template = all.randomElement()!
        return (template.name, template.build())
    }
}

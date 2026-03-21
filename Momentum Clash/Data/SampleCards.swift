import Foundation

/// 샘플 카드 데이터 및 테스트 덱
enum SampleCards {

    // MARK: - 🔥 화(Fire) 몬스터

    static let fireSlasher = MonsterCard(
        name: "화염 검사", attribute: .fire, cost: 2, rarity: .normal,
        combatPower: 1100, monsterType: .warrior,
        flavorText: "불꽃을 검에 담아 싸우는 용맹한 전사",
        imageName: "card_fire_slasher"
    )

    static let fireImp = MonsterCard(
        name: "불꽃 임프", attribute: .fire, cost: 1, rarity: .normal,
        combatPower: 500, monsterType: .spirit,
        flavorText: "작지만 맹렬한 불의 정령",
        imageName: "card_fire_imp"
    )

    static let flameDragon = MonsterCard(
        name: "염룡", attribute: .fire, cost: 4, rarity: .rare,
        combatPower: 2200, monsterType: .dragon,
        effect: CardEffect(timing: .onSummon, description: "소환 시 인접 슬롯 1개를 화(火) 지형으로 변경"),
        flavorText: "화염 속에서 태어난 드래곤",
        imageName: "card_flame_dragon"
    )

    static let infernoKnight = MonsterCard(
        name: "지옥 기사", attribute: .fire, cost: 5, rarity: .superRare,
        combatPower: 2800, monsterType: .warrior,
        effect: CardEffect(timing: .onSummon, description: "소환 시 상대에게 LP 500 데미지"),
        flavorText: "지옥의 불꽃으로 갑옷을 두른 기사",
        imageName: "card_inferno_knight"
    )

    // MARK: - 💧 수(Water) 몬스터

    static let mistSpirit = MonsterCard(
        name: "안개 정령", attribute: .water, cost: 2, rarity: .normal,
        combatPower: 700, monsterType: .spirit,
        effect: CardEffect(timing: .onSummon, description: "소환 시 인접 슬롯 1개를 수(水) 지형으로 변경"),
        flavorText: "안개를 몰고 다니는 신비한 정령",
        imageName: "card_mist_spirit"
    )

    static let waterShield = MonsterCard(
        name: "파수 거북", attribute: .water, cost: 2, rarity: .normal,
        combatPower: 1200, monsterType: .warrior,
        flavorText: "견고한 등껍질로 모든 것을 막아낸다",
        imageName: "card_water_shield"
    )

    static let tidalSerpent = MonsterCard(
        name: "해류 뱀", attribute: .water, cost: 3, rarity: .rare,
        combatPower: 1500, monsterType: .dragon,
        flavorText: "깊은 바다에서 올라온 거대 뱀",
        imageName: "card_tidal_serpent"
    )

    static let oceanLord = MonsterCard(
        name: "해왕", attribute: .water, cost: 5, rarity: .superRare,
        combatPower: 2700, monsterType: .dragon,
        effect: CardEffect(timing: .onSummon, description: "소환 시 아군 필드 전체를 수(水) 지형으로 변경"),
        flavorText: "바다를 지배하는 고대의 왕",
        imageName: "card_ocean_lord"
    )

    // MARK: - 🌿 풍(Wind) 몬스터

    static let windFairy = MonsterCard(
        name: "바람 요정", attribute: .wind, cost: 1, rarity: .normal,
        combatPower: 400, monsterType: .spirit,
        effect: CardEffect(timing: .onDestroy, description: "파괴 시 카드 1장 드로우"),
        flavorText: "산들바람과 함께 사라지는 요정",
        imageName: "card_wind_fairy"
    )

    static let stormHawk = MonsterCard(
        name: "폭풍 매", attribute: .wind, cost: 3, rarity: .rare,
        combatPower: 1600, monsterType: .dragon,
        flavorText: "폭풍 속을 자유로이 날아다니는 맹금",
        imageName: "card_storm_hawk"
    )

    static let galeAssassin = MonsterCard(
        name: "질풍 암살자", attribute: .wind, cost: 2, rarity: .normal,
        combatPower: 1000, monsterType: .warrior,
        flavorText: "바람처럼 빠른 그림자의 암살자",
        imageName: "card_gale_assassin"
    )

    // MARK: - ⛰️ 지(Earth) 몬스터

    static let rockGolem = MonsterCard(
        name: "바위 골렘", attribute: .earth, cost: 3, rarity: .normal,
        combatPower: 1800, monsterType: .machine,
        flavorText: "움직이는 거대한 바위 덩어리",
        imageName: "card_rock_golem"
    )

    static let earthGuard = MonsterCard(
        name: "대지의 수호자", attribute: .earth, cost: 2, rarity: .normal,
        combatPower: 1100, monsterType: .warrior,
        flavorText: "대지의 힘으로 아군을 지키는 수호자",
        imageName: "card_earth_guard"
    )

    static let mountainGiant = MonsterCard(
        name: "산악 거인", attribute: .earth, cost: 4, rarity: .rare,
        combatPower: 2400, monsterType: .warrior,
        flavorText: "산 하나를 등에 지고 걸어다니는 거인",
        imageName: "card_mountain_giant"
    )

    // MARK: - ⚡ 뇌(Thunder) 몬스터

    static let sparkSoldier = MonsterCard(
        name: "전격 병사", attribute: .thunder, cost: 1, rarity: .normal,
        combatPower: 600, monsterType: .machine,
        flavorText: "전류로 무장한 기계 병사",
        imageName: "card_spark_soldier"
    )

    static let thunderBeast = MonsterCard(
        name: "뇌수", attribute: .thunder, cost: 3, rarity: .rare,
        combatPower: 1400, monsterType: .dragon,
        effect: CardEffect(timing: .onAttack, description: "공격 시 상대 몬스터 전투력 -200"),
        flavorText: "번개를 몸에 두른 야수",
        imageName: "card_thunder_beast"
    )

    static let raijuEmperor = MonsterCard(
        name: "뇌제 라이쥬", attribute: .thunder, cost: 5, rarity: .ultraRare,
        combatPower: 2800, monsterType: .dragon,
        effect: CardEffect(timing: .onSummon, description: "소환 시 상대 지형 전체를 뇌(雷)로 변경"),
        flavorText: "번개의 화신이자 하늘의 제왕",
        imageName: "card_raiju_emperor"
    )

    // MARK: - 🌑 암(Dark) 몬스터

    static let shadowRogue = MonsterCard(
        name: "그림자 도적", attribute: .dark, cost: 2, rarity: .normal,
        combatPower: 900, monsterType: .warrior,
        effect: CardEffect(timing: .onDestroy, description: "파괴 시 상대 기세 -1"),
        flavorText: "어둠 속에서 기회를 노리는 도적",
        imageName: "card_shadow_rogue"
    )

    static let deathKnight = MonsterCard(
        name: "죽음의 기사", attribute: .dark, cost: 4, rarity: .rare,
        combatPower: 2100, monsterType: .undead,
        flavorText: "죽음 이후에도 싸움을 멈추지 않는 기사",
        imageName: "card_death_knight"
    )

    // MARK: - ✨ 광(Light) 몬스터

    static let holyPriest = MonsterCard(
        name: "성광 사제", attribute: .light, cost: 2, rarity: .normal,
        combatPower: 600, monsterType: .mage,
        effect: CardEffect(timing: .onSummon, description: "소환 시 아군 몬스터 1체에 방어막 500 부여"),
        flavorText: "빛의 힘으로 아군을 치유하는 사제",
        imageName: "card_holy_priest"
    )

    static let archangel = MonsterCard(
        name: "대천사", attribute: .light, cost: 5, rarity: .superRare,
        combatPower: 2600, monsterType: .spirit,
        effect: CardEffect(timing: .onSummon, description: "소환 시 아군 전체 전투력 +200"),
        flavorText: "천상에서 내려온 심판의 천사",
        imageName: "card_archangel"
    )

    // MARK: - 지형 마법 카드 (7종)

    static let fireStorm = SpellCard(
        name: "화염 폭풍", attribute: .fire, cost: 2, rarity: .rare,
        spellType: .terrain,
        effect: CardEffect(timing: .onSummon, description: "지형을 화염으로 2라운드 변경. 상대 몬스터 전체에 200 데미지"),
        flavorText: "불의 폭풍이 전장을 뒤덮는다",
        imageName: "spell_fire_storm"
    )

    static let healingRain = SpellCard(
        name: "치유의 비", attribute: .water, cost: 2, rarity: .rare,
        spellType: .terrain,
        effect: CardEffect(timing: .onSummon, description: "지형을 수류로 2라운드 변경. 아군 LP 300 회복"),
        flavorText: "생명의 비가 전장을 적신다",
        imageName: "spell_healing_rain"
    )

    static let earthEcho = SpellCard(
        name: "대지의 울림", attribute: .earth, cost: 2, rarity: .rare,
        spellType: .terrain,
        effect: CardEffect(timing: .onSummon, description: "지형을 대지로 2라운드 변경. 아군 몬스터 전체에 방어막 200 부여"),
        flavorText: "대지가 울리며 전장이 변한다",
        imageName: "spell_earth_echo"
    )

    static let windStorm = SpellCard(
        name: "폭풍의 눈", attribute: .wind, cost: 2, rarity: .rare,
        spellType: .terrain,
        effect: CardEffect(timing: .onSummon, description: "지형을 폭풍으로 2라운드 변경. 상대 몬스터 1체 전투력 -200"),
        flavorText: "폭풍이 전장을 휩쓸며 바꿔놓는다",
        imageName: "spell_wind_storm"
    )

    static let thunderJudgment = SpellCard(
        name: "번개의 심판", attribute: .thunder, cost: 2, rarity: .rare,
        spellType: .terrain,
        effect: CardEffect(timing: .onSummon, description: "지형을 번개로 2라운드 변경. 상대 몬스터 1체에 300 데미지"),
        flavorText: "하늘의 심판이 전장을 뒤흔든다",
        imageName: "spell_thunder_judgment"
    )

    static let darkVeil = SpellCard(
        name: "암흑의 장막", attribute: .dark, cost: 2, rarity: .rare,
        spellType: .terrain,
        effect: CardEffect(timing: .onSummon, description: "지형을 암흑으로 2라운드 변경. 상대 몬스터 전체 방어막 제거"),
        flavorText: "어둠이 전장을 삼키며 방어를 무너뜨린다",
        imageName: "spell_dark_veil"
    )

    static let holyLight = SpellCard(
        name: "성스러운 빛", attribute: .light, cost: 2, rarity: .rare,
        spellType: .terrain,
        effect: CardEffect(timing: .onSummon, description: "지형을 빛으로 2라운드 변경. 아군 몬스터 전체 HP 200 회복"),
        flavorText: "성스러운 빛이 전장을 비추며 아군을 치유한다",
        imageName: "spell_holy_light"
    )

    // MARK: - 카드 풀

    /// 전체 몬스터 카드 목록 (21종)
    static let allMonsters: [MonsterCard] = [
        fireSlasher, fireImp, flameDragon, infernoKnight,
        mistSpirit, waterShield, tidalSerpent, oceanLord,
        windFairy, stormHawk, galeAssassin,
        rockGolem, earthGuard, mountainGiant,
        sparkSoldier, thunderBeast, raijuEmperor,
        shadowRogue, deathKnight,
        holyPriest, archangel
    ]

    /// 전체 마법 카드 목록 (7종)
    static let allSpells: [SpellCard] = [
        fireStorm, healingRain, earthEcho, windStorm,
        thunderJudgment, darkVeil, holyLight
    ]

    // MARK: - 프리셋 덱 메타데이터

    struct PresetDeck: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let emoji: String
        let accentColorName: String
        let monsters: [(MonsterCard, Int)]
        let spells: [(SpellCard, Int)]

        func build() -> [AnyCard] {
            var deck: [AnyCard] = []
            for (card, count) in monsters {
                for _ in 0..<count { deck.append(.monster(card)) }
            }
            for (card, count) in spells {
                for _ in 0..<count { deck.append(.spell(card)) }
            }
            return deck
        }
    }

    static let presetDecks: [PresetDeck] = [
        PresetDeck(
            name: "화염 러시",
            description: "저코스트 화/풍 몬스터로 빠르게 공격하는 공격형 덱",
            emoji: "🔥",
            accentColorName: "red",
            monsters: [
                (fireImp, 3), (fireSlasher, 3), (galeAssassin, 3),
                (windFairy, 2), (sparkSoldier, 2), (flameDragon, 2),
                (stormHawk, 3), (infernoKnight, 2),
            ],
            spells: [
                (fireStorm, 3), (windStorm, 3),
                (thunderJudgment, 2), (darkVeil, 2),
            ]
        ),
        PresetDeck(
            name: "대지 요새",
            description: "높은 전투력의 지/수 몬스터로 버티는 방어형 덱",
            emoji: "⛰️",
            accentColorName: "brown",
            monsters: [
                (earthGuard, 3), (rockGolem, 3), (mountainGiant, 2),
                (waterShield, 3), (tidalSerpent, 2), (mistSpirit, 3),
                (holyPriest, 2), (oceanLord, 2),
            ],
            spells: [
                (earthEcho, 3), (healingRain, 3),
                (holyLight, 2), (darkVeil, 2),
            ]
        ),
        PresetDeck(
            name: "뇌광 폭풍",
            description: "뇌+광 시너지로 지형을 장악하는 콤보 덱",
            emoji: "⚡",
            accentColorName: "yellow",
            monsters: [
                (sparkSoldier, 3), (thunderBeast, 3), (raijuEmperor, 2),
                (holyPriest, 3), (archangel, 2), (waterShield, 3),
                (tidalSerpent, 2), (windFairy, 2),
            ],
            spells: [
                (thunderJudgment, 3), (holyLight, 3),
                (healingRain, 2), (windStorm, 2),
            ]
        ),
        PresetDeck(
            name: "암흑 지배",
            description: "암+화 속성으로 상대를 압박하는 파괴형 덱",
            emoji: "🌑",
            accentColorName: "purple",
            monsters: [
                (shadowRogue, 3), (deathKnight, 3), (fireSlasher, 3),
                (fireImp, 3), (flameDragon, 2), (infernoKnight, 2),
                (earthGuard, 2), (rockGolem, 2),
            ],
            spells: [
                (darkVeil, 3), (fireStorm, 3),
                (earthEcho, 2), (thunderJudgment, 2),
            ]
        ),
    ]

    // MARK: - 테스트 덱

    /// 화염 러시 덱 (30장)
    static func fireRushDeck() -> [AnyCard] {
        var deck: [AnyCard] = []
        // 몬스터 22장
        for _ in 0..<3 { deck.append(.monster(fireImp)) }
        for _ in 0..<3 { deck.append(.monster(fireSlasher)) }
        for _ in 0..<3 { deck.append(.monster(galeAssassin)) }
        for _ in 0..<2 { deck.append(.monster(flameDragon)) }
        for _ in 0..<2 { deck.append(.monster(sparkSoldier)) }
        for _ in 0..<3 { deck.append(.monster(earthGuard)) }
        for _ in 0..<2 { deck.append(.monster(stormHawk)) }
        for _ in 0..<2 { deck.append(.monster(infernoKnight)) }
        for _ in 0..<2 { deck.append(.monster(shadowRogue)) }
        // 마법 8장 (지형 마법)
        for _ in 0..<2 { deck.append(.spell(fireStorm)) }
        for _ in 0..<2 { deck.append(.spell(thunderJudgment)) }
        for _ in 0..<2 { deck.append(.spell(windStorm)) }
        for _ in 0..<2 { deck.append(.spell(darkVeil)) }
        deck.shuffle()
        return deck
    }

    /// 대지 요새 덱 (30장)
    static func earthFortressDeck() -> [AnyCard] {
        var deck: [AnyCard] = []
        // 몬스터 22장
        for _ in 0..<3 { deck.append(.monster(earthGuard)) }
        for _ in 0..<3 { deck.append(.monster(rockGolem)) }
        for _ in 0..<2 { deck.append(.monster(mountainGiant)) }
        for _ in 0..<3 { deck.append(.monster(waterShield)) }
        for _ in 0..<2 { deck.append(.monster(tidalSerpent)) }
        for _ in 0..<2 { deck.append(.monster(holyPriest)) }
        for _ in 0..<2 { deck.append(.monster(deathKnight)) }
        for _ in 0..<3 { deck.append(.monster(mistSpirit)) }
        for _ in 0..<2 { deck.append(.monster(oceanLord)) }
        // 마법 8장 (지형 마법)
        for _ in 0..<2 { deck.append(.spell(earthEcho)) }
        for _ in 0..<2 { deck.append(.spell(healingRain)) }
        for _ in 0..<2 { deck.append(.spell(holyLight)) }
        for _ in 0..<2 { deck.append(.spell(darkVeil)) }
        deck.shuffle()
        return deck
    }
}

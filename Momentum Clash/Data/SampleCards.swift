import Foundation

/// 샘플 카드 데이터 및 테스트 덱
enum SampleCards {

    // MARK: - 🔥 화(Fire) 몬스터

    static let fireSlasher = MonsterCard(
        name: "화염 검사", attribute: .fire, cost: 2, rarity: .normal,
        combatPower: 1100, monsterType: .warrior,
        flavorText: "불꽃을 검에 담아 싸우는 용맹한 전사"
    )

    static let fireImp = MonsterCard(
        name: "불꽃 임프", attribute: .fire, cost: 1, rarity: .normal,
        combatPower: 500, monsterType: .spirit,
        flavorText: "작지만 맹렬한 불의 정령"
    )

    static let flameDragon = MonsterCard(
        name: "염룡", attribute: .fire, cost: 4, rarity: .rare,
        combatPower: 2200, monsterType: .dragon,
        effect: CardEffect(timing: .onSummon, description: "소환 시 인접 슬롯 1개를 화(火) 지형으로 변경"),
        flavorText: "화염 속에서 태어난 드래곤"
    )

    static let infernoKnight = MonsterCard(
        name: "지옥화 기사", attribute: .fire, cost: 5, rarity: .superRare,
        combatPower: 2800, monsterType: .warrior,
        effect: CardEffect(timing: .onSummon, description: "소환 시 상대 몬스터 1체에 500 데미지"),
        flavorText: "지옥의 불꽃으로 갑옷을 두른 기사"
    )

    // MARK: - 💧 수(Water) 몬스터

    static let mistSpirit = MonsterCard(
        name: "안개 정령", attribute: .water, cost: 2, rarity: .normal,
        combatPower: 700, monsterType: .spirit,
        effect: CardEffect(timing: .onSummon, description: "소환 시 인접 슬롯 1개를 수(水) 지형으로 변경"),
        flavorText: "안개를 몰고 다니는 신비한 정령"
    )

    static let waterShield = MonsterCard(
        name: "파수 거북", attribute: .water, cost: 2, rarity: .normal,
        combatPower: 1200, monsterType: .warrior,
        flavorText: "견고한 등껍질로 모든 것을 막아낸다"
    )

    static let tidalSerpent = MonsterCard(
        name: "해류 뱀", attribute: .water, cost: 3, rarity: .rare,
        combatPower: 1500, monsterType: .dragon,
        flavorText: "깊은 바다에서 올라온 거대 뱀"
    )

    static let oceanLord = MonsterCard(
        name: "해왕", attribute: .water, cost: 5, rarity: .superRare,
        combatPower: 2700, monsterType: .dragon,
        effect: CardEffect(timing: .onSummon, description: "소환 시 아군 필드 전체를 수(水) 지형으로 변경"),
        flavorText: "바다를 지배하는 고대의 왕"
    )

    // MARK: - 🌿 풍(Wind) 몬스터

    static let windFairy = MonsterCard(
        name: "바람 요정", attribute: .wind, cost: 1, rarity: .normal,
        combatPower: 400, monsterType: .spirit,
        effect: CardEffect(timing: .onDestroy, description: "파괴 시 카드 1장 드로우"),
        flavorText: "산들바람과 함께 사라지는 요정"
    )

    static let stormHawk = MonsterCard(
        name: "폭풍 매", attribute: .wind, cost: 3, rarity: .rare,
        combatPower: 1600, monsterType: .dragon,
        flavorText: "폭풍 속을 자유로이 날아다니는 맹금"
    )

    static let galeAssassin = MonsterCard(
        name: "질풍 암살자", attribute: .wind, cost: 2, rarity: .normal,
        combatPower: 1000, monsterType: .warrior,
        flavorText: "바람처럼 빠른 그림자의 암살자"
    )

    // MARK: - ⛰️ 지(Earth) 몬스터

    static let rockGolem = MonsterCard(
        name: "바위 골렘", attribute: .earth, cost: 3, rarity: .normal,
        combatPower: 1800, monsterType: .machine,
        flavorText: "움직이는 거대한 바위 덩어리"
    )

    static let earthGuard = MonsterCard(
        name: "대지의 수호자", attribute: .earth, cost: 2, rarity: .normal,
        combatPower: 1100, monsterType: .warrior,
        flavorText: "대지의 힘으로 아군을 지키는 수호자"
    )

    static let mountainGiant = MonsterCard(
        name: "산악 거인", attribute: .earth, cost: 4, rarity: .rare,
        combatPower: 2400, monsterType: .warrior,
        flavorText: "산 하나를 등에 지고 걸어다니는 거인"
    )

    // MARK: - ⚡ 뇌(Thunder) 몬스터

    static let sparkSoldier = MonsterCard(
        name: "전격 병사", attribute: .thunder, cost: 1, rarity: .normal,
        combatPower: 600, monsterType: .machine,
        flavorText: "전류로 무장한 기계 병사"
    )

    static let thunderBeast = MonsterCard(
        name: "뇌수", attribute: .thunder, cost: 3, rarity: .rare,
        combatPower: 1400, monsterType: .dragon,
        effect: CardEffect(timing: .onAttack, description: "공격 시 상대 몬스터 전투력 -200"),
        flavorText: "번개를 몸에 두른 야수"
    )

    static let raijuEmperor = MonsterCard(
        name: "뇌제 라이쥬", attribute: .thunder, cost: 5, rarity: .ultraRare,
        combatPower: 2800, monsterType: .dragon,
        effect: CardEffect(timing: .onSummon, description: "소환 시 상대 지형 전체를 뇌(雷)로 변경"),
        flavorText: "번개의 화신이자 하늘의 제왕"
    )

    // MARK: - 🌑 암(Dark) 몬스터

    static let shadowRogue = MonsterCard(
        name: "그림자 도적", attribute: .dark, cost: 2, rarity: .normal,
        combatPower: 900, monsterType: .warrior,
        effect: CardEffect(timing: .onDestroy, description: "파괴 시 상대 기세 -1"),
        flavorText: "어둠 속에서 기회를 노리는 도적"
    )

    static let deathKnight = MonsterCard(
        name: "죽음의 기사", attribute: .dark, cost: 4, rarity: .rare,
        combatPower: 2100, monsterType: .undead,
        flavorText: "죽음 이후에도 싸움을 멈추지 않는 기사"
    )

    // MARK: - ✨ 광(Light) 몬스터

    static let holyPriest = MonsterCard(
        name: "성광 사제", attribute: .light, cost: 2, rarity: .normal,
        combatPower: 600, monsterType: .mage,
        effect: CardEffect(timing: .onSummon, description: "소환 시 아군 몬스터 1체에 방어막 500 부여"),
        flavorText: "빛의 힘으로 아군을 치유하는 사제"
    )

    static let archangel = MonsterCard(
        name: "대천사", attribute: .light, cost: 5, rarity: .superRare,
        combatPower: 2600, monsterType: .spirit,
        effect: CardEffect(timing: .onSummon, description: "소환 시 아군 전체 전투력 +200"),
        flavorText: "천상에서 내려온 심판의 천사"
    )

    // MARK: - 마법 카드

    static let earthBarrier = SpellCard(
        name: "대지의 방벽", attribute: .earth, cost: 1, rarity: .normal,
        spellType: .normal,
        effect: CardEffect(timing: .onSummon, description: "아군 몬스터 1체에 방어막 600 부여"),
        flavorText: "대지의 힘이 아군을 감싼다"
    )

    static let fireStorm = SpellCard(
        name: "화염 폭풍", attribute: .fire, cost: 3, rarity: .rare,
        spellType: .normal,
        effect: CardEffect(timing: .onSummon, description: "상대 몬스터 전체에 400 데미지"),
        flavorText: "모든 것을 태우는 불의 폭풍"
    )

    static let healingRain = SpellCard(
        name: "치유의 비", attribute: .water, cost: 2, rarity: .normal,
        spellType: .normal,
        effect: CardEffect(timing: .onSummon, description: "아군 LP 500 회복"),
        flavorText: "생명의 비가 상처를 씻어낸다"
    )

    static let eternalFurnace = SpellCard(
        name: "불멸의 화로", attribute: .fire, cost: 3, rarity: .rare,
        spellType: .continuous,
        effect: CardEffect(timing: .eachTurn, description: "매 턴 아군 화(火) 속성 몬스터 전투력 +200"),
        flavorText: "꺼지지 않는 화로가 아군을 강화한다"
    )

    static let earthEcho = SpellCard(
        name: "대지의 울림", attribute: .earth, cost: 2, rarity: .normal,
        spellType: .terrain,
        effect: CardEffect(timing: .onSummon, description: "필드 슬롯 2개를 지(地) 속성으로 변경"),
        flavorText: "대지가 울리며 지형이 변한다"
    )

    static let windBlade = SpellCard(
        name: "바람의 칼날", attribute: .wind, cost: 1, rarity: .normal,
        spellType: .equipment,
        effect: CardEffect(timing: .passive, description: "장착된 몬스터 전투력 +400"),
        flavorText: "바람을 베는 보이지 않는 칼"
    )

    static let thunderStrike = SpellCard(
        name: "낙뢰", attribute: .thunder, cost: 2, rarity: .normal,
        spellType: .normal,
        effect: CardEffect(timing: .onSummon, description: "상대 몬스터 1체에 800 데미지"),
        flavorText: "하늘에서 내리꽂히는 심판의 번개"
    )

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
        // 강화: 고비용 추가
        for _ in 0..<2 { deck.append(.monster(shadowRogue)) }
        // 마법 8장
        for _ in 0..<2 { deck.append(.spell(fireStorm)) }
        for _ in 0..<2 { deck.append(.spell(earthBarrier)) }
        for _ in 0..<2 { deck.append(.spell(windBlade)) }
        for _ in 0..<2 { deck.append(.spell(thunderStrike)) }
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
        // 마법 8장
        for _ in 0..<3 { deck.append(.spell(earthBarrier)) }
        for _ in 0..<2 { deck.append(.spell(earthEcho)) }
        for _ in 0..<2 { deck.append(.spell(healingRain)) }
        deck.append(.spell(eternalFurnace))
        deck.shuffle()
        return deck
    }
}

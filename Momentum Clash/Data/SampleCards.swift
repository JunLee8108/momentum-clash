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
        effect: CardEffect(timing: .onSummon, description: "소환 시 상대 몬스터 1체의 전투력 -400",
            actions: [EffectActionEntry(action: .cpDebuff(-400), target: .selectEnemy)]),
        flavorText: "화염 속에서 태어난 드래곤",
        imageName: "card_flame_dragon"
    )

    static let infernoKnight = MonsterCard(
        name: "지옥 기사", attribute: .fire, cost: 5, rarity: .superRare,
        combatPower: 2800, monsterType: .warrior,
        effect: CardEffect(timing: .onSummon, description: "소환 시 필드를 화(火)로 오버라이드(2턴). 상대에게 LP 500 데미지",
            actions: [
                EffectActionEntry(action: .fieldOverride, target: .selfSlot),
                EffectActionEntry(action: .damageLP(500), target: .opponent),
            ]),
        flavorText: "지옥의 불꽃으로 갑옷을 두른 기사",
        imageName: "card_inferno_knight"
    )

    static let volcanoMage = MonsterCard(
        name: "화산 마도사", attribute: .fire, cost: 3, rarity: .rare,
        combatPower: 1300, monsterType: .mage,
        effect: CardEffect(timing: .onSummon, description: "소환 시 상대 몬스터 1체의 전투력 -300",
            actions: [EffectActionEntry(action: .cpDebuff(-300), target: .selectEnemy)]),
        flavorText: "용암을 다루는 화산의 마도사",
        imageName: "card_volcano_mage"
    )

    // MARK: - 💧 수(Water) 몬스터

    static let mistSpirit = MonsterCard(
        name: "안개 정령", attribute: .water, cost: 1, rarity: .normal,
        combatPower: 450, monsterType: .spirit,
        effect: CardEffect(timing: .onSummon, description: "소환 시 아군 LP 150 회복",
            actions: [EffectActionEntry(action: .healLP(150), target: .player)]),
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
        effect: CardEffect(timing: .onSummon, description: "소환 시 필드를 수(水)로 오버라이드(2턴). 아군 LP 500 회복",
            actions: [
                EffectActionEntry(action: .fieldOverride, target: .selfSlot),
                EffectActionEntry(action: .healLP(500), target: .player),
            ]),
        flavorText: "바다를 지배하는 고대의 왕",
        imageName: "card_ocean_lord"
    )

    static let iceWarrior = MonsterCard(
        name: "빙결 용사", attribute: .water, cost: 4, rarity: .rare,
        combatPower: 2100, monsterType: .warrior,
        effect: CardEffect(timing: .onSummon, description: "소환 시 아군 LP 300 회복",
            actions: [EffectActionEntry(action: .healLP(300), target: .player)]),
        flavorText: "얼음 갑옷을 두른 냉혹한 전사",
        imageName: "card_ice_warrior"
    )

    // MARK: - 🌿 풍(Wind) 몬스터

    static let windFairy = MonsterCard(
        name: "바람 요정", attribute: .wind, cost: 1, rarity: .normal,
        combatPower: 400, monsterType: .spirit,
        effect: CardEffect(timing: .onDestroy, description: "파괴 시 카드 1장 드로우",
            actions: [EffectActionEntry(action: .drawCards(1), target: .player)]),
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

    static let forestSage = MonsterCard(
        name: "숲의 현자", attribute: .wind, cost: 4, rarity: .rare,
        combatPower: 2100, monsterType: .mage,
        effect: CardEffect(timing: .onSummon, description: "소환 시 카드 1장 드로우",
            actions: [EffectActionEntry(action: .drawCards(1), target: .player)]),
        flavorText: "고대 숲의 지혜를 간직한 현자",
        imageName: "card_forest_sage"
    )

    static let typhoonDragon = MonsterCard(
        name: "태풍룡", attribute: .wind, cost: 5, rarity: .superRare,
        combatPower: 2700, monsterType: .dragon,
        effect: CardEffect(timing: .onSummon, description: "소환 시 필드를 풍(風)으로 오버라이드(2턴). 상대 몬스터 전체 전투력 -300",
            actions: [
                EffectActionEntry(action: .fieldOverride, target: .selfSlot),
                EffectActionEntry(action: .fieldCpDebuff(-300), target: .opponent),
            ]),
        flavorText: "태풍을 몰고 다니는 바람의 용",
        imageName: "card_typhoon_dragon"
    )

    // MARK: - ⛰️ 지(Earth) 몬스터

    static let pebbleFairy = MonsterCard(
        name: "자갈 요정", attribute: .earth, cost: 1, rarity: .normal,
        combatPower: 500, monsterType: .spirit,
        flavorText: "작은 자갈에 깃든 대지의 정령",
        imageName: "card_pebble_fairy"
    )

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
        effect: CardEffect(timing: .onSummon, description: "소환 시 자신에게 방어막 300 부여",
            actions: [EffectActionEntry(action: .applyShield(300), target: .selfSlot)]),
        flavorText: "산 하나를 등에 지고 걸어다니는 거인",
        imageName: "card_mountain_giant"
    )

    static let earthEmperor = MonsterCard(
        name: "대지의 제왕", attribute: .earth, cost: 5, rarity: .superRare,
        combatPower: 2700, monsterType: .warrior,
        effect: CardEffect(timing: .onSummon, description: "소환 시 필드를 지(地)로 오버라이드(2턴). 아군 전체에 방어막 400 부여",
            actions: [
                EffectActionEntry(action: .fieldOverride, target: .selfSlot),
                EffectActionEntry(action: .applyShield(400), target: .allAllies),
            ]),
        flavorText: "대지를 호령하는 불멸의 제왕",
        imageName: "card_earth_emperor"
    )

    // MARK: - ⚡ 뇌(Thunder) 몬스터

    static let thunderFox = MonsterCard(
        name: "뇌격 여우", attribute: .thunder, cost: 2, rarity: .normal,
        combatPower: 1000, monsterType: .spirit,
        effect: CardEffect(timing: .onAttack, description: "공격 시 상대 기세 -1",
            actions: [EffectActionEntry(action: .loseMomentum(1), target: .opponent)]),
        flavorText: "번개를 두른 민첩한 여우 정령",
        imageName: "card_thunder_fox"
    )

    static let sparkSoldier = MonsterCard(
        name: "전격 병사", attribute: .thunder, cost: 1, rarity: .normal,
        combatPower: 600, monsterType: .machine,
        flavorText: "전류로 무장한 기계 병사",
        imageName: "card_spark_soldier"
    )

    static let thunderBeast = MonsterCard(
        name: "뇌수", attribute: .thunder, cost: 3, rarity: .rare,
        combatPower: 1400, monsterType: .dragon,
        effect: CardEffect(timing: .onAttack, description: "공격 시 상대 몬스터 전투력 -200",
            actions: [EffectActionEntry(action: .cpDebuff(-200), target: .destroyer)]),
        flavorText: "번개를 몸에 두른 야수",
        imageName: "card_thunder_beast"
    )

    static let raijuEmperor = MonsterCard(
        name: "뇌제 라이쥬", attribute: .thunder, cost: 5, rarity: .superRare,
        combatPower: 3000, monsterType: .dragon,
        effect: CardEffect(timing: .onSummon, description: "소환 시 필드를 뇌(雷)로 오버라이드(2턴). 상대에게 LP 300 데미지",
            actions: [
                EffectActionEntry(action: .fieldOverride, target: .selfSlot),
                EffectActionEntry(action: .damageLP(300), target: .opponent),
            ]),
        flavorText: "번개의 화신이자 하늘의 제왕",
        imageName: "card_raiju_emperor"
    )

    static let lightningGeneral = MonsterCard(
        name: "번개 장군", attribute: .thunder, cost: 4, rarity: .rare,
        combatPower: 2200, monsterType: .machine,
        effect: CardEffect(timing: .onSummon, description: "소환 시 기세 +2 획득",
            actions: [EffectActionEntry(action: .gainMomentum(2), target: .player)]),
        flavorText: "전장을 번개로 뒤덮는 기계 장군",
        imageName: "card_lightning_general"
    )

    // MARK: - 🌑 암(Dark) 몬스터

    static let darkBat = MonsterCard(
        name: "어둠 박쥐", attribute: .dark, cost: 1, rarity: .normal,
        combatPower: 450, monsterType: .spirit,
        effect: CardEffect(timing: .onDestroy, description: "파괴 시 상대에게 LP 200 데미지",
            actions: [EffectActionEntry(action: .damageLP(200), target: .opponent)]),
        flavorText: "어둠 속에서 날아드는 흡혈 박쥐",
        imageName: "card_dark_bat"
    )

    static let shadowRogue = MonsterCard(
        name: "그림자 도적", attribute: .dark, cost: 2, rarity: .normal,
        combatPower: 900, monsterType: .warrior,
        effect: CardEffect(timing: .onDestroy, description: "파괴 시 상대 기세 -1",
            actions: [EffectActionEntry(action: .loseMomentum(1), target: .opponent)]),
        flavorText: "어둠 속에서 기회를 노리는 도적",
        imageName: "card_shadow_rogue"
    )

    static let deathKnight = MonsterCard(
        name: "죽음의 기사", attribute: .dark, cost: 4, rarity: .rare,
        combatPower: 2100, monsterType: .undead,
        effect: CardEffect(timing: .onDestroy, description: "파괴 시 자신을 파괴한 몬스터의 전투력 -300",
            actions: [EffectActionEntry(action: .cpDebuff(-300), target: .destroyer)]),
        flavorText: "죽음 이후에도 싸움을 멈추지 않는 기사",
        imageName: "card_death_knight"
    )

    static let curseMage = MonsterCard(
        name: "저주술사", attribute: .dark, cost: 3, rarity: .rare,
        combatPower: 1300, monsterType: .mage,
        effect: CardEffect(timing: .onSummon, description: "소환 시 상대 몬스터 1체의 전투력 -200",
            actions: [EffectActionEntry(action: .cpDebuff(-200), target: .selectEnemy)]),
        flavorText: "저주의 힘으로 적을 약화시키는 마법사",
        imageName: "card_curse_mage"
    )

    static let darkDragon = MonsterCard(
        name: "암흑룡", attribute: .dark, cost: 5, rarity: .superRare,
        combatPower: 2600, monsterType: .dragon,
        effect: CardEffect(timing: .onSummon, description: "소환 시 필드를 암(暗)으로 오버라이드(2턴). 상대 기세 -3",
            actions: [
                EffectActionEntry(action: .fieldOverride, target: .selfSlot),
                EffectActionEntry(action: .loseMomentum(3), target: .opponent),
            ]),
        flavorText: "어둠을 삼키며 자라난 공포의 용",
        imageName: "card_dark_dragon"
    )

    // MARK: - ✨ 광(Light) 몬스터

    static let lightFirefly = MonsterCard(
        name: "빛의 반딧불", attribute: .light, cost: 1, rarity: .normal,
        combatPower: 400, monsterType: .spirit,
        effect: CardEffect(timing: .onSummon, description: "소환 시 아군 LP 200 회복",
            actions: [EffectActionEntry(action: .healLP(200), target: .player)]),
        flavorText: "따뜻한 빛으로 아군을 감싸는 반딧불",
        imageName: "card_light_firefly"
    )

    static let holyPriest = MonsterCard(
        name: "성광 사제", attribute: .light, cost: 2, rarity: .normal,
        combatPower: 600, monsterType: .mage,
        effect: CardEffect(timing: .onSummon, description: "소환 시 아군 몬스터 1체에 방어막 500 부여",
            actions: [EffectActionEntry(action: .applyShield(500), target: .selectAlly)]),
        flavorText: "빛의 힘으로 아군을 치유하는 사제",
        imageName: "card_holy_priest"
    )

    static let archangel = MonsterCard(
        name: "대천사", attribute: .light, cost: 5, rarity: .superRare,
        combatPower: 2600, monsterType: .spirit,
        effect: CardEffect(timing: .onSummon, description: "소환 시 필드를 광(光)으로 오버라이드(2턴). 아군 LP 500 회복",
            actions: [
                EffectActionEntry(action: .fieldOverride, target: .selfSlot),
                EffectActionEntry(action: .healLP(500), target: .player),
            ]),
        flavorText: "천상에서 내려온 심판의 천사",
        imageName: "card_archangel"
    )

    static let holyKnight = MonsterCard(
        name: "성기사", attribute: .light, cost: 3, rarity: .rare,
        combatPower: 1400, monsterType: .warrior,
        effect: CardEffect(timing: .onSummon, description: "소환 시 아군 몬스터 전체 전투력 +100",
            actions: [EffectActionEntry(action: .cpBuff(100), target: .allAllies)]),
        flavorText: "빛의 축복을 받은 성스러운 기사",
        imageName: "card_holy_knight"
    )

    static let judgeAngel = MonsterCard(
        name: "심판의 천사", attribute: .light, cost: 4, rarity: .rare,
        combatPower: 2300, monsterType: .spirit,
        effect: CardEffect(timing: .onSummon, description: "소환 시 아군 몬스터 1체에 방어막 300 부여",
            actions: [EffectActionEntry(action: .applyShield(300), target: .selectAlly)]),
        flavorText: "천상의 심판으로 아군을 수호한다",
        imageName: "card_judge_angel"
    )

    // MARK: - 지형 마법 카드 (7종)

    static let fireStorm = SpellCard(
        name: "화염 폭풍", attribute: .fire, cost: 2, rarity: .rare,
        spellType: .terrain,
        effect: CardEffect(timing: .onSummon, description: "지형을 화염으로 2라운드 변경. 상대 몬스터 전체 전투력 -200",
            actions: [EffectActionEntry(action: .cpDebuff(-200), target: .allEnemies)]),
        flavorText: "불의 폭풍이 전장을 뒤덮는다",
        imageName: "spell_fire_storm"
    )

    static let healingRain = SpellCard(
        name: "치유의 비", attribute: .water, cost: 2, rarity: .rare,
        spellType: .terrain,
        effect: CardEffect(timing: .onSummon, description: "지형을 수류로 2라운드 변경. 아군 LP 300 회복",
            actions: [EffectActionEntry(action: .healLP(300), target: .player)]),
        flavorText: "생명의 비가 전장을 적신다",
        imageName: "spell_healing_rain"
    )

    static let earthEcho = SpellCard(
        name: "대지의 울림", attribute: .earth, cost: 2, rarity: .rare,
        spellType: .terrain,
        effect: CardEffect(timing: .onSummon, description: "지형을 대지로 2라운드 변경. 아군 몬스터 전체에 방어막 200 부여",
            actions: [EffectActionEntry(action: .applyShield(200), target: .allAllies)]),
        flavorText: "대지가 울리며 전장이 변한다",
        imageName: "spell_earth_echo"
    )

    static let windStorm = SpellCard(
        name: "폭풍의 눈", attribute: .wind, cost: 2, rarity: .rare,
        spellType: .terrain,
        effect: CardEffect(timing: .onSummon, description: "지형을 폭풍으로 2라운드 변경. 상대 몬스터 1체의 전투력 -200",
            actions: [EffectActionEntry(action: .cpDebuff(-200), target: .selectEnemy)]),
        flavorText: "폭풍이 전장을 휩쓸며 바꿔놓는다",
        imageName: "spell_wind_storm"
    )

    static let thunderJudgment = SpellCard(
        name: "번개의 심판", attribute: .thunder, cost: 2, rarity: .rare,
        spellType: .terrain,
        effect: CardEffect(timing: .onSummon, description: "지형을 번개로 2라운드 변경. 상대 몬스터 1체의 전투력 -300",
            actions: [EffectActionEntry(action: .cpDebuff(-300), target: .selectEnemy)]),
        flavorText: "하늘의 심판이 전장을 뒤흔든다",
        imageName: "spell_thunder_judgment"
    )

    static let darkVeil = SpellCard(
        name: "암흑의 장막", attribute: .dark, cost: 2, rarity: .rare,
        spellType: .terrain,
        effect: CardEffect(timing: .onSummon, description: "지형을 암흑으로 2라운드 변경. 상대 몬스터 전체 방어막 제거",
            actions: [EffectActionEntry(action: .removeAllShields, target: .allEnemies)]),
        flavorText: "어둠이 전장을 삼키며 방어를 무너뜨린다",
        imageName: "spell_dark_veil"
    )

    static let holyLight = SpellCard(
        name: "성스러운 빛", attribute: .light, cost: 2, rarity: .rare,
        spellType: .terrain,
        effect: CardEffect(timing: .onSummon, description: "지형을 빛으로 2라운드 변경. 아군 몬스터 전체에 방어막 200 부여",
            actions: [EffectActionEntry(action: .applyShield(200), target: .allAllies)]),
        flavorText: "성스러운 빛이 전장을 비추며 아군을 치유한다",
        imageName: "spell_holy_light"
    )

    // MARK: - 카드 풀

    /// 전체 몬스터 카드 목록 (35종)
    static let allMonsters: [MonsterCard] = [
        fireImp, fireSlasher, volcanoMage, flameDragon, infernoKnight,
        mistSpirit, waterShield, tidalSerpent, iceWarrior, oceanLord,
        windFairy, galeAssassin, stormHawk, forestSage, typhoonDragon,
        pebbleFairy, earthGuard, rockGolem, mountainGiant, earthEmperor,
        sparkSoldier, thunderFox, thunderBeast, lightningGeneral, raijuEmperor,
        darkBat, shadowRogue, curseMage, deathKnight, darkDragon,
        lightFirefly, holyPriest, holyKnight, judgeAngel, archangel
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
            description: "화+풍 저코스트 몬스터로 빠르게 공격하는 공격형 덱",
            emoji: "🔥",
            accentColorName: "red",
            monsters: [
                (fireImp, 3), (windFairy, 2),
                (fireSlasher, 3), (galeAssassin, 3),
                (volcanoMage, 2), (stormHawk, 2),
                (flameDragon, 2), (forestSage, 2),
                (infernoKnight, 1),
            ],  // 20장, ★5: 1장
            spells: [
                (fireStorm, 3), (windStorm, 3),
                (thunderJudgment, 2), (darkVeil, 2),
            ]  // 10장
        ),
        PresetDeck(
            name: "대지 요새",
            description: "지+수 고전투력 몬스터로 버티는 방어형 덱",
            emoji: "⛰️",
            accentColorName: "brown",
            monsters: [
                (pebbleFairy, 2), (mistSpirit, 2),
                (earthGuard, 3), (waterShield, 3),
                (rockGolem, 2), (tidalSerpent, 2),
                (mountainGiant, 2), (iceWarrior, 2),
                (earthEmperor, 1), (oceanLord, 1),
            ],  // 20장, ★5: 2장
            spells: [
                (earthEcho, 3), (healingRain, 3),
                (holyLight, 2), (darkVeil, 2),
            ]  // 10장
        ),
        PresetDeck(
            name: "뇌광 폭풍",
            description: "뇌+광 시너지로 지형을 장악하는 콤보 덱",
            emoji: "⚡",
            accentColorName: "yellow",
            monsters: [
                (sparkSoldier, 3), (lightFirefly, 2),
                (thunderFox, 3), (holyPriest, 3),
                (thunderBeast, 2), (holyKnight, 2),
                (lightningGeneral, 2), (judgeAngel, 2),
                (raijuEmperor, 1),
            ],  // 20장, ★5: 1장
            spells: [
                (thunderJudgment, 3), (holyLight, 3),
                (healingRain, 2), (windStorm, 2),
            ]  // 10장
        ),
        PresetDeck(
            name: "암흑 지배",
            description: "암+화 디버프로 상대를 압박하는 파괴형 덱",
            emoji: "🌑",
            accentColorName: "purple",
            monsters: [
                (darkBat, 3), (fireImp, 2),
                (shadowRogue, 3), (fireSlasher, 3),
                (curseMage, 2), (volcanoMage, 2),
                (deathKnight, 2), (flameDragon, 1),
                (darkDragon, 1), (infernoKnight, 1),
            ],  // 20장, ★5: 2장
            spells: [
                (darkVeil, 3), (fireStorm, 3),
                (earthEcho, 2), (thunderJudgment, 2),
            ]  // 10장
        ),
        PresetDeck(
            name: "심해의 저주",
            description: "수+암 방어와 디버프로 상대를 서서히 압살하는 컨트롤 덱",
            emoji: "🌊",
            accentColorName: "blue",
            monsters: [
                (mistSpirit, 3), (darkBat, 2),
                (waterShield, 3), (shadowRogue, 3),
                (tidalSerpent, 2), (curseMage, 2),
                (iceWarrior, 2), (deathKnight, 2),
                (oceanLord, 1),
            ],  // 20장, ★5: 1장
            spells: [
                (healingRain, 3), (darkVeil, 3),
                (holyLight, 2), (earthEcho, 2),
            ]  // 10장
        ),
        PresetDeck(
            name: "질풍노도",
            description: "풍+뇌 저코스트 속공으로 빠르게 몰아치는 속공 덱",
            emoji: "🌪️",
            accentColorName: "green",
            monsters: [
                (windFairy, 3), (sparkSoldier, 3),
                (galeAssassin, 3), (thunderFox, 3),
                (stormHawk, 2), (thunderBeast, 2),
                (forestSage, 2), (lightningGeneral, 1),
                (typhoonDragon, 1),
            ],  // 20장, ★5: 1장
            spells: [
                (windStorm, 3), (thunderJudgment, 3),
                (fireStorm, 2), (darkVeil, 2),
            ]  // 10장
        ),
    ]

    // MARK: - 테스트 덱

    /// 화염 러시 덱 (30장: 몬스터 20 + 마법 10)
    static func fireRushDeck() -> [AnyCard] {
        var deck: [AnyCard] = []
        // 몬스터 20장
        for _ in 0..<3 { deck.append(.monster(fireImp)) }
        for _ in 0..<2 { deck.append(.monster(windFairy)) }
        for _ in 0..<3 { deck.append(.monster(fireSlasher)) }
        for _ in 0..<3 { deck.append(.monster(galeAssassin)) }
        for _ in 0..<2 { deck.append(.monster(volcanoMage)) }
        for _ in 0..<2 { deck.append(.monster(stormHawk)) }
        for _ in 0..<2 { deck.append(.monster(flameDragon)) }
        for _ in 0..<2 { deck.append(.monster(forestSage)) }
        for _ in 0..<1 { deck.append(.monster(infernoKnight)) }
        // 마법 10장
        for _ in 0..<3 { deck.append(.spell(fireStorm)) }
        for _ in 0..<3 { deck.append(.spell(windStorm)) }
        for _ in 0..<2 { deck.append(.spell(thunderJudgment)) }
        for _ in 0..<2 { deck.append(.spell(darkVeil)) }
        deck.shuffle()
        return deck
    }

    /// 대지 요새 덱 (30장: 몬스터 20 + 마법 10)
    static func earthFortressDeck() -> [AnyCard] {
        var deck: [AnyCard] = []
        // 몬스터 20장
        for _ in 0..<2 { deck.append(.monster(pebbleFairy)) }
        for _ in 0..<2 { deck.append(.monster(mistSpirit)) }
        for _ in 0..<3 { deck.append(.monster(earthGuard)) }
        for _ in 0..<3 { deck.append(.monster(waterShield)) }
        for _ in 0..<2 { deck.append(.monster(rockGolem)) }
        for _ in 0..<2 { deck.append(.monster(tidalSerpent)) }
        for _ in 0..<2 { deck.append(.monster(mountainGiant)) }
        for _ in 0..<2 { deck.append(.monster(iceWarrior)) }
        for _ in 0..<1 { deck.append(.monster(earthEmperor)) }
        for _ in 0..<1 { deck.append(.monster(oceanLord)) }
        // 마법 10장
        for _ in 0..<3 { deck.append(.spell(earthEcho)) }
        for _ in 0..<3 { deck.append(.spell(healingRain)) }
        for _ in 0..<2 { deck.append(.spell(holyLight)) }
        for _ in 0..<2 { deck.append(.spell(darkVeil)) }
        deck.shuffle()
        return deck
    }
}

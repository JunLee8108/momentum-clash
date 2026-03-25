import Foundation

/// 카드 효과 발동 타이밍
enum EffectTiming: String, Codable {
    case onSummon       // 소환 시
    case onDestroy      // 파괴 시
    case eachTurn       // 매 턴
    case onAttack       // 공격 시
    case onAttributeControl // 속성 지배 중
    case passive        // 상시 적용
}

/// 효과가 적용되는 대상
enum EffectTarget: String, Codable {
    case selfSlot       // 자기 자신 슬롯
    case allAllies      // 아군 몬스터 전체
    case selectAlly     // 아군 1체 선택 (AI: 최강 아군 자동)
    case selectEnemy    // 적 1체 선택 (AI: 최강 적 자동)
    case allEnemies     // 적 몬스터 전체
    case player         // 자기 플레이어 (LP/기세 등)
    case opponent       // 상대 플레이어 (LP/기세 등)
    case destroyer      // 자신을 파괴한 몬스터 (onDestroy 전용)
}

/// 효과 행동 (데이터로 표현)
enum EffectAction: Codable, Equatable {
    case healLP(Int)              // LP 회복
    case damageLP(Int)            // LP 데미지
    case applyShield(Int)         // 방어막 부여
    case cpDebuff(Int)            // CP 디버프 (음수값)
    case cpBuff(Int)              // CP 버프 (양수값, 슬롯별)
    case drawCards(Int)           // 카드 드로우
    case gainMomentum(Int)        // 기세 획득
    case loseMomentum(Int)        // 기세 감소
    case fieldOverride            // 필드 오버라이드 (카드 속성 사용, 5성 전용)
    case fieldCpDebuff(Int)       // 필드 전체 CP 디버프 (오버라이드와 수명 공유, 태풍룡 등)
    case removeAllShields         // 방어막 전체 제거
    case momentumBonus(Int)       // 이번 턴 전투력 보너스
}

/// 효과 행동 + 대상 쌍
struct EffectActionEntry: Codable, Equatable {
    let action: EffectAction
    let target: EffectTarget
}

/// 카드 효과
struct CardEffect: Codable, Equatable {
    let timing: EffectTiming
    let description: String
    let actions: [EffectActionEntry]

    init(timing: EffectTiming, description: String, actions: [EffectActionEntry] = []) {
        self.timing = timing
        self.description = description
        self.actions = actions
    }
}

/// 모든 카드의 공통 프로토콜
protocol Card: Identifiable, Codable {
    var id: UUID { get }
    var name: String { get }
    var attribute: Attribute { get }
    var cost: Int { get }        // 소환 비용 (1~5)
    var rarity: Rarity { get }
    var flavorText: String { get }
    var imageName: String { get } // 에셋 카탈로그 이미지 이름
}

/// 몬스터 카드
struct MonsterCard: Card, Equatable {
    let id: UUID
    let name: String
    let attribute: Attribute
    let cost: Int
    let rarity: Rarity
    let flavorText: String
    let imageName: String

    let combatPower: Int           // 전투력 (CP)
    let monsterType: MonsterType
    let effect: CardEffect?        // nil이면 일반 몬스터

    /// 일반 몬스터 여부 (효과 없음)
    var isVanilla: Bool { effect == nil }

    init(
        id: UUID = UUID(),
        name: String,
        attribute: Attribute,
        cost: Int,
        rarity: Rarity,
        combatPower: Int,
        monsterType: MonsterType,
        effect: CardEffect? = nil,
        flavorText: String = "",
        imageName: String = ""
    ) {
        self.id = id
        self.name = name
        self.attribute = attribute
        self.cost = min(max(cost, 1), 5)
        self.rarity = rarity
        self.combatPower = max(combatPower, 0)
        self.monsterType = monsterType
        self.effect = effect
        self.flavorText = flavorText
        self.imageName = imageName
    }
}

/// 마법 카드
struct SpellCard: Card, Equatable {
    let id: UUID
    let name: String
    let attribute: Attribute
    let cost: Int
    let rarity: Rarity
    let flavorText: String
    let imageName: String

    let spellType: SpellType
    let effect: CardEffect

    init(
        id: UUID = UUID(),
        name: String,
        attribute: Attribute,
        cost: Int,
        rarity: Rarity,
        spellType: SpellType,
        effect: CardEffect,
        flavorText: String = "",
        imageName: String = ""
    ) {
        self.id = id
        self.name = name
        self.attribute = attribute
        self.cost = min(max(cost, 1), 5)
        self.rarity = rarity
        self.spellType = spellType
        self.effect = effect
        self.flavorText = flavorText
        self.imageName = imageName
    }

    /// 이 마법이 필드 슬롯을 차지하는지
    var occupiesSlot: Bool { spellType.occupiesSlot }
}

/// 덱에 들어가는 카드를 통합 타입으로 다루기 위한 열거형
enum AnyCard: Identifiable, Codable, Equatable {
    case monster(MonsterCard)
    case spell(SpellCard)

    var id: UUID {
        switch self {
        case .monster(let card): return card.id
        case .spell(let card): return card.id
        }
    }

    var name: String {
        switch self {
        case .monster(let card): return card.name
        case .spell(let card): return card.name
        }
    }

    var attribute: Attribute {
        switch self {
        case .monster(let card): return card.attribute
        case .spell(let card): return card.attribute
        }
    }

    var cost: Int {
        switch self {
        case .monster(let card): return card.cost
        case .spell(let card): return card.cost
        }
    }

    var isSpell: Bool {
        if case .spell = self { return true }
        return false
    }

    var rarity: Rarity {
        switch self {
        case .monster(let card): return card.rarity
        case .spell(let card): return card.rarity
        }
    }

    var imageName: String {
        switch self {
        case .monster(let card): return card.imageName
        case .spell(let card): return card.imageName
        }
    }

    var flavorText: String {
        switch self {
        case .monster(let card): return card.flavorText
        case .spell(let card): return card.flavorText
        }
    }
}

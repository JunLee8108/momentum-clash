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

/// 카드 효과
struct CardEffect: Codable, Equatable {
    let timing: EffectTiming
    let description: String
}

/// 모든 카드의 공통 프로토콜
protocol Card: Identifiable, Codable {
    var id: UUID { get }
    var name: String { get }
    var attribute: Attribute { get }
    var cost: Int { get }        // 소환 비용 (1~5)
    var rarity: Rarity { get }
    var flavorText: String { get }
}

/// 몬스터 카드
struct MonsterCard: Card, Equatable {
    let id: UUID
    let name: String
    let attribute: Attribute
    let cost: Int
    let rarity: Rarity
    let flavorText: String

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
        flavorText: String = ""
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
        flavorText: String = ""
    ) {
        self.id = id
        self.name = name
        self.attribute = attribute
        self.cost = min(max(cost, 1), 5)
        self.rarity = rarity
        self.spellType = spellType
        self.effect = effect
        self.flavorText = flavorText
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

    var rarity: Rarity {
        switch self {
        case .monster(let card): return card.rarity
        case .spell(let card): return card.rarity
        }
    }
}

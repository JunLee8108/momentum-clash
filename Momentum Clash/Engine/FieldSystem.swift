import Foundation

/// 필드 슬롯에 배치된 카드
enum SlotContent: Equatable {
    case monster(MonsterCard, shield: Int)  // 몬스터 + 방어막
    case spell(SpellCard)                   // 지속 마법
    case empty

    var isOccupied: Bool {
        if case .empty = self { return false }
        return true
    }
}

/// 필드의 개별 슬롯 (배치 카드)
struct FieldSlot: Equatable {
    var content: SlotContent     // 배치된 카드
    var hasAttacked: Bool = false // 이번 턴에 공격했는지
    var slotCpDebuff: Int = 0    // 개별 전투력 디버프 (염룡/죽음의 기사 효과, 영구)

    static var empty: FieldSlot {
        FieldSlot(content: .empty, hasAttacked: false, slotCpDebuff: 0)
    }
}

/// 플레이어의 필드 (5개 통합 슬롯)
struct PlayerField: Equatable {
    static let slotCount = 5

    var slots: [FieldSlot]

    init() {
        slots = Array(repeating: .empty, count: PlayerField.slotCount)
    }

    // MARK: - 슬롯 관리

    /// 빈 슬롯 인덱스 목록
    var emptySlotIndices: [Int] {
        slots.indices.filter { !slots[$0].content.isOccupied }
    }

    /// 몬스터가 있는 슬롯 인덱스 목록
    var monsterSlotIndices: [Int] {
        slots.indices.filter {
            if case .monster = slots[$0].content { return true }
            return false
        }
    }

    /// 필드 위 몬스터 수
    var monsterCount: Int { monsterSlotIndices.count }

    /// 슬롯에 몬스터 소환
    mutating func summonMonster(_ card: MonsterCard, at index: Int) -> Bool {
        guard index >= 0, index < PlayerField.slotCount,
              !slots[index].content.isOccupied else { return false }

        slots[index].content = .monster(card, shield: 0)
        return true
    }

    /// 슬롯에 지속 마법 배치
    mutating func placeSpell(_ card: SpellCard, at index: Int) -> Bool {
        guard card.spellType == .continuous,
              index >= 0, index < PlayerField.slotCount,
              !slots[index].content.isOccupied else { return false }

        slots[index].content = .spell(card)
        return true
    }

    /// 슬롯 카드 제거 (파괴/제거)
    mutating func removeCard(at index: Int) {
        guard index >= 0, index < PlayerField.slotCount else { return }
        slots[index].content = .empty
        slots[index].slotCpDebuff = 0
    }

    /// 방어막 부여
    mutating func applyShield(_ amount: Int, at index: Int) {
        guard index >= 0, index < PlayerField.slotCount else { return }
        if case .monster(let card, let currentShield) = slots[index].content {
            slots[index].content = .monster(card, shield: currentShield + amount)
        }
    }

    /// 방어막 설정 (전투 후 잔여 방어막 반영)
    mutating func setShield(_ amount: Int, at index: Int) {
        guard index >= 0, index < PlayerField.slotCount else { return }
        if case .monster(let card, _) = slots[index].content {
            slots[index].content = .monster(card, shield: amount)
        }
    }

    /// 모든 슬롯의 공격 플래그 리셋 (턴 시작 시)
    mutating func resetAttackFlags() {
        for i in slots.indices {
            slots[i].hasAttacked = false
        }
    }

    /// 모든 방어막 제거 (턴 종료 시)
    mutating func clearAllShields() {
        for i in slots.indices {
            if case .monster(let card, _) = slots[i].content {
                slots[i].content = .monster(card, shield: 0)
            }
        }
    }

    // MARK: - 슬롯별 전투력 디버프

    /// 슬롯에 개별 전투력 디버프 적용 (염룡/죽음의 기사 효과)
    mutating func applySlotCpDebuff(_ amount: Int, at index: Int) {
        guard index >= 0, index < PlayerField.slotCount else { return }
        if case .monster = slots[index].content {
            slots[index].slotCpDebuff += amount
        }
    }

    // MARK: - 필드 오버라이드 시스템

    /// 5성 소환 시 필드 전체 속성 오버라이드 (2턴)
    var fieldOverrideAttribute: Attribute? = nil
    var fieldOverrideTurnsRemaining: Int = 0
    var fieldOverrideSourceSlot: Int? = nil

    /// 태풍룡 효과: 상대로부터 받는 전투력 디버프 (음수 값, 필드 오버라이드와 수명 공유)
    var cpDebuff: Int = 0

    /// 필드 오버라이드 설정 (5성 소환 공통 효과)
    mutating func setFieldOverride(attribute: Attribute, sourceSlot: Int) {
        fieldOverrideAttribute = attribute
        fieldOverrideTurnsRemaining = 2
        fieldOverrideSourceSlot = sourceSlot
    }

    /// 필드 오버라이드 해제
    mutating func clearFieldOverride() {
        fieldOverrideAttribute = nil
        fieldOverrideTurnsRemaining = 0
        fieldOverrideSourceSlot = nil
        cpDebuff = 0
    }

    /// 해당 플레이어 턴 종료 시 오버라이드 남은 턴 감소
    mutating func tickFieldOverride() {
        guard fieldOverrideTurnsRemaining > 0 else { return }
        fieldOverrideTurnsRemaining -= 1
        if fieldOverrideTurnsRemaining <= 0 {
            clearFieldOverride()
        }
    }

    // MARK: - 글로벌 지형 보너스

    /// 글로벌 지형 보너스 계산 (해당 속성 몬스터 +300 CP)
    static let globalTerrainBonus = 300

    /// 특정 슬롯 몬스터의 지형 보너스 (필드 오버라이드 우선, 없으면 글로벌 지형)
    func terrainBonus(at index: Int, globalTerrain: Attribute) -> Int {
        guard index >= 0, index < PlayerField.slotCount,
              case .monster(let card, _) = slots[index].content else { return 0 }
        let activeTerrain = fieldOverrideAttribute ?? globalTerrain
        return card.attribute == activeTerrain ? PlayerField.globalTerrainBonus : 0
    }
}

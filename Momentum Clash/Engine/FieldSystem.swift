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

/// 필드의 개별 슬롯 (지형 속성 + 배치 카드)
struct FieldSlot: Equatable {
    var terrain: Attribute?      // nil이면 중립 지형
    var content: SlotContent     // 배치된 카드
    var terrainRetainTurns: Int  // 카드 제거 후 지형 유지 남은 턴 수
    var hasAttacked: Bool = false // 이번 턴에 공격했는지

    static var empty: FieldSlot {
        FieldSlot(terrain: nil, content: .empty, terrainRetainTurns: 0, hasAttacked: false)
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
        slots[index].terrain = card.attribute  // 소환 시 지형 오염
        slots[index].terrainRetainTurns = 0
        return true
    }

    /// 슬롯에 지속 마법 배치
    mutating func placeSpell(_ card: SpellCard, at index: Int) -> Bool {
        guard card.spellType == .continuous,
              index >= 0, index < PlayerField.slotCount,
              !slots[index].content.isOccupied else { return false }

        slots[index].content = .spell(card)
        slots[index].terrain = card.attribute
        slots[index].terrainRetainTurns = 0
        return true
    }

    /// 슬롯 카드 제거 (파괴/제거)
    mutating func removeCard(at index: Int) {
        guard index >= 0, index < PlayerField.slotCount else { return }
        slots[index].content = .empty
        // 지형은 1턴 동안 유지
        slots[index].terrainRetainTurns = 1
    }

    /// 슬롯 지형 변경
    mutating func setTerrain(_ attribute: Attribute?, at index: Int) {
        guard index >= 0, index < PlayerField.slotCount else { return }
        slots[index].terrain = attribute
        slots[index].terrainRetainTurns = 0
    }

    /// 방어막 부여
    mutating func applyShield(_ amount: Int, at index: Int) {
        guard index >= 0, index < PlayerField.slotCount else { return }
        if case .monster(let card, let currentShield) = slots[index].content {
            slots[index].content = .monster(card, shield: currentShield + amount)
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

    /// 지형 유지 턴 감소 (턴 종료 시)
    mutating func tickTerrainRetention() {
        for i in slots.indices {
            if slots[i].terrainRetainTurns > 0 {
                slots[i].terrainRetainTurns -= 1
                if slots[i].terrainRetainTurns == 0 && !slots[i].content.isOccupied {
                    slots[i].terrain = nil  // 유지 시간 끝, 중립으로
                }
            }
        }
    }

    // MARK: - 지형 계산

    /// 특정 속성의 지형 수
    func terrainCount(for attribute: Attribute) -> Int {
        slots.filter { $0.terrain == attribute }.count
    }

    /// 속성 지배 상태 확인 (3개 이상 같은 속성)
    func attributeDominance() -> Attribute? {
        for attr in Attribute.allCases {
            if terrainCount(for: attr) >= 3 {
                return attr
            }
        }
        return nil
    }

    /// 완전 지배 확인 (5개 전부 같은 속성)
    func isFullDominance() -> Bool {
        guard let dominant = attributeDominance() else { return false }
        return terrainCount(for: dominant) == PlayerField.slotCount
    }

    /// 지형 보너스 계산 (특정 슬롯의 몬스터에 대해)
    func terrainBonus(at index: Int) -> Int {
        guard index >= 0, index < PlayerField.slotCount,
              case .monster(let card, _) = slots[index].content else { return 0 }

        var bonus = 0
        let terrain = slots[index].terrain

        // 같은 속성 지형 위의 몬스터: +200
        if terrain == card.attribute {
            bonus += 200
        }

        // 속성 지배 보너스
        if let dominant = attributeDominance(), dominant == card.attribute {
            if isFullDominance() {
                bonus += 500  // 완전 지배: +500 (기본 200 대신)
                bonus -= 200  // 위에서 이미 200 더했으므로 조정
            } else {
                bonus += 300  // 속성 지배: +300
            }
        }

        return bonus
    }
}

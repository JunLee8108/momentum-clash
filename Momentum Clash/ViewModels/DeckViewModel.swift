import Foundation
import Observation

/// 덱 빌딩 상수
enum DeckConstants {
    static let deckSize = 30
    static let monsterLimit = 20
    static let spellLimit = 10
    static let sameCardLimit = 3
}

/// 덱 빌딩 뷰모델
@Observable
@MainActor
class DeckViewModel {
    /// 현재 덱에 넣은 카드 목록
    var deck: [AnyCard] = []

    /// 카드 풀 필터: 몬스터/마법 탭
    var selectedCardType: CardTypeFilter = .monster

    /// 속성 필터 (nil이면 전체)
    var selectedAttribute: Attribute? = nil

    // MARK: - 카드 풀

    /// 필터링된 몬스터 카드 풀
    var filteredMonsters: [MonsterCard] {
        if let attr = selectedAttribute {
            return SampleCards.allMonsters.filter { $0.attribute == attr }
        }
        return SampleCards.allMonsters
    }

    /// 필터링된 마법 카드 풀
    var filteredSpells: [SpellCard] {
        if let attr = selectedAttribute {
            return SampleCards.allSpells.filter { $0.attribute == attr }
        }
        return SampleCards.allSpells
    }

    // MARK: - 덱 현황

    var monsterCount: Int {
        deck.filter { !$0.isSpell }.count
    }

    var spellCount: Int {
        deck.filter { $0.isSpell }.count
    }

    var isDeckValid: Bool {
        deck.count == DeckConstants.deckSize &&
        monsterCount == DeckConstants.monsterLimit &&
        spellCount == DeckConstants.spellLimit
    }

    /// 특정 카드가 덱에 몇 장 들어있는지
    func countInDeck(name: String) -> Int {
        deck.filter { $0.name == name }.count
    }

    /// 카드를 더 추가할 수 있는지
    func canAdd(card: AnyCard) -> Bool {
        if deck.count >= DeckConstants.deckSize { return false }
        if countInDeck(name: card.name) >= DeckConstants.sameCardLimit { return false }

        switch card {
        case .monster:
            return monsterCount < DeckConstants.monsterLimit
        case .spell:
            return spellCount < DeckConstants.spellLimit
        }
    }

    // MARK: - 덱 편집

    func addMonster(_ card: MonsterCard) {
        let anyCard = AnyCard.monster(card)
        guard canAdd(card: anyCard) else { return }
        deck.append(anyCard)
    }

    func addSpell(_ card: SpellCard) {
        let anyCard = AnyCard.spell(card)
        guard canAdd(card: anyCard) else { return }
        deck.append(anyCard)
    }

    /// 덱에서 특정 이름의 카드 1장 제거
    func removeCard(name: String) {
        if let index = deck.lastIndex(where: { $0.name == name }) {
            deck.remove(at: index)
        }
    }

    /// 프리셋 덱 불러오기
    func loadPreset(_ preset: SampleCards.PresetDeck) {
        deck = preset.build()
    }

    /// 덱 초기화
    func clearDeck() {
        deck = []
    }

    /// 게임 시작용 덱 빌드 (셔플된 복사본)
    func buildDeck() -> [AnyCard] {
        var result = deck
        result.shuffle()
        return result
    }

    // MARK: - 덱 요약 (그룹화)

    /// 덱에 있는 카드를 이름별로 그룹화
    var deckSummary: [(name: String, card: AnyCard, count: Int)] {
        var seen: [String: (card: AnyCard, count: Int)] = [:]
        var order: [String] = []

        for card in deck {
            if seen[card.name] != nil {
                seen[card.name]!.count += 1
            } else {
                seen[card.name] = (card: card, count: 1)
                order.append(card.name)
            }
        }

        return order.compactMap { name in
            guard let entry = seen[name] else { return nil }
            return (name: name, card: entry.card, count: entry.count)
        }
    }
}

/// 카드 타입 필터
enum CardTypeFilter: String, CaseIterable {
    case monster = "몬스터"
    case spell = "마법"
}

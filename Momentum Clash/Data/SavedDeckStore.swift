import Foundation

/// 저장된 커스텀 덱
struct SavedDeck: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    let cards: [AnyCard]
    let createdAt: Date

    /// 덱에 포함된 주요 속성 (몬스터 기준, 순서 유지, 중복 제거)
    var mainAttributes: [Attribute] {
        var seen = Set<Attribute>()
        var result: [Attribute] = []
        for card in cards {
            if case .monster(let m) = card, seen.insert(m.attribute).inserted {
                result.append(m.attribute)
            }
        }
        return result
    }

    var monsterCount: Int { cards.filter { !$0.isSpell }.count }
    var spellCount: Int { cards.filter { $0.isSpell }.count }
}

/// UserDefaults 기반 커스텀 덱 저장소
struct SavedDeckStore {
    static let maxSlots = 3
    private static let storageKey = "savedCustomDecks"

    /// 저장된 모든 덱 불러오기
    static func loadAll() -> [SavedDeck] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decks = try? JSONDecoder().decode([SavedDeck].self, from: data) else {
            return []
        }
        return decks.sorted { $0.createdAt < $1.createdAt }
    }

    /// 덱 저장 (최대 3개)
    @discardableResult
    static func save(_ deck: SavedDeck) -> Bool {
        var decks = loadAll()

        // 같은 ID면 덮어쓰기
        if let idx = decks.firstIndex(where: { $0.id == deck.id }) {
            decks[idx] = deck
        } else {
            guard decks.count < maxSlots else { return false }
            decks.append(deck)
        }

        return persist(decks)
    }

    /// 덱 삭제
    static func delete(id: UUID) {
        var decks = loadAll()
        decks.removeAll { $0.id == id }
        persist(decks)
    }

    /// 저장 슬롯이 남아있는지
    static var hasAvailableSlot: Bool {
        loadAll().count < maxSlots
    }

    @discardableResult
    private static func persist(_ decks: [SavedDeck]) -> Bool {
        guard let data = try? JSONEncoder().encode(decks) else { return false }
        UserDefaults.standard.set(data, forKey: storageKey)
        return true
    }
}

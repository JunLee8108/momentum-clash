import Foundation

/// 플레이어 상태
struct Player: Equatable {
    let id: UUID
    var name: String

    var lp: Int                    // Life Points
    var momentum: Int              // 기세 (0~10)
    var energy: Int                // 이번 턴 기본 기력

    var deck: [AnyCard]            // 덱
    var hand: [AnyCard]            // 패
    var graveyard: [AnyCard]       // 묘지
    var field: PlayerField         // 필드 (5슬롯)

    var didAttackThisTurn: Bool    // 이번 턴 공격 여부
    var momentumBonus: Int         // 기세 스킬에 의한 전투력 증가 (턴 종료 시 리셋)
    var activeMomentumSkill: MomentumSkill?  // 이번 턴 활성화된 기세 스킬
    var fightingTargetSlot: Int?   // 투지 스킬 적용 대상 슬롯 인덱스
    var summonedThisTurn: Set<Int> // 이번 턴에 소환한 슬롯 인덱스 (희생 불가)

    init(
        id: UUID = UUID(),
        name: String,
        deck: [AnyCard]
    ) {
        self.id = id
        self.name = name
        self.lp = TurnSystem.startingLP
        self.momentum = 0
        self.energy = 0
        self.deck = deck
        self.hand = []
        self.graveyard = []
        self.field = PlayerField()
        self.didAttackThisTurn = false
        self.momentumBonus = 0
        self.activeMomentumSkill = nil
        self.fightingTargetSlot = nil
        self.summonedThisTurn = []
    }

    // MARK: - LP

    mutating func takeDamage(_ amount: Int) {
        lp = max(0, lp - amount)
    }

    var isDefeated: Bool { lp <= 0 }
    var canDraw: Bool { !deck.isEmpty }

    // MARK: - 기세

    mutating func gainMomentum(_ amount: Int) {
        momentum = min(MomentumSystem.maxMomentum, momentum + amount)
    }

    mutating func loseMomentum(_ amount: Int) {
        momentum = max(0, momentum - amount)
    }

    /// 턴 시작 시 기본 기력 세팅
    mutating func refreshEnergy() {
        energy = MomentumSystem.baseEnergy(
            currentLP: lp,
            maxLP: TurnSystem.startingLP
        )
    }

    // MARK: - 초기 드로우

    mutating func drawInitialHand() {
        let handSize = min(TurnSystem.startingHandSize, deck.count)
        let minMonsters = 3

        // 덱에서 몬스터/마법 인덱스 분리
        let monsterIndices = deck.indices.filter { !deck[$0].isSpell }
        let spellIndices = deck.indices.filter { deck[$0].isSpell }

        // 몬스터가 충분하면 최소 3장 보장
        if monsterIndices.count >= minMonsters {
            let chosenMonsters = Array(monsterIndices.shuffled().prefix(minMonsters))
            let remaining = deck.indices.filter { !chosenMonsters.contains($0) }
            let chosenRest = Array(remaining.shuffled().prefix(handSize - minMonsters))
            let allChosen = (chosenMonsters + chosenRest).sorted(by: >)

            for idx in allChosen {
                hand.append(deck.remove(at: idx))
            }
        } else {
            // 몬스터 부족 시 기존 방식 (발생 가능성 낮음)
            for _ in 0..<handSize {
                hand.append(deck.removeFirst())
            }
        }

        // 드로우 후 덱 재셔플
        deck.shuffle()
    }
}

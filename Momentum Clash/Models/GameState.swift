import Foundation

/// 게임 승리 조건
enum GameResult: Equatable {
    case ongoing
    case win(playerIndex: Int, reason: WinReason)
}

enum WinReason: String, Equatable {
    case lpZero = "LP가 0이 되었습니다"
    case deckOut = "덱에서 드로우할 수 없습니다"
}

/// 게임 전체 상태
struct GameState {
    var players: [Player]          // [0]: 플레이어1, [1]: 플레이어2
    var currentPlayerIndex: Int    // 현재 턴 플레이어
    var turnNumber: Int
    var currentPhase: TurnPhase
    var isFirstTurn: Bool          // 선공 첫 턴 (공격 불가)
    let firstPlayerIndex: Int      // 선공 플레이어 인덱스 (라운드 판정용)

    // MARK: - 글로벌 지형 시스템
    var globalTerrain: Attribute           // 현재 활성 지형 속성
    var terrainTurnsRemaining: Int         // 지형 유지 남은 라운드 수 (1라운드 = 양쪽 턴)
    var isSpellTerrain: Bool               // 마법카드에 의한 지형인지

    var currentPlayer: Player {
        get { players[currentPlayerIndex] }
        set { players[currentPlayerIndex] = newValue }
    }

    var opponentIndex: Int { 1 - currentPlayerIndex }

    var opponent: Player {
        get { players[opponentIndex] }
        set { players[opponentIndex] = newValue }
    }

    /// 게임 초기화
    init(player1Deck: [AnyCard], player2Deck: [AnyCard], firstPlayerIndex: Int = 0) {
        self.players = [
            Player(name: "Player 1", deck: player1Deck),
            Player(name: "Player 2", deck: player2Deck)
        ]
        self.currentPlayerIndex = firstPlayerIndex
        self.firstPlayerIndex = firstPlayerIndex
        self.turnNumber = 1
        self.currentPhase = .draw
        self.isFirstTurn = true

        // 글로벌 지형 초기화 (랜덤)
        self.globalTerrain = Attribute.allCases.randomElement()!
        self.terrainTurnsRemaining = 2
        self.isSpellTerrain = false

        // 선공은 기세 2로 시작
        self.players[firstPlayerIndex].momentum = 2

        // 초기 패 드로우
        self.players[0].drawInitialHand()
        self.players[1].drawInitialHand()

        // 덱 셔플은 게임 시작 전에 호출자가 처리
    }

    // MARK: - 게임 결과 확인

    var result: GameResult {
        for i in players.indices {
            if players[i].isDefeated {
                return .win(playerIndex: 1 - i, reason: .lpZero)
            }
        }
        return .ongoing
    }

    // MARK: - 턴 전환

    mutating func nextTurn() {
        // 엔드 페이즈 정리
        endPhaseCleanup()

        // 라운드 완료 판정: 후공 플레이어 턴이 끝날 때 = 1라운드 종료
        let isRoundComplete = (currentPlayerIndex != firstPlayerIndex)

        if isRoundComplete {
            // 지형 카운트다운 (라운드 단위)
            terrainTurnsRemaining -= 1
            if terrainTurnsRemaining <= 0 {
                isSpellTerrain = false
                globalTerrain = Attribute.allCases.randomElement()!
                terrainTurnsRemaining = 2
            }

            // 로컬 슬롯 지형 유지도 라운드 단위로 감소
            players[0].field.tickTerrainRetention()
            players[1].field.tickTerrainRetention()
        }

        // 턴 전환
        currentPlayerIndex = opponentIndex
        turnNumber += 1
        currentPhase = .draw
        isFirstTurn = false

        // 새 턴 시작
        currentPlayer.refreshEnergy()
        currentPlayer.didAttackThisTurn = false
    }

    // MARK: - 지형 마법

    /// 마법카드로 지형 강제 변경 (2라운드 지속)
    mutating func setSpellTerrain(_ attribute: Attribute) {
        globalTerrain = attribute
        terrainTurnsRemaining = 2
        isSpellTerrain = true
    }

    // MARK: - 스탠바이 페이즈

    mutating func processStandbyPhase() {
        currentPhase = .standby
        currentPlayer.refreshEnergy()

        // 글로벌 지형과 일치하는 몬스터가 있으면 기세 +1
        let hasMatchingMonster = currentPlayer.field.monsterSlotIndices.contains { i in
            if case .monster(let m, _) = currentPlayer.field.slots[i].content {
                return m.attribute == globalTerrain
            }
            return false
        }
        if hasMatchingMonster {
            currentPlayer.gainMomentum(1)
        }

        // 기세 6 이상이면 자연 감소 -1
        if currentPlayer.momentum >= 6 {
            currentPlayer.loseMomentum(1)
        }
    }

    // MARK: - 엔드 페이즈

    private mutating func endPhaseCleanup() {
        // 미사용 기본 기력 소멸
        currentPlayer.energy = 0

        // 기세 보너스 리셋 (턴 한정 전투력 증가)
        currentPlayer.momentumBonus = 0
        currentPlayer.activeMomentumSkill = nil
        currentPlayer.fightingTargetSlot = nil
        currentPlayer.summonedThisTurn = []

        // 공격하지 않았으면 기세 -1
        if !currentPlayer.didAttackThisTurn {
            currentPlayer.loseMomentum(1)
        }

        // 로컬 지형 유지 감소는 nextTurn()에서 라운드 완료 시 처리
    }

    // MARK: - 드로우 페이즈

    /// 선택 드로우 (2장 중 1장)
    /// - Returns: 드로우할 수 없으면 nil (덱 아웃)
    mutating func drawPhase() -> (choice1: AnyCard, choice2: AnyCard)? {
        currentPhase = .draw

        guard currentPlayer.deck.count >= 2 else {
            // 덱에 1장 이하 → 드로우 불가, 패배
            return nil
        }

        return TurnSystem.selectiveDraw(player: &players[currentPlayerIndex])
    }

    /// 선택 드로우 결과 적용
    mutating func resolveDrawChoice(chosen: AnyCard, rejected: AnyCard) {
        TurnSystem.resolveSelectiveDraw(
            chosen: chosen,
            rejected: rejected,
            player: &players[currentPlayerIndex]
        )
    }
}

import Foundation
import Observation
import SwiftUI

/// 게임 진행 상태 (UI용)
enum GameUIState: Equatable {
    case notStarted
    case drawSelection(choice1: AnyCard, choice2: AnyCard)
    case mainPhase
    case battlePhase
    case selectingAttackTarget(attackerSlot: Int)
    case selectingSummonSlot(card: AnyCard, handIndex: Int)
    case aiTurn
    case gameOver(winner: String)
}

/// 로그 메시지
struct GameLog: Identifiable {
    let id = UUID()
    let message: String
}

/// 게임 뷰모델 (MVVM 컨트롤러)
@Observable
@MainActor
class GameViewModel {
    var gameState: GameState
    var uiState: GameUIState = .notStarted
    var logs: [GameLog] = []
    var selectedHandIndex: Int? = nil

    let playerIndex = 0  // 플레이어는 항상 인덱스 0
    let aiIndex = 1      // AI는 항상 인덱스 1

    private let ai = BasicAI()

    var player: Player { gameState.players[playerIndex] }
    var aiPlayer: Player { gameState.players[aiIndex] }

    var isPlayerTurn: Bool { gameState.currentPlayerIndex == playerIndex }
    var canAttack: Bool {
        gameState.currentPhase == .battle &&
        !gameState.isFirstTurn &&
        isPlayerTurn
    }

    init() {
        let playerDeck = SampleCards.fireRushDeck()
        let aiDeck = SampleCards.earthFortressDeck()
        self.gameState = GameState(
            player1Deck: playerDeck,
            player2Deck: aiDeck,
            firstPlayerIndex: 0
        )
    }

    // MARK: - 게임 시작

    func startGame() {
        addLog("⚔️ Momentum Clash 시작!")
        addLog("\(player.name)이 선공입니다. 기세 2로 시작!")
        startTurn()
    }

    // MARK: - 턴 시작

    private func startTurn() {
        let currentName = gameState.currentPlayer.name

        if gameState.turnNumber > 1 || gameState.currentPlayerIndex != 0 {
            addLog("── 턴 \(gameState.turnNumber): \(currentName)의 턴 ──")
        }

        // 드로우 페이즈
        if let choices = gameState.drawPhase() {
            if isPlayerTurn {
                uiState = .drawSelection(choice1: choices.choice1, choice2: choices.choice2)
            } else {
                // AI 드로우
                performAIDraw(choices: choices)
            }
        } else {
            // 덱 아웃
            let loserIndex = gameState.currentPlayerIndex
            let winnerIndex = 1 - loserIndex
            addLog("\(gameState.players[loserIndex].name)의 덱이 바닥났습니다!")
            endGame(winnerIndex: winnerIndex)
        }
    }

    // MARK: - 드로우 선택

    func selectDrawCard(_ card: AnyCard, rejected: AnyCard) {
        gameState.resolveDrawChoice(chosen: card, rejected: rejected)
        addLog("\(cardName(card))을(를) 드로우했습니다.")
        proceedToStandby()
    }

    private func proceedToStandby() {
        gameState.processStandbyPhase()

        let p = gameState.currentPlayer
        addLog("기력: \(p.energy) / 기세: \(p.momentum)")

        if isPlayerTurn {
            gameState.currentPhase = .main
            uiState = .mainPhase
        } else {
            performAITurn()
        }
    }

    // MARK: - 메인 페이즈 액션

    func selectCardFromHand(_ index: Int) {
        guard isPlayerTurn, gameState.currentPhase == .main else { return }
        guard index >= 0, index < player.hand.count else { return }

        let card = player.hand[index]

        // 비용 확인
        let totalResource = player.energy + player.momentum
        if card.cost > totalResource {
            addLog("자원이 부족합니다! (비용: \(card.cost), 보유: \(totalResource))")
            return
        }

        // 슬롯 선택 모드
        if case .monster = card {
            if player.field.emptySlotIndices.isEmpty {
                addLog("빈 슬롯이 없습니다!")
                return
            }
            uiState = .selectingSummonSlot(card: card, handIndex: index)
        } else if case .spell(let spellCard) = card {
            if spellCard.spellType == .continuous {
                if player.field.emptySlotIndices.isEmpty {
                    addLog("빈 슬롯이 없습니다!")
                    return
                }
                uiState = .selectingSummonSlot(card: card, handIndex: index)
            } else {
                // 즉시 발동 마법
                executeSpell(spellCard, handIndex: index)
            }
        }
    }

    func summonToSlot(_ slotIndex: Int) {
        guard case .selectingSummonSlot(let card, let handIndex) = uiState else { return }

        guard let payment = TurnSystem.payCost(
            cost: card.cost,
            player: &gameState.players[gameState.currentPlayerIndex]
        ) else {
            addLog("비용 지불 실패!")
            uiState = .mainPhase
            return
        }

        // 패에서 제거
        gameState.currentPlayer.hand.remove(at: handIndex)

        if case .monster(let monsterCard) = card {
            let success = gameState.currentPlayer.field.summonMonster(monsterCard, at: slotIndex)
            if success {
                addLog("\(monsterCard.name) 소환! (슬롯 \(slotIndex + 1)) [기력 -\(payment.energySpent), 기세 -\(payment.momentumSpent)]")
            }
        } else if case .spell(let spellCard) = card {
            let success = gameState.currentPlayer.field.placeSpell(spellCard, at: slotIndex)
            if success {
                addLog("\(spellCard.name) 배치! (슬롯 \(slotIndex + 1))")
            }
        }

        uiState = .mainPhase
    }

    func cancelSlotSelection() {
        uiState = .mainPhase
    }

    private func executeSpell(_ spell: SpellCard, handIndex: Int) {
        guard let payment = TurnSystem.payCost(
            cost: spell.cost,
            player: &gameState.players[gameState.currentPlayerIndex]
        ) else { return }
        gameState.currentPlayer.hand.remove(at: handIndex)

        addLog("\(spell.name) 발동! [기력 -\(payment.energySpent), 기세 -\(payment.momentumSpent)]")

        // 간단한 효과 처리
        applySpellEffect(spell)

        // 묘지로
        gameState.currentPlayer.graveyard.append(.spell(spell))
    }

    private func applySpellEffect(_ spell: SpellCard) {
        switch spell.name {
        case "대지의 방벽":
            // 아군 몬스터 1체에 방어막 600
            if let firstMonster = gameState.currentPlayer.field.monsterSlotIndices.first {
                gameState.currentPlayer.field.applyShield(600, at: firstMonster)
                addLog("방어막 600 부여!")
            }
        case "화염 폭풍":
            // 상대 몬스터 전체에 400 데미지 (CP 이하면 파괴)
            let opponentIdx = gameState.opponentIndex
            for i in gameState.players[opponentIdx].field.monsterSlotIndices.reversed() {
                if case .monster(let m, _) = gameState.players[opponentIdx].field.slots[i].content {
                    if m.combatPower <= 400 {
                        gameState.players[opponentIdx].field.removeCard(at: i)
                        gameState.players[opponentIdx].graveyard.append(.monster(m))
                        addLog("\(m.name) 파괴!")
                    }
                }
            }
        case "치유의 비":
            gameState.currentPlayer.lp = min(TurnSystem.startingLP, gameState.currentPlayer.lp + 500)
            addLog("LP 500 회복! (현재 LP: \(gameState.currentPlayer.lp))")
        case "낙뢰":
            // 상대 몬스터 1체에 800 데미지
            let opponentIdx = gameState.opponentIndex
            if let target = gameState.players[opponentIdx].field.monsterSlotIndices.first {
                if case .monster(let m, _) = gameState.players[opponentIdx].field.slots[target].content {
                    if m.combatPower <= 800 {
                        gameState.players[opponentIdx].field.removeCard(at: target)
                        gameState.players[opponentIdx].graveyard.append(.monster(m))
                        addLog("\(m.name) 파괴!")
                    } else {
                        addLog("\(m.name)에게 800 데미지! (파괴 실패)")
                    }
                }
            }
        case "대지의 울림":
            // 빈 슬롯 2개를 지(地) 속성으로 변경
            var changed = 0
            for i in 0..<PlayerField.slotCount where changed < 2 {
                gameState.currentPlayer.field.setTerrain(.earth, at: i)
                changed += 1
            }
            addLog("슬롯 \(changed)개를 지(地) 지형으로 변경!")
        case "바람의 칼날":
            // 장착: 첫 번째 몬스터 전투력 +400 (방어막으로 구현)
            if let firstMonster = gameState.currentPlayer.field.monsterSlotIndices.first {
                gameState.currentPlayer.field.applyShield(400, at: firstMonster)
                addLog("몬스터에 전투력 +400 장착!")
            }
        default:
            addLog("\(spell.name) 효과 발동!")
        }
    }

    // MARK: - 배틀 페이즈

    func enterBattlePhase() {
        guard isPlayerTurn, gameState.currentPhase == .main else { return }
        gameState.currentPhase = .battle

        if gameState.isFirstTurn && gameState.currentPlayerIndex == 0 {
            addLog("선공 첫 턴은 공격할 수 없습니다.")
            uiState = .battlePhase
            return
        }

        uiState = .battlePhase
        addLog("── 배틀 페이즈 ──")
    }

    func selectAttacker(_ slotIndex: Int) {
        guard canAttack else { return }
        guard case .monster = player.field.slots[slotIndex].content else { return }
        uiState = .selectingAttackTarget(attackerSlot: slotIndex)
    }

    func executeAttack(attackerSlot: Int, defenderSlot: Int?) {
        guard isPlayerTurn else { return }

        if let defSlot = defenderSlot {
            // 몬스터 vs 몬스터
            performMonsterBattle(
                attackerPlayerIdx: playerIndex,
                defenderPlayerIdx: aiIndex,
                attackerSlot: attackerSlot,
                defenderSlot: defSlot
            )
        } else {
            // 직접 공격
            performDirectAttack(
                attackerPlayerIdx: playerIndex,
                defenderPlayerIdx: aiIndex,
                attackerSlot: attackerSlot
            )
        }

        uiState = .battlePhase
        checkGameEnd()
    }

    func cancelAttack() {
        uiState = .battlePhase
    }

    private func performMonsterBattle(
        attackerPlayerIdx: Int,
        defenderPlayerIdx: Int,
        attackerSlot: Int,
        defenderSlot: Int
    ) {
        guard case .monster(let atkCard, _) = gameState.players[attackerPlayerIdx].field.slots[attackerSlot].content,
              case .monster(let defCard, let shield) = gameState.players[defenderPlayerIdx].field.slots[defenderSlot].content
        else { return }

        let result = BattleEngine.resolveCombat(
            attackerCard: atkCard,
            attackerSlot: attackerSlot,
            attackerField: gameState.players[attackerPlayerIdx].field,
            defenderCard: defCard,
            defenderSlot: defenderSlot,
            defenderField: gameState.players[defenderPlayerIdx].field,
            attackerMomentumBonus: 0,
            defenderMomentumBonus: 0,
            defenderShield: shield
        )

        addLog("\(atkCard.name)(CP:\(atkCard.combatPower)) → \(defCard.name)(CP:\(defCard.combatPower))")

        // 기세 획득: 공격 성공
        gameState.players[attackerPlayerIdx].gainMomentum(1)
        gameState.players[attackerPlayerIdx].didAttackThisTurn = true

        if result.defenderDestroyed {
            gameState.players[defenderPlayerIdx].field.removeCard(at: defenderSlot)
            gameState.players[defenderPlayerIdx].graveyard.append(.monster(defCard))
            gameState.players[attackerPlayerIdx].gainMomentum(1) // 파괴 보너스
            addLog("\(defCard.name) 파괴!")
        }

        if result.attackerDestroyed {
            gameState.players[attackerPlayerIdx].field.removeCard(at: attackerSlot)
            gameState.players[attackerPlayerIdx].graveyard.append(.monster(atkCard))
            gameState.players[defenderPlayerIdx].gainMomentum(1) // 피격 보너스
            addLog("\(atkCard.name) 파괴!")
        }

        if result.lpDamageToDefender > 0 {
            gameState.players[defenderPlayerIdx].takeDamage(result.lpDamageToDefender)
            addLog("\(gameState.players[defenderPlayerIdx].name)에게 \(result.lpDamageToDefender) LP 데미지!")
        }

        if result.lpDamageToAttacker > 0 {
            gameState.players[attackerPlayerIdx].takeDamage(result.lpDamageToAttacker)
            addLog("\(gameState.players[attackerPlayerIdx].name)에게 \(result.lpDamageToAttacker) LP 데미지!")
        }
    }

    private func performDirectAttack(
        attackerPlayerIdx: Int,
        defenderPlayerIdx: Int,
        attackerSlot: Int
    ) {
        guard case .monster(let atkCard, _) = gameState.players[attackerPlayerIdx].field.slots[attackerSlot].content
        else { return }

        let damage = BattleEngine.resolveDirectAttack(
            attackerCard: atkCard,
            attackerSlot: attackerSlot,
            attackerField: gameState.players[attackerPlayerIdx].field,
            momentumBonus: 0
        )

        gameState.players[defenderPlayerIdx].takeDamage(damage)
        gameState.players[attackerPlayerIdx].gainMomentum(2) // 직접 데미지 보너스
        gameState.players[attackerPlayerIdx].didAttackThisTurn = true

        addLog("\(atkCard.name)이(가) 직접 공격! \(damage) LP 데미지!")
    }

    // MARK: - 기세 스킬

    func useMomentumSkill(_ skill: MomentumSkill) {
        guard isPlayerTurn, gameState.currentPhase == .main else { return }
        guard player.momentum >= skill.cost else {
            addLog("기세가 부족합니다! (필요: \(skill.cost), 보유: \(player.momentum))")
            return
        }

        gameState.currentPlayer.momentum -= skill.cost
        addLog("기세 스킬 [\(skill.displayName)] 발동! (기세 -\(skill.cost))")

        switch skill {
        case .fighting:
            // 첫 번째 몬스터 전투력 +500 (방어막으로 근사 구현)
            if let slot = player.field.monsterSlotIndices.first {
                gameState.currentPlayer.field.applyShield(500, at: slot)
                addLog("몬스터 전투력 +500!")
            }
        case .terrainShift:
            // 슬롯 2개를 현재 플레이어 주력 속성으로 변경
            var changed = 0
            for i in 0..<PlayerField.slotCount where changed < 2 {
                if gameState.currentPlayer.field.slots[i].terrain == nil {
                    gameState.currentPlayer.field.setTerrain(.fire, at: i)
                    changed += 1
                }
            }
            addLog("지형 2개 변경!")
        case .breakthrough:
            // 모든 몬스터 +300
            for slot in player.field.monsterSlotIndices {
                gameState.currentPlayer.field.applyShield(300, at: slot)
            }
            addLog("전 몬스터 전투력 +300!")
        case .explosion:
            // 상대 전체에 기세 × 100 데미지
            let dmg = BattleEngine.explosionDamage(momentum: skill.cost)
            let opIdx = gameState.opponentIndex
            for i in gameState.players[opIdx].field.monsterSlotIndices.reversed() {
                if case .monster(let m, _) = gameState.players[opIdx].field.slots[i].content {
                    if m.combatPower <= dmg {
                        gameState.players[opIdx].field.removeCard(at: i)
                        gameState.players[opIdx].graveyard.append(.monster(m))
                        addLog("\(m.name) 파괴! (\(dmg) 데미지)")
                    }
                }
            }
        default:
            break
        }
    }

    // MARK: - 턴 종료

    func endTurn() {
        guard isPlayerTurn else { return }

        // 패 초과 처리 (단순화: 초과분 자동 버림)
        while gameState.currentPlayer.hand.count > TurnSystem.maxHandSize {
            let discarded = gameState.currentPlayer.hand.removeLast()
            gameState.currentPlayer.graveyard.append(discarded)
        }

        gameState.nextTurn()

        // AI 턴
        if !isPlayerTurn {
            uiState = .aiTurn
            addLog("")
            startTurn()
        }
    }

    // MARK: - AI

    private func performAIDraw(choices: (choice1: AnyCard, choice2: AnyCard)) {
        let chosen = ai.chooseDrawCard(choice1: choices.choice1, choice2: choices.choice2)
        let rejected = (chosen.id == choices.choice1.id) ? choices.choice2 : choices.choice1
        gameState.resolveDrawChoice(chosen: chosen, rejected: rejected)
        proceedToStandby()
    }

    private func performAITurn() {
        uiState = .aiTurn

        // 메인 페이즈: AI 소환
        gameState.currentPhase = .main
        ai.performMainPhase(gameState: &gameState)

        // 배틀 페이즈: AI 공격
        gameState.currentPhase = .battle
        if !gameState.isFirstTurn {
            let battleLogs = ai.performBattlePhase(gameState: &gameState)
            for log in battleLogs {
                addLog(log)
            }
        }

        if checkGameEnd() { return }

        // 패 초과 처리
        while gameState.currentPlayer.hand.count > TurnSystem.maxHandSize {
            let discarded = gameState.currentPlayer.hand.removeLast()
            gameState.currentPlayer.graveyard.append(discarded)
        }

        // 턴 종료
        gameState.nextTurn()

        // 플레이어 턴 시작
        addLog("")
        startTurn()
    }

    // MARK: - 게임 종료

    @discardableResult
    private func checkGameEnd() -> Bool {
        let result = gameState.result
        if case .win(let winnerIdx, let reason) = result {
            endGame(winnerIndex: winnerIdx)
            addLog(reason.rawValue)
            return true
        }
        return false
    }

    private func endGame(winnerIndex: Int) {
        let winnerName = gameState.players[winnerIndex].name
        uiState = .gameOver(winner: winnerName)
        addLog("🏆 \(winnerName) 승리!")
    }

    // MARK: - 유틸리티

    private func addLog(_ message: String) {
        logs.append(GameLog(message: message))
    }

    private func cardName(_ card: AnyCard) -> String {
        card.name
    }

    func restartGame() {
        let playerDeck = SampleCards.fireRushDeck()
        let aiDeck = SampleCards.earthFortressDeck()
        gameState = GameState(
            player1Deck: playerDeck,
            player2Deck: aiDeck,
            firstPlayerIndex: 0
        )
        logs = []
        uiState = .notStarted
        selectedHandIndex = nil
    }
}

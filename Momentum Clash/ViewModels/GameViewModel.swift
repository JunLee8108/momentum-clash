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
    case selectingSacrificeSlot
    case selectingFightingTarget
    case aiTurn
    case gameOver(winner: String)
}

/// 전투 연출 상태 (AI/플레이어 공용)
struct BattleDisplay: Equatable {
    var message: String = ""
    var highlightedSlot: Int? = nil          // 소환 강조 슬롯
    var attackerSlot: Int? = nil             // 공격자 슬롯
    var targetSlot: Int? = nil               // 공격 대상 슬롯
    var isDirectAttack: Bool = false         // 직접 공격 여부
    var showLPFlash: Bool = false            // LP 데미지 플래시
    var isPlayerAction: Bool = false         // true면 플레이어, false면 AI
}

/// 전투 프리뷰 데이터
struct CombatPreviewData: Equatable {
    let attackerSlot: Int
    let defenderSlot: Int

    let attackerName: String
    let attackerAttribute: Attribute
    let attackerBaseCP: Int
    let attackerEffectiveCP: Int
    let attackerTerrainBonus: Int

    let defenderName: String
    let defenderAttribute: Attribute
    let defenderBaseCP: Int
    let defenderEffectiveCP: Int
    let defenderTerrainBonus: Int
    let defenderShield: Int

    let attackerMultiplier: Double  // 공격자 속성 배율
    let defenderMultiplier: Double  // 방어자 속성 배율

    /// 예상 결과
    var predictedResult: PredictedResult {
        let attackDamage = max(0, attackerEffectiveCP - defenderShield)
        if attackDamage > defenderEffectiveCP {
            return .win
        } else if attackDamage < defenderEffectiveCP {
            return .lose
        } else {
            return .draw
        }
    }

    enum PredictedResult {
        case win, lose, draw

        var displayText: String {
            switch self {
            case .win:  return "승리 예상"
            case .lose: return "패배 예상"
            case .draw: return "동귀어진"
            }
        }

        var color: Color {
            switch self {
            case .win:  return .green
            case .lose: return .red
            case .draw: return .yellow
            }
        }
    }
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
    var showingCardDetail: (card: AnyCard, handIndex: Int)? = nil
    var showingFieldCardDetail: AnyCard? = nil
    var battleDisplay: BattleDisplay? = nil
    var combatPreview: CombatPreviewData? = nil

    let playerIndex = 0  // 플레이어는 항상 인덱스 0
    let aiIndex = 1      // AI는 항상 인덱스 1

    private let ai = BasicAI()

    /// AI 덱 아키타입 이름
    var aiDeckName: String = ""

    /// 마지막으로 사용한 플레이어 덱 (재시작용)
    private var lastPlayerDeck: [AnyCard] = []

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

    /// 커스텀 덱으로 게임 시작
    func startGameWithDeck(playerDeck: [AnyCard], aiDeck: [AnyCard], aiDeckName: String) {
        self.lastPlayerDeck = playerDeck
        self.aiDeckName = aiDeckName

        gameState = GameState(
            player1Deck: playerDeck,
            player2Deck: aiDeck,
            firstPlayerIndex: 0
        )
        logs = []
        uiState = .notStarted
        selectedHandIndex = nil
        showingCardDetail = nil
        showingFieldCardDetail = nil
        battleDisplay = nil
        combatPreview = nil

        addLog("⚔️ Momentum Clash 시작!")
        addLog("상대 덱: \(aiDeckName)")
        addLog("\(player.name)이 선공입니다. 기세 2로 시작!")
        addLog("\(gameState.globalTerrain.emoji) 지형: \(gameState.globalTerrain.displayName) (2라운드)")
        startTurn()
    }

    func startGame() {
        addLog("⚔️ Momentum Clash 시작!")
        addLog("\(player.name)이 선공입니다. 기세 2로 시작!")
        addLog("\(gameState.globalTerrain.emoji) 지형: \(gameState.globalTerrain.displayName) (2라운드)")
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
        gameState.currentPlayer.field.resetAttackFlags()

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
        // 카드 상세보기 표시
        showingCardDetail = (card: card, handIndex: index)
    }

    /// 상세보기에서 "배치하기/사용하기" 눌렀을 때
    func useCardFromDetail() {
        guard let detail = showingCardDetail else { return }
        let card = detail.card
        let index = detail.handIndex
        showingCardDetail = nil

        // 비용 확인 (기력으로만 지불)
        if card.cost > player.energy {
            addLog("기력이 부족합니다! (비용: \(card.cost), 기력: \(player.energy))")
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

    func closeCardDetail() {
        showingCardDetail = nil
    }

    /// 패에서 카드 사용 가능 여부
    func canUseCard(_ card: AnyCard) -> Bool {
        guard isPlayerTurn, gameState.currentPhase == .main else { return false }
        guard card.cost <= player.energy else { return false }
        if case .monster = card {
            return !player.field.emptySlotIndices.isEmpty
        }
        if case .spell(let s) = card, s.spellType == .continuous {
            return !player.field.emptySlotIndices.isEmpty
        }
        return true
    }

    func summonToSlot(_ slotIndex: Int) {
        guard case .selectingSummonSlot(let card, let handIndex) = uiState else { return }

        guard let energySpent = TurnSystem.payCost(
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
                gameState.currentPlayer.summonedThisTurn.insert(slotIndex)
                addLog("\(monsterCard.name) 소환! (슬롯 \(slotIndex + 1)) [기력 -\(energySpent)]")
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

    // MARK: - 릴리즈 (몬스터 희생)

    /// 희생 가능한 몬스터가 있는지 확인
    var hasSacrifiableMonster: Bool {
        let field = player.field
        for i in field.monsterSlotIndices {
            if !player.summonedThisTurn.contains(i) {
                return true
            }
        }
        return false
    }

    func enterSacrificeMode() {
        guard isPlayerTurn, gameState.currentPhase == .main else { return }
        uiState = .selectingSacrificeSlot
    }

    func sacrificeMonster(at slotIndex: Int) {
        guard case .selectingSacrificeSlot = uiState else { return }
        guard case .monster(let card, _) = player.field.slots[slotIndex].content else { return }
        guard !player.summonedThisTurn.contains(slotIndex) else {
            addLog("이번 턴에 소환한 몬스터는 희생할 수 없습니다!")
            return
        }

        // 필드에서 제거 → 묘지로 이동
        gameState.currentPlayer.field.removeCard(at: slotIndex)
        gameState.currentPlayer.graveyard.append(.monster(card))

        // 기력 충전 (소환 비용만큼)
        gameState.currentPlayer.energy += card.cost
        addLog("릴리즈: \(card.name) 희생! (기력 +\(card.cost))")

        uiState = .mainPhase
    }

    private func executeSpell(_ spell: SpellCard, handIndex: Int) {
        guard let energySpent = TurnSystem.payCost(
            cost: spell.cost,
            player: &gameState.players[gameState.currentPlayerIndex]
        ) else { return }
        gameState.currentPlayer.hand.remove(at: handIndex)

        addLog("\(spell.name) 발동! [기력 -\(energySpent)]")

        // 간단한 효과 처리
        applySpellEffect(spell)

        // 묘지로
        gameState.currentPlayer.graveyard.append(.spell(spell))
    }

    private func applySpellEffect(_ spell: SpellCard) {
        // 지형 마법 처리
        if spell.spellType == .terrain {
            applyTerrainSpell(spell)
            return
        }

        switch spell.name {
        case "대지의 방벽":
            if let firstMonster = gameState.currentPlayer.field.monsterSlotIndices.first {
                gameState.currentPlayer.field.applyShield(600, at: firstMonster)
                addLog("방어막 600 부여!")
            }
        case "낙뢰":
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
        case "바람의 칼날":
            gameState.currentPlayer.momentumBonus += 400
            addLog("이번 턴 전투력 +400!")
        default:
            addLog("\(spell.name) 효과 발동!")
        }
    }

    /// 지형 마법카드 효과 처리
    private func applyTerrainSpell(_ spell: SpellCard) {
        let prevTerrain = gameState.globalTerrain
        gameState.setSpellTerrain(spell.attribute)
        addLog("\(spell.attribute.emoji) 지형 변경: \(prevTerrain.displayName) → \(spell.attribute.displayName) (2라운드)")

        // 속성별 부가효과
        switch spell.attribute {
        case .fire:
            // 상대 몬스터 전체에 200 데미지
            let opponentIdx = gameState.opponentIndex
            for i in gameState.players[opponentIdx].field.monsterSlotIndices.reversed() {
                if case .monster(let m, _) = gameState.players[opponentIdx].field.slots[i].content {
                    if m.combatPower <= 200 {
                        gameState.players[opponentIdx].field.removeCard(at: i)
                        gameState.players[opponentIdx].graveyard.append(.monster(m))
                        addLog("\(m.name) 파괴! (화염 데미지)")
                    }
                }
            }
            addLog("상대 전체에 200 데미지!")

        case .water:
            // LP 300 회복
            gameState.currentPlayer.lp = min(TurnSystem.startingLP, gameState.currentPlayer.lp + 300)
            addLog("LP 300 회복! (현재 LP: \(gameState.currentPlayer.lp))")

        case .earth:
            // 아군 몬스터 전체에 방어막 200
            for slot in gameState.currentPlayer.field.monsterSlotIndices {
                gameState.currentPlayer.field.applyShield(200, at: slot)
            }
            addLog("아군 전체 방어막 200 부여!")

        case .wind:
            // 상대 몬스터 1체 CP -200 (방어막 -200으로 구현, 최소 0)
            let opponentIdx = gameState.opponentIndex
            if let target = gameState.players[opponentIdx].field.monsterSlotIndices.first {
                if case .monster(let m, _) = gameState.players[opponentIdx].field.slots[target].content {
                    addLog("\(m.name) 전투력 -200!")
                }
            }

        case .thunder:
            // 상대 몬스터 1체에 300 데미지 (가장 강한 몬스터 타겟)
            let opponentIdx = gameState.opponentIndex
            let monsterSlots = gameState.players[opponentIdx].field.monsterSlotIndices
            if let target = monsterSlots.max(by: { a, b in
                guard case .monster(let mA, _) = gameState.players[opponentIdx].field.slots[a].content,
                      case .monster(let mB, _) = gameState.players[opponentIdx].field.slots[b].content else { return false }
                return mA.combatPower < mB.combatPower
            }) {
                if case .monster(let m, _) = gameState.players[opponentIdx].field.slots[target].content {
                    if m.combatPower <= 300 {
                        gameState.players[opponentIdx].field.removeCard(at: target)
                        gameState.players[opponentIdx].graveyard.append(.monster(m))
                        addLog("\(m.name) 파괴! (번개 심판)")
                    } else {
                        addLog("\(m.name)에 300 데미지!")
                    }
                }
            }

        case .dark:
            // 상대 몬스터 전체 방어막 제거
            let opponentIdx = gameState.opponentIndex
            for i in gameState.players[opponentIdx].field.monsterSlotIndices {
                if case .monster(let m, let shield) = gameState.players[opponentIdx].field.slots[i].content, shield > 0 {
                    gameState.players[opponentIdx].field.slots[i].content = .monster(m, shield: 0)
                    addLog("\(m.name) 방어막 제거! (-\(shield))")
                }
            }
            addLog("상대 전체 방어막 제거!")

        case .light:
            // 아군 몬스터 전체에 방어막 200 부여 (HP 회복 대신 방어막으로 구현)
            for slot in gameState.currentPlayer.field.monsterSlotIndices {
                gameState.currentPlayer.field.applyShield(200, at: slot)
            }
            addLog("아군 전체 HP 200 회복! (방어막 부여)")
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
        guard !player.field.slots[slotIndex].hasAttacked else {
            addLog("이미 공격한 몬스터입니다!")
            return
        }
        uiState = .selectingAttackTarget(attackerSlot: slotIndex)
        combatPreview = nil
    }

    /// 공격 대상 위에 호버/선택 시 프리뷰 갱신
    func updateCombatPreview(attackerSlot: Int, defenderSlot: Int) {
        guard case .monster(let atkCard, _) = player.field.slots[attackerSlot].content,
              case .monster(let defCard, let shield) = aiPlayer.field.slots[defenderSlot].content
        else {
            combatPreview = nil
            return
        }

        let atkTerrainBonus = player.field.terrainBonus(at: attackerSlot, globalTerrain: gameState.globalTerrain)
        let defTerrainBonus = aiPlayer.field.terrainBonus(at: defenderSlot, globalTerrain: gameState.globalTerrain)

        let atkMultiplier = atkCard.attribute.damageMultiplier(against: defCard.attribute)
        let defMultiplier = defCard.attribute.damageMultiplier(against: atkCard.attribute)

        let atkEffective = BattleEngine.calculateEffectiveCP(
            card: atkCard, slotIndex: attackerSlot,
            field: player.field, opponentAttribute: defCard.attribute,
            momentumBonus: effectiveMomentumBonus(forPlayerAt: playerIndex, slotIndex: attackerSlot), globalTerrain: gameState.globalTerrain
        )
        let defEffective = BattleEngine.calculateEffectiveCP(
            card: defCard, slotIndex: defenderSlot,
            field: aiPlayer.field, opponentAttribute: atkCard.attribute,
            momentumBonus: effectiveMomentumBonus(forPlayerAt: aiIndex, slotIndex: defenderSlot), globalTerrain: gameState.globalTerrain
        )

        combatPreview = CombatPreviewData(
            attackerSlot: attackerSlot,
            defenderSlot: defenderSlot,
            attackerName: atkCard.name,
            attackerAttribute: atkCard.attribute,
            attackerBaseCP: atkCard.combatPower,
            attackerEffectiveCP: atkEffective,
            attackerTerrainBonus: atkTerrainBonus,
            defenderName: defCard.name,
            defenderAttribute: defCard.attribute,
            defenderBaseCP: defCard.combatPower,
            defenderEffectiveCP: defEffective,
            defenderTerrainBonus: defTerrainBonus,
            defenderShield: shield,
            attackerMultiplier: atkMultiplier,
            defenderMultiplier: defMultiplier
        )
    }

    func executeAttack(attackerSlot: Int, defenderSlot: Int?) {
        guard isPlayerTurn else { return }

        combatPreview = nil

        // 공격 애니메이션 중에는 추가 입력 차단
        uiState = .battlePhase

        Task {
            await performPlayerAttackAnimated(attackerSlot: attackerSlot, defenderSlot: defenderSlot)
            checkGameEnd()
        }
    }

    func cancelAttack() {
        combatPreview = nil
        uiState = .battlePhase
    }

    private func performPlayerAttackAnimated(attackerSlot: Int, defenderSlot: Int?) async {
        if let defSlot = defenderSlot {
            // 몬스터 vs 몬스터
            guard case .monster(let atkCard, _) = gameState.players[playerIndex].field.slots[attackerSlot].content,
                  case .monster(let defCard, let shield) = gameState.players[aiIndex].field.slots[defSlot].content
            else { return }

            // 공격 선언 연출
            withAnimation(.easeInOut(duration: 0.3)) {
                battleDisplay = BattleDisplay(
                    message: "\(atkCard.name) → \(defCard.name)!",
                    attackerSlot: attackerSlot,
                    targetSlot: defSlot,
                    isPlayerAction: true
                )
            }
            try? await Task.sleep(for: .seconds(0.5))

            // 전투 실행
            let result = BattleEngine.resolveCombat(
                attackerCard: atkCard,
                attackerSlot: attackerSlot,
                attackerField: gameState.players[playerIndex].field,
                defenderCard: defCard,
                defenderSlot: defSlot,
                defenderField: gameState.players[aiIndex].field,
                attackerMomentumBonus: effectiveMomentumBonus(forPlayerAt: playerIndex, slotIndex: attackerSlot),
                defenderMomentumBonus: effectiveMomentumBonus(forPlayerAt: aiIndex, slotIndex: defSlot),
                defenderShield: shield,
                globalTerrain: gameState.globalTerrain
            )

            addLog("\(atkCard.name)(CP:\(result.attackerEffectiveCP)) → \(defCard.name)(CP:\(result.defenderEffectiveCP))")
            gameState.players[playerIndex].gainMomentum(1)
            gameState.players[playerIndex].didAttackThisTurn = true
            gameState.players[playerIndex].field.slots[attackerSlot].hasAttacked = true

            // 방어막 소모 반영 (파괴되지 않은 경우)
            if !result.defenderDestroyed {
                gameState.players[aiIndex].field.setShield(result.remainingShield, at: defSlot)
                if shield > 0 && result.remainingShield < shield {
                    addLog("\(defCard.name) 방어막 \(shield - result.remainingShield) 소모! (잔여: \(result.remainingShield))")
                }
            }

            // 결과 연출
            if result.defenderDestroyed {
                gameState.players[aiIndex].field.removeCard(at: defSlot)
                gameState.players[aiIndex].graveyard.append(.monster(defCard))
                gameState.players[playerIndex].gainMomentum(1)
                withAnimation(.easeInOut(duration: 0.3)) {
                    battleDisplay = BattleDisplay(
                        message: "\(defCard.name) 파괴!",
                        isPlayerAction: true
                    )
                }
                addLog("\(defCard.name) 파괴!")
                try? await Task.sleep(for: .seconds(0.4))
            }

            if result.attackerDestroyed {
                gameState.players[playerIndex].field.removeCard(at: attackerSlot)
                gameState.players[playerIndex].graveyard.append(.monster(atkCard))
                gameState.players[aiIndex].gainMomentum(1)
                withAnimation(.easeInOut(duration: 0.3)) {
                    battleDisplay = BattleDisplay(
                        message: "\(atkCard.name) 파괴!",
                        isPlayerAction: true
                    )
                }
                addLog("\(atkCard.name) 파괴!")
                try? await Task.sleep(for: .seconds(0.4))
            }

            if result.lpDamageToDefender > 0 {
                gameState.players[aiIndex].takeDamage(result.lpDamageToDefender)
                withAnimation(.easeInOut(duration: 0.2)) {
                    battleDisplay = BattleDisplay(
                        message: "\(gameState.players[aiIndex].name)에게 \(result.lpDamageToDefender) 데미지!",
                        showLPFlash: true,
                        isPlayerAction: true
                    )
                }
                addLog("\(gameState.players[aiIndex].name)에게 \(result.lpDamageToDefender) LP 데미지!")
                try? await Task.sleep(for: .seconds(0.4))
            }

            if result.lpDamageToAttacker > 0 {
                gameState.players[playerIndex].takeDamage(result.lpDamageToAttacker)
                addLog("\(gameState.players[playerIndex].name)에게 \(result.lpDamageToAttacker) LP 데미지!")
            }

        } else {
            // 직접 공격
            guard case .monster(let atkCard, _) = gameState.players[playerIndex].field.slots[attackerSlot].content
            else { return }

            // 직접 공격 연출
            withAnimation(.easeInOut(duration: 0.3)) {
                battleDisplay = BattleDisplay(
                    message: "\(atkCard.name) 직접 공격!",
                    attackerSlot: attackerSlot,
                    isDirectAttack: true,
                    isPlayerAction: true
                )
            }
            try? await Task.sleep(for: .seconds(0.5))

            let damage = BattleEngine.resolveDirectAttack(
                attackerCard: atkCard,
                attackerSlot: attackerSlot,
                attackerField: gameState.players[playerIndex].field,
                momentumBonus: effectiveMomentumBonus(forPlayerAt: playerIndex, slotIndex: attackerSlot),
                globalTerrain: gameState.globalTerrain
            )

            gameState.players[aiIndex].takeDamage(damage)
            gameState.players[playerIndex].gainMomentum(2)
            gameState.players[playerIndex].didAttackThisTurn = true
            gameState.players[playerIndex].field.slots[attackerSlot].hasAttacked = true

            withAnimation(.easeInOut(duration: 0.2)) {
                battleDisplay = BattleDisplay(
                    message: "\(damage) LP 데미지!",
                    showLPFlash: true,
                    isPlayerAction: true
                )
            }
            addLog("\(atkCard.name)이(가) 직접 공격! \(damage) LP 데미지!")
            try? await Task.sleep(for: .seconds(0.4))
        }

        // 클린업
        withAnimation {
            battleDisplay = nil
        }
    }

    // MARK: - 기세 보너스 계산

    /// 특정 플레이어의 특정 슬롯에 적용되는 기세 보너스 계산
    /// 투지는 타겟 슬롯에만, 돌파 등은 전체에 적용
    func effectiveMomentumBonus(forPlayerAt playerIdx: Int, slotIndex: Int) -> Int {
        let p = gameState.players[playerIdx]
        guard let skill = p.activeMomentumSkill else { return 0 }
        switch skill {
        case .fighting:
            return p.fightingTargetSlot == slotIndex ? 500 : 0
        case .breakthrough:
            return 300
        case .terrainMastery:
            return p.momentumBonus  // 이미 전체 적용
        default:
            return p.momentumBonus
        }
    }

    // MARK: - 기세 스킬

    func useMomentumSkill(_ skill: MomentumSkill) {
        guard isPlayerTurn, gameState.currentPhase == .main else { return }
        guard player.momentum >= skill.cost else {
            addLog("기세가 부족합니다! (필요: \(skill.cost), 보유: \(player.momentum))")
            return
        }

        // 투지: 필드에 몬스터가 있어야 하고, 타겟 선택 모드로 전환
        if skill == .fighting {
            guard player.field.monsterCount > 0 else {
                addLog("필드에 몬스터가 없습니다!")
                return
            }
            gameState.currentPlayer.momentum -= skill.cost
            gameState.currentPlayer.activeMomentumSkill = skill
            addLog("기세 스킬 [\(skill.displayName)] 발동! 대상 몬스터를 선택하세요.")
            uiState = .selectingFightingTarget
            return
        }

        gameState.currentPlayer.momentum -= skill.cost
        gameState.currentPlayer.activeMomentumSkill = skill
        addLog("기세 스킬 [\(skill.displayName)] 발동! (기세 -\(skill.cost))")

        // 배너 애니메이션
        withAnimation(.easeInOut(duration: 0.3)) {
            battleDisplay = BattleDisplay(
                message: "기세 스킬: \(skill.displayName)!",
                isPlayerAction: true
            )
        }
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            await MainActor.run {
                withAnimation {
                    battleDisplay = nil
                }
            }
        }

        switch skill {
        case .terrainMastery:
            // 지형 보너스 2배: 추가 +300 (합계 +600)
            gameState.currentPlayer.momentumBonus += PlayerField.globalTerrainBonus
            let terrain = gameState.globalTerrain
            addLog("\(terrain.emoji) 지형 장악! 보너스 2배!")
        case .breakthrough:
            // 모든 몬스터 +300
            gameState.currentPlayer.momentumBonus += 300
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

    /// 투지 스킬 타겟 선택 완료
    func applyFightingSkill(toSlot slotIndex: Int) {
        guard case .selectingFightingTarget = uiState else { return }
        guard case .monster(let m, _) = player.field.slots[slotIndex].content else { return }

        gameState.currentPlayer.fightingTargetSlot = slotIndex
        gameState.currentPlayer.momentumBonus += 500
        addLog("\(m.name)에 투지 적용! 전투력 +500!")

        // 배너 애니메이션
        withAnimation(.easeInOut(duration: 0.3)) {
            battleDisplay = BattleDisplay(
                message: "\(m.name) 전투력 +500!",
                isPlayerAction: true
            )
        }
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            await MainActor.run {
                withAnimation {
                    battleDisplay = nil
                }
            }
        }

        uiState = .mainPhase
    }

    // MARK: - 턴 종료

    func endTurn() {
        guard isPlayerTurn else { return }

        // 패 초과 처리 (단순화: 초과분 자동 버림)
        while gameState.currentPlayer.hand.count > TurnSystem.maxHandSize {
            let discarded = gameState.currentPlayer.hand.removeLast()
            gameState.currentPlayer.graveyard.append(discarded)
        }

        let prevTerrain = gameState.globalTerrain
        gameState.nextTurn()
        announceTerrainChangeIfNeeded(from: prevTerrain)

        // AI 턴
        if !isPlayerTurn {
            uiState = .aiTurn
            addLog("")
            startTurn()
        }
    }

    /// 지형 변경 시 로그 출력
    private func announceTerrainChangeIfNeeded(from previous: Attribute) {
        if gameState.globalTerrain != previous {
            addLog("\(gameState.globalTerrain.emoji) 지형 변경! → \(gameState.globalTerrain.displayName) (2라운드)")
        }
    }

    // MARK: - AI

    private func performAIDraw(choices: (choice1: AnyCard, choice2: AnyCard)) {
        let chosen = ai.chooseDrawCard(choice1: choices.choice1, choice2: choices.choice2, gameState: gameState)
        let rejected = (chosen.id == choices.choice1.id) ? choices.choice2 : choices.choice1
        gameState.resolveDrawChoice(chosen: chosen, rejected: rejected)
        addLog("\(cardName(chosen))을(를) 드로우했습니다.")
        proceedToStandby()
    }

    private func performAITurn() {
        uiState = .aiTurn

        Task {
            await performAITurnAnimated()
        }
    }

    private func performAITurnAnimated() async {
        let idx = gameState.currentPlayerIndex

        // -- 메인 페이즈 --
        gameState.currentPhase = .main

        // 릴리즈 판단: 소환 전에 희생 여부 결정
        if let sacrifice = ai.planSacrifice(gameState: gameState),
           case .monster(let sacMonster, _) = gameState.players[idx].field.slots[sacrifice.sacrificeSlot].content {

            await showAIBanner("릴리즈", duration: 0.8)

            // 필드에서 제거 → 묘지 이동
            gameState.players[idx].field.removeCard(at: sacrifice.sacrificeSlot)
            gameState.players[idx].graveyard.append(.monster(sacMonster))

            // 기력 충전
            gameState.players[idx].energy += sacMonster.cost

            withAnimation(.easeInOut(duration: 0.3)) {
                battleDisplay = BattleDisplay(
                    message: "릴리즈: \(sacMonster.name) 희생!",
                    highlightedSlot: sacrifice.sacrificeSlot
                )
            }
            addLog("릴리즈: \(sacMonster.name) 희생! (기력 +\(sacMonster.cost))")

            try? await Task.sleep(for: .seconds(1.2))
        }

        let summonPlans = ai.planMainPhase(gameState: gameState)

        if !summonPlans.isEmpty {
            await showAIBanner("메인 페이즈", duration: 0.8)
        }

        for plan in summonPlans {
            // 비용 지불 (기력으로만)
            guard TurnSystem.payCost(
                cost: plan.card.cost,
                player: &gameState.players[idx]
            ) != nil else { continue }

            // 패에서 제거 (인덱스가 변할 수 있으므로 id 기반 검색)
            if let handIdx = gameState.players[idx].hand.firstIndex(where: { $0.id == plan.card.id }) {
                gameState.players[idx].hand.remove(at: handIdx)
            }

            // 빈 슬롯 찾기
            guard let slotIdx = gameState.players[idx].field.emptySlotIndices.first else { continue }

            // 소환 연출
            withAnimation(.easeInOut(duration: 0.3)) {
                battleDisplay = BattleDisplay(
                    message: "\(plan.card.name) 소환!",
                    highlightedSlot: slotIdx
                )
            }

            // 실제 소환
            switch plan.card {
            case .monster(let m):
                _ = gameState.players[idx].field.summonMonster(m, at: slotIdx)
                addLog("\(m.name) 소환! (슬롯 \(slotIdx + 1))")
            case .spell(let s):
                if s.spellType == .continuous {
                    _ = gameState.players[idx].field.placeSpell(s, at: slotIdx)
                    addLog("\(s.name) 배치! (슬롯 \(slotIdx + 1))")
                } else {
                    gameState.players[idx].graveyard.append(.spell(s))
                    addLog("\(s.name) 발동!")
                }
            }

            try? await Task.sleep(for: .seconds(1.4))
        }

        // -- 기세 스킬 --
        if let choice = ai.chooseMomentumSkill(gameState: gameState) {
            await executeAIMomentumSkill(choice)
        }

        // -- 배틀 페이즈 --
        gameState.currentPhase = .battle
        if !gameState.isFirstTurn {
            let attackPlans = ai.planBattlePhase(gameState: gameState)

            if !attackPlans.isEmpty {
                await showAIBanner("배틀 페이즈", duration: 0.8)
            }

            for plan in attackPlans {
                guard case .monster(let atkCard, _) = gameState.players[idx].field.slots[plan.attackerSlot].content
                else { continue }

                let defIdx = 1 - idx

                if let defSlot = plan.defenderSlot {
                    // 몬스터 vs 몬스터
                    guard case .monster(let defCard, let shield) = gameState.players[defIdx].field.slots[defSlot].content
                    else { continue }

                    // 공격 연출: 공격자 강조
                    withAnimation(.easeInOut(duration: 0.3)) {
                        battleDisplay = BattleDisplay(
                            message: "\(atkCard.name) → \(defCard.name)!",
                            attackerSlot: plan.attackerSlot,
                            targetSlot: defSlot
                        )
                    }
                    try? await Task.sleep(for: .seconds(1.2))

                    // 전투 실행
                    let result = BattleEngine.resolveCombat(
                        attackerCard: atkCard,
                        attackerSlot: plan.attackerSlot,
                        attackerField: gameState.players[idx].field,
                        defenderCard: defCard,
                        defenderSlot: defSlot,
                        defenderField: gameState.players[defIdx].field,
                        attackerMomentumBonus: effectiveMomentumBonus(forPlayerAt: idx, slotIndex: plan.attackerSlot),
                        defenderMomentumBonus: effectiveMomentumBonus(forPlayerAt: defIdx, slotIndex: defSlot),
                        defenderShield: shield,
                        globalTerrain: gameState.globalTerrain
                    )

                    addLog("\(atkCard.name)(CP:\(result.attackerEffectiveCP)) → \(defCard.name)(CP:\(result.defenderEffectiveCP))")
                    gameState.players[idx].gainMomentum(1)
                    gameState.players[idx].didAttackThisTurn = true
                    gameState.players[idx].field.slots[plan.attackerSlot].hasAttacked = true

                    // 방어막 소모 반영
                    if !result.defenderDestroyed {
                        gameState.players[defIdx].field.setShield(result.remainingShield, at: defSlot)
                        if shield > 0 && result.remainingShield < shield {
                            addLog("  → \(defCard.name) 방어막 \(shield - result.remainingShield) 소모! (잔여: \(result.remainingShield))")
                        }
                    }

                    // 결과 연출
                    if result.defenderDestroyed {
                        gameState.players[defIdx].field.removeCard(at: defSlot)
                        gameState.players[defIdx].graveyard.append(.monster(defCard))
                        gameState.players[idx].gainMomentum(1)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            battleDisplay = BattleDisplay(message: "\(defCard.name) 파괴!")
                        }
                        addLog("  → \(defCard.name) 파괴!")
                        try? await Task.sleep(for: .seconds(0.9))
                    }
                    if result.attackerDestroyed {
                        gameState.players[idx].field.removeCard(at: plan.attackerSlot)
                        gameState.players[idx].graveyard.append(.monster(atkCard))
                        gameState.players[defIdx].gainMomentum(1)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            battleDisplay = BattleDisplay(message: "\(atkCard.name) 파괴!")
                        }
                        addLog("  → \(atkCard.name) 파괴!")
                        try? await Task.sleep(for: .seconds(0.9))
                    }
                    if result.lpDamageToDefender > 0 {
                        gameState.players[defIdx].takeDamage(result.lpDamageToDefender)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            battleDisplay = BattleDisplay(
                                message: "\(gameState.players[defIdx].name)에게 \(result.lpDamageToDefender) 데미지!",
                                showLPFlash: true
                            )
                        }
                        addLog("  → \(gameState.players[defIdx].name)에게 \(result.lpDamageToDefender) LP 데미지!")
                        try? await Task.sleep(for: .seconds(0.9))
                    }
                    if result.lpDamageToAttacker > 0 {
                        gameState.players[idx].takeDamage(result.lpDamageToAttacker)
                        addLog("  → \(gameState.players[idx].name)에게 \(result.lpDamageToAttacker) LP 데미지!")
                    }

                    if gameState.players[defIdx].isDefeated { break }

                } else {
                    // 직접 공격
                    let damage = BattleEngine.resolveDirectAttack(
                        attackerCard: atkCard,
                        attackerSlot: plan.attackerSlot,
                        attackerField: gameState.players[idx].field,
                        momentumBonus: effectiveMomentumBonus(forPlayerAt: idx, slotIndex: plan.attackerSlot),
                        globalTerrain: gameState.globalTerrain
                    )

                    // 직접 공격 연출
                    withAnimation(.easeInOut(duration: 0.3)) {
                        battleDisplay = BattleDisplay(
                            message: "\(atkCard.name) 직접 공격!",
                            attackerSlot: plan.attackerSlot,
                            isDirectAttack: true
                        )
                    }
                    try? await Task.sleep(for: .seconds(1.2))

                    gameState.players[defIdx].takeDamage(damage)
                    gameState.players[idx].gainMomentum(2)
                    gameState.players[idx].didAttackThisTurn = true
                    gameState.players[idx].field.slots[plan.attackerSlot].hasAttacked = true

                    withAnimation(.easeInOut(duration: 0.2)) {
                        battleDisplay = BattleDisplay(
                            message: "\(damage) LP 데미지!",
                            showLPFlash: true
                        )
                    }
                    addLog("\(atkCard.name)이(가) 직접 공격! \(damage) LP 데미지!")
                    try? await Task.sleep(for: .seconds(0.9))

                    if gameState.players[defIdx].isDefeated { break }
                }

                try? await Task.sleep(for: .seconds(0.5))
            }
        }

        // 클린업
        withAnimation {
            battleDisplay = nil
        }

        if checkGameEnd() { return }

        // 패 초과 처리
        while gameState.currentPlayer.hand.count > TurnSystem.maxHandSize {
            let discarded = gameState.currentPlayer.hand.removeLast()
            gameState.currentPlayer.graveyard.append(discarded)
        }

        // 턴 종료
        let prevTerrain = gameState.globalTerrain
        gameState.nextTurn()
        announceTerrainChangeIfNeeded(from: prevTerrain)

        // 잠시 대기 후 플레이어 턴 시작
        try? await Task.sleep(for: .seconds(0.7))
        addLog("")
        startTurn()
    }

    private func executeAIMomentumSkill(_ choice: BasicAI.MomentumSkillChoice) async {
        let idx = gameState.currentPlayerIndex
        let skill = choice.skill
        guard gameState.players[idx].momentum >= skill.cost else { return }

        gameState.players[idx].momentum -= skill.cost
        gameState.players[idx].activeMomentumSkill = skill

        withAnimation(.easeInOut(duration: 0.3)) {
            battleDisplay = BattleDisplay(
                message: "기세 스킬: \(skill.displayName)!"
            )
        }
        addLog("기세 스킬 [\(skill.displayName)] 발동! (기세 -\(skill.cost))")
        try? await Task.sleep(for: .seconds(1.0))

        switch skill {
        case .fighting:
            // 시뮬레이션에서 미리 결정된 최적 타겟 사용
            if let targetSlot = choice.fightingTargetSlot {
                gameState.players[idx].fightingTargetSlot = targetSlot
                gameState.players[idx].momentumBonus += 500
                if case .monster(let m, _) = gameState.players[idx].field.slots[targetSlot].content {
                    addLog("\(m.name)에 투지 적용! 전투력 +500!")
                }
            }
        case .terrainMastery:
            let terrain = gameState.globalTerrain
            gameState.players[idx].momentumBonus += PlayerField.globalTerrainBonus
            addLog("\(terrain.emoji) 지형 장악! 보너스 2배!")
        case .breakthrough:
            gameState.players[idx].momentumBonus += 300
            addLog("전 몬스터 전투력 +300!")
        case .explosion:
            let dmg = BattleEngine.explosionDamage(momentum: skill.cost)
            let opIdx = 1 - idx
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

        try? await Task.sleep(for: .seconds(0.6))
        withAnimation {
            battleDisplay = nil
        }
    }

    private func showAIBanner(_ text: String, duration: Double) async {
        withAnimation(.easeInOut(duration: 0.2)) {
            battleDisplay = BattleDisplay(message: "── \(text) ──")
        }
        try? await Task.sleep(for: .seconds(duration))
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
        // 이전 덱이 있으면 재사용, 없으면 기본 덱
        let playerDeck = lastPlayerDeck.isEmpty ? SampleCards.fireRushDeck() : lastPlayerDeck
        var newPlayerDeck = playerDeck
        newPlayerDeck.shuffle()

        let aiDeckInfo = AIDeckTemplates.randomDeck()
        aiDeckName = aiDeckInfo.name

        gameState = GameState(
            player1Deck: newPlayerDeck,
            player2Deck: aiDeckInfo.deck,
            firstPlayerIndex: 0
        )
        logs = []
        uiState = .notStarted
        selectedHandIndex = nil
        showingCardDetail = nil
        showingFieldCardDetail = nil
        battleDisplay = nil
        combatPreview = nil
    }
}

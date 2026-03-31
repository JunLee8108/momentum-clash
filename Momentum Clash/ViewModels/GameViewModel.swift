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
    case selectingEffectTarget(card: MonsterCard, slotIndex: Int, isAllyTarget: Bool)
    case selectingSpellEffectTarget(spell: SpellCard, isAllyTarget: Bool)
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
    var summonEffect: SummonEffectType? = nil // 5성 소환 풀스크린 이펙트
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

/// 핸드 카드 상세보기 데이터 (sheet용)
struct HandCardDetail: Identifiable {
    let id = UUID()
    let card: AnyCard
    let handIndex: Int
}

/// 필드 카드 상세보기 데이터 (sheet용)
struct FieldCardDetail: Identifiable {
    let id = UUID()
    let card: AnyCard
}

/// 소환 카드 이동 애니메이션 데이터
struct SummonAnimation: Equatable {
    let card: AnyCard
    let targetSlotIndex: Int
    let isPlayer: Bool
    let startPosition: CGPoint   // 출발 좌표 (해당 카드의 실제 위치)
    var animating: Bool = false   // true면 도착 위치로 이동 중
    let handIndex: Int?          // 패에서 숨길 카드 인덱스 (플레이어만)
}

/// 게임 뷰모델 (MVVM 컨트롤러)
@Observable
@MainActor
class GameViewModel {
    var gameState: GameState
    var uiState: GameUIState = .notStarted
    var logs: [GameLog] = []
    var selectedHandIndex: Int? = nil
    var summoningHandIndex: Int? {
        if case .selectingSummonSlot(_, let handIndex) = uiState { return handIndex }
        return nil
    }
    var showingCardDetail: HandCardDetail? = nil
    var showingFieldCardDetail: FieldCardDetail? = nil
    var battleDisplay: BattleDisplay? = nil
    var combatPreview: CombatPreviewData? = nil
    var summonAnimation: SummonAnimation? = nil

    /// 필드 슬롯 좌표 저장 (View에서 업데이트)
    var playerSlotFrames: [Int: CGRect] = [:]
    var aiSlotFrames: [Int: CGRect] = [:]
    var playerHandCenter: CGPoint = .zero
    var aiHandCenter: CGPoint = .zero
    var handCardFrames: [Int: CGRect] = [:]

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

    var hasAttackableMonster: Bool {
        player.field.slots.contains { slot in
            slot.content.isOccupied && !slot.hasAttacked
        }
    }

    init() {
        let playerDeck = SampleCards.fireRushDeck()
        let aiDeck = SampleCards.earthFortressDeck()
        self.gameState = GameState(
            player1Deck: playerDeck,
            player2Deck: aiDeck,
            firstPlayerIndex: Int.random(in: 0...1)
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
            firstPlayerIndex: Int.random(in: 0...1)
        )
        logs = []
        uiState = .notStarted
        selectedHandIndex = nil
        showingCardDetail = nil
        showingFieldCardDetail = nil
        battleDisplay = nil
        combatPreview = nil

        showFirstTurnBanner(aiDeckName: aiDeckName)
    }

    func startGame() {
        showFirstTurnBanner(aiDeckName: nil)
    }

    /// 선공 배너 표시 → 1.5초 후 게임 시작
    private func showFirstTurnBanner(aiDeckName: String?) {
        let isPlayerFirst = gameState.firstPlayerIndex == 0
        let firstLabel = isPlayerFirst ? "당신이 선공입니다!" : "AI가 선공입니다!"

        addLog("⚔️ Momentum Clash 시작!")
        if let deckName = aiDeckName {
            addLog("상대 덱: \(deckName)")
        }
        addLog("\(firstLabel) 기세 2로 시작!")
        addLog("\(gameState.globalTerrain.emoji) 지형: \(gameState.globalTerrain.displayName) (2라운드)")

        withAnimation(.easeInOut(duration: 0.3)) {
            battleDisplay = BattleDisplay(
                message: "⚔️ \(firstLabel)",
                isPlayerAction: isPlayerFirst
            )
        }

        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeOut(duration: 0.3)) {
                battleDisplay = nil
            }
            try? await Task.sleep(for: .seconds(0.3))
            startTurn()
        }
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
        withAnimation(.easeInOut(duration: 0.25)) {
            showingCardDetail = HandCardDetail(card: card, handIndex: index)
        }
    }

    /// 상세보기에서 "배치하기/사용하기" 눌렀을 때
    func useCardFromDetail() {
        guard let detail = showingCardDetail else { return }
        let card = detail.card
        let index = detail.handIndex

        // 오버레이 즉시 닫기
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
                executeSpell(spellCard, handIndex: index)
            }
        }
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

        // 카드 좌표 캡처 (패에서 제거 전)
        let cardFrame = handCardFrames[handIndex]
        let startPos = cardFrame.map { CGPoint(x: $0.midX, y: $0.midY) } ?? playerHandCenter

        // 소환 애니메이션 시작 (패에서는 아직 제거하지 않음 — handIndex로 숨김 처리)
        summonAnimation = SummonAnimation(card: card, targetSlotIndex: slotIndex, isPlayer: true, startPosition: startPos, handIndex: handIndex)
        uiState = .mainPhase

        // 짧은 딜레이 후 애니메이션 트리거 + 실제 배치
        Task {
            // 시작 위치에 렌더 → 바로 애니메이션 트리거
            try? await Task.sleep(for: .milliseconds(50))
            withAnimation(.easeInOut(duration: 0.35)) {
                summonAnimation?.animating = true
            }

            // 애니메이션 완료 대기
            try? await Task.sleep(for: .milliseconds(350))

            // 패에서 제거 (애니메이션 완료 후 자연스럽게)
            withAnimation(.easeInOut(duration: 0.2)) {
                _ = gameState.currentPlayer.hand.remove(at: handIndex)
            }

            // 실제 필드 배치
            summonAnimation = nil

            if case .monster(let monsterCard) = card {
                let success = gameState.currentPlayer.field.summonMonster(monsterCard, at: slotIndex)
                if success {
                    gameState.currentPlayer.summonedThisTurn.insert(slotIndex)
                    addLog("\(monsterCard.name) 소환! (슬롯 \(slotIndex + 1)) [기력 -\(energySpent)]")
                    handleSummonEffect(card: monsterCard, slotIndex: slotIndex, playerIndex: gameState.currentPlayerIndex)
                }
            } else if case .spell(let spellCard) = card {
                let success = gameState.currentPlayer.field.placeSpell(spellCard, at: slotIndex)
                if success {
                    addLog("\(spellCard.name) 배치! (슬롯 \(slotIndex + 1))")
                }
            }
        }
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

        // 필드에서 제거 → 묘지로 이동 (5성 오버라이드 자동 정리 포함)
        gameState.destroyMonster(playerIndex: gameState.currentPlayerIndex, slot: slotIndex)

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
        let playerIdx = gameState.currentPlayerIndex
        let opponentIdx = gameState.opponentIndex

        // 지형 마법: 지형 변경 + 상대 오버라이드 해제
        if spell.spellType == .terrain {
            let prevTerrain = gameState.globalTerrain
            gameState.setSpellTerrain(spell.attribute)
            addLog("\(spell.attribute.emoji) 지형 변경: \(prevTerrain.displayName) → \(spell.attribute.displayName) (2라운드)")

            if gameState.players[opponentIdx].field.fieldOverrideAttribute != nil {
                gameState.players[opponentIdx].field.clearFieldOverride()
                addLog("상대 필드 오버라이드 해제!")
            }
        }

        // 타겟 선택이 필요한 부가효과인지 확인
        let isPlayer = (playerIdx == 0)
        if let targetType = EffectEngine.needsPlayerTargetSelection(spell.effect.actions) {
            let hasTargets: Bool
            if targetType == .selectEnemy {
                hasTargets = !gameState.players[opponentIdx].field.monsterSlotIndices.isEmpty
            } else {
                hasTargets = !gameState.players[playerIdx].field.monsterSlotIndices.isEmpty
            }

            if hasTargets && isPlayer {
                let isAllyTarget = (targetType == .selectAlly)
                uiState = .selectingSpellEffectTarget(spell: spell, isAllyTarget: isAllyTarget)
                addLog("\(spell.attribute.emoji) \(spell.name) 효과! 대상을 선택하세요.")
                return
            }
            // 대상 없거나 AI: 자동 선택으로 진행
        }

        // 데이터 기반 부가효과 실행
        let context = EffectContext(
            playerIndex: playerIdx,
            opponentIndex: opponentIdx,
            slotIndex: 0,
            isPlayer: isPlayer,
            cardAttribute: spell.attribute,
            destroyerSlot: nil
        )
        let results = EffectEngine.resolve(
            actions: spell.effect.actions,
            context: context,
            gameState: &gameState
        )
        for r in results {
            addLog("\(spell.attribute.emoji) \(spell.name) 효과! \(r.message)")
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
                // onDestroy 효과 (파괴 전에 처리)
                await handleDestroyEffect(card: defCard, ownerIndex: aiIndex, destroyerIndex: playerIndex, destroyerSlot: attackerSlot, isPlayerAction: true)
                gameState.destroyMonster(playerIndex: aiIndex, slot: defSlot)
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
                // onDestroy 효과 (파괴 전에 처리)
                await handleDestroyEffect(card: atkCard, ownerIndex: playerIndex, destroyerIndex: aiIndex, destroyerSlot: defSlot, isPlayerAction: true)
                gameState.destroyMonster(playerIndex: playerIndex, slot: attackerSlot)
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

            // onAttack 효과 (공격자)
            await handleAttackEffect(card: atkCard, attackerIndex: playerIndex, defenderIndex: aiIndex, defenderSlot: defSlot, isPlayerAction: true)

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
            let terrain = gameState.currentPlayer.field.fieldOverrideAttribute ?? gameState.globalTerrain
            addLog("\(terrain.emoji) 지형 장악! 보너스 2배!")
        case .breakthrough:
            // 모든 몬스터 +300
            gameState.currentPlayer.momentumBonus += 300
            addLog("전 몬스터 전투력 +300!")
        case .explosion:
            // 상대 필드에서 전투력이 가장 높은 몬스터 1체 제거
            let opIdx = gameState.opponentIndex
            if let targetSlot = gameState.players[opIdx].field.monsterSlotIndices.max(by: { a, b in
                guard case .monster(let ma, _) = gameState.players[opIdx].field.slots[a].content,
                      case .monster(let mb, _) = gameState.players[opIdx].field.slots[b].content else { return false }
                return ma.combatPower < mb.combatPower
            }), case .monster(let m, _) = gameState.players[opIdx].field.slots[targetSlot].content {
                gameState.destroyMonster(playerIndex: opIdx, slot: targetSlot)
                addLog("기세 폭발! \(m.name)(CP \(m.combatPower)) 제거!")
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

            // 필드에서 제거 → 묘지 이동 (5성 오버라이드 자동 정리 포함)
            gameState.destroyMonster(playerIndex: idx, slot: sacrifice.sacrificeSlot)

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

            // 소환 카드 이동 애니메이션
            summonAnimation = SummonAnimation(card: plan.card, targetSlotIndex: slotIdx, isPlayer: false, startPosition: aiHandCenter, handIndex: nil)
            try? await Task.sleep(for: .milliseconds(50))
            withAnimation(.easeInOut(duration: 0.35)) {
                summonAnimation?.animating = true
            }
            try? await Task.sleep(for: .milliseconds(350))
            summonAnimation = nil

            // 소환 배너
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

                // 소환 효과 (데이터 기반)
                if m.effect != nil && m.effect!.timing == .onSummon && !m.effect!.actions.isEmpty {
                    let is5Star = m.cost == 5
                    if is5Star { try? await Task.sleep(for: .seconds(0.5)) }
                    handleSummonEffect(card: m, slotIndex: slotIdx, playerIndex: idx)
                    if is5Star {
                        try? await Task.sleep(for: .seconds(2.2))
                        continue
                    } else {
                        try? await Task.sleep(for: .seconds(0.8))
                    }
                }
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
                        // onDestroy 효과 (파괴 전에 처리)
                        await handleDestroyEffect(card: defCard, ownerIndex: defIdx, destroyerIndex: idx, destroyerSlot: plan.attackerSlot, isPlayerAction: false)
                        gameState.destroyMonster(playerIndex: defIdx, slot: defSlot)
                        gameState.players[idx].gainMomentum(1)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            battleDisplay = BattleDisplay(message: "\(defCard.name) 파괴!")
                        }
                        addLog("  → \(defCard.name) 파괴!")
                        try? await Task.sleep(for: .seconds(0.9))
                    }
                    if result.attackerDestroyed {
                        // onDestroy 효과 (파괴 전에 처리)
                        await handleDestroyEffect(card: atkCard, ownerIndex: idx, destroyerIndex: defIdx, destroyerSlot: defSlot, isPlayerAction: false)
                        gameState.destroyMonster(playerIndex: idx, slot: plan.attackerSlot)
                        gameState.players[defIdx].gainMomentum(1)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            battleDisplay = BattleDisplay(message: "\(atkCard.name) 파괴!")
                        }
                        addLog("  → \(atkCard.name) 파괴!")
                        try? await Task.sleep(for: .seconds(0.9))
                    }

                    // onAttack 효과 (공격자)
                    await handleAttackEffect(card: atkCard, attackerIndex: idx, defenderIndex: defIdx, defenderSlot: defSlot, isPlayerAction: false)
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
            let terrain = gameState.players[idx].field.fieldOverrideAttribute ?? gameState.globalTerrain
            gameState.players[idx].momentumBonus += PlayerField.globalTerrainBonus
            addLog("\(terrain.emoji) 지형 장악! 보너스 2배!")
        case .breakthrough:
            gameState.players[idx].momentumBonus += 300
            addLog("전 몬스터 전투력 +300!")
        case .explosion:
            // 상대 필드에서 전투력이 가장 높은 몬스터 1체 제거
            let opIdx = 1 - idx
            if let targetSlot = gameState.players[opIdx].field.monsterSlotIndices.max(by: { a, b in
                guard case .monster(let ma, _) = gameState.players[opIdx].field.slots[a].content,
                      case .monster(let mb, _) = gameState.players[opIdx].field.slots[b].content else { return false }
                return ma.combatPower < mb.combatPower
            }), case .monster(let m, _) = gameState.players[opIdx].field.slots[targetSlot].content {
                gameState.destroyMonster(playerIndex: opIdx, slot: targetSlot)
                addLog("기세 폭발! \(m.name)(CP \(m.combatPower)) 제거!")
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

    // MARK: - 데이터 기반 효과 시스템

    /// 5성 속성 → SummonEffectType 매핑
    private func summonEffectType(for attribute: Attribute) -> SummonEffectType {
        switch attribute {
        case .fire:    return .lavaEruption
        case .water:   return .tidalWave
        case .wind:    return .typhoonStorm
        case .earth:   return .earthquake
        case .thunder: return .thunderStrike
        case .dark:    return .darkVoid
        case .light:   return .holyRadiance
        }
    }

    /// 소환 효과 통합 처리 (4성/5성/3성 이하 모두)
    private func handleSummonEffect(card: MonsterCard, slotIndex: Int, playerIndex: Int) {
        guard let effect = card.effect, effect.timing == .onSummon, !effect.actions.isEmpty else { return }

        let opponentIdx = 1 - playerIndex
        let isPlayer = (playerIndex == 0)

        // 타겟 선택이 필요한 효과인지 확인
        if let targetType = EffectEngine.needsPlayerTargetSelection(effect.actions) {
            // 타겟이 존재하는지 확인
            let hasTargets: Bool
            if targetType == .selectEnemy {
                hasTargets = !gameState.players[opponentIdx].field.monsterSlotIndices.isEmpty
            } else {
                hasTargets = !gameState.players[playerIndex].field.monsterSlotIndices.isEmpty
            }

            if !hasTargets {
                addLog("\(card.attribute.emoji) \(card.name) 효과: 대상이 없어 효과 무시")
                return
            }

            if isPlayer {
                let isAllyTarget = (targetType == .selectAlly)
                uiState = .selectingEffectTarget(card: card, slotIndex: slotIndex, isAllyTarget: isAllyTarget)
                addLog("\(card.attribute.emoji) \(card.name) 효과! 대상을 선택하세요.")
                return
            }
            // AI: 자동 선택으로 진행 (EffectEngine이 처리)
        }

        // 효과 실행
        let context = EffectContext(
            playerIndex: playerIndex,
            opponentIndex: opponentIdx,
            slotIndex: slotIndex,
            isPlayer: isPlayer,
            cardAttribute: card.attribute,
            destroyerSlot: nil
        )
        let results = EffectEngine.resolve(
            actions: effect.actions,
            context: context,
            gameState: &gameState
        )

        // 결과 로그
        for r in results {
            addLog("\(card.attribute.emoji) \(card.name) 효과! \(r.message)")
        }

        // 5성: 풀스크린 이펙트 연출
        if card.cost == 5 {
            let effectType = summonEffectType(for: card.attribute)
            let effectMessage = results.map { $0.message }.joined(separator: " ")
            withAnimation(.easeInOut(duration: 0.3)) {
                battleDisplay = BattleDisplay(
                    message: "\(card.name): \(effectMessage)",
                    showLPFlash: true,
                    isPlayerAction: isPlayer,
                    summonEffect: effectType
                )
            }

            // LP 0 체크
            if gameState.players[opponentIdx].lp <= 0 {
                gameState.players[opponentIdx].lp = 0
                endGame(winnerIndex: playerIndex)
            }

            // 2초 후 연출 클리어
            Task {
                try? await Task.sleep(for: .seconds(2.0))
                withAnimation(.easeOut(duration: 0.3)) {
                    if battleDisplay?.summonEffect != nil {
                        battleDisplay = nil
                    }
                }
            }
        } else {
            // 4성 이하: 간단한 배너
            if let firstResult = results.first {
                withAnimation(.easeInOut(duration: 0.3)) {
                    battleDisplay = BattleDisplay(
                        message: firstResult.message,
                        highlightedSlot: firstResult.highlightedSlot,
                        isPlayerAction: isPlayer
                    )
                }
            }

            // 배너 자동 클리어
            Task {
                try? await Task.sleep(for: .seconds(1.0))
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.3)) {
                        if battleDisplay?.summonEffect == nil {
                            battleDisplay = nil
                        }
                    }
                }
            }
        }
    }

    /// 타겟 선택 효과 완료 (데이터 기반)
    func applyFourStarEffectOnTarget(targetSlot: Int) {
        guard case .selectingEffectTarget(let card, let slotIndex, _) = uiState else { return }
        guard let effect = card.effect else { return }

        let playerIndex = gameState.currentPlayerIndex
        let opponentIdx = 1 - playerIndex

        let context = EffectContext(
            playerIndex: playerIndex,
            opponentIndex: opponentIdx,
            slotIndex: slotIndex,
            isPlayer: true,
            cardAttribute: card.attribute,
            destroyerSlot: nil
        )
        let results = EffectEngine.resolve(
            actions: effect.actions,
            context: context,
            gameState: &gameState,
            selectedTargetSlot: targetSlot
        )

        for r in results {
            addLog("\(card.attribute.emoji) \(card.name) 효과! \(r.message)")
        }

        if let firstResult = results.first {
            withAnimation(.easeInOut(duration: 0.3)) {
                battleDisplay = BattleDisplay(
                    message: firstResult.message,
                    isPlayerAction: true
                )
            }
        }

        uiState = .mainPhase

        // 배너 자동 클리어
        Task {
            try? await Task.sleep(for: .seconds(1.0))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    battleDisplay = nil
                }
            }
        }
    }

    /// 마법 카드 타겟 선택 효과 완료
    func applySpellEffectOnTarget(targetSlot: Int) {
        guard case .selectingSpellEffectTarget(let spell, _) = uiState else { return }

        let playerIndex = gameState.currentPlayerIndex
        let opponentIdx = 1 - playerIndex

        let context = EffectContext(
            playerIndex: playerIndex,
            opponentIndex: opponentIdx,
            slotIndex: 0,
            isPlayer: true,
            cardAttribute: spell.attribute,
            destroyerSlot: nil
        )
        let results = EffectEngine.resolve(
            actions: spell.effect.actions,
            context: context,
            gameState: &gameState,
            selectedTargetSlot: targetSlot
        )

        for r in results {
            addLog("\(spell.attribute.emoji) \(spell.name) 효과! \(r.message)")
        }

        if let firstResult = results.first {
            withAnimation(.easeInOut(duration: 0.3)) {
                battleDisplay = BattleDisplay(
                    message: firstResult.message,
                    isPlayerAction: true
                )
            }
        }

        uiState = .mainPhase

        // 배너 자동 클리어
        Task {
            try? await Task.sleep(for: .seconds(1.0))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    battleDisplay = nil
                }
            }
        }
    }

    /// 파괴 시 효과 처리 (onDestroy, 데이터 기반)
    private func handleDestroyEffect(card: MonsterCard, ownerIndex: Int, destroyerIndex: Int, destroyerSlot: Int, isPlayerAction: Bool) async {
        guard let effect = card.effect, effect.timing == .onDestroy, !effect.actions.isEmpty else { return }

        let context = EffectContext(
            playerIndex: ownerIndex,
            opponentIndex: destroyerIndex,
            slotIndex: 0,
            isPlayer: ownerIndex == 0,
            cardAttribute: card.attribute,
            destroyerSlot: destroyerSlot
        )
        let results = EffectEngine.resolve(
            actions: effect.actions,
            context: context,
            gameState: &gameState
        )

        for r in results {
            addLog("\(card.attribute.emoji) \(card.name) 효과! \(r.message)")
            withAnimation(.easeInOut(duration: 0.3)) {
                battleDisplay = BattleDisplay(
                    message: r.message,
                    isPlayerAction: isPlayerAction
                )
            }
            try? await Task.sleep(for: .seconds(0.4))
        }
    }

    /// 공격 시 효과 처리 (onAttack, 데이터 기반)
    private func handleAttackEffect(card: MonsterCard, attackerIndex: Int, defenderIndex: Int, defenderSlot: Int, isPlayerAction: Bool) async {
        guard let effect = card.effect, effect.timing == .onAttack, !effect.actions.isEmpty else { return }

        let context = EffectContext(
            playerIndex: attackerIndex,
            opponentIndex: defenderIndex,
            slotIndex: 0,
            isPlayer: attackerIndex == 0,
            cardAttribute: card.attribute,
            destroyerSlot: defenderSlot  // onAttack에서 destroyer = 공격 대상
        )
        let results = EffectEngine.resolve(
            actions: effect.actions,
            context: context,
            gameState: &gameState
        )

        for r in results {
            addLog("\(card.attribute.emoji) \(card.name) 효과! \(r.message)")
            withAnimation(.easeInOut(duration: 0.3)) {
                battleDisplay = BattleDisplay(
                    message: r.message,
                    isPlayerAction: isPlayerAction
                )
            }
            try? await Task.sleep(for: .seconds(0.4))
        }
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
            firstPlayerIndex: Int.random(in: 0...1)
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

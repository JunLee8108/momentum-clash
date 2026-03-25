import Foundation

/// 효과 실행 컨텍스트
struct EffectContext {
    let playerIndex: Int
    let opponentIndex: Int
    let slotIndex: Int
    let isPlayer: Bool          // true면 플레이어, false면 AI
    let cardAttribute: Attribute
    let destroyerSlot: Int?     // onDestroy 시 자신을 파괴한 몬스터의 슬롯
}

/// 효과 실행 결과 (로그/연출용)
struct EffectResult {
    let message: String
    let emoji: String
    let showLPFlash: Bool
    let highlightedSlot: Int?
    let isPlayerAction: Bool
}

/// 데이터 기반 효과 해석/실행 엔진
struct EffectEngine {

    /// 플레이어가 타겟을 선택해야 하는 효과가 있는지 확인
    /// - Returns: 선택이 필요한 타겟 타입 (selectAlly / selectEnemy), 없으면 nil
    static func needsPlayerTargetSelection(_ actions: [EffectActionEntry]) -> EffectTarget? {
        for entry in actions {
            if entry.target == .selectAlly || entry.target == .selectEnemy {
                return entry.target
            }
        }
        return nil
    }

    /// 효과 실행
    /// - Parameters:
    ///   - actions: 실행할 효과 액션 목록
    ///   - context: 효과 발동 컨텍스트
    ///   - gameState: 게임 상태 (inout)
    ///   - selectedTargetSlot: 플레이어가 선택한 타겟 슬롯 (타겟 선택 효과용)
    /// - Returns: 효과 결과 목록 (로그/연출용)
    static func resolve(
        actions: [EffectActionEntry],
        context: EffectContext,
        gameState: inout GameState,
        selectedTargetSlot: Int? = nil
    ) -> [EffectResult] {
        var results: [EffectResult] = []

        for entry in actions {
            let result = resolveEntry(
                entry,
                context: context,
                gameState: &gameState,
                selectedTargetSlot: selectedTargetSlot
            )
            if let r = result {
                results.append(r)
            }
        }

        return results
    }

    // MARK: - Private

    private static func resolveEntry(
        _ entry: EffectActionEntry,
        context: EffectContext,
        gameState: inout GameState,
        selectedTargetSlot: Int?
    ) -> EffectResult? {
        switch entry.action {

        case .healLP(let amount):
            let idx = playerIndexForTarget(entry.target, context: context)
            gameState.players[idx].lp = min(TurnSystem.startingLP, gameState.players[idx].lp + amount)
            return EffectResult(
                message: "LP \(amount) 회복!",
                emoji: "💚",
                showLPFlash: true,
                highlightedSlot: nil,
                isPlayerAction: context.isPlayer
            )

        case .damageLP(let amount):
            let idx = playerIndexForTarget(entry.target, context: context)
            gameState.players[idx].lp -= amount
            if gameState.players[idx].lp < 0 { gameState.players[idx].lp = 0 }
            return EffectResult(
                message: "LP \(amount) 데미지!",
                emoji: "💥",
                showLPFlash: true,
                highlightedSlot: nil,
                isPlayerAction: context.isPlayer
            )

        case .applyShield(let amount):
            let slots = resolveTargetSlots(entry.target, context: context, gameState: gameState, selectedTargetSlot: selectedTargetSlot)
            let targetPlayerIdx = targetPlayerIndex(entry.target, context: context)
            for slot in slots {
                gameState.players[targetPlayerIdx].field.applyShield(amount, at: slot)
            }
            let slotDesc = slots.count == 1 ? "방어막 \(amount) 부여!" : "전체 방어막 \(amount) 부여!"
            return EffectResult(
                message: slotDesc,
                emoji: "🛡️",
                showLPFlash: false,
                highlightedSlot: slots.first,
                isPlayerAction: context.isPlayer
            )

        case .cpDebuff(let amount):
            let slots = resolveTargetSlots(entry.target, context: context, gameState: gameState, selectedTargetSlot: selectedTargetSlot)
            let targetPlayerIdx = targetPlayerIndex(entry.target, context: context)
            var targetName = ""
            for slot in slots {
                gameState.players[targetPlayerIdx].field.applySlotCpDebuff(amount, at: slot)
                if case .monster(let m, _) = gameState.players[targetPlayerIdx].field.slots[slot].content {
                    targetName = m.name
                }
            }
            let desc = slots.count == 1 ? "\(targetName) 전투력 \(amount)!" : "전체 전투력 \(amount)!"
            return EffectResult(
                message: desc,
                emoji: "⬇️",
                showLPFlash: false,
                highlightedSlot: slots.first,
                isPlayerAction: context.isPlayer
            )

        case .cpBuff(let amount):
            let slots = resolveTargetSlots(entry.target, context: context, gameState: gameState, selectedTargetSlot: selectedTargetSlot)
            let targetPlayerIdx = targetPlayerIndex(entry.target, context: context)
            // cpBuff는 슬롯별 디버프의 역순으로 적용 (양수값)
            for slot in slots {
                gameState.players[targetPlayerIdx].field.applySlotCpDebuff(amount, at: slot)
            }
            return EffectResult(
                message: "전투력 +\(amount)!",
                emoji: "⬆️",
                showLPFlash: false,
                highlightedSlot: nil,
                isPlayerAction: context.isPlayer
            )

        case .drawCards(let count):
            let idx = playerIndexForTarget(entry.target, context: context)
            var drawnNames: [String] = []
            for _ in 0..<count {
                guard !gameState.players[idx].deck.isEmpty else { break }
                let drawn = gameState.players[idx].deck.removeFirst()
                gameState.players[idx].hand.append(drawn)
                drawnNames.append(drawn.name)
            }
            guard !drawnNames.isEmpty else { return nil }
            return EffectResult(
                message: "\(drawnNames.joined(separator: ", ")) 드로우!",
                emoji: "📖",
                showLPFlash: false,
                highlightedSlot: nil,
                isPlayerAction: context.isPlayer
            )

        case .gainMomentum(let amount):
            let idx = playerIndexForTarget(entry.target, context: context)
            gameState.players[idx].gainMomentum(amount)
            return EffectResult(
                message: "기세 +\(amount)!",
                emoji: "🔥",
                showLPFlash: false,
                highlightedSlot: nil,
                isPlayerAction: context.isPlayer
            )

        case .loseMomentum(let amount):
            let idx = playerIndexForTarget(entry.target, context: context)
            gameState.players[idx].loseMomentum(amount)
            return EffectResult(
                message: "기세 -\(amount)!",
                emoji: "💨",
                showLPFlash: false,
                highlightedSlot: nil,
                isPlayerAction: context.isPlayer
            )

        case .fieldOverride:
            // 5성 전용: 카드 속성으로 필드 오버라이드
            gameState.players[context.playerIndex].field.setFieldOverride(
                attribute: context.cardAttribute,
                sourceSlot: context.slotIndex
            )
            return EffectResult(
                message: "필드 오버라이드! \(context.cardAttribute.displayName) (2턴)",
                emoji: context.cardAttribute.emoji,
                showLPFlash: false,
                highlightedSlot: nil,
                isPlayerAction: context.isPlayer
            )

        case .fieldCpDebuff(let amount):
            // 필드 전체 CP 디버프 (오버라이드와 수명 공유)
            let targetPlayerIdx = playerIndexForTarget(entry.target, context: context)
            gameState.players[targetPlayerIdx].field.cpDebuff = amount
            return EffectResult(
                message: "전체 전투력 \(amount)!",
                emoji: "⬇️",
                showLPFlash: false,
                highlightedSlot: nil,
                isPlayerAction: context.isPlayer
            )

        case .removeAllShields:
            let targetPlayerIdx = targetPlayerIndex(entry.target, context: context)
            for i in gameState.players[targetPlayerIdx].field.monsterSlotIndices {
                if case .monster(let m, let shield) = gameState.players[targetPlayerIdx].field.slots[i].content, shield > 0 {
                    gameState.players[targetPlayerIdx].field.slots[i].content = .monster(m, shield: 0)
                }
            }
            return EffectResult(
                message: "전체 방어막 제거!",
                emoji: "💔",
                showLPFlash: false,
                highlightedSlot: nil,
                isPlayerAction: context.isPlayer
            )

        case .destroyIfCPBelow(let threshold):
            let targetPlayerIdx = targetPlayerIndex(entry.target, context: context)
            let slots = resolveTargetSlots(entry.target, context: context, gameState: gameState, selectedTargetSlot: selectedTargetSlot)
            var destroyed: [String] = []
            // 역순으로 파괴 (인덱스 이동 방지)
            for slot in slots.sorted(by: >) {
                if case .monster(let m, _) = gameState.players[targetPlayerIdx].field.slots[slot].content {
                    if m.combatPower <= threshold {
                        gameState.destroyMonster(playerIndex: targetPlayerIdx, slot: slot)
                        destroyed.append(m.name)
                    }
                }
            }
            if destroyed.isEmpty {
                return EffectResult(
                    message: "전체에 \(threshold) 데미지!",
                    emoji: "💥",
                    showLPFlash: false,
                    highlightedSlot: nil,
                    isPlayerAction: context.isPlayer
                )
            }
            return EffectResult(
                message: "\(destroyed.joined(separator: ", ")) 파괴!",
                emoji: "💥",
                showLPFlash: false,
                highlightedSlot: nil,
                isPlayerAction: context.isPlayer
            )

        case .momentumBonus(let amount):
            let idx = playerIndexForTarget(entry.target, context: context)
            gameState.players[idx].momentumBonus += amount
            return EffectResult(
                message: "이번 턴 전투력 +\(amount)!",
                emoji: "⚡",
                showLPFlash: false,
                highlightedSlot: nil,
                isPlayerAction: context.isPlayer
            )
        }
    }

    // MARK: - 타겟 해석 헬퍼

    /// LP/기세 등 플레이어 단위 효과의 대상 인덱스
    private static func playerIndexForTarget(_ target: EffectTarget, context: EffectContext) -> Int {
        switch target {
        case .player, .selfSlot, .allAllies, .selectAlly:
            return context.playerIndex
        case .opponent, .allEnemies, .selectEnemy, .strongestEnemy, .destroyer:
            return context.opponentIndex
        }
    }

    /// 몬스터 슬롯 단위 효과의 대상 플레이어 인덱스
    private static func targetPlayerIndex(_ target: EffectTarget, context: EffectContext) -> Int {
        switch target {
        case .selfSlot, .allAllies, .selectAlly:
            return context.playerIndex
        case .allEnemies, .selectEnemy, .strongestEnemy:
            return context.opponentIndex
        case .destroyer:
            // 자신을 파괴한 몬스터는 상대편
            return context.opponentIndex
        case .player, .opponent:
            // 플레이어 단위이지만 슬롯 컨텍스트에서 호출될 수 있음
            return target == .player ? context.playerIndex : context.opponentIndex
        }
    }

    /// 대상 슬롯 인덱스 목록 해석
    private static func resolveTargetSlots(
        _ target: EffectTarget,
        context: EffectContext,
        gameState: GameState,
        selectedTargetSlot: Int?
    ) -> [Int] {
        switch target {
        case .selfSlot:
            return [context.slotIndex]

        case .allAllies:
            return gameState.players[context.playerIndex].field.monsterSlotIndices

        case .selectAlly:
            if let selected = selectedTargetSlot {
                return [selected]
            }
            // AI: 가장 전투력 높은 아군
            return autoSelectStrongest(
                playerIndex: context.playerIndex,
                gameState: gameState
            ).map { [$0] } ?? []

        case .selectEnemy:
            if let selected = selectedTargetSlot {
                return [selected]
            }
            // AI: 가장 전투력 높은 적
            return autoSelectStrongest(
                playerIndex: context.opponentIndex,
                gameState: gameState
            ).map { [$0] } ?? []

        case .strongestEnemy:
            return autoSelectStrongest(
                playerIndex: context.opponentIndex,
                gameState: gameState
            ).map { [$0] } ?? []

        case .allEnemies:
            return gameState.players[context.opponentIndex].field.monsterSlotIndices

        case .destroyer:
            if let destroyerSlot = context.destroyerSlot {
                return [destroyerSlot]
            }
            return []

        case .player, .opponent:
            return []
        }
    }

    /// 가장 전투력 높은 몬스터 슬롯 자동 선택
    private static func autoSelectStrongest(playerIndex: Int, gameState: GameState) -> Int? {
        let slots = gameState.players[playerIndex].field.monsterSlotIndices
        return slots.max(by: { a, b in
            guard case .monster(let ma, _) = gameState.players[playerIndex].field.slots[a].content,
                  case .monster(let mb, _) = gameState.players[playerIndex].field.slots[b].content
            else { return false }
            return ma.combatPower < mb.combatPower
        })
    }
}

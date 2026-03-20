import Foundation

/// AI가 수행할 개별 액션
enum AIAction {
    case draw(card: AnyCard)
    case summon(card: AnyCard, slotIndex: Int)
    case attack(attackerSlot: Int, defenderSlot: Int, attackerName: String, defenderName: String)
    case directAttack(attackerSlot: Int, attackerName: String, damage: Int)
    case cardDestroyed(cardName: String, ownerIsAI: Bool)
    case lpDamage(targetName: String, amount: Int)
}

/// 규칙 기반 기본 AI
struct BasicAI {

    // MARK: - 드로우 선택

    func chooseDrawCard(choice1: AnyCard, choice2: AnyCard) -> AnyCard {
        // 몬스터 우선, 같으면 비용 높은 쪽
        let score1 = evaluateCard(choice1)
        let score2 = evaluateCard(choice2)
        return score1 >= score2 ? choice1 : choice2
    }

    private func evaluateCard(_ card: AnyCard) -> Int {
        switch card {
        case .monster(let m):
            return m.combatPower + (m.isVanilla ? 100 : 200)
        case .spell(let s):
            return s.cost * 300
        }
    }

    // MARK: - 메인 페이즈

    func performMainPhase(gameState: inout GameState) {
        let idx = gameState.currentPlayerIndex

        // 소환 가능한 카드를 비용 효율 순으로 소환
        var keepGoing = true
        while keepGoing {
            keepGoing = false

            let hand = gameState.players[idx].hand
            let totalResource = gameState.players[idx].energy + gameState.players[idx].momentum

            // 소환할 카드 찾기 (몬스터 우선, 마법은 유용성 판단)
            let summonCandidates = hand.enumerated().compactMap { (i, card) -> (index: Int, card: AnyCard, priority: Int)? in
                guard card.cost <= totalResource else { return nil }

                switch card {
                case .monster(let m):
                    guard !gameState.players[idx].field.emptySlotIndices.isEmpty else { return nil }
                    return (i, card, m.combatPower + 1000)  // 몬스터 우선
                case .spell(let s):
                    guard shouldPlaySpell(s, gameState: gameState) else { return nil }
                    if s.spellType == .continuous {
                        guard !gameState.players[idx].field.emptySlotIndices.isEmpty else { return nil }
                    }
                    return (i, card, s.cost * 100)
                }
            }.sorted { $0.priority > $1.priority }

            if let best = summonCandidates.first {
                guard TurnSystem.payCost(
                    cost: best.card.cost,
                    player: &gameState.players[idx]
                ) != nil else { continue }

                // 패에서 제거
                gameState.players[idx].hand.remove(at: best.index)

                switch best.card {
                case .monster(let m):
                    if let slot = gameState.players[idx].field.emptySlotIndices.first {
                        _ = gameState.players[idx].field.summonMonster(m, at: slot)
                    }
                case .spell(let s):
                    if s.spellType == .continuous {
                        if let slot = gameState.players[idx].field.emptySlotIndices.first {
                            _ = gameState.players[idx].field.placeSpell(s, at: slot)
                        }
                    } else {
                        // 즉시 마법은 묘지로
                        gameState.players[idx].graveyard.append(.spell(s))
                    }
                }

                keepGoing = true // 추가 소환 시도
            }
        }
    }

    // MARK: - 배틀 페이즈

    func performBattlePhase(gameState: inout GameState) -> [String] {
        var logs: [String] = []
        let atkIdx = gameState.currentPlayerIndex
        let defIdx = 1 - atkIdx

        let attackerSlots = gameState.players[atkIdx].field.monsterSlotIndices

        for atkSlot in attackerSlots {
            guard case .monster(let atkCard, _) = gameState.players[atkIdx].field.slots[atkSlot].content
            else { continue }

            // 방어 몬스터가 없으면 직접 공격
            let currentDefSlots = gameState.players[defIdx].field.monsterSlotIndices
            if currentDefSlots.isEmpty {
                let damage = BattleEngine.resolveDirectAttack(
                    attackerCard: atkCard,
                    attackerSlot: atkSlot,
                    attackerField: gameState.players[atkIdx].field,
                    momentumBonus: 0
                )
                gameState.players[defIdx].takeDamage(damage)
                gameState.players[atkIdx].gainMomentum(2)
                gameState.players[atkIdx].didAttackThisTurn = true
                logs.append("\(atkCard.name)이(가) 직접 공격! \(damage) LP 데미지!")

                if gameState.players[defIdx].isDefeated { break }
                continue
            }

            // 유리한 상대 찾기
            let bestTarget = chooseBestTarget(
                attacker: atkCard,
                attackerSlot: atkSlot,
                attackerField: gameState.players[atkIdx].field,
                defenderSlots: currentDefSlots,
                defenderField: gameState.players[defIdx].field
            )

            guard let targetSlot = bestTarget else { continue }
            guard case .monster(let defCard, let shield) = gameState.players[defIdx].field.slots[targetSlot].content
            else { continue }

            let result = BattleEngine.resolveCombat(
                attackerCard: atkCard,
                attackerSlot: atkSlot,
                attackerField: gameState.players[atkIdx].field,
                defenderCard: defCard,
                defenderSlot: targetSlot,
                defenderField: gameState.players[defIdx].field,
                attackerMomentumBonus: 0,
                defenderMomentumBonus: 0,
                defenderShield: shield
            )

            logs.append("\(atkCard.name)(CP:\(atkCard.combatPower)) → \(defCard.name)(CP:\(defCard.combatPower))")
            gameState.players[atkIdx].gainMomentum(1)
            gameState.players[atkIdx].didAttackThisTurn = true

            if result.defenderDestroyed {
                gameState.players[defIdx].field.removeCard(at: targetSlot)
                gameState.players[defIdx].graveyard.append(.monster(defCard))
                gameState.players[atkIdx].gainMomentum(1)
                logs.append("  → \(defCard.name) 파괴!")
            }
            if result.attackerDestroyed {
                gameState.players[atkIdx].field.removeCard(at: atkSlot)
                gameState.players[atkIdx].graveyard.append(.monster(atkCard))
                gameState.players[defIdx].gainMomentum(1)
                logs.append("  → \(atkCard.name) 파괴!")
            }
            if result.lpDamageToDefender > 0 {
                gameState.players[defIdx].takeDamage(result.lpDamageToDefender)
                logs.append("  → \(gameState.players[defIdx].name)에게 \(result.lpDamageToDefender) LP 데미지!")
            }
            if result.lpDamageToAttacker > 0 {
                gameState.players[atkIdx].takeDamage(result.lpDamageToAttacker)
                logs.append("  → \(gameState.players[atkIdx].name)에게 \(result.lpDamageToAttacker) LP 데미지!")
            }

            if gameState.players[defIdx].isDefeated { break }
        }

        return logs
    }

    // MARK: - 액션 계획 (애니메이션용)

    /// 메인 페이즈에서 AI가 할 소환 액션들을 계획만 하고 반환
    func planMainPhase(gameState: GameState) -> [(card: AnyCard, handIndex: Int, slotIndex: Int)] {
        var plans: [(card: AnyCard, handIndex: Int, slotIndex: Int)] = []
        var simulatedHand = gameState.players[gameState.currentPlayerIndex].hand
        var simulatedEnergy = gameState.players[gameState.currentPlayerIndex].energy
        var simulatedMomentum = gameState.players[gameState.currentPlayerIndex].momentum
        var occupiedSlots = Set<Int>()
        for i in 0..<PlayerField.slotCount {
            if gameState.players[gameState.currentPlayerIndex].field.slots[i].content.isOccupied {
                occupiedSlots.insert(i)
            }
        }

        var keepGoing = true
        while keepGoing {
            keepGoing = false
            let totalResource = simulatedEnergy + simulatedMomentum

            let candidates = simulatedHand.enumerated().compactMap { (i, card) -> (index: Int, card: AnyCard, priority: Int)? in
                guard card.cost <= totalResource else { return nil }
                switch card {
                case .monster:
                    let hasEmpty = (0..<PlayerField.slotCount).contains { !occupiedSlots.contains($0) }
                    guard hasEmpty else { return nil }
                    return (i, card, card.cost * 200)  // 몬스터 우선
                case .spell(let s):
                    // 마법 유용성 판단
                    guard shouldPlaySpell(s, gameState: gameState) else { return nil }
                    if s.spellType == .continuous {
                        let hasEmpty = (0..<PlayerField.slotCount).contains { !occupiedSlots.contains($0) }
                        guard hasEmpty else { return nil }
                    }
                    return (i, card, s.cost * 100)  // 마법은 몬스터 후순위
                }
            }.sorted { $0.priority > $1.priority }

            if let best = candidates.first {
                let cost = best.card.cost
                let energySpent = min(simulatedEnergy, cost)
                let momentumSpent = cost - energySpent
                simulatedEnergy -= energySpent
                simulatedMomentum -= momentumSpent

                simulatedHand.remove(at: best.index)

                let slotIndex: Int
                switch best.card {
                case .monster, .spell:
                    slotIndex = (0..<PlayerField.slotCount).first { !occupiedSlots.contains($0) } ?? 0
                    occupiedSlots.insert(slotIndex)
                }

                plans.append((card: best.card, handIndex: best.index, slotIndex: slotIndex))
                keepGoing = true
            }
        }
        return plans
    }

    /// 배틀 페이즈에서 AI가 할 공격 액션들을 계획만 하고 반환
    func planBattlePhase(gameState: GameState) -> [(attackerSlot: Int, defenderSlot: Int?)] {
        var plans: [(attackerSlot: Int, defenderSlot: Int?)] = []
        let atkIdx = gameState.currentPlayerIndex
        let defIdx = 1 - atkIdx

        let attackerSlots = gameState.players[atkIdx].field.monsterSlotIndices

        // 파괴 시뮬레이션용: 살아있는 적 슬롯 추적
        var aliveDefSlots = Set(gameState.players[defIdx].field.monsterSlotIndices)

        for atkSlot in attackerSlots {
            guard case .monster(let atkCard, _) = gameState.players[atkIdx].field.slots[atkSlot].content
            else { continue }

            // 적 몬스터가 모두 파괴됐으면 직접 공격
            if aliveDefSlots.isEmpty {
                plans.append((attackerSlot: atkSlot, defenderSlot: nil))
                continue
            }

            let bestTarget = chooseBestTarget(
                attacker: atkCard,
                attackerSlot: atkSlot,
                attackerField: gameState.players[atkIdx].field,
                defenderSlots: Array(aliveDefSlots),
                defenderField: gameState.players[defIdx].field
            )

            if let target = bestTarget {
                plans.append((attackerSlot: atkSlot, defenderSlot: target))

                // 시뮬레이션: 이 공격으로 적이 파괴되는지 예측
                if case .monster(let defCard, let shield) = gameState.players[defIdx].field.slots[target].content {
                    let result = BattleEngine.resolveCombat(
                        attackerCard: atkCard,
                        attackerSlot: atkSlot,
                        attackerField: gameState.players[atkIdx].field,
                        defenderCard: defCard,
                        defenderSlot: target,
                        defenderField: gameState.players[defIdx].field,
                        attackerMomentumBonus: 0,
                        defenderMomentumBonus: 0,
                        defenderShield: shield
                    )
                    if result.defenderDestroyed {
                        aliveDefSlots.remove(target)
                    }
                }
            }
        }
        return plans
    }

    // MARK: - 마법 유용성 판단

    /// 현재 게임 상태에서 이 마법을 사용할 가치가 있는지 판단
    private func shouldPlaySpell(_ spell: SpellCard, gameState: GameState) -> Bool {
        let idx = gameState.currentPlayerIndex
        let opponentIdx = 1 - idx
        let myField = gameState.players[idx].field
        let opponentField = gameState.players[opponentIdx].field
        let myMonsterCount = myField.monsterCount
        let opponentMonsterCount = opponentField.monsterCount
        let desc = spell.effect.description

        switch spell.spellType {
        case .equipment:
            // 장착 대상 몬스터가 필요
            return myMonsterCount > 0

        case .continuous:
            // 지속 마법: 관련 속성 몬스터가 필드나 핸드에 있어야 의미 있음
            let hasRelevantMonster = myField.monsterSlotIndices.contains { i in
                if case .monster(let m, _) = myField.slots[i].content {
                    return m.attribute == spell.attribute
                }
                return false
            }
            let hasRelevantInHand = gameState.players[idx].hand.contains { card in
                if case .monster(let m) = card { return m.attribute == spell.attribute }
                return false
            }
            return hasRelevantMonster || hasRelevantInHand

        case .terrain:
            // 지형 마법: 관련 속성 몬스터가 있어야 지형 보너스 활용 가능
            let hasRelevantMonster = myField.monsterSlotIndices.contains { i in
                if case .monster(let m, _) = myField.slots[i].content {
                    return m.attribute == spell.attribute
                }
                return false
            }
            let hasRelevantInHand = gameState.players[idx].hand.contains { card in
                if case .monster(let m) = card { return m.attribute == spell.attribute }
                return false
            }
            return hasRelevantMonster || hasRelevantInHand

        case .normal:
            // 키워드 기반 판단
            if desc.contains("방어막") || desc.contains("장착") {
                return myMonsterCount > 0
            }
            if desc.contains("상대") && (desc.contains("데미지") || desc.contains("파괴")) {
                return opponentMonsterCount > 0
            }
            if desc.contains("회복") {
                // LP가 70% 미만일 때만
                return gameState.players[idx].lp < Int(Double(TurnSystem.startingLP) * 0.7)
            }
            // 그 외 일반 마법은 허용
            return true
        }
    }

    // MARK: - 타겟 선택

    private func chooseBestTarget(
        attacker: MonsterCard,
        attackerSlot: Int,
        attackerField: PlayerField,
        defenderSlots: [Int],
        defenderField: PlayerField
    ) -> Int? {
        struct TargetInfo {
            let slot: Int
            let atkCP: Int
            let defCP: Int
        }

        var targets: [TargetInfo] = []

        for defSlot in defenderSlots {
            guard case .monster(let defCard, _) = defenderField.slots[defSlot].content else { continue }

            let effectiveAtkCP = BattleEngine.calculateEffectiveCP(
                card: attacker,
                slotIndex: attackerSlot,
                field: attackerField,
                opponentAttribute: defCard.attribute,
                momentumBonus: 0
            )

            let defCP = BattleEngine.calculateEffectiveCP(
                card: defCard,
                slotIndex: defSlot,
                field: defenderField,
                opponentAttribute: attacker.attribute,
                momentumBonus: 0
            )

            targets.append(TargetInfo(slot: defSlot, atkCP: effectiveAtkCP, defCP: defCP))
        }

        guard !targets.isEmpty else { return nil }

        // 1순위: 이길 수 있는 상대 중 가장 약한 적 (확실한 킬 우선)
        let winnable = targets.filter { $0.atkCP >= $0.defCP }
        if let best = winnable.min(by: { $0.defCP < $1.defCP }) {
            return best.slot
        }

        // 2순위: 동귀어진 가능 (CP 차이 200 이내) 중 가장 약한 적
        let tradeTargets = targets.filter { $0.defCP - $0.atkCP <= 200 }
        if let best = tradeTargets.min(by: { $0.defCP < $1.defCP }) {
            return best.slot
        }

        // 3순위: 무조건 가장 약한 적 공격
        return targets.min(by: { $0.defCP < $1.defCP })?.slot
    }
}

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

    func chooseDrawCard(choice1: AnyCard, choice2: AnyCard, gameState: GameState) -> AnyCard {
        let score1 = evaluateCardForDraw(choice1, gameState: gameState)
        let score2 = evaluateCardForDraw(choice2, gameState: gameState)
        return score1 >= score2 ? choice1 : choice2
    }

    /// 보드 상태를 반영한 드로우 카드 평가
    private func evaluateCardForDraw(_ card: AnyCard, gameState: GameState) -> Int {
        let idx = gameState.currentPlayerIndex
        let opponentIdx = 1 - idx
        let myField = gameState.players[idx].field
        let opponentField = gameState.players[opponentIdx].field
        let hand = gameState.players[idx].hand

        switch card {
        case .monster(let m):
            var score = m.combatPower + (m.isVanilla ? 100 : 200)

            // 패에 몬스터가 없으면 몬스터 보너스
            let monstersInHand = hand.filter { if case .monster = $0 { return true }; return false }
            if monstersInHand.isEmpty {
                score += 500
            }

            // 상대 필드 약점 속성 보너스
            let opponentAttributes = opponentField.monsterSlotIndices.compactMap { i -> Attribute? in
                if case .monster(let om, _) = opponentField.slots[i].content { return om.attribute }
                return nil
            }
            if opponentAttributes.contains(where: { m.attribute.strongAgainst == $0 }) {
                score += 300
            }

            // 글로벌 지형 시너지
            if m.attribute == gameState.globalTerrain {
                score += 300
            }

            return score

        case .spell(let s):
            var score = s.cost * 200

            // 패에 마법만 있으면 마법 감점
            let monstersInHand = hand.filter { if case .monster = $0 { return true }; return false }
            if monstersInHand.isEmpty && myField.monsterCount == 0 {
                score -= 300  // 필드에도 몬스터 없으면 마법 쓸 일 없음
            }

            return score
        }
    }

    // MARK: - 메인 페이즈

    func performMainPhase(gameState: inout GameState) {
        let idx = gameState.currentPlayerIndex
        let opponentIdx = 1 - idx

        // 소환 가능한 카드를 전략적 우선순위로 소환
        var keepGoing = true
        while keepGoing {
            keepGoing = false

            let hand = gameState.players[idx].hand

            let summonCandidates = hand.enumerated().compactMap { (i, card) -> (index: Int, card: AnyCard, priority: Int)? in
                guard card.cost <= gameState.players[idx].energy else { return nil }

                switch card {
                case .monster(let m):
                    guard !gameState.players[idx].field.emptySlotIndices.isEmpty else { return nil }
                    let score = evaluateSummonPriority(
                        monster: m,
                        myField: gameState.players[idx].field,
                        opponentField: gameState.players[opponentIdx].field,
                        globalTerrain: gameState.globalTerrain
                    )
                    return (i, card, score)
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

                gameState.players[idx].hand.remove(at: best.index)

                switch best.card {
                case .monster(let m):
                    let slot = bestSummonSlot(
                        for: m,
                        field: gameState.players[idx].field
                    )
                    _ = gameState.players[idx].field.summonMonster(m, at: slot)
                case .spell(let s):
                    if s.spellType == .continuous {
                        if let slot = gameState.players[idx].field.emptySlotIndices.first {
                            _ = gameState.players[idx].field.placeSpell(s, at: slot)
                        }
                    } else {
                        gameState.players[idx].graveyard.append(.spell(s))
                    }
                }

                keepGoing = true
            }
        }
    }

    // MARK: - 배틀 페이즈

    func performBattlePhase(gameState: inout GameState) -> [String] {
        var logs: [String] = []
        let atkIdx = gameState.currentPlayerIndex
        let defIdx = 1 - atkIdx

        // 최적 공격 순서 계획
        let simAtkFighting = gameState.players[atkIdx].activeMomentumSkill == .fighting
            ? gameState.players[atkIdx].fightingTargetSlot : nil
        let simDefFighting = gameState.players[defIdx].activeMomentumSkill == .fighting
            ? gameState.players[defIdx].fightingTargetSlot : nil
        let attackPlan = buildOptimalAttackPlan(
            attackerField: gameState.players[atkIdx].field,
            defenderField: gameState.players[defIdx].field,
            globalTerrain: gameState.globalTerrain,
            attackerMomentumBonus: gameState.players[atkIdx].momentumBonus,
            defenderMomentumBonus: gameState.players[defIdx].momentumBonus,
            attackerFightingSlot: simAtkFighting,
            defenderFightingSlot: simDefFighting
        )

        var usedAttackers = Set<Int>()

        for plan in attackPlan {
            guard !usedAttackers.contains(plan.attackerSlot) else { continue }
            guard case .monster(let atkCard, _) = gameState.players[atkIdx].field.slots[plan.attackerSlot].content
            else { continue }

            if let defSlot = plan.defenderSlot {
                guard case .monster(let defCard, let shield) = gameState.players[defIdx].field.slots[defSlot].content
                else { continue }

                let result = BattleEngine.resolveCombat(
                    attackerCard: atkCard,
                    attackerSlot: plan.attackerSlot,
                    attackerField: gameState.players[atkIdx].field,
                    defenderCard: defCard,
                    defenderSlot: defSlot,
                    defenderField: gameState.players[defIdx].field,
                    attackerMomentumBonus: gameState.players[atkIdx].momentumBonus,
                    defenderMomentumBonus: gameState.players[defIdx].momentumBonus,
                    defenderShield: shield,
                    globalTerrain: gameState.globalTerrain
                )

                logs.append("\(atkCard.name)(CP:\(result.attackerEffectiveCP)) → \(defCard.name)(CP:\(result.defenderEffectiveCP))")
                gameState.players[atkIdx].gainMomentum(1)
                gameState.players[atkIdx].didAttackThisTurn = true
                usedAttackers.insert(plan.attackerSlot)

                // 방어막 소모 반영
                if !result.defenderDestroyed {
                    gameState.players[defIdx].field.setShield(result.remainingShield, at: defSlot)
                    if shield > 0 && result.remainingShield < shield {
                        logs.append("  → \(defCard.name) 방어막 \(shield - result.remainingShield) 소모! (잔여: \(result.remainingShield))")
                    }
                }

                if result.defenderDestroyed {
                    gameState.destroyMonster(playerIndex: defIdx, slot: defSlot)
                    gameState.players[atkIdx].gainMomentum(1)
                    logs.append("  → \(defCard.name) 파괴!")
                }
                if result.attackerDestroyed {
                    gameState.destroyMonster(playerIndex: atkIdx, slot: plan.attackerSlot)
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
            } else {
                // 직접 공격
                let damage = BattleEngine.resolveDirectAttack(
                    attackerCard: atkCard,
                    attackerSlot: plan.attackerSlot,
                    attackerField: gameState.players[atkIdx].field,
                    momentumBonus: gameState.players[atkIdx].momentumBonus,
                    globalTerrain: gameState.globalTerrain
                )
                gameState.players[defIdx].takeDamage(damage)
                gameState.players[atkIdx].gainMomentum(2)
                gameState.players[atkIdx].didAttackThisTurn = true
                usedAttackers.insert(plan.attackerSlot)
                logs.append("\(atkCard.name)이(가) 직접 공격! \(damage) LP 데미지!")
            }

            if gameState.players[defIdx].isDefeated { break }
        }

        // 남은 공격자로 직접 공격 (적 몬스터가 전부 파괴된 경우)
        if !gameState.players[defIdx].isDefeated {
            let remainingAttackers = gameState.players[atkIdx].field.monsterSlotIndices
                .filter { !usedAttackers.contains($0) }
            let currentDefSlots = gameState.players[defIdx].field.monsterSlotIndices

            if currentDefSlots.isEmpty {
                for atkSlot in remainingAttackers {
                    guard case .monster(let atkCard, _) = gameState.players[atkIdx].field.slots[atkSlot].content
                    else { continue }

                    let damage = BattleEngine.resolveDirectAttack(
                        attackerCard: atkCard,
                        attackerSlot: atkSlot,
                        attackerField: gameState.players[atkIdx].field,
                        momentumBonus: gameState.players[atkIdx].momentumBonus,
                        globalTerrain: gameState.globalTerrain
                    )
                    gameState.players[defIdx].takeDamage(damage)
                    gameState.players[atkIdx].gainMomentum(2)
                    gameState.players[atkIdx].didAttackThisTurn = true
                    logs.append("\(atkCard.name)이(가) 직접 공격! \(damage) LP 데미지!")

                    if gameState.players[defIdx].isDefeated { break }
                }
            }
        }

        return logs
    }

    // MARK: - 액션 계획 (애니메이션용)

    /// 메인 페이즈에서 AI가 할 소환 액션들을 계획만 하고 반환
    func planMainPhase(gameState: GameState) -> [(card: AnyCard, handIndex: Int, slotIndex: Int)] {
        var plans: [(card: AnyCard, handIndex: Int, slotIndex: Int)] = []
        let idx = gameState.currentPlayerIndex
        let opponentIdx = 1 - idx
        var simulatedHand = gameState.players[idx].hand
        var simulatedEnergy = gameState.players[idx].energy
        var occupiedSlots = Set<Int>()
        // 슬롯 점유 정보만 복사 (슬롯 지형 제거됨)

        for i in 0..<PlayerField.slotCount {
            if gameState.players[idx].field.slots[i].content.isOccupied {
                occupiedSlots.insert(i)
            }
        }

        var keepGoing = true
        while keepGoing {
            keepGoing = false
            let candidates = simulatedHand.enumerated().compactMap { (i, card) -> (index: Int, card: AnyCard, priority: Int)? in
                guard card.cost <= simulatedEnergy else { return nil }
                switch card {
                case .monster(let m):
                    let hasEmpty = (0..<PlayerField.slotCount).contains { !occupiedSlots.contains($0) }
                    guard hasEmpty else { return nil }
                    let score = evaluateSummonPriority(
                        monster: m,
                        myField: gameState.players[idx].field,
                        opponentField: gameState.players[opponentIdx].field,
                        globalTerrain: gameState.globalTerrain
                    )
                    return (i, card, score)
                case .spell(let s):
                    guard shouldPlaySpell(s, gameState: gameState) else { return nil }
                    if s.spellType == .continuous {
                        let hasEmpty = (0..<PlayerField.slotCount).contains { !occupiedSlots.contains($0) }
                        guard hasEmpty else { return nil }
                    }
                    return (i, card, s.cost * 100)
                }
            }.sorted { $0.priority > $1.priority }

            if let best = candidates.first {
                simulatedEnergy -= best.card.cost

                simulatedHand.remove(at: best.index)

                // 빈 슬롯 선택
                let slotIndex = (0..<PlayerField.slotCount).first { !occupiedSlots.contains($0) } ?? 0
                occupiedSlots.insert(slotIndex)

                plans.append((card: best.card, handIndex: best.index, slotIndex: slotIndex))
                keepGoing = true
            }
        }
        return plans
    }

    /// 배틀 페이즈에서 AI가 할 공격 액션들을 계획만 하고 반환
    func planBattlePhase(gameState: GameState) -> [(attackerSlot: Int, defenderSlot: Int?)] {
        let atkIdx = gameState.currentPlayerIndex
        let defIdx = 1 - atkIdx

        // 최적 매칭 기반 공격 계획
        let atkFighting = gameState.players[atkIdx].activeMomentumSkill == .fighting
            ? gameState.players[atkIdx].fightingTargetSlot : nil
        let defFighting = gameState.players[defIdx].activeMomentumSkill == .fighting
            ? gameState.players[defIdx].fightingTargetSlot : nil
        var plans = buildOptimalAttackPlan(
            attackerField: gameState.players[atkIdx].field,
            defenderField: gameState.players[defIdx].field,
            globalTerrain: gameState.globalTerrain,
            attackerMomentumBonus: gameState.players[atkIdx].momentumBonus,
            defenderMomentumBonus: gameState.players[defIdx].momentumBonus,
            attackerFightingSlot: atkFighting,
            defenderFightingSlot: defFighting
        )

        // 파괴 시뮬레이션: 적이 전멸하면 남은 공격자로 직접 공격 추가
        var aliveDefSlots = Set(gameState.players[defIdx].field.monsterSlotIndices)
        var usedAttackers = Set<Int>()

        for plan in plans {
            usedAttackers.insert(plan.attackerSlot)
            if let defSlot = plan.defenderSlot {
                if case .monster(let atkCard, _) = gameState.players[atkIdx].field.slots[plan.attackerSlot].content,
                   case .monster(let defCard, let shield) = gameState.players[defIdx].field.slots[defSlot].content {
                    let result = BattleEngine.resolveCombat(
                        attackerCard: atkCard,
                        attackerSlot: plan.attackerSlot,
                        attackerField: gameState.players[atkIdx].field,
                        defenderCard: defCard,
                        defenderSlot: defSlot,
                        defenderField: gameState.players[defIdx].field,
                        attackerMomentumBonus: gameState.players[atkIdx].momentumBonus,
                        defenderMomentumBonus: gameState.players[defIdx].momentumBonus,
                        defenderShield: shield,
                        globalTerrain: gameState.globalTerrain
                    )
                    if result.defenderDestroyed {
                        aliveDefSlots.remove(defSlot)
                    }
                    if result.attackerDestroyed {
                        usedAttackers.insert(plan.attackerSlot) // 파괴된 공격자는 직접 공격 불가
                    }
                }
            }
        }

        // 적이 전멸했으면 남은 공격자로 직접 공격
        if aliveDefSlots.isEmpty {
            let remainingAttackers = gameState.players[atkIdx].field.monsterSlotIndices
                .filter { !usedAttackers.contains($0) }
            for atkSlot in remainingAttackers {
                plans.append((attackerSlot: atkSlot, defenderSlot: nil))
            }
        }

        return plans
    }

    // MARK: - 최적 공격 매칭

    /// 그리디 알고리즘으로 가장 유리한 공격자-방어자 매칭을 계산
    private func buildOptimalAttackPlan(
        attackerField: PlayerField,
        defenderField: PlayerField,
        globalTerrain: Attribute,
        attackerMomentumBonus: Int = 0,
        defenderMomentumBonus: Int = 0,
        attackerFightingSlot: Int? = nil,
        defenderFightingSlot: Int? = nil
    ) -> [(attackerSlot: Int, defenderSlot: Int?)] {
        let atkSlots = attackerField.monsterSlotIndices
        let defSlots = defenderField.monsterSlotIndices

        // 적 몬스터가 없으면 전원 직접 공격
        if defSlots.isEmpty {
            return atkSlots.map { (attackerSlot: $0, defenderSlot: nil) }
        }

        // 모든 (공격자, 방어자) 조합의 유효 CP 차이 계산
        struct MatchScore {
            let atkSlot: Int
            let defSlot: Int
            let atkCP: Int
            let defCP: Int
            let advantage: Int  // atkCP - defCP (클수록 유리)
            let defBaseCP: Int
        }

        var allMatches: [MatchScore] = []

        for atkSlot in atkSlots {
            guard case .monster(let atkCard, _) = attackerField.slots[atkSlot].content else { continue }

            for defSlot in defSlots {
                guard case .monster(let defCard, _) = defenderField.slots[defSlot].content else { continue }

                let atkBonus = (attackerFightingSlot != nil)
                    ? (atkSlot == attackerFightingSlot ? attackerMomentumBonus : 0)
                    : attackerMomentumBonus
                let defBonus = (defenderFightingSlot != nil)
                    ? (defSlot == defenderFightingSlot ? defenderMomentumBonus : 0)
                    : defenderMomentumBonus
                let atkCP = BattleEngine.calculateEffectiveCP(
                    card: atkCard, slotIndex: atkSlot,
                    field: attackerField, opponentAttribute: defCard.attribute,
                    momentumBonus: atkBonus, globalTerrain: globalTerrain
                )
                let defCP = BattleEngine.calculateEffectiveCP(
                    card: defCard, slotIndex: defSlot,
                    field: defenderField, opponentAttribute: atkCard.attribute,
                    momentumBonus: defBonus, globalTerrain: globalTerrain
                )

                allMatches.append(MatchScore(
                    atkSlot: atkSlot, defSlot: defSlot,
                    atkCP: atkCP, defCP: defCP,
                    advantage: atkCP - defCP,
                    defBaseCP: defCard.combatPower
                ))
            }
        }

        // 이길 수 있는 매칭만 필터 (advantage > 0, 또는 동귀어진 허용 조건)
        let myMonsterCount = atkSlots.count
        let opMonsterCount = defSlots.count
        let profitable = allMatches.filter { match in
            if match.advantage > 0 { return true }
            // 동귀어진 허용 조건: 고가치 타겟 + 필드가 비지 않아야 함
            if match.advantage == 0 && match.defBaseCP >= 800 {
                // AI 몬스터가 1체뿐이고 상대도 1체뿐이면 동귀어진 금지
                // (양쪽 빈 필드 → 상대 턴에 소환 후 직접 공격당함)
                if myMonsterCount <= 1 && opMonsterCount <= 1 { return false }
                return true
            }
            return false
        }

        // advantage 큰 순으로 정렬 → 그리디 매칭
        let sorted = profitable.sorted { $0.advantage > $1.advantage }

        var plans: [(attackerSlot: Int, defenderSlot: Int?)] = []
        var usedAttackers = Set<Int>()
        var usedDefenders = Set<Int>()

        for match in sorted {
            if usedAttackers.contains(match.atkSlot) || usedDefenders.contains(match.defSlot) {
                continue
            }
            plans.append((attackerSlot: match.atkSlot, defenderSlot: match.defSlot))
            usedAttackers.insert(match.atkSlot)
            usedDefenders.insert(match.defSlot)
        }

        return plans
    }

    // MARK: - 릴리즈 (희생) 판단

    /// 필드 몬스터의 유지 가치 평가 (상성 + 지형 시너지 반영)
    private func evaluateFieldValue(
        monster: MonsterCard,
        slotIndex: Int,
        myField: PlayerField,
        opponentField: PlayerField,
        globalTerrain: Attribute
    ) -> Int {
        var score = monster.combatPower

        let opponentAttributes = opponentField.monsterSlotIndices.compactMap { i -> Attribute? in
            if case .monster(let m, _) = opponentField.slots[i].content { return m.attribute }
            return nil
        }

        // 상대 약점을 찌르는 중이면 유지 가치 높음
        if opponentAttributes.contains(where: { monster.attribute.strongAgainst == $0 }) {
            score += 400
        }

        // 상대에게 약점 잡혀 있으면 유지 가치 낮음
        if opponentAttributes.contains(where: { monster.attribute.weakAgainst == $0 }) {
            score -= 200
        }

        // 글로벌 지형과 속성 일치하면 유지 가치 높음
        if monster.attribute == globalTerrain {
            score += 300
        }

        return score
    }

    /// 메인 페이즈 소환 전에 릴리즈 여부 판단 (한 턴 최대 1회)
    func planSacrifice(gameState: GameState) -> (sacrificeSlot: Int, cardToSummon: AnyCard, handIndex: Int)? {
        let idx = gameState.currentPlayerIndex
        let opponentIdx = 1 - idx
        let player = gameState.players[idx]
        let myField = player.field
        let opponentField = gameState.players[opponentIdx].field

        // 패에서 현재 소환 불가능한 몬스터 후보 탐색 (기력 부족 or 필드 꽉 참)
        let fieldFull = myField.emptySlotIndices.isEmpty
        let hand = player.hand

        let summonCandidates: [(index: Int, card: MonsterCard, score: Int)] = hand.enumerated().compactMap { (i, card) in
            guard case .monster(let m) = card else { return nil }

            let needsRelease: Bool
            if fieldFull {
                // 필드 꽉 참 → 릴리즈 필요
                needsRelease = true
            } else if m.cost > player.energy {
                // 기력 부족 → 릴리즈로 기력 확보 필요
                needsRelease = true
            } else {
                // 이미 소환 가능 → 릴리즈 불필요
                return nil
            }

            guard needsRelease else { return nil }

            let score = evaluateSummonPriority(
                monster: m,
                myField: myField,
                opponentField: opponentField,
                globalTerrain: gameState.globalTerrain
            )
            return (i, m, score)
        }.sorted { $0.score > $1.score }

        guard !summonCandidates.isEmpty else { return nil }

        // 희생 가능한 필드 몬스터 평가 (이번 턴 소환 제외)
        let sacrificeCandidates: [(slot: Int, monster: MonsterCard, value: Int)] = myField.monsterSlotIndices.compactMap { slot in
            guard !player.summonedThisTurn.contains(slot) else { return nil }
            guard case .monster(let m, _) = myField.slots[slot].content else { return nil }

            let value = evaluateFieldValue(
                monster: m,
                slotIndex: slot,
                myField: myField,
                opponentField: opponentField,
                globalTerrain: gameState.globalTerrain
            )
            return (slot, m, value)
        }.sorted { $0.value < $1.value } // 유지 가치 낮은 순

        guard let weakest = sacrificeCandidates.first else { return nil }

        // 희생 대상과 동일한 카드는 소환 후보에서 제외 (같은 카드 교체는 턴 낭비)
        let filteredCandidates = summonCandidates.filter { $0.card.name != weakest.monster.name }
        guard let bestCandidate = filteredCandidates.first else { return nil }

        // 릴리즈 후 소환 가능한지 확인 (기력 = 현재 + 희생 몬스터 비용)
        let energyAfterSacrifice = player.energy + weakest.monster.cost
        guard bestCandidate.card.cost <= energyAfterSacrifice else { return nil }

        // 교체 이득 비교: 소환 점수 - 유지 가치 >= 300이어야 실행
        let swapGain = bestCandidate.score - weakest.value
        guard swapGain >= 300 else { return nil }

        return (
            sacrificeSlot: weakest.slot,
            cardToSummon: .monster(bestCandidate.card),
            handIndex: bestCandidate.index
        )
    }

    // MARK: - 소환 전략 평가

    /// 몬스터 소환 우선도 점수 계산 (상성 + 지형 시너지)
    private func evaluateSummonPriority(
        monster: MonsterCard,
        myField: PlayerField,
        opponentField: PlayerField,
        globalTerrain: Attribute
    ) -> Int {
        var score = monster.combatPower + 1000  // 기본 점수 (몬스터 > 마법)

        // 상성 보너스: 상대 필드에 약점 속성 몬스터가 있으면 +500
        let opponentAttributes = opponentField.monsterSlotIndices.compactMap { i -> Attribute? in
            if case .monster(let m, _) = opponentField.slots[i].content { return m.attribute }
            return nil
        }
        let hasAdvantage = opponentAttributes.contains { monster.attribute.strongAgainst == $0 }
        if hasAdvantage {
            score += 500
        }

        // 불리한 상성 감점: 상대에게 약점 잡히면 -300
        let hasDisadvantage = opponentAttributes.contains { monster.attribute.weakAgainst == $0 }
        if hasDisadvantage {
            score -= 300
        }

        // 글로벌 지형 보너스: 몬스터 속성이 현재 지형과 일치하면 +300
        if monster.attribute == globalTerrain {
            score += 300
        }

        return score
    }

    /// 최적 소환 슬롯 (빈 슬롯 중 첫 번째)
    private func bestSummonSlot(for monster: MonsterCard, field: PlayerField) -> Int {
        return field.emptySlotIndices.first ?? 0
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
            // 지형 마법: 현재 지형이 이미 같은 속성이면 불필요
            if gameState.globalTerrain == spell.attribute { return false }
            // 관련 속성 몬스터가 있어야 지형 보너스 활용 가능
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

    // MARK: - 기세 스킬 판단

    /// 기세 스킬 선택 결과 (스킬 + 투지 타겟 슬롯)
    struct MomentumSkillChoice {
        let skill: MomentumSkill
        let fightingTargetSlot: Int?  // 투지 전용
    }

    /// 배틀 시뮬레이션 기반 기세 스킬 판단
    /// 각 스킬을 사용했을 때의 배틀 결과를 시뮬레이션하고, 가장 이득이 큰 스킬을 선택
    func chooseMomentumSkill(gameState: GameState) -> MomentumSkillChoice? {
        let idx = gameState.currentPlayerIndex
        let opponentIdx = 1 - idx
        let momentum = gameState.players[idx].momentum
        let myField = gameState.players[idx].field
        let opponentField = gameState.players[opponentIdx].field

        // 몬스터가 없으면 스킬 사용 불가 (폭발 제외하고 의미 없음)
        let myMonsterCount = myField.monsterCount
        let opponentMonsterCount = opponentField.monsterCount
        if myMonsterCount == 0 && opponentMonsterCount == 0 { return nil }

        // 1. 기준선: 스킬 없이 배틀 시뮬레이션
        let baselineScore = simulateBattleScore(
            gameState: gameState,
            momentumBonus: 0,
            fightingSlot: nil,
            explosionKills: []
        )

        // 2. 각 사용 가능한 스킬별 시뮬레이션
        struct Candidate {
            let skill: MomentumSkill
            let score: Int
            let netGain: Int
            let fightingSlot: Int?
        }
        var candidates: [Candidate] = []

        // -- 투지 (코스트 3): 몬스터 1체에 +500 --
        if momentum >= MomentumSkill.fighting.cost && myMonsterCount > 0 && opponentMonsterCount > 0 {
            // 각 몬스터에 투지를 걸어보고 최적 타겟 찾기
            var bestFightingScore = Int.min
            var bestFightingSlot: Int?
            for slot in myField.monsterSlotIndices {
                let score = simulateBattleScore(
                    gameState: gameState,
                    momentumBonus: 500,
                    fightingSlot: slot,
                    explosionKills: []
                )
                if score > bestFightingScore {
                    bestFightingScore = score
                    bestFightingSlot = slot
                }
            }
            if let slot = bestFightingSlot {
                candidates.append(Candidate(
                    skill: .fighting,
                    score: bestFightingScore,
                    netGain: bestFightingScore - baselineScore,
                    fightingSlot: slot
                ))
            }
        }

        // -- 지형 장악 (코스트 4): 지형 매칭 몬스터에 추가 +300 --
        if momentum >= MomentumSkill.terrainMastery.cost && myMonsterCount > 0 {
            let hasTerrainMatch = myField.monsterSlotIndices.contains { i in
                if case .monster(let m, _) = myField.slots[i].content {
                    return m.attribute == gameState.globalTerrain
                }
                return false
            }
            if hasTerrainMatch {
                let score = simulateBattleScore(
                    gameState: gameState,
                    momentumBonus: PlayerField.globalTerrainBonus,  // +300 추가 (2배 효과)
                    fightingSlot: nil,
                    explosionKills: [],
                    terrainMastery: true
                )
                candidates.append(Candidate(
                    skill: .terrainMastery,
                    score: score,
                    netGain: score - baselineScore,
                    fightingSlot: nil
                ))
            }
        }

        // -- 돌파 (코스트 6): 전 몬스터 +300 --
        if momentum >= MomentumSkill.breakthrough.cost && myMonsterCount > 0 && opponentMonsterCount > 0 {
            let score = simulateBattleScore(
                gameState: gameState,
                momentumBonus: 300,
                fightingSlot: nil,
                explosionKills: []
            )
            candidates.append(Candidate(
                skill: .breakthrough,
                score: score,
                netGain: score - baselineScore,
                fightingSlot: nil
            ))
        }

        // -- 폭발 (코스트 8): 상대 최강 몬스터 1체 제거 후 배틀 --
        if momentum >= MomentumSkill.explosion.cost && opponentMonsterCount > 0 {
            // 상대 필드에서 CP가 가장 높은 몬스터 슬롯 찾기
            if let targetSlot = opponentField.monsterSlotIndices.max(by: { a, b in
                guard case .monster(let ma, _) = opponentField.slots[a].content,
                      case .monster(let mb, _) = opponentField.slots[b].content else { return false }
                return ma.combatPower < mb.combatPower
            }) {
                let score = simulateBattleScore(
                    gameState: gameState,
                    momentumBonus: 0,
                    fightingSlot: nil,
                    explosionKills: [targetSlot]
                )
                candidates.append(Candidate(
                    skill: .explosion,
                    score: score,
                    netGain: score - baselineScore,
                    fightingSlot: nil
                ))
            }
        }

        // 3. 최적 선택: 순이익이 가장 높은 스킬
        guard !candidates.isEmpty else { return nil }

        // 기세 낭비 방지: 기세가 높을수록 임계값을 낮춤
        let threshold: Int
        if momentum >= 8 {
            threshold = 0     // 조금이라도 이득이면 사용
        } else if momentum >= 6 {
            threshold = 150   // 적당한 이득
        } else {
            threshold = 300   // 확실한 이득일 때만
        }

        // 순이익 기준 정렬, 동점이면 코스트 낮은 쪽 우선 (기세 절약)
        let best = candidates
            .filter { $0.netGain >= threshold }
            .sorted { a, b in
                if a.netGain != b.netGain { return a.netGain > b.netGain }
                return a.skill.cost < b.skill.cost
            }
            .first

        guard let chosen = best else { return nil }
        return MomentumSkillChoice(skill: chosen.skill, fightingTargetSlot: chosen.fightingSlot)
    }

    // MARK: - 배틀 시뮬레이션

    /// 특정 기세 스킬 조건에서 배틀을 시뮬레이션하고 점수를 반환
    /// 점수 = (적 몬스터 파괴 × 1000) + (상대 LP 데미지) - (내 몬스터 파괴 × 800) - (내 LP 데미지)
    private func simulateBattleScore(
        gameState: GameState,
        momentumBonus: Int,
        fightingSlot: Int?,
        explosionKills: [Int],
        terrainMastery: Bool = false
    ) -> Int {
        let idx = gameState.currentPlayerIndex
        let opponentIdx = 1 - idx
        let myField = gameState.players[idx].field
        var opponentField = gameState.players[opponentIdx].field

        // 폭발로 파괴된 몬스터 반영 (임시 필드 복사)
        var explosionScore = 0
        if !explosionKills.isEmpty {
            for slot in explosionKills.sorted().reversed() {
                if case .monster(let m, _) = opponentField.slots[slot].content {
                    explosionScore += 1000 + m.combatPower / 2  // 파괴 가치 + CP 비례 보너스
                }
                opponentField.removeCard(at: slot)
            }
        }

        // 지형 장악: 지형 매칭 몬스터에만 보너스 적용
        // 투지: 특정 슬롯에만 보너스 적용
        // 돌파: 전체에 보너스 적용
        let attackPlan = buildOptimalAttackPlan(
            attackerField: myField,
            defenderField: opponentField,
            globalTerrain: gameState.globalTerrain,
            attackerMomentumBonus: momentumBonus,
            defenderMomentumBonus: 0,
            attackerFightingSlot: fightingSlot,
            defenderFightingSlot: nil
        )

        var score = explosionScore
        var destroyedDefSlots = Set<Int>()
        var destroyedAtkSlots = Set<Int>()

        for plan in attackPlan {
            let atkSlot = plan.attackerSlot
            guard case .monster(let atkCard, _) = myField.slots[atkSlot].content else { continue }

            if let defSlot = plan.defenderSlot {
                // 몬스터 vs 몬스터
                guard case .monster(let defCard, let shield) = opponentField.slots[defSlot].content else { continue }

                let atkBonus: Int
                if terrainMastery {
                    // 지형 장악: 지형 매칭 몬스터에 추가 보너스
                    let isTerrainMatch = atkCard.attribute == gameState.globalTerrain
                    atkBonus = isTerrainMatch ? momentumBonus : 0
                } else if fightingSlot != nil {
                    atkBonus = (atkSlot == fightingSlot) ? momentumBonus : 0
                } else {
                    atkBonus = momentumBonus
                }

                let result = BattleEngine.resolveCombat(
                    attackerCard: atkCard,
                    attackerSlot: atkSlot,
                    attackerField: myField,
                    defenderCard: defCard,
                    defenderSlot: defSlot,
                    defenderField: opponentField,
                    attackerMomentumBonus: atkBonus,
                    defenderMomentumBonus: 0,
                    defenderShield: shield,
                    globalTerrain: gameState.globalTerrain
                )

                if result.defenderDestroyed {
                    score += 1000
                    score += result.lpDamageToDefender
                    destroyedDefSlots.insert(defSlot)
                }
                if result.attackerDestroyed {
                    score -= 800
                    score -= result.lpDamageToAttacker
                    destroyedAtkSlots.insert(atkSlot)
                }
                if !result.attackerDestroyed && !result.defenderDestroyed {
                    // 방어막에 막힘 → 작은 가산점
                    score += 50
                }
            } else {
                // 직접 공격
                let atkBonus: Int
                if terrainMastery {
                    let isTerrainMatch = atkCard.attribute == gameState.globalTerrain
                    atkBonus = isTerrainMatch ? momentumBonus : 0
                } else if fightingSlot != nil {
                    atkBonus = (atkSlot == fightingSlot) ? momentumBonus : 0
                } else {
                    atkBonus = momentumBonus
                }
                let directDmg = BattleEngine.resolveDirectAttack(
                    attackerCard: atkCard,
                    attackerSlot: atkSlot,
                    attackerField: myField,
                    momentumBonus: atkBonus,
                    globalTerrain: gameState.globalTerrain
                )
                score += directDmg
            }
        }

        // 폭발 후 적이 전멸 → 남은 공격자로 직접 공격 추가 점수
        // opponentField는 이미 폭발 파괴가 반영된 복사본이므로 explosionKills 중복 차감 불필요
        let remainingDefenders = opponentField.monsterCount - destroyedDefSlots.count
        if remainingDefenders <= 0 {
            let unusedAttackers = myField.monsterSlotIndices.filter { slot in
                !destroyedAtkSlots.contains(slot) && !attackPlan.contains(where: { $0.attackerSlot == slot })
            }
            for atkSlot in unusedAttackers {
                guard case .monster(let atkCard, _) = myField.slots[atkSlot].content else { continue }
                let atkBonus: Int
                if terrainMastery {
                    atkBonus = atkCard.attribute == gameState.globalTerrain ? momentumBonus : 0
                } else if fightingSlot != nil {
                    atkBonus = (atkSlot == fightingSlot) ? momentumBonus : 0
                } else {
                    atkBonus = momentumBonus
                }
                let directDmg = BattleEngine.resolveDirectAttack(
                    attackerCard: atkCard,
                    attackerSlot: atkSlot,
                    attackerField: myField,
                    momentumBonus: atkBonus,
                    globalTerrain: gameState.globalTerrain
                )
                score += directDmg
            }
        }

        return score
    }

    // MARK: - 타겟 선택

    private func chooseBestTarget(
        attacker: MonsterCard,
        attackerSlot: Int,
        attackerField: PlayerField,
        defenderSlots: [Int],
        defenderField: PlayerField,
        globalTerrain: Attribute,
        attackerMomentumBonus: Int = 0,
        defenderMomentumBonus: Int = 0
    ) -> Int? {
        struct TargetInfo {
            let slot: Int
            let atkCP: Int
            let defCP: Int
            let defBaseCP: Int  // 방어자 기본 CP (고가치 판단용)
            let shield: Int
        }

        var targets: [TargetInfo] = []

        for defSlot in defenderSlots {
            guard case .monster(let defCard, let shield) = defenderField.slots[defSlot].content else { continue }

            let effectiveAtkCP = BattleEngine.calculateEffectiveCP(
                card: attacker,
                slotIndex: attackerSlot,
                field: attackerField,
                opponentAttribute: defCard.attribute,
                momentumBonus: attackerMomentumBonus,
                globalTerrain: globalTerrain
            )

            let defCP = BattleEngine.calculateEffectiveCP(
                card: defCard,
                slotIndex: defSlot,
                field: defenderField,
                opponentAttribute: attacker.attribute,
                momentumBonus: defenderMomentumBonus,
                globalTerrain: globalTerrain
            )

            targets.append(TargetInfo(
                slot: defSlot, atkCP: effectiveAtkCP, defCP: defCP,
                defBaseCP: defCard.combatPower, shield: shield
            ))
        }

        guard !targets.isEmpty else { return nil }

        // 1순위: 확실히 이길 수 있는 상대 — LP 데미지가 가장 큰 조합 우선
        let winnable = targets.filter { $0.atkCP > $0.defCP }
        if let best = winnable.max(by: { ($0.atkCP - $0.defCP) < ($1.atkCP - $1.defCP) }) {
            return best.slot
        }

        // 2순위: 동귀어진 — 상대가 고가치(기본CP ≥ 800)일 때만 허용
        let tradeable = targets.filter { $0.atkCP == $0.defCP && $0.defBaseCP >= 800 }
        if let best = tradeable.max(by: { $0.defBaseCP < $1.defBaseCP }) {
            return best.slot
        }

        // 이길 수 없으면 공격하지 않음 — 자멸 방지
        return nil
    }
}

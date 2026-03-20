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

            // 지형 시너지
            let hasMatchingTerrain = myField.slots.contains { $0.terrain == m.attribute }
            if hasMatchingTerrain {
                score += 200
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
            let totalResource = gameState.players[idx].energy + gameState.players[idx].momentum

            let summonCandidates = hand.enumerated().compactMap { (i, card) -> (index: Int, card: AnyCard, priority: Int)? in
                guard card.cost <= totalResource else { return nil }

                switch card {
                case .monster(let m):
                    guard !gameState.players[idx].field.emptySlotIndices.isEmpty else { return nil }
                    let score = evaluateSummonPriority(
                        monster: m,
                        myField: gameState.players[idx].field,
                        opponentField: gameState.players[opponentIdx].field
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
        let attackPlan = buildOptimalAttackPlan(
            attackerField: gameState.players[atkIdx].field,
            defenderField: gameState.players[defIdx].field
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
                    attackerMomentumBonus: 0,
                    defenderMomentumBonus: 0,
                    defenderShield: shield
                )

                logs.append("\(atkCard.name)(CP:\(atkCard.combatPower)) → \(defCard.name)(CP:\(defCard.combatPower))")
                gameState.players[atkIdx].gainMomentum(1)
                gameState.players[atkIdx].didAttackThisTurn = true
                usedAttackers.insert(plan.attackerSlot)

                if result.defenderDestroyed {
                    gameState.players[defIdx].field.removeCard(at: defSlot)
                    gameState.players[defIdx].graveyard.append(.monster(defCard))
                    gameState.players[atkIdx].gainMomentum(1)
                    logs.append("  → \(defCard.name) 파괴!")
                }
                if result.attackerDestroyed {
                    gameState.players[atkIdx].field.removeCard(at: plan.attackerSlot)
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
            } else {
                // 직접 공격
                let damage = BattleEngine.resolveDirectAttack(
                    attackerCard: atkCard,
                    attackerSlot: plan.attackerSlot,
                    attackerField: gameState.players[atkIdx].field,
                    momentumBonus: 0
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
                        momentumBonus: 0
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
        var simulatedMomentum = gameState.players[idx].momentum
        var occupiedSlots = Set<Int>()
        // 지형 정보를 시뮬레이션용으로 복사
        var simulatedTerrains: [Attribute?] = gameState.players[idx].field.slots.map { $0.terrain }

        for i in 0..<PlayerField.slotCount {
            if gameState.players[idx].field.slots[i].content.isOccupied {
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
                case .monster(let m):
                    let hasEmpty = (0..<PlayerField.slotCount).contains { !occupiedSlots.contains($0) }
                    guard hasEmpty else { return nil }
                    let score = evaluateSummonPriority(
                        monster: m,
                        myField: gameState.players[idx].field,
                        opponentField: gameState.players[opponentIdx].field
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
                let cost = best.card.cost
                let energySpent = min(simulatedEnergy, cost)
                let momentumSpent = cost - energySpent
                simulatedEnergy -= energySpent
                simulatedMomentum -= momentumSpent

                simulatedHand.remove(at: best.index)

                // 지형 시너지를 고려한 슬롯 선택
                let slotIndex: Int
                if case .monster(let m) = best.card {
                    // 같은 속성 지형 슬롯 우선
                    let matchingTerrainSlot = (0..<PlayerField.slotCount).first {
                        !occupiedSlots.contains($0) && simulatedTerrains[$0] == m.attribute
                    }
                    slotIndex = matchingTerrainSlot
                        ?? (0..<PlayerField.slotCount).first { !occupiedSlots.contains($0) }
                        ?? 0
                    simulatedTerrains[slotIndex] = m.attribute
                } else {
                    slotIndex = (0..<PlayerField.slotCount).first { !occupiedSlots.contains($0) } ?? 0
                }
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
        var plans = buildOptimalAttackPlan(
            attackerField: gameState.players[atkIdx].field,
            defenderField: gameState.players[defIdx].field
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
                        attackerMomentumBonus: 0,
                        defenderMomentumBonus: 0,
                        defenderShield: shield
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
        defenderField: PlayerField
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

                let atkCP = BattleEngine.calculateEffectiveCP(
                    card: atkCard, slotIndex: atkSlot,
                    field: attackerField, opponentAttribute: defCard.attribute,
                    momentumBonus: 0
                )
                let defCP = BattleEngine.calculateEffectiveCP(
                    card: defCard, slotIndex: defSlot,
                    field: defenderField, opponentAttribute: atkCard.attribute,
                    momentumBonus: 0
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
        let profitable = allMatches.filter { match in
            if match.advantage > 0 { return true }
            if match.advantage == 0 && match.defBaseCP >= 800 { return true }
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

    // MARK: - 소환 전략 평가

    /// 몬스터 소환 우선도 점수 계산 (상성 + 지형 시너지)
    private func evaluateSummonPriority(
        monster: MonsterCard,
        myField: PlayerField,
        opponentField: PlayerField
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

        // 지형 매칭 보너스: 같은 속성 지형 빈 슬롯이 있으면 +200
        let hasMatchingTerrain = myField.emptySlotIndices.contains { i in
            myField.slots[i].terrain == monster.attribute
        }
        if hasMatchingTerrain {
            score += 200
        }

        // 속성 지배 기여: 소환하면 지배(3+) 달성에 가까워지면 +300
        let currentTerrainCount = myField.terrainCount(for: monster.attribute)
        if currentTerrainCount == 2 {
            score += 300  // 이 소환으로 속성 지배 달성
        } else if currentTerrainCount >= 3 {
            score += 150  // 지배 강화
        }

        return score
    }

    /// 지형 시너지를 고려한 최적 소환 슬롯
    private func bestSummonSlot(for monster: MonsterCard, field: PlayerField) -> Int {
        let emptySlots = field.emptySlotIndices

        // 1순위: 같은 속성 지형 슬롯
        if let matchingSlot = emptySlots.first(where: { field.slots[$0].terrain == monster.attribute }) {
            return matchingSlot
        }

        // 2순위: 중립 지형 슬롯 (다른 속성이 아닌 곳)
        if let neutralSlot = emptySlots.first(where: { field.slots[$0].terrain == nil }) {
            return neutralSlot
        }

        // 3순위: 아무 빈 슬롯
        return emptySlots.first ?? 0
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

    // MARK: - 기세 스킬 판단

    /// 메인 페이즈 끝에서 기세 스킬 사용 여부 판단
    func chooseMomentumSkill(gameState: GameState) -> MomentumSkill? {
        let idx = gameState.currentPlayerIndex
        let opponentIdx = 1 - idx
        let momentum = gameState.players[idx].momentum
        let myField = gameState.players[idx].field
        let opponentField = gameState.players[opponentIdx].field
        let myMonsterCount = myField.monsterCount
        let opponentMonsterCount = opponentField.monsterCount

        // 기세 폭발 (비용 8): 상대 약한 몬스터 2체 이상 파괴 가능
        if momentum >= MomentumSkill.explosion.cost && opponentMonsterCount >= 2 {
            let explosionDmg = BattleEngine.explosionDamage(momentum: MomentumSkill.explosion.cost)
            let killable = opponentField.monsterSlotIndices.filter { i in
                if case .monster(let m, _) = opponentField.slots[i].content {
                    return m.combatPower <= explosionDmg
                }
                return false
            }
            if killable.count >= 2 {
                return .explosion
            }
        }

        // 전선 돌파 (비용 6): 아군 몬스터 3체 이상 + 상대 몬스터 있음
        if momentum >= MomentumSkill.breakthrough.cost
            && myMonsterCount >= 3 && opponentMonsterCount > 0 {
            return .breakthrough
        }

        // 투지 (비용 3): 핵심 몬스터가 상대보다 약간 약할 때 +500으로 역전 가능
        if momentum >= MomentumSkill.fighting.cost && myMonsterCount > 0 && opponentMonsterCount > 0 {
            // 가장 강한 내 몬스터와 가장 강한 적 몬스터 비교
            let myBestCP = myField.monsterSlotIndices.compactMap { i -> Int? in
                if case .monster(let m, _) = myField.slots[i].content { return m.combatPower }
                return nil
            }.max() ?? 0

            let opponentBestCP = opponentField.monsterSlotIndices.compactMap { i -> Int? in
                if case .monster(let m, _) = opponentField.slots[i].content { return m.combatPower }
                return nil
            }.max() ?? 0

            // 내가 약간 약한데 +500이면 역전 가능
            if myBestCP < opponentBestCP && myBestCP + 500 > opponentBestCP {
                return .fighting
            }
        }

        return nil
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
                momentumBonus: 0
            )

            let defCP = BattleEngine.calculateEffectiveCP(
                card: defCard,
                slotIndex: defSlot,
                field: defenderField,
                opponentAttribute: attacker.attribute,
                momentumBonus: 0
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

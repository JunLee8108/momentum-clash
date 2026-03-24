import Foundation

/// 전투 결과
struct BattleResult {
    let attackerDestroyed: Bool
    let defenderDestroyed: Bool
    let lpDamageToDefender: Int  // 방어 측 플레이어 LP 데미지
    let lpDamageToAttacker: Int  // 공격 측 플레이어 LP 데미지
    let remainingShield: Int     // 전투 후 방어자에게 남은 방어막
    let attackerEffectiveCP: Int // 효과 반영된 공격자 전투력
    let defenderEffectiveCP: Int // 효과 반영된 방어자 전투력
}

/// 전투 계산 엔진
struct BattleEngine {

    /// 몬스터 vs 몬스터 전투
    static func resolveCombat(
        attackerCard: MonsterCard,
        attackerSlot: Int,
        attackerField: PlayerField,
        defenderCard: MonsterCard,
        defenderSlot: Int,
        defenderField: PlayerField,
        attackerMomentumBonus: Int,   // 기세 스킬에 의한 추가 전투력
        defenderMomentumBonus: Int,
        defenderShield: Int,
        globalTerrain: Attribute
    ) -> BattleResult {
        // 공격자 전투력 계산
        let attackerCP = calculateEffectiveCP(
            card: attackerCard,
            slotIndex: attackerSlot,
            field: attackerField,
            opponentAttribute: defenderCard.attribute,
            momentumBonus: attackerMomentumBonus,
            globalTerrain: globalTerrain
        )

        // 방어자 전투력 계산
        let defenderCP = calculateEffectiveCP(
            card: defenderCard,
            slotIndex: defenderSlot,
            field: defenderField,
            opponentAttribute: attackerCard.attribute,
            momentumBonus: defenderMomentumBonus,
            globalTerrain: globalTerrain
        )

        // 방어막 적용: 공격자의 공격력을 방어막이 먼저 흡수
        let shieldAfterHit = max(0, defenderShield - attackerCP)
        let attackDamage = max(0, attackerCP - defenderShield)

        if attackDamage > defenderCP {
            // 공격자 승리: 방어자 파괴, 차이만큼 LP 데미지
            return BattleResult(
                attackerDestroyed: false,
                defenderDestroyed: true,
                lpDamageToDefender: attackDamage - defenderCP,
                lpDamageToAttacker: 0,
                remainingShield: 0,
                attackerEffectiveCP: attackerCP,
                defenderEffectiveCP: defenderCP
            )
        } else if attackDamage < defenderCP {
            // 방어자 승리: 공격자 파괴, 차이만큼 LP 데미지
            return BattleResult(
                attackerDestroyed: true,
                defenderDestroyed: false,
                lpDamageToDefender: 0,
                lpDamageToAttacker: defenderCP - attackDamage,
                remainingShield: shieldAfterHit,
                attackerEffectiveCP: attackerCP,
                defenderEffectiveCP: defenderCP
            )
        } else {
            // 동일: 양쪽 파괴
            return BattleResult(
                attackerDestroyed: true,
                defenderDestroyed: true,
                lpDamageToDefender: 0,
                lpDamageToAttacker: 0,
                remainingShield: 0,
                attackerEffectiveCP: attackerCP,
                defenderEffectiveCP: defenderCP
            )
        }
    }

    /// 직접 공격 (상대 필드에 몬스터 없을 때)
    static func resolveDirectAttack(
        attackerCard: MonsterCard,
        attackerSlot: Int,
        attackerField: PlayerField,
        momentumBonus: Int,
        globalTerrain: Attribute
    ) -> Int {
        return calculateEffectiveCP(
            card: attackerCard,
            slotIndex: attackerSlot,
            field: attackerField,
            opponentAttribute: nil,
            momentumBonus: momentumBonus,
            globalTerrain: globalTerrain
        )
    }

    /// 유효 전투력 계산
    /// 순서: 기본 CP → 장착/지속 효과 → 글로벌 지형 보너스 → 속성 상성 배율 → 기세 스킬
    static func calculateEffectiveCP(
        card: MonsterCard,
        slotIndex: Int,
        field: PlayerField,
        opponentAttribute: Attribute?,
        momentumBonus: Int,
        globalTerrain: Attribute
    ) -> Int {
        // 1. 기본 전투력
        var cp = Double(card.combatPower)

        // 2. 디버프 적용 (필드 전체: 태풍룡 등 + 슬롯 개별: 염룡/죽음의 기사)
        cp += Double(field.cpDebuff)
        cp += Double(field.slots[slotIndex].slotCpDebuff)

        // 3. 글로벌 지형 보너스 (+300)
        cp += Double(field.terrainBonus(at: slotIndex, globalTerrain: globalTerrain))

        // 4. 속성 상성 배율
        if let opponentAttr = opponentAttribute {
            cp *= card.attribute.damageMultiplier(against: opponentAttr)
        }

        // 5. 기세 스킬 효과
        cp += Double(momentumBonus)

        return max(0, Int(cp))
    }
}

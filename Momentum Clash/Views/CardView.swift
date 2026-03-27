import SwiftUI

/// 카드 1장 표시 뷰
struct CardView: View {
    let card: AnyCard
    var isSelected: Bool = false
    var isSmall: Bool = false
    var flatBottom: Bool = false
    var onTap: (() -> Void)? = nil

    private var width: CGFloat { isSmall ? 70 : 100 }
    private var height: CGFloat { isSmall ? 100 : 140 }

    var body: some View {
        VStack(spacing: 2) {
            // 상단: 기력 비용 + 속성
            HStack {
                HStack(spacing: 1) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: isSmall ? 8 : 10))
                    Text("\(card.cost)")
                        .font(.system(size: isSmall ? 10 : 12, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, isSmall ? 3 : 4)
                .padding(.vertical, isSmall ? 1 : 2)
                .background(Capsule().fill(Color.cyan.opacity(0.8)))

                Spacer()

                Text(card.attribute.emoji)
                    .font(.system(size: isSmall ? 12 : 16))
            }
            .padding(.horizontal, 4)

            // 이름
            Text(card.name)
                .font(.system(size: isSmall ? 9 : 11, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // 카드별 정보
            switch card {
            case .monster(let m):
                Text(m.monsterType.displayName)
                    .font(.system(size: isSmall ? 7 : 9))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                // 전투력
                HStack(spacing: 2) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: isSmall ? 8 : 10))
                    Text("\(m.combatPower)")
                        .font(.system(size: isSmall ? 10 : 13, weight: .bold))
                }
                .foregroundColor(.orange)

                // 효과 유무
                if !m.isVanilla {
                    Image(systemName: "sparkles")
                        .font(.system(size: isSmall ? 6 : 8))
                        .foregroundColor(.purple)
                }

            case .spell(let s):
                Text(s.spellType.displayName)
                    .font(.system(size: isSmall ? 7 : 9))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Image(systemName: "wand.and.stars")
                    .font(.system(size: isSmall ? 12 : 16))
                    .foregroundColor(.purple)
            }
        }
        .padding(4)
        .frame(width: width, height: height)
        .background(
            ZStack {
                // 카드 이미지 썸네일
                if let uiImage = UIImage(named: card.imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .clipped()

                    // 어두운 오버레이 (텍스트 가독성)
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.2),
                            Color.black.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    // 이미지 없으면 기존 속성 색상 배경
                    attributeColor(card.attribute).opacity(0.15)
                }
            }
            .clipShape(cardShape)
        )
        .overlay(
            cardShape
                .strokeBorder(isSelected ? Color.yellow : Color.gray.opacity(0.5), lineWidth: isSelected ? 3 : 1)
        )
        .onTapGesture {
            onTap?()
        }
    }

    private var cardShape: UnevenRoundedRectangle {
        if flatBottom {
            return UnevenRoundedRectangle(
                topLeadingRadius: 8, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 8
            )
        }
        return UnevenRoundedRectangle(
            topLeadingRadius: 8, bottomLeadingRadius: 8,
            bottomTrailingRadius: 8, topTrailingRadius: 8
        )
    }
}

/// 필드 슬롯 뷰
struct FieldSlotView: View {
    let slot: FieldSlot
    let index: Int
    var globalTerrain: Attribute? = nil
    var fieldOverrideAttribute: Attribute? = nil
    var activeMomentumSkill: MomentumSkill? = nil
    var fightingTargetSlot: Int? = nil
    var momentumBonus: Int = 0
    var cpDebuff: Int = 0
    var isHighlighted: Bool = false
    var aiHighlightColor: Color? = nil
    var hasAttacked: Bool = false
    var onTap: (() -> Void)? = nil

    private let slotWidth: CGFloat = 75
    private let slotHeight: CGFloat = 90

    /// 이 슬롯에 적용되는 유효 지형 (오버라이드 우선)
    private var activeTerrain: Attribute? {
        fieldOverrideAttribute ?? globalTerrain
    }

    var body: some View {
        VStack(spacing: 2) {
            // 오버라이드 활성 시 속성 이모지 + 남은 턴 표시
            if let override = fieldOverrideAttribute {
                Text(override.emoji)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.9))
            } else {
                Text("·")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }

            // 카드 내용
            slotContentView
        }
        .frame(width: slotWidth, height: slotHeight)
        .background(slotBackgroundView)
        .overlay(borderOverlay)
        .overlay(glowOverlay)
        .overlay(attackedOverlay)
        .scaleEffect(aiHighlightColor != nil ? 1.05 : 1.0)
        .onTapGesture {
            onTap?()
        }
    }

    @ViewBuilder
    private var slotContentView: some View {
        switch slot.content {
        case .monster(let card, let shield):
            monsterContentView(card: card, shield: shield)
        case .spell(let card):
            VStack(spacing: 1) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 10))
                    .foregroundColor(.purple)
                Text(card.name)
                    .font(.system(size: 7))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        case .empty:
            Text("빈칸")
                .font(.system(size: 8))
                .foregroundColor(.gray.opacity(0.5))
        }
    }

    @ViewBuilder
    private func monsterContentView(card: MonsterCard, shield: Int) -> some View {
        let effectiveTerrain = activeTerrain
        let terrainBonus = (effectiveTerrain != nil && card.attribute == effectiveTerrain!) ? PlayerField.globalTerrainBonus : 0
        let mBonus = effectiveMomentumBonus(for: card)
        let hasAnyModifier = terrainBonus > 0 || mBonus > 0 || cpDebuff != 0

        VStack(spacing: 1) {
            Text(card.name)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if hasAnyModifier {
                // 원본 CP
                Text("\(card.combatPower)")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.6))

                // 지형 보너스
                if terrainBonus > 0 {
                    Text("(+\(terrainBonus))")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundColor(.cyan)
                }

                // 기세 보너스
                if mBonus > 0 {
                    HStack(spacing: 1) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 6))
                        Text("+\(mBonus)")
                            .font(.system(size: 7, weight: .semibold))
                    }
                    .foregroundColor(.orange)
                }

                // 버프
                if cpDebuff > 0 {
                    HStack(spacing: 1) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 6))
                        Text("+\(cpDebuff)")
                            .font(.system(size: 7, weight: .semibold))
                    }
                    .foregroundColor(.green)
                }

                // 디버프
                if cpDebuff < 0 {
                    HStack(spacing: 1) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 6))
                        Text("\(cpDebuff)")
                            .font(.system(size: 7, weight: .semibold))
                    }
                    .foregroundColor(.red)
                }

                // 합산 CP
                let totalCP = max(0, card.combatPower + terrainBonus + mBonus + cpDebuff)
                Text("\(totalCP)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(cpDebuff < 0 ? .red : (cpDebuff > 0 ? .green : .orange))
            } else {
                Text("\(card.combatPower)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.orange)
            }

            if shield > 0 {
                HStack(spacing: 1) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 6))
                    Text("\(shield)")
                        .font(.system(size: 8))
                }
                .foregroundColor(.cyan)
            }
        }
    }

    /// 이 몬스터에 적용되는 기세 보너스 계산
    private func effectiveMomentumBonus(for card: MonsterCard) -> Int {
        guard let skill = activeMomentumSkill else { return 0 }
        switch skill {
        case .fighting:
            return fightingTargetSlot == index ? 500 : 0
        case .terrainMastery:
            // 지형 일치 몬스터만 추가 보너스 (오버라이드 우선)
            if let terrain = activeTerrain, card.attribute == terrain {
                return PlayerField.globalTerrainBonus
            }
            return 0
        case .breakthrough:
            return 300
        default:
            return 0
        }
    }

    private var slotBackgroundView: some View {
        ZStack {
            if let imageName = cardImageName, let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: slotWidth, height: slotHeight)
                    .clipped()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(slotBackground)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var borderOverlay: some View {
        let momentumGlow = hasMomentumGlow
        let buffActive = hasBuff
        let debuffActive = hasDebuff
        let hasOverride = fieldOverrideAttribute != nil
        let overrideColor = fieldOverrideAttribute.map { attributeColor($0).opacity(0.7) } ?? Color.clear
        let borderColor: Color = aiHighlightColor
            ?? (isHighlighted ? .yellow : (momentumGlow ? .orange.opacity(0.7) : (buffActive ? .green.opacity(0.7) : (debuffActive ? .red.opacity(0.7) : (hasOverride ? overrideColor : .gray.opacity(0.3))))))
        let borderWidth: CGFloat = aiHighlightColor != nil ? 3 : (isHighlighted ? 2 : (momentumGlow ? 2 : (buffActive ? 2 : (debuffActive ? 2 : (hasOverride ? 2 : 1)))))

        return RoundedRectangle(cornerRadius: 6)
            .stroke(borderColor, lineWidth: borderWidth)
            .shadow(color: momentumGlow ? .orange.opacity(0.4) : (buffActive ? .green.opacity(0.4) : (debuffActive ? .red.opacity(0.4) : (hasOverride ? overrideColor.opacity(0.3) : .clear))), radius: (momentumGlow || buffActive || debuffActive || hasOverride) ? 4 : 0)
    }

    /// 디버프 걸린 몬스터 여부
    private var hasDebuff: Bool {
        guard cpDebuff < 0, case .monster = slot.content else { return false }
        return true
    }

    /// 버프 걸린 몬스터 여부
    private var hasBuff: Bool {
        guard cpDebuff > 0, case .monster = slot.content else { return false }
        return true
    }

    @ViewBuilder
    private var glowOverlay: some View {
        if let color = aiHighlightColor {
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.2))
                .allowsHitTesting(false)
        } else if hasMomentumGlow {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.orange.opacity(0.12))
                .allowsHitTesting(false)
        } else if hasBuff {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.green.opacity(0.12))
                .allowsHitTesting(false)
        } else if hasDebuff {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.red.opacity(0.12))
                .allowsHitTesting(false)
        }
    }

    /// 기세 스킬에 의한 glow 표시 여부
    private var hasMomentumGlow: Bool {
        guard let skill = activeMomentumSkill else { return false }
        switch skill {
        case .fighting:
            // 투지: 타겟 슬롯에만 glow
            if fightingTargetSlot == index, case .monster = slot.content { return true }
            return false
        case .breakthrough:
            // 돌파: 모든 몬스터 슬롯에 glow
            if case .monster = slot.content { return true }
            return false
        case .terrainMastery:
            // 지형 일치 몬스터만 (오버라이드 우선)
            if case .monster(let card, _) = slot.content,
               let terrain = activeTerrain, card.attribute == terrain {
                return true
            }
            return false
        default:
            return false
        }
    }

    @ViewBuilder
    private var attackedOverlay: some View {
        if hasAttacked {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.4))
                .allowsHitTesting(false)
        }
    }

    private var cardImageName: String? {
        switch slot.content {
        case .monster(let card, _): return card.imageName
        case .spell(let card): return card.imageName
        case .empty: return nil
        }
    }

    private var slotBackground: Color {
        if let override = fieldOverrideAttribute {
            return attributeColor(override).opacity(0.25)
        }
        return Color.gray.opacity(0.1)
    }
}

/// 속성별 색상
func attributeColor(_ attr: Attribute) -> Color {
    switch attr {
    case .fire:    return .red
    case .water:   return .blue
    case .wind:    return .green
    case .earth:   return .brown
    case .thunder: return .yellow
    case .dark:    return .purple
    case .light:   return .orange
    }
}

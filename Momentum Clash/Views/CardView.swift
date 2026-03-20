import SwiftUI

/// 카드 1장 표시 뷰
struct CardView: View {
    let card: AnyCard
    var isSelected: Bool = false
    var isSmall: Bool = false
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
            .clipShape(RoundedRectangle(cornerRadius: 8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.yellow : Color.gray.opacity(0.5), lineWidth: isSelected ? 3 : 1)
        )
        .onTapGesture {
            onTap?()
        }
    }
}

/// 필드 슬롯 뷰
struct FieldSlotView: View {
    let slot: FieldSlot
    let index: Int
    var globalTerrain: Attribute? = nil
    var activeMomentumSkill: MomentumSkill? = nil
    var fightingTargetSlot: Int? = nil
    var momentumBonus: Int = 0
    var isHighlighted: Bool = false
    var aiHighlightColor: Color? = nil
    var hasAttacked: Bool = false
    var onTap: (() -> Void)? = nil

    private let slotWidth: CGFloat = 75
    private let slotHeight: CGFloat = 90

    var body: some View {
        VStack(spacing: 2) {
            // 지형 표시
            Text(slot.terrain?.emoji ?? "·")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.9))

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
        let terrainBonus = (globalTerrain != nil && card.attribute == globalTerrain!) ? PlayerField.globalTerrainBonus : 0
        let mBonus = effectiveMomentumBonus(for: card)
        let hasAnyBonus = terrainBonus > 0 || mBonus > 0

        VStack(spacing: 1) {
            Text(card.name)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if hasAnyBonus {
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

                // 합산 CP
                Text("\(card.combatPower + terrainBonus + mBonus)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.orange)
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
            // 지형 일치 몬스터만 추가 보너스
            if let terrain = globalTerrain, card.attribute == terrain {
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
        let borderColor: Color = aiHighlightColor
            ?? (isHighlighted ? .yellow : (momentumGlow ? .orange.opacity(0.7) : .gray.opacity(0.3)))
        let borderWidth: CGFloat = aiHighlightColor != nil ? 3 : (isHighlighted ? 2 : (momentumGlow ? 2 : 1))

        return RoundedRectangle(cornerRadius: 6)
            .stroke(borderColor, lineWidth: borderWidth)
            .shadow(color: momentumGlow ? .orange.opacity(0.4) : .clear, radius: momentumGlow ? 4 : 0)
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
            // 지형 일치 몬스터만
            if case .monster(let card, _) = slot.content,
               let terrain = globalTerrain, card.attribute == terrain {
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
        if let terrain = slot.terrain {
            return attributeColor(terrain).opacity(0.2)
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

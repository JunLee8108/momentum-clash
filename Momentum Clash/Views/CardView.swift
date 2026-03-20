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
            // 상단: 비용 + 속성
            HStack {
                Text("\(card.cost)")
                    .font(.system(size: isSmall ? 10 : 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: isSmall ? 16 : 20, height: isSmall ? 16 : 20)
                    .background(Circle().fill(Color.blue))

                Spacer()

                Text(card.attribute.emoji)
                    .font(.system(size: isSmall ? 12 : 16))
            }
            .padding(.horizontal, 4)

            // 이름
            Text(card.name)
                .font(.system(size: isSmall ? 9 : 11, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // 카드별 정보
            switch card {
            case .monster(let m):
                Text(m.monsterType.displayName)
                    .font(.system(size: isSmall ? 7 : 9))
                    .foregroundColor(.secondary)

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
                    .foregroundColor(.secondary)

                Spacer()

                Image(systemName: "wand.and.stars")
                    .font(.system(size: isSmall ? 12 : 16))
                    .foregroundColor(.purple)
            }
        }
        .padding(4)
        .frame(width: width, height: height)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.yellow : Color.gray.opacity(0.5), lineWidth: isSelected ? 3 : 1)
        )
        .onTapGesture {
            onTap?()
        }
    }

    private var cardBackground: Color {
        attributeColor(card.attribute).opacity(0.15)
    }
}

/// 필드 슬롯 뷰
struct FieldSlotView: View {
    let slot: FieldSlot
    let index: Int
    var isHighlighted: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 2) {
            // 지형 표시
            Text(slot.terrain?.emoji ?? "·")
                .font(.system(size: 10))

            // 카드 내용
            switch slot.content {
            case .monster(let card, let shield):
                VStack(spacing: 1) {
                    Text(card.name)
                        .font(.system(size: 8, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    HStack(spacing: 1) {
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

            case .spell(let card):
                VStack(spacing: 1) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 10))
                        .foregroundColor(.purple)
                    Text(card.name)
                        .font(.system(size: 7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

            case .empty:
                Text("빈칸")
                    .font(.system(size: 8))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .frame(width: 75, height: 90)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(slotBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isHighlighted ? Color.yellow : Color.gray.opacity(0.3), lineWidth: isHighlighted ? 2 : 1)
        )
        .onTapGesture {
            onTap?()
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

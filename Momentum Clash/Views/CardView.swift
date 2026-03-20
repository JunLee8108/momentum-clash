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
    var isHighlighted: Bool = false
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
            switch slot.content {
            case .monster(let card, let shield):
                VStack(spacing: 1) {
                    Text(card.name)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
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
        .frame(width: slotWidth, height: slotHeight)
        .background(
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
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isHighlighted ? Color.yellow : Color.gray.opacity(0.3), lineWidth: isHighlighted ? 2 : 1)
        )
        .onTapGesture {
            onTap?()
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

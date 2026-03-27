import SwiftUI

/// 덱 빌딩용 카드 상세 정보 풀스크린 뷰
struct DeckCardDetailView: View {
    let card: AnyCard
    let currentCount: Int
    let canAdd: Bool
    let onClose: () -> Void
    let onAdd: () -> Void

    @State private var appeared = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // 배경 이미지
            GeometryReader { geo in
                cardBackground(size: geo.size)
            }
            .ignoresSafeArea()

            // 그라데이션 오버레이
            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.clear,
                    Color.black.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // 콘텐츠
            VStack(spacing: 0) {
                // 스와이프 힌트 바
                Capsule()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)

                topBadges
                    .padding(.top, 8)

                Spacer()

                infoPanel

                actionButtons
                    .padding(.top, 12)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
        }
        .offset(y: dragOffset)
        .opacity(appeared ? 1 : 0)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = UIScreen.main.bounds.height
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onClose()
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                appeared = true
            }
        }
    }

    // MARK: - 배경

    @ViewBuilder
    private func cardBackground(size: CGSize) -> some View {
        if let uiImage = UIImage(named: card.imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipped()
        } else {
            LinearGradient(
                colors: [attributeColor(card.attribute).opacity(0.8), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - 상단 배지

    private var topBadges: some View {
        HStack {
            Text(card.attribute.emoji + " " + card.attribute.displayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .liquidGlass(cornerRadius: 20, opacity: 0.5)

            Spacer()

            // 보유 장수 (5성 몬스터는 최대 2장)
            Text("\(currentCount)/\(cardLimit)장")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(currentCount >= cardLimit ? .red : .cyan)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .liquidGlass(cornerRadius: 20, opacity: 0.5)

            Text(card.rarity.displayName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(rarityColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .liquidGlass(cornerRadius: 20, opacity: 0.5)
        }
    }

    // MARK: - 정보 패널

    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(card.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            switch card {
            case .monster(let m):
                monsterInfo(m)
            case .spell(let s):
                spellInfo(s)
            }

            HStack(spacing: 6) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.cyan)
                Text("기력: \(card.cost)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }

            if !card.flavorText.isEmpty {
                Text(card.flavorText)
                    .font(.system(size: 13, weight: .regular))
                    .italic()
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .liquidGlass(cornerRadius: 16, opacity: 0.5)
    }

    private func monsterInfo(_ m: MonsterCard) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    Text(m.monsterType.displayName)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }

                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("전투력 \(m.combatPower)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.orange)
                }
            }

            if let effect = m.effect {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(.purple)
                    Text(effect.description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            attributeMatchupSection(m)
        }
    }

    private func attributeMatchupSection(_ m: MonsterCard) -> some View {
        let attr = m.attribute
        let strong = attr.strongAgainst
        let weak = attr.weakAgainst
        let strongCP = Int(Double(m.combatPower) * attr.damageMultiplier(against: strong))
        let weakCP = Int(Double(m.combatPower) * attr.damageMultiplier(against: weak))
        let isMutual = strong == weak

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                Text("속성 상성")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 2)

            if isMutual {
                HStack(spacing: 6) {
                    Text(strong.emoji)
                        .font(.system(size: 12))
                    Text("\(strong.displayName)과 상호 강화")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                    Text("전투력 \(strongCP)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.orange)
                }
            } else {
                HStack(spacing: 6) {
                    Text(strong.emoji)
                        .font(.system(size: 12))
                    Text("\(strong.displayName)에 강함")
                        .font(.system(size: 13))
                        .foregroundColor(.green.opacity(0.9))
                    Spacer()
                    Text("전투력 \(strongCP)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.green.opacity(0.9))
                }

                HStack(spacing: 6) {
                    Text(weak.emoji)
                        .font(.system(size: 12))
                    Text("\(weak.displayName)에 약함")
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.9))
                    Spacer()
                    Text("전투력 \(weakCP)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.red.opacity(0.9))
                }
            }
        }
    }

    private func spellInfo(_ s: SpellCard) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 12))
                    .foregroundColor(.purple)
                Text(s.spellType.displayName)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                Text(s.effect.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - 액션 버튼

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button("닫기") {
                onClose()
            }
            .buttonStyle(LiquidGlassButtonStyle(color: .white))

            Button("덱에 추가") {
                onAdd()
            }
            .buttonStyle(LiquidGlassButtonStyle(color: canAdd ? .orange : .gray))
            .disabled(!canAdd)
            .opacity(canAdd ? 1.0 : 0.5)
        }
    }

    /// 카드별 최대 투입 장수 (5성 몬스터는 2장, 그 외 3장)
    private var cardLimit: Int {
        if case .monster(let m) = card, m.cost >= DeckConstants.highCostThreshold {
            return DeckConstants.highCostLimit
        }
        return DeckConstants.sameCardLimit
    }

    private var rarityColor: Color {
        switch card.rarity {
        case .normal: return .white
        case .rare: return .cyan
        case .superRare: return .yellow
        case .ultraRare: return .orange
        }
    }
}

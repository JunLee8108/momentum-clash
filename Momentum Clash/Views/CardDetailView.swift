import SwiftUI

/// 카드 상세 정보 풀스크린 뷰
struct CardDetailView: View {
    let card: AnyCard
    let handIndex: Int
    let canUse: Bool
    let onClose: () -> Void
    let onUse: () -> Void

    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 배경 이미지 (정확히 화면 크기)
                cardBackground(size: geo.size)

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

                // 콘텐츠
                VStack(spacing: 0) {
                    topBadges
                        .padding(.top, geo.safeAreaInsets.top + 12)

                    Spacer()

                    infoPanel

                    actionButtons
                        .padding(.top, 12)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 16)
                }
                .padding(.horizontal, 20)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                appeared = true
            }
        }
    }

    // MARK: - 배경 이미지

    @ViewBuilder
    private func cardBackground(size: CGSize) -> some View {
        if let uiImage = UIImage(named: card.imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipped()
        } else {
            // placeholder 배경
            attributeGradient
        }
    }

    private var attributeGradient: some View {
        LinearGradient(
            colors: [attributeColor.opacity(0.8), Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var attributeColor: Color {
        switch card.attribute {
        case .fire: return .red
        case .water: return .blue
        case .wind: return .green
        case .earth: return .brown
        case .thunder: return .yellow
        case .dark: return .purple
        case .light: return .orange
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
                Text("비용: \(card.cost)")
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

            Button(useButtonLabel) {
                onUse()
            }
            .buttonStyle(LiquidGlassButtonStyle(color: canUse ? useButtonColor : .gray))
            .disabled(!canUse)
            .opacity(canUse ? 1.0 : 0.5)
        }
    }

    private var useButtonLabel: String {
        switch card {
        case .monster: return "배치하기"
        case .spell: return "사용하기"
        }
    }

    private var useButtonColor: Color {
        switch card {
        case .monster: return .cyan
        case .spell: return .purple
        }
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

/// 필드 카드 상세보기 (읽기 전용)
struct FieldCardDetailView: View {
    let card: AnyCard
    let onClose: () -> Void

    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 배경 이미지
                cardBackground(size: geo.size)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.3),
                        Color.clear,
                        Color.black.opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: 0) {
                    HStack {
                        Text(card.attribute.emoji + " " + card.attribute.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .liquidGlass(cornerRadius: 20, opacity: 0.5)

                        Spacer()

                        Text(card.rarity.displayName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(rarityColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .liquidGlass(cornerRadius: 20, opacity: 0.5)
                    }
                    .padding(.top, geo.safeAreaInsets.top + 12)

                    Spacer()

                    // 정보 패널
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

                        if !card.flavorText.isEmpty {
                            Text(card.flavorText)
                                .font(.system(size: 13))
                                .italic()
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .liquidGlass(cornerRadius: 16, opacity: 0.5)

                    Button("닫기") {
                        onClose()
                    }
                    .buttonStyle(LiquidGlassButtonStyle(color: .white))
                    .padding(.top, 12)
                    .padding(.bottom, geo.safeAreaInsets.bottom + 16)
                }
                .padding(.horizontal, 20)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                appeared = true
            }
        }
    }

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
                colors: [Color.gray.opacity(0.6), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var rarityColor: Color {
        switch card.rarity {
        case .normal: return .white
        case .rare: return .cyan
        case .superRare: return .yellow
        case .ultraRare: return .orange
        }
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
}

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
        ZStack {
            // 배경 이미지 (풀스크린)
            cardImage
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

            // 상단~중단 그라데이션 (이미지 가독성)
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

            // 콘텐츠 오버레이
            VStack(spacing: 0) {
                // 상단 레어리티 & 속성 배지
                topBadges
                    .padding(.top, 60)

                Spacer()

                // 하단 카드 정보 패널
                infoPanel
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                // 하단 버튼
                actionButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                appeared = true
            }
        }
    }

    // MARK: - 카드 이미지

    private var cardImage: Image {
        if let uiImage = UIImage(named: card.imageName) {
            return Image(uiImage: uiImage)
        }
        // placeholder: 속성 기반 그라데이션 대신 SF Symbol
        return Image(systemName: placeholderSymbol)
    }

    private var placeholderSymbol: String {
        switch card {
        case .monster: return "shield.fill"
        case .spell: return "wand.and.stars"
        }
    }

    // MARK: - 상단 배지

    private var topBadges: some View {
        HStack {
            // 속성
            Text(card.attribute.emoji + " " + card.attribute.displayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .liquidGlass(cornerRadius: 20, opacity: 0.5)

            Spacer()

            // 레어리티
            Text(card.rarity.displayName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(rarityColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .liquidGlass(cornerRadius: 20, opacity: 0.5)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 정보 패널

    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 카드 이름
            Text(card.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            // 카드 타입별 정보
            switch card {
            case .monster(let m):
                monsterInfo(m)
            case .spell(let s):
                spellInfo(s)
            }

            // 비용
            HStack(spacing: 6) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.cyan)
                Text("비용: \(card.cost)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }

            // 플레이버 텍스트
            if !card.flavorText.isEmpty {
                Text(card.flavorText)
                    .font(.system(size: 13, weight: .regular))
                    .italic()
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .liquidGlass(cornerRadius: 16, opacity: 0.5)
    }

    private func monsterInfo(_ m: MonsterCard) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // 타입 + 전투력
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

            // 효과
            if let effect = m.effect {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(.purple)
                    Text(effect.description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
    }

    private func spellInfo(_ s: SpellCard) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // 마법 타입
            HStack(spacing: 4) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 12))
                    .foregroundColor(.purple)
                Text(s.spellType.displayName)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }

            // 효과
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                Text(s.effect.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.85))
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
        ZStack {
            // 배경 이미지
            cardImage
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

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
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                // 정보 패널
                VStack(alignment: .leading, spacing: 10) {
                    Text(card.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

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
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .liquidGlass(cornerRadius: 16, opacity: 0.5)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                Button("닫기") {
                    onClose()
                }
                .buttonStyle(LiquidGlassButtonStyle(color: .white))
                .padding(.bottom, 40)
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                appeared = true
            }
        }
    }

    private var cardImage: Image {
        if let uiImage = UIImage(named: card.imageName) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: card.imageName.isEmpty ? "photo" : card.imageName)
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
            }
        }
    }
}

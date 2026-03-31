import SwiftUI

/// 카드 상세 정보 뷰 (풀스크린 오버레이)
struct CardDetailView: View {
    let card: AnyCard
    let handIndex: Int
    let canUse: Bool
    let onUse: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            // 배경 이미지 (전체화면)
            GeometryReader { geo in
                cardBackground(size: geo.size)
            }
            .ignoresSafeArea()

            // 그라데이션 오버레이 (전체화면)
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

            // 콘텐츠 (safe area 내)
            VStack(spacing: 0) {
                topBadges
                    .padding(.top, 12)

                Spacer()

                infoPanel

                // 하단 버튼: 배치하기(왼쪽) + 닫기(오른쪽)
                HStack(spacing: 12) {
                    actionButton
                    Button {
                        onClose()
                    } label: {
                        Text("닫기")
                    }
                    .buttonStyle(LiquidGlassButtonStyle(color: .red))
                }
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
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
        VStack(spacing: 10) {
            // 섹션 1: 카드명 + 스탯
            nameAndStatsSection

            // 섹션 2: 효과
            switch card {
            case .monster(let m):
                if let effect = m.effect {
                    effectSection(icon: "sparkles", color: .purple, title: "소환 효과", description: effect.description)
                }
            case .spell(let s):
                effectSection(icon: "wand.and.stars", color: .yellow, title: "\(s.spellType.displayName) 효과", description: s.effect.description)
            }

            // 섹션 3: 속성 상성 (몬스터만)
            if case .monster(let m) = card {
                attributeMatchupSection(m)
            }

            // 플레이버 텍스트
            if !card.flavorText.isEmpty {
                Text(card.flavorText)
                    .font(.system(size: 13))
                    .italic()
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var nameAndStatsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(card.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            switch card {
            case .monster(let m):
                HStack(spacing: 8) {
                    statPill(icon: "person.fill", text: m.monsterType.displayName, color: .white.opacity(0.7))
                    statPill(icon: "bolt.fill", text: "전투력 \(m.combatPower)", color: .orange)
                    statPill(icon: "flame.fill", text: "기력 \(m.cost)", color: .cyan)
                }
            case .spell(let s):
                HStack(spacing: 8) {
                    statPill(icon: "wand.and.stars", text: s.spellType.displayName, color: .purple)
                    statPill(icon: "flame.fill", text: "기력 \(s.cost)", color: .cyan)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .liquidGlass(cornerRadius: 14, opacity: 0.5)
    }

    private func statPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(color.opacity(0.15))
        )
    }

    private func effectSection(icon: String, color: Color, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
            }

            Divider().background(color.opacity(0.3))

            Text(description)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .liquidGlass(cornerRadius: 14, opacity: 0.5)
    }

    private func attributeMatchupSection(_ m: MonsterCard) -> some View {
        let attr = m.attribute
        let strong = attr.strongAgainst
        let weak = attr.weakAgainst
        let strongCP = Int(Double(m.combatPower) * attr.damageMultiplier(against: strong))
        let weakCP = Int(Double(m.combatPower) * attr.damageMultiplier(against: weak))
        let isMutual = strong == weak

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                Text("속성 상성")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }

            Divider().background(Color.white.opacity(0.2))

            if isMutual {
                matchupRow(emoji: strong.emoji, text: "\(strong.displayName)과 상호 강화", cp: strongCP, color: .orange)
            } else {
                matchupRow(emoji: strong.emoji, text: "\(strong.displayName)에 강함", cp: strongCP, color: .green)
                matchupRow(emoji: weak.emoji, text: "\(weak.displayName)에 약함", cp: weakCP, color: .red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .liquidGlass(cornerRadius: 14, opacity: 0.5)
    }

    private func matchupRow(emoji: String, text: String, cp: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(color.opacity(0.9))
            Spacer()
            Text("CP \(cp)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(color.opacity(0.9))
        }
    }

    // MARK: - 액션 버튼

    private var actionButton: some View {
        Button(useButtonLabel) {
            onUse()
        }
        .buttonStyle(LiquidGlassButtonStyle(color: canUse ? useButtonColor : .gray))
        .disabled(!canUse)
        .opacity(canUse ? 1.0 : 0.5)
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

/// 필드 카드 상세보기 (읽기 전용, 풀스크린 오버레이)
struct FieldCardDetailView: View {
    let card: AnyCard
    let onClose: () -> Void

    var body: some View {
        ZStack {
            // 배경 이미지 (전체화면)
            GeometryReader { geo in
                cardBackground(size: geo.size)
            }
            .ignoresSafeArea()

            // 그라데이션 오버레이 (전체화면)
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

            // 콘텐츠 (safe area 내)
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
                .padding(.top, 12)

                Spacer()

                // 정보 섹션들
                fieldInfoSections

                // 닫기 버튼
                Button {
                    onClose()
                } label: {
                    Text("닫기")
                }
                .buttonStyle(LiquidGlassButtonStyle(color: .red))
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
        }
    }

    private var fieldInfoSections: some View {
        VStack(spacing: 10) {
            // 섹션 1: 카드명 + 스탯
            VStack(alignment: .leading, spacing: 10) {
                Text(card.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                switch card {
                case .monster(let m):
                    HStack(spacing: 8) {
                        fieldStatPill(icon: "person.fill", text: m.monsterType.displayName, color: .white.opacity(0.7))
                        fieldStatPill(icon: "bolt.fill", text: "전투력 \(m.combatPower)", color: .orange)
                        fieldStatPill(icon: "flame.fill", text: "기력 \(m.cost)", color: .cyan)
                    }
                case .spell(let s):
                    HStack(spacing: 8) {
                        fieldStatPill(icon: "wand.and.stars", text: s.spellType.displayName, color: .purple)
                        fieldStatPill(icon: "flame.fill", text: "기력 \(s.cost)", color: .cyan)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .liquidGlass(cornerRadius: 14, opacity: 0.5)

            // 섹션 2: 효과
            switch card {
            case .monster(let m):
                if let effect = m.effect {
                    fieldEffectSection(icon: "sparkles", color: .purple, title: "소환 효과", description: effect.description)
                }
            case .spell(let s):
                fieldEffectSection(icon: "wand.and.stars", color: .yellow, title: "\(s.spellType.displayName) 효과", description: s.effect.description)
            }

            // 섹션 3: 속성 상성 (몬스터만)
            if case .monster(let m) = card {
                fieldAttributeMatchupSection(m)
            }

            // 플레이버 텍스트
            if !card.flavorText.isEmpty {
                Text(card.flavorText)
                    .font(.system(size: 13))
                    .italic()
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
        }
    }

    private func fieldStatPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.15)))
    }

    private func fieldEffectSection(icon: String, color: Color, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
            }
            Divider().background(color.opacity(0.3))
            Text(description)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .liquidGlass(cornerRadius: 14, opacity: 0.5)
    }

    private func fieldAttributeMatchupSection(_ m: MonsterCard) -> some View {
        let attr = m.attribute
        let strong = attr.strongAgainst
        let weak = attr.weakAgainst
        let strongCP = Int(Double(m.combatPower) * attr.damageMultiplier(against: strong))
        let weakCP = Int(Double(m.combatPower) * attr.damageMultiplier(against: weak))
        let isMutual = strong == weak

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                Text("속성 상성")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            Divider().background(Color.white.opacity(0.2))
            if isMutual {
                fieldMatchupRow(emoji: strong.emoji, text: "\(strong.displayName)과 상호 강화", cp: strongCP, color: .orange)
            } else {
                fieldMatchupRow(emoji: strong.emoji, text: "\(strong.displayName)에 강함", cp: strongCP, color: .green)
                fieldMatchupRow(emoji: weak.emoji, text: "\(weak.displayName)에 약함", cp: weakCP, color: .red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .liquidGlass(cornerRadius: 14, opacity: 0.5)
    }

    private func fieldMatchupRow(emoji: String, text: String, cp: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(color.opacity(0.9))
            Spacer()
            Text("CP \(cp)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(color.opacity(0.9))
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
}

import SwiftUI

// MARK: - 5성 소환 이펙트 종류

enum SummonEffectType {
    case lavaEruption   // 지옥 기사 (화)
    case tidalWave      // 해왕 (수)
    case typhoonStorm   // 태풍룡 (풍)
    case earthquake     // 대지의 제왕 (지)
    case darkVoid       // 암흑룡 (암)
    case holyRadiance   // 대천사 (광)
    case thunderStrike  // 뇌제 라이쥬 (뇌)

    /// 카드 이미지 Asset 이름
    var imageName: String {
        switch self {
        case .lavaEruption:  return "card_inferno_knight"
        case .tidalWave:     return "card_ocean_lord"
        case .typhoonStorm:  return "card_typhoon_dragon"
        case .earthquake:    return "card_earth_emperor"
        case .darkVoid:      return "card_dark_dragon"
        case .holyRadiance:  return "card_archangel"
        case .thunderStrike: return "card_raiju_emperor"
        }
    }

    /// 속성 글로우 색상
    var glowColor: Color {
        switch self {
        case .lavaEruption:  return Color(red: 1, green: 0.3, blue: 0)
        case .tidalWave:     return Color(red: 0.1, green: 0.5, blue: 1)
        case .typhoonStorm:  return Color(red: 0.2, green: 0.9, blue: 0.3)
        case .earthquake:    return Color(red: 0.8, green: 0.6, blue: 0.2)
        case .darkVoid:      return Color(red: 0.6, green: 0.1, blue: 0.9)
        case .holyRadiance:  return Color(red: 1, green: 0.9, blue: 0.4)
        case .thunderStrike: return Color(red: 0.5, green: 0.7, blue: 1)
        }
    }

    /// 비네팅 색상
    var vignetteColors: [Color] {
        switch self {
        case .lavaEruption:
            return [.clear, Color(red: 1, green: 0.1, blue: 0).opacity(0.4), Color(red: 0.6, green: 0, blue: 0).opacity(0.7)]
        case .tidalWave:
            return [.clear, Color(red: 0, green: 0.2, blue: 1).opacity(0.35), Color(red: 0, green: 0.05, blue: 0.5).opacity(0.6)]
        case .typhoonStorm:
            return [.clear, Color(red: 0, green: 0.6, blue: 0.15).opacity(0.3), Color(red: 0, green: 0.3, blue: 0.05).opacity(0.6)]
        case .earthquake:
            return [.clear, Color(red: 0.5, green: 0.35, blue: 0.1).opacity(0.35), Color(red: 0.3, green: 0.15, blue: 0).opacity(0.6)]
        case .darkVoid:
            return [.clear, Color(red: 0.3, green: 0, blue: 0.5).opacity(0.5), Color(red: 0.1, green: 0, blue: 0.15).opacity(0.8)]
        case .holyRadiance:
            return [.clear, Color(red: 1, green: 0.85, blue: 0.4).opacity(0.3), Color(red: 0.8, green: 0.6, blue: 0.1).opacity(0.5)]
        case .thunderStrike:
            return [.clear, Color(red: 0.4, green: 0.6, blue: 1).opacity(0.35), Color(red: 0.2, green: 0.3, blue: 0.7).opacity(0.6)]
        }
    }
}

// MARK: - 시네마틱 소환 오버레이

struct SummonFullscreenOverlay: View {
    let effectType: SummonEffectType

    // 애니메이션 상태
    @State private var darkOverlayOpacity: Double = 0
    @State private var cardScale: CGFloat = 0.15
    @State private var cardBlur: CGFloat = 24
    @State private var cardOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var glowOpacity: Double = 0
    @State private var vignetteOpacity: Double = 0
    @State private var flashOpacity: Double = 0
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1) 어둠 배경
                Color.black
                    .opacity(darkOverlayOpacity)

                // 2) 비네팅
                RadialGradient(
                    gradient: Gradient(colors: effectType.vignetteColors),
                    center: .center,
                    startRadius: geo.size.width * 0.1,
                    endRadius: geo.size.width * 0.7
                )
                .opacity(vignetteOpacity)

                // 3) 카드 이미지
                Image(effectType.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: geo.size.width * 0.65)
                    .scaleEffect(cardScale)
                    .blur(radius: cardBlur)
                    .opacity(cardOpacity)
                    .shadow(color: effectType.glowColor.opacity(glowOpacity), radius: glowRadius)
                    .shadow(color: effectType.glowColor.opacity(glowOpacity * 0.6), radius: glowRadius * 1.5)

                // 4) 임팩트 백색 플래시
                Color.white
                    .opacity(flashOpacity)
            }
        }
        .offset(x: shakeOffset)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            startCinematic()
        }
    }

    private func startCinematic() {
        // === Phase 1: Intro (0 ~ 0.5s) — 어둠 + 카드 먼 곳에서 등장 ===
        withAnimation(.easeIn(duration: 0.3)) {
            darkOverlayOpacity = 0.7
            vignetteOpacity = 0.8
        }
        withAnimation(.easeOut(duration: 0.5)) {
            cardOpacity = 0.6
            cardScale = 0.3
            cardBlur = 18
        }

        // === Phase 2: Zoom (0.5 ~ 1.2s) — 급속 확대 + 선명해짐 + 글로우 ===
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.7)) {
                cardScale = 1.1
                cardBlur = 0
                cardOpacity = 1.0
                glowRadius = 40
                glowOpacity = 0.9
            }
        }

        // === Phase 3: Impact (1.2 ~ 1.5s) — 플래시 + 흔들림 + 오버슈트 ===
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            // 백색 플래시
            withAnimation(.easeIn(duration: 0.08)) {
                flashOpacity = 0.6
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.easeOut(duration: 0.25)) {
                    flashOpacity = 0
                }
            }
            // 카드 오버슈트 → 안정
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                cardScale = 1.0
            }
            // 화면 흔들림
            startImpactShake()
        }

        // === Phase 4: Fade (1.5 ~ 2.0s) — 전부 페이드아웃 ===
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                cardOpacity = 0
                cardScale = 1.3
                glowOpacity = 0
                glowRadius = 60
                darkOverlayOpacity = 0
                vignetteOpacity = 0
            }
        }
    }

    private func startImpactShake() {
        let shakes: [(CGFloat, Double)] = [
            (6, 0.04), (-7, 0.04), (5, 0.04),
            (-4, 0.04), (3, 0.04), (-2, 0.04),
            (1, 0.04), (0, 0.06)
        ]
        var delay: Double = 0
        for (offset, duration) in shakes {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.linear(duration: duration)) {
                    shakeOffset = offset
                }
            }
            delay += duration
        }
    }
}

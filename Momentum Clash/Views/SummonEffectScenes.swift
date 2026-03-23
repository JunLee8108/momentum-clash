import SwiftUI
import SpriteKit

// MARK: - 공용 텍스처 (재사용)
enum ParticleTextures {
    static let glow = LavaEruptionScene.glowTexture
    static let softGlow = LavaEruptionScene.softGlowTexture
}

// MARK: - 5성 소환 이펙트 종류
enum SummonEffectType {
    case lavaEruption   // 지옥 기사 (화)
    case tidalWave      // 해왕 (수)
    case typhoonStorm   // 태풍룡 (풍)
    case earthquake     // 대지의 제왕 (지)
    case darkVoid       // 암흑룡 (암)
    case holyRadiance   // 대천사 (광)
    case thunderStrike  // 뇌제 라이쥬 (뇌)
}

// MARK: - 🌊 해일 씬 (해왕)
class TidalWaveScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.0)
        let w = size.width, h = size.height

        // 파도 안개 (하단)
        let waveMist = makeEmitter(
            texture: ParticleTextures.softGlow,
            birthRate: 30, lifetime: 2.0,
            posRange: CGVector(dx: w * 1.2, dy: 40),
            speed: 20, angle: .pi / 2, angleRange: .pi / 3,
            scale: 2.5, scaleSpeed: 0.2,
            colors: [
                (r: 0.0, g: 0.3, b: 1.0, a: 0.0),
                (r: 0.0, g: 0.5, b: 1.0, a: 0.6),
                (r: 0.0, g: 0.3, b: 0.8, a: 0.4),
                (r: 0.0, g: 0.1, b: 0.5, a: 0.0)
            ]
        )
        waveMist.position = CGPoint(x: 0, y: 0)
        addChild(waveMist)

        // 물방울 (상단 → 하단)
        let drops = makeEmitter(
            texture: ParticleTextures.glow,
            birthRate: 45, lifetime: 1.5,
            posRange: CGVector(dx: w * 1.2, dy: 20),
            speed: 180, angle: -.pi / 2, angleRange: .pi / 6,
            scale: 0.5, scaleSpeed: -0.1,
            colors: [
                (r: 0.6, g: 0.9, b: 1.0, a: 1.0),
                (r: 0.2, g: 0.6, b: 1.0, a: 0.9),
                (r: 0.0, g: 0.3, b: 0.8, a: 0.6),
                (r: 0.0, g: 0.1, b: 0.5, a: 0.0)
            ]
        )
        drops.position = CGPoint(x: 0, y: h)
        drops.yAcceleration = -120
        addChild(drops)

        // 물기둥 (하단 → 상단)
        for xPos in [-w * 0.3, 0, w * 0.3] as [CGFloat] {
            let pillar = makeEmitter(
                texture: ParticleTextures.glow,
                birthRate: 70, lifetime: 0.9,
                posRange: CGVector(dx: 35, dy: 10),
                speed: 220, angle: .pi / 2, angleRange: .pi / 10,
                scale: 0.4, scaleSpeed: -0.2,
                colors: [
                    (r: 0.8, g: 0.95, b: 1.0, a: 1.0),
                    (r: 0.3, g: 0.7, b: 1.0, a: 0.9),
                    (r: 0.0, g: 0.4, b: 0.9, a: 0.6),
                    (r: 0.0, g: 0.1, b: 0.4, a: 0.0)
                ]
            )
            pillar.position = CGPoint(x: xPos, y: 0)
            addChild(pillar)
        }

        scheduleCleanup()
    }
}

// MARK: - 🌪️ 회오리 씬 (태풍룡)
class TyphoonStormScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        let w = size.width, h = size.height

        // 회오리 바람
        let vortex = makeEmitter(
            texture: ParticleTextures.glow,
            birthRate: 80, lifetime: 1.2,
            posRange: CGVector(dx: w * 0.6, dy: h * 0.6),
            speed: 150, angle: 0, angleRange: .pi * 2,
            scale: 0.4, scaleSpeed: -0.2,
            colors: [
                (r: 0.5, g: 1.0, b: 0.5, a: 1.0),
                (r: 0.2, g: 0.8, b: 0.3, a: 0.8),
                (r: 0.1, g: 0.6, b: 0.2, a: 0.5),
                (r: 0.0, g: 0.3, b: 0.1, a: 0.0)
            ]
        )
        addChild(vortex)

        // 바람 줄기 (중앙으로 수렴)
        let streaks = makeEmitter(
            texture: ParticleTextures.softGlow,
            birthRate: 25, lifetime: 1.5,
            posRange: CGVector(dx: w * 1.0, dy: h * 0.8),
            speed: 100, angle: .pi, angleRange: .pi / 4,
            scale: 1.5, scaleSpeed: -0.5,
            colors: [
                (r: 0.3, g: 0.9, b: 0.4, a: 0.0),
                (r: 0.2, g: 0.8, b: 0.3, a: 0.5),
                (r: 0.1, g: 0.5, b: 0.2, a: 0.3),
                (r: 0.0, g: 0.2, b: 0.1, a: 0.0)
            ]
        )
        addChild(streaks)

        // 나뭇잎/파편
        let debris = makeEmitter(
            texture: ParticleTextures.glow,
            birthRate: 40, lifetime: 0.8,
            posRange: CGVector(dx: w * 0.3, dy: h * 0.3),
            speed: 250, angle: 0, angleRange: .pi * 2,
            scale: 0.2, scaleSpeed: -0.15
        )
        debris.particleColor = SKColor(red: 0.4, green: 1.0, blue: 0.5, alpha: 1.0)
        debris.particleAlphaSpeed = -1.2
        addChild(debris)

        scheduleCleanup()
    }
}

// MARK: - ⛰️ 지진 씬 (대지의 제왕)
class EarthquakeScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.0)
        let w = size.width, h = size.height

        // 대지 균열 파편 (하단에서 사방으로)
        let shatter = makeEmitter(
            texture: ParticleTextures.glow,
            birthRate: 70, lifetime: 1.0,
            posRange: CGVector(dx: w * 0.8, dy: 20),
            speed: 200, angle: .pi / 2, angleRange: .pi / 3,
            scale: 0.5, scaleSpeed: -0.3,
            colors: [
                (r: 0.9, g: 0.7, b: 0.3, a: 1.0),
                (r: 0.7, g: 0.5, b: 0.2, a: 0.9),
                (r: 0.5, g: 0.3, b: 0.1, a: 0.6),
                (r: 0.3, g: 0.15, b: 0.05, a: 0.0)
            ]
        )
        shatter.position = CGPoint(x: 0, y: 0)
        shatter.yAcceleration = -100
        addChild(shatter)

        // 먼지 구름
        let dust = makeEmitter(
            texture: ParticleTextures.softGlow,
            birthRate: 20, lifetime: 2.0,
            posRange: CGVector(dx: w * 1.2, dy: 30),
            speed: 10, angle: .pi / 2, angleRange: .pi / 2,
            scale: 3.0, scaleSpeed: 0.5,
            colors: [
                (r: 0.6, g: 0.45, b: 0.2, a: 0.0),
                (r: 0.5, g: 0.35, b: 0.15, a: 0.4),
                (r: 0.4, g: 0.25, b: 0.1, a: 0.3),
                (r: 0.3, g: 0.15, b: 0.05, a: 0.0)
            ]
        )
        dust.position = CGPoint(x: 0, y: h * 0.2)
        addChild(dust)

        // 암석 파편
        let rocks = makeEmitter(
            texture: ParticleTextures.glow,
            birthRate: 50, lifetime: 0.7,
            posRange: CGVector(dx: w * 0.5, dy: 10),
            speed: 300, angle: .pi / 2, angleRange: .pi / 5,
            scale: 0.3, scaleSpeed: -0.2
        )
        rocks.particleColor = SKColor(red: 0.6, green: 0.4, blue: 0.15, alpha: 1.0)
        rocks.particleAlphaSpeed = -1.0
        rocks.yAcceleration = -200
        rocks.position = CGPoint(x: 0, y: 0)
        addChild(rocks)

        scheduleCleanup()
    }
}

// MARK: - 🌑 암흑 안개 씬 (암흑룡)
class DarkVoidScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        let w = size.width, h = size.height

        // 암흑 안개 (중앙에서 퍼짐)
        let void = makeEmitter(
            texture: ParticleTextures.softGlow,
            birthRate: 30, lifetime: 2.0,
            posRange: CGVector(dx: w * 0.3, dy: h * 0.3),
            speed: 30, angle: 0, angleRange: .pi * 2,
            scale: 3.0, scaleSpeed: 0.5,
            colors: [
                (r: 0.3, g: 0.0, b: 0.5, a: 0.0),
                (r: 0.2, g: 0.0, b: 0.4, a: 0.6),
                (r: 0.1, g: 0.0, b: 0.3, a: 0.4),
                (r: 0.05, g: 0.0, b: 0.1, a: 0.0)
            ]
        )
        addChild(void)

        // 보라색 스파크
        let sparks = makeEmitter(
            texture: ParticleTextures.glow,
            birthRate: 50, lifetime: 0.8,
            posRange: CGVector(dx: w * 0.6, dy: h * 0.5),
            speed: 120, angle: 0, angleRange: .pi * 2,
            scale: 0.25, scaleSpeed: -0.2,
            colors: [
                (r: 0.8, g: 0.3, b: 1.0, a: 1.0),
                (r: 0.5, g: 0.1, b: 0.8, a: 0.8),
                (r: 0.3, g: 0.0, b: 0.5, a: 0.4),
                (r: 0.1, g: 0.0, b: 0.2, a: 0.0)
            ]
        )
        addChild(sparks)

        // 검은 입자 (중력 없이 부유)
        let darkParticles = makeEmitter(
            texture: ParticleTextures.glow,
            birthRate: 35, lifetime: 1.5,
            posRange: CGVector(dx: w * 0.8, dy: h * 0.6),
            speed: 40, angle: .pi / 2, angleRange: .pi * 2,
            scale: 0.5, scaleSpeed: 0.1
        )
        darkParticles.particleColor = SKColor(red: 0.15, green: 0.0, blue: 0.25, alpha: 1.0)
        darkParticles.particleAlphaSpeed = -0.8
        addChild(darkParticles)

        scheduleCleanup()
    }
}

// MARK: - ✨ 빛 기둥 씬 (대천사)
class HolyRadianceScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.0)
        let w = size.width, h = size.height

        // 빛 기둥 (상단에서 쏟아짐)
        let lightBeam = makeEmitter(
            texture: ParticleTextures.softGlow,
            birthRate: 25, lifetime: 1.8,
            posRange: CGVector(dx: w * 0.4, dy: 10),
            speed: 150, angle: -.pi / 2, angleRange: .pi / 12,
            scale: 2.0, scaleSpeed: 0.3,
            colors: [
                (r: 1.0, g: 0.95, b: 0.7, a: 1.0),
                (r: 1.0, g: 0.85, b: 0.4, a: 0.8),
                (r: 1.0, g: 0.7, b: 0.2, a: 0.5),
                (r: 0.8, g: 0.5, b: 0.1, a: 0.0)
            ]
        )
        lightBeam.position = CGPoint(x: 0, y: h)
        addChild(lightBeam)

        // 금색 입자 (전체 화면 부유)
        let goldDust = makeEmitter(
            texture: ParticleTextures.glow,
            birthRate: 60, lifetime: 1.2,
            posRange: CGVector(dx: w * 1.0, dy: h * 0.8),
            speed: 50, angle: .pi / 2, angleRange: .pi * 2,
            scale: 0.3, scaleSpeed: -0.1,
            colors: [
                (r: 1.0, g: 0.9, b: 0.5, a: 1.0),
                (r: 1.0, g: 0.8, b: 0.3, a: 0.8),
                (r: 0.9, g: 0.6, b: 0.1, a: 0.4),
                (r: 0.5, g: 0.3, b: 0.0, a: 0.0)
            ]
        )
        goldDust.position = CGPoint(x: 0, y: h * 0.5)
        addChild(goldDust)

        // 흰색 깜빡임
        let flare = makeEmitter(
            texture: ParticleTextures.glow,
            birthRate: 20, lifetime: 0.6,
            posRange: CGVector(dx: w * 0.6, dy: h * 0.5),
            speed: 10, angle: 0, angleRange: .pi * 2,
            scale: 0.8, scaleSpeed: -0.5
        )
        flare.particleColor = SKColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 1.0)
        flare.particleAlphaSpeed = -1.5
        flare.position = CGPoint(x: 0, y: h * 0.5)
        addChild(flare)

        scheduleCleanup()
    }
}

// MARK: - ⚡ 낙뢰 씬 (뇌제 라이쥬)
class ThunderStrikeScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.0)
        let w = size.width, h = size.height

        // 번개 줄기 (상단 → 하단)
        for xOffset in [-w * 0.2, w * 0.05, w * 0.25] as [CGFloat] {
            let bolt = makeEmitter(
                texture: ParticleTextures.glow,
                birthRate: 100, lifetime: 0.5,
                posRange: CGVector(dx: 15, dy: h * 0.8),
                speed: 300, angle: -.pi / 2, angleRange: .pi / 15,
                scale: 0.3, scaleSpeed: -0.3,
                colors: [
                    (r: 1.0, g: 1.0, b: 0.9, a: 1.0),
                    (r: 1.0, g: 0.95, b: 0.5, a: 0.9),
                    (r: 0.7, g: 0.8, b: 1.0, a: 0.6),
                    (r: 0.3, g: 0.5, b: 1.0, a: 0.0)
                ]
            )
            bolt.position = CGPoint(x: xOffset, y: h * 0.8)
            addChild(bolt)
        }

        // 전기 스파크 (중앙)
        let sparks = makeEmitter(
            texture: ParticleTextures.glow,
            birthRate: 70, lifetime: 0.6,
            posRange: CGVector(dx: w * 0.5, dy: h * 0.3),
            speed: 200, angle: 0, angleRange: .pi * 2,
            scale: 0.2, scaleSpeed: -0.15
        )
        sparks.particleColor = SKColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
        sparks.particleAlphaSpeed = -1.5
        sparks.position = CGPoint(x: 0, y: h * 0.4)
        addChild(sparks)

        // 노란 글로우 (하단 충격파)
        let impact = makeEmitter(
            texture: ParticleTextures.softGlow,
            birthRate: 20, lifetime: 1.5,
            posRange: CGVector(dx: w * 0.8, dy: 20),
            speed: 15, angle: .pi / 2, angleRange: .pi / 2,
            scale: 2.0, scaleSpeed: 0.3,
            colors: [
                (r: 1.0, g: 1.0, b: 0.5, a: 0.0),
                (r: 1.0, g: 0.9, b: 0.3, a: 0.5),
                (r: 0.7, g: 0.7, b: 0.2, a: 0.3),
                (r: 0.3, g: 0.3, b: 0.1, a: 0.0)
            ]
        )
        impact.position = CGPoint(x: 0, y: 0)
        addChild(impact)

        scheduleCleanup()
    }
}

// MARK: - SKScene 헬퍼

extension SKScene {
    typealias RGBA = (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)

    func makeEmitter(
        texture: SKTexture,
        birthRate: CGFloat,
        lifetime: CGFloat,
        posRange: CGVector,
        speed: CGFloat,
        angle: CGFloat,
        angleRange: CGFloat,
        scale: CGFloat,
        scaleSpeed: CGFloat,
        colors: [RGBA]? = nil
    ) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = texture
        e.particleBirthRate = birthRate
        e.particleLifetime = lifetime
        e.particleLifetimeRange = lifetime * 0.2
        e.particlePositionRange = posRange
        e.particleSpeed = speed
        e.particleSpeedRange = speed * 0.3
        e.emissionAngle = angle
        e.emissionAngleRange = angleRange
        e.particleScale = scale
        e.particleScaleRange = scale * 0.3
        e.particleScaleSpeed = scaleSpeed
        e.particleBlendMode = .add

        if let colors = colors, colors.count >= 4 {
            let seq = SKKeyframeSequence(
                keyframeValues: colors.map { SKColor(red: $0.r, green: $0.g, blue: $0.b, alpha: $0.a) },
                times: [0.0, 0.25, 0.6, 1.0]
            )
            e.particleColorSequence = seq
        }

        return e
    }

    func scheduleCleanup() {
        let allEmitters = children.compactMap { $0 as? SKEmitterNode }
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.2),
            SKAction.run {
                for emitter in allEmitters {
                    emitter.particleBirthRate = 0
                }
            },
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                self?.removeAllChildren()
            }
        ]))
    }
}

// MARK: - 범용 풀스크린 소환 오버레이

struct SummonFullscreenOverlay: View {
    let effectType: SummonEffectType
    @State private var shakeOffset: CGFloat = 0
    @State private var vignetteOpacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SpriteView(
                    scene: makeScene(size: geo.size),
                    options: [.allowsTransparency]
                )
                .allowsHitTesting(false)

                // 비네팅
                RadialGradient(
                    gradient: Gradient(colors: vignetteColors),
                    center: .center,
                    startRadius: geo.size.width * 0.2,
                    endRadius: geo.size.width * 0.8
                )
                .opacity(vignetteOpacity)
                .allowsHitTesting(false)
            }
        }
        .offset(x: shakeOffset)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                vignetteOpacity = 1.0
            }
            startShake()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    vignetteOpacity = 0
                }
            }
        }
    }

    private func makeScene(size: CGSize) -> SKScene {
        let scene: SKScene
        switch effectType {
        case .lavaEruption:
            scene = LavaEruptionScene()
        case .tidalWave:
            scene = TidalWaveScene()
        case .typhoonStorm:
            scene = TyphoonStormScene()
        case .earthquake:
            scene = EarthquakeScene()
        case .darkVoid:
            scene = DarkVoidScene()
        case .holyRadiance:
            scene = HolyRadianceScene()
        case .thunderStrike:
            scene = ThunderStrikeScene()
        }
        scene.size = size
        scene.backgroundColor = .clear
        return scene
    }

    private var vignetteColors: [Color] {
        switch effectType {
        case .lavaEruption:
            return [.clear, Color(red: 1, green: 0.1, blue: 0).opacity(0.3), Color(red: 0.8, green: 0, blue: 0).opacity(0.5)]
        case .tidalWave:
            return [.clear, Color(red: 0, green: 0.2, blue: 1).opacity(0.3), Color(red: 0, green: 0.1, blue: 0.7).opacity(0.5)]
        case .typhoonStorm:
            return [.clear, Color(red: 0, green: 0.8, blue: 0.2).opacity(0.3), Color(red: 0, green: 0.5, blue: 0.1).opacity(0.5)]
        case .earthquake:
            return [.clear, Color(red: 0.6, green: 0.4, blue: 0.1).opacity(0.3), Color(red: 0.4, green: 0.25, blue: 0.05).opacity(0.5)]
        case .darkVoid:
            return [.clear, Color(red: 0.3, green: 0, blue: 0.5).opacity(0.4), Color(red: 0.1, green: 0, blue: 0.2).opacity(0.6)]
        case .holyRadiance:
            return [.clear, Color(red: 1, green: 0.9, blue: 0.5).opacity(0.25), Color(red: 1, green: 0.8, blue: 0.3).opacity(0.4)]
        case .thunderStrike:
            return [.clear, Color(red: 0.8, green: 0.9, blue: 1).opacity(0.3), Color(red: 0.5, green: 0.6, blue: 1).opacity(0.5)]
        }
    }

    private func startShake() {
        let shakeCount = 8
        let interval = 0.06
        for i in 0..<shakeCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                withAnimation(.linear(duration: interval)) {
                    shakeOffset = CGFloat.random(in: -4...4)
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(shakeCount) * interval) {
            withAnimation(.easeOut(duration: 0.1)) {
                shakeOffset = 0
            }
        }
    }
}

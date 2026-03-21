import SwiftUI
import SpriteKit

// MARK: - 용암 분출 SpriteKit 씬 (풀스크린)

class LavaEruptionScene: SKScene {

    // MARK: - 코드 생성 텍스처

    /// 원형 그라디언트 (범용 파티클)
    static let glowTexture: SKTexture = {
        let size: CGFloat = 32
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor.white.cgColor,
                    UIColor.white.withAlphaComponent(0.6).cgColor,
                    UIColor.white.withAlphaComponent(0).cgColor
                ] as CFArray,
                locations: [0.0, 0.4, 1.0]
            )!
            let center = CGPoint(x: size / 2, y: size / 2)
            ctx.cgContext.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: size / 2,
                options: .drawsAfterEndLocation
            )
        }
        return SKTexture(image: image)
    }()

    /// 큰 소프트 원형 (용암 안개용)
    static let softGlowTexture: SKTexture = {
        let size: CGFloat = 64
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor.white.withAlphaComponent(0.8).cgColor,
                    UIColor.white.withAlphaComponent(0.3).cgColor,
                    UIColor.white.withAlphaComponent(0).cgColor
                ] as CFArray,
                locations: [0.0, 0.5, 1.0]
            )!
            let center = CGPoint(x: size / 2, y: size / 2)
            ctx.cgContext.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: size / 2,
                options: .drawsAfterEndLocation
            )
        }
        return SKTexture(image: image)
    }()

    // MARK: - 씬 라이프사이클

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.0)

        let w = size.width
        let h = size.height

        // 1) 화면 하단 용암 안개
        let lavaMist = createLavaMistEmitter(width: w)
        lavaMist.position = CGPoint(x: 0, y: 0)
        lavaMist.zPosition = 0
        addChild(lavaMist)

        // 2) 화면 상단에서 떨어지는 용암 방울
        let lavaDrops = createLavaDropEmitter(width: w, height: h)
        lavaDrops.position = CGPoint(x: 0, y: h)
        lavaDrops.zPosition = 1
        addChild(lavaDrops)

        // 3) 화염 기둥 3개 (좌/중/우)
        let positions: [CGFloat] = [-w * 0.3, 0, w * 0.3]
        var firePillars: [SKEmitterNode] = []
        for xPos in positions {
            let pillar = createFirePillarEmitter(height: h)
            pillar.position = CGPoint(x: xPos, y: 0)
            pillar.zPosition = 2
            addChild(pillar)
            firePillars.append(pillar)
        }

        // 4) 사방으로 튀는 열기 파편
        let sparks = createHeatSparkEmitter(width: w, height: h)
        sparks.position = CGPoint(x: 0, y: h * 0.3)
        sparks.zPosition = 3
        addChild(sparks)

        // 타이밍: 1.2초 분출 → 방출 정지 → 0.8초 잔여 소멸
        let allEmitters = [lavaMist, lavaDrops, sparks] + firePillars
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

    // MARK: - 이미터 생성

    /// 용암 안개: 하단에 깔리는 붉은 열기
    private func createLavaMistEmitter(width: CGFloat) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = Self.softGlowTexture

        e.particleBirthRate = 25
        e.particleLifetime = 1.8
        e.particleLifetimeRange = 0.4

        e.particlePositionRange = CGVector(dx: width * 1.2, dy: 30)

        e.particleSpeed = 15
        e.particleSpeedRange = 10
        e.emissionAngle = .pi / 2
        e.emissionAngleRange = .pi / 3

        e.particleScale = 2.5
        e.particleScaleRange = 1.0
        e.particleScaleSpeed = 0.3

        let colors = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 0.0),
                SKColor(red: 1.0, green: 0.2, blue: 0.0, alpha: 0.5),
                SKColor(red: 0.8, green: 0.1, blue: 0.0, alpha: 0.4),
                SKColor(red: 0.4, green: 0.05, blue: 0.0, alpha: 0.0)
            ],
            times: [0.0, 0.2, 0.6, 1.0]
        )
        e.particleColorSequence = colors
        e.particleBlendMode = .add

        return e
    }

    /// 용암 방울: 상단에서 아래로 떨어짐
    private func createLavaDropEmitter(width: CGFloat, height: CGFloat) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = Self.glowTexture

        e.particleBirthRate = 50
        e.particleLifetime = 1.4
        e.particleLifetimeRange = 0.4

        e.particlePositionRange = CGVector(dx: width * 1.2, dy: 20)

        // 아래로 떨어짐
        e.particleSpeed = 200
        e.particleSpeedRange = 100
        e.emissionAngle = -.pi / 2      // 아래 방향
        e.emissionAngleRange = .pi / 8

        e.yAcceleration = -150           // 중력 가속

        e.particleScale = 0.6
        e.particleScaleRange = 0.4
        e.particleScaleSpeed = -0.1

        let colors = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0),   // 밝은 노랑 (핵)
                SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.9),   // 주황
                SKColor(red: 0.9, green: 0.2, blue: 0.0, alpha: 0.7),   // 붉은 용암
                SKColor(red: 0.5, green: 0.05, blue: 0.0, alpha: 0.0)   // 검붉은 소멸
            ],
            times: [0.0, 0.2, 0.5, 1.0]
        )
        e.particleColorSequence = colors
        e.particleBlendMode = .add

        return e
    }

    /// 화염 기둥: 하단에서 위로 솟구침
    private func createFirePillarEmitter(height: CGFloat) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = Self.glowTexture

        e.particleBirthRate = 80
        e.particleLifetime = 0.8
        e.particleLifetimeRange = 0.3

        e.particlePositionRange = CGVector(dx: 40, dy: 10)

        e.particleSpeed = 250
        e.particleSpeedRange = 80
        e.emissionAngle = .pi / 2       // 위쪽
        e.emissionAngleRange = .pi / 10  // 좁은 퍼짐 → 기둥 형태

        e.particleScale = 0.5
        e.particleScaleRange = 0.3
        e.particleScaleSpeed = -0.3

        let colors = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1.0),  // 뜨거운 백색~노랑
                SKColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 0.9),   // 주황
                SKColor(red: 1.0, green: 0.25, blue: 0.0, alpha: 0.6),  // 빨강
                SKColor(red: 0.3, green: 0.05, blue: 0.0, alpha: 0.0)   // 소멸
            ],
            times: [0.0, 0.25, 0.6, 1.0]
        )
        e.particleColorSequence = colors
        e.particleBlendMode = .add

        return e
    }

    /// 열기 파편: 사방으로 튀는 스파크
    private func createHeatSparkEmitter(width: CGFloat, height: CGFloat) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = Self.glowTexture

        e.particleBirthRate = 60
        e.particleLifetime = 0.6
        e.particleLifetimeRange = 0.3

        e.particlePositionRange = CGVector(dx: width * 0.6, dy: height * 0.3)

        e.particleSpeed = 180
        e.particleSpeedRange = 100
        e.emissionAngle = 0
        e.emissionAngleRange = .pi * 2   // 전방향

        e.particleScale = 0.2
        e.particleScaleRange = 0.15
        e.particleScaleSpeed = -0.2

        e.particleColor = SKColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0)
        e.particleAlpha = 1.0
        e.particleAlphaSpeed = -1.5

        e.particleBlendMode = .add

        return e
    }
}

// MARK: - SwiftUI 풀스크린 용암 오버레이

struct LavaFullscreenOverlay: View {
    @State private var shakeOffset: CGFloat = 0
    @State private var vignetteOpacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // SpriteKit 용암 파티클
                SpriteView(
                    scene: makeScene(size: geo.size),
                    options: [.allowsTransparency]
                )
                .allowsHitTesting(false)

                // 붉은 비네팅 (가장자리 붉은 빛)
                RadialGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        Color(red: 1, green: 0.1, blue: 0).opacity(0.3),
                        Color(red: 0.8, green: 0, blue: 0).opacity(0.5)
                    ]),
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
            // 비네팅 페이드인
            withAnimation(.easeIn(duration: 0.3)) {
                vignetteOpacity = 1.0
            }
            // 화면 흔들림
            startShake()
            // 1.5초 후 비네팅 페이드아웃
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    vignetteOpacity = 0
                }
            }
        }
    }

    private func makeScene(size: CGSize) -> LavaEruptionScene {
        let scene = LavaEruptionScene()
        scene.size = size
        scene.backgroundColor = .clear
        return scene
    }

    private func startShake() {
        // 0.5초 동안 빠른 진동
        let shakeCount = 8
        let interval = 0.06
        for i in 0..<shakeCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                withAnimation(.linear(duration: interval)) {
                    shakeOffset = CGFloat.random(in: -4...4)
                }
            }
        }
        // 원위치
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(shakeCount) * interval) {
            withAnimation(.easeOut(duration: 0.1)) {
                shakeOffset = 0
            }
        }
    }
}

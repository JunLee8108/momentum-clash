import SwiftUI
import SpriteKit

/// 화염 파티클 SpriteKit 씬
class FireParticleScene: SKScene {

    /// 코드로 생성한 원형 스파크 텍스처
    static let sparkTexture: SKTexture = {
        let size: CGFloat = 16
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray,
                locations: [0.0, 1.0]
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

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.0)

        // 메인 불꽃 이미터
        let fire = createFireEmitter()
        fire.position = CGPoint(x: 0, y: 10)
        addChild(fire)

        // 스파크 (작은 불씨)
        let sparks = createSparkEmitter()
        sparks.position = CGPoint(x: 0, y: 20)
        addChild(sparks)

        // 0.8초 후 방출 중지 → 자연 소멸
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.run {
                fire.particleBirthRate = 0
                sparks.particleBirthRate = 0
            },
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                self?.removeAllChildren()
            }
        ]))
    }

    /// 메인 화염 파티클
    private func createFireEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // 텍스처: 내장 원형
        emitter.particleTexture = FireParticleScene.sparkTexture

        // 생성
        emitter.particleBirthRate = 120
        emitter.numParticlesToEmit = 0  // 무제한 (birthRate = 0 으로 정지)
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.2

        // 위치 범위
        emitter.particlePositionRange = CGVector(dx: 50, dy: 10)

        // 속도 (위로 상승)
        emitter.particleSpeed = 80
        emitter.particleSpeedRange = 40
        emitter.emissionAngle = .pi / 2          // 위쪽
        emitter.emissionAngleRange = .pi / 6     // ±30도 퍼짐

        // 크기
        emitter.particleScale = 0.4
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = -0.3        // 점점 작아짐

        // 색상 시퀀스: 주황 → 빨강 → 투명
        let colorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0),   // 밝은 주황
                SKColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 0.9),   // 주황
                SKColor(red: 0.8, green: 0.15, blue: 0.05, alpha: 0.6), // 빨강
                SKColor(red: 0.4, green: 0.05, blue: 0.0, alpha: 0.0)   // 소멸
            ],
            times: [0.0, 0.3, 0.6, 1.0]
        )
        emitter.particleColorSequence = colorSequence

        // 알파
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.8

        // 블렌드 모드
        emitter.particleBlendMode = .add

        return emitter
    }

    /// 스파크 (작은 불씨 입자)
    private func createSparkEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()

        emitter.particleTexture = FireParticleScene.sparkTexture

        emitter.particleBirthRate = 40
        emitter.particleLifetime = 0.4
        emitter.particleLifetimeRange = 0.2

        emitter.particlePositionRange = CGVector(dx: 60, dy: 5)

        emitter.particleSpeed = 120
        emitter.particleSpeedRange = 60
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 4

        emitter.particleScale = 0.15
        emitter.particleScaleRange = 0.1
        emitter.particleScaleSpeed = -0.2

        emitter.particleColor = SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0)
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -2.0

        emitter.particleBlendMode = .add

        return emitter
    }
}

/// SwiftUI에서 사용할 화염 파티클 오버레이
struct FireParticleOverlay: View {
    var body: some View {
        SpriteView(scene: makeScene(), options: [.allowsTransparency])
            .allowsHitTesting(false)
    }

    private func makeScene() -> FireParticleScene {
        let scene = FireParticleScene()
        scene.size = CGSize(width: 90, height: 120)
        scene.backgroundColor = .clear
        return scene
    }
}

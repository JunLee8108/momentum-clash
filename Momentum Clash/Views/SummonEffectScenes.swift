import SwiftUI
import SceneKit

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

// MARK: - 3D 파티클 헬퍼

private func makeParticleSystem(
    birthRate: CGFloat,
    lifetime: CGFloat,
    velocity: CGFloat,
    size: CGFloat,
    color: UIColor,
    endColor: UIColor,
    spread: CGFloat = .pi / 4,
    blendMode: SCNParticleSystem.BlendMode = .additive
) -> SCNParticleSystem {
    let ps = SCNParticleSystem()
    ps.birthRate = birthRate
    ps.particleLifeSpan = lifetime
    ps.particleLifeSpanVariation = lifetime * 0.3
    ps.particleVelocity = velocity
    ps.particleVelocityVariation = velocity * 0.3
    ps.particleSize = size
    ps.particleSizeVariation = size * 0.3
    ps.particleColor = color
    ps.spreadingAngle = spread
    ps.blendMode = blendMode
    ps.isAffectedByGravity = false
    ps.isAffectedByPhysicsFields = false

    // 색상 변화
    let colorAnim = CAKeyframeAnimation()
    colorAnim.values = [color, endColor]
    colorAnim.keyTimes = [0.0, 1.0]
    colorAnim.duration = CFTimeInterval(lifetime)
    let controller = SCNParticlePropertyController(animation: colorAnim)
    ps.propertyControllers = [.color: controller]

    return ps
}

private func makeSphereNode(
    radius: CGFloat,
    color: UIColor,
    emission: UIColor,
    transparency: CGFloat = 0.6,
    position: SCNVector3 = SCNVector3(0, 0, 0)
) -> SCNNode {
    let sphere = SCNSphere(radius: radius)
    let mat = SCNMaterial()
    mat.diffuse.contents = color
    mat.emission.contents = emission
    mat.transparency = transparency
    mat.isDoubleSided = true
    sphere.materials = [mat]
    let node = SCNNode(geometry: sphere)
    node.position = position
    return node
}

// MARK: - 🔥 용암 분출 (화)

private func buildLavaEruptionScene() -> SCNScene {
    let scene = SCNScene()

    // 카메라
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(0, 2, 8)
    cameraNode.look(at: SCNVector3(0, 1, 0))
    scene.rootNode.addChildNode(cameraNode)

    // 조명
    let light = SCNNode()
    light.light = SCNLight()
    light.light!.type = .omni
    light.light!.color = UIColor(red: 1, green: 0.3, blue: 0, alpha: 1)
    light.light!.intensity = 2000
    light.position = SCNVector3(0, 3, 2)
    scene.rootNode.addChildNode(light)

    // 용암 구체 (중앙)
    let core = makeSphereNode(
        radius: 0.8,
        color: UIColor(red: 1, green: 0.2, blue: 0, alpha: 1),
        emission: UIColor(red: 1, green: 0.5, blue: 0, alpha: 1),
        transparency: 0.7
    )
    core.position = SCNVector3(0, 0, 0)
    scene.rootNode.addChildNode(core)

    // 구체 맥동
    let pulse = SCNAction.sequence([
        SCNAction.scale(to: 1.3, duration: 0.4),
        SCNAction.scale(to: 0.9, duration: 0.3),
        SCNAction.scale(to: 1.1, duration: 0.3)
    ])
    core.runAction(SCNAction.repeatForever(pulse))

    // 화염 기둥 파티클 3개
    for xPos in [-1.5, 0.0, 1.5] as [Float] {
        let ps = makeParticleSystem(
            birthRate: 150, lifetime: 1.2, velocity: 5, size: 0.15,
            color: UIColor(red: 1, green: 0.9, blue: 0.3, alpha: 1),
            endColor: UIColor(red: 0.8, green: 0.1, blue: 0, alpha: 0),
            spread: 15
        )
        ps.emittingDirection = SCNVector3(0, 1, 0)
        ps.isAffectedByGravity = false

        let pillarNode = SCNNode()
        pillarNode.position = SCNVector3(xPos, -2, 0)
        pillarNode.addParticleSystem(ps)
        scene.rootNode.addChildNode(pillarNode)
    }

    // 용암 스파크 (사방)
    let sparks = makeParticleSystem(
        birthRate: 80, lifetime: 0.8, velocity: 8, size: 0.06,
        color: UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 1),
        endColor: UIColor(red: 0.5, green: 0.05, blue: 0, alpha: 0),
        spread: 180
    )
    sparks.isAffectedByGravity = true
    core.addParticleSystem(sparks)

    // 용암 안개 (하단)
    let mist = makeParticleSystem(
        birthRate: 30, lifetime: 2, velocity: 1, size: 0.8,
        color: UIColor(red: 1, green: 0.3, blue: 0, alpha: 0.4),
        endColor: UIColor(red: 0.4, green: 0.05, blue: 0, alpha: 0),
        spread: 90
    )
    let mistNode = SCNNode()
    mistNode.position = SCNVector3(0, -2, 0)
    mistNode.addParticleSystem(mist)
    scene.rootNode.addChildNode(mistNode)

    scheduleCleanup(scene: scene)
    return scene
}

// MARK: - 🌊 해일 (수)

private func buildTidalWaveScene() -> SCNScene {
    let scene = SCNScene()

    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(0, 2, 8)
    cameraNode.look(at: SCNVector3(0, 0, 0))
    scene.rootNode.addChildNode(cameraNode)

    let light = SCNNode()
    light.light = SCNLight()
    light.light!.type = .omni
    light.light!.color = UIColor(red: 0, green: 0.4, blue: 1, alpha: 1)
    light.light!.intensity = 2000
    light.position = SCNVector3(0, 3, 3)
    scene.rootNode.addChildNode(light)

    // 물 구체 (중앙)
    let waterCore = makeSphereNode(
        radius: 1.0,
        color: UIColor(red: 0, green: 0.3, blue: 0.9, alpha: 1),
        emission: UIColor(red: 0.2, green: 0.6, blue: 1, alpha: 1),
        transparency: 0.5
    )
    scene.rootNode.addChildNode(waterCore)

    let wobble = SCNAction.sequence([
        SCNAction.scale(to: 1.2, duration: 0.5),
        SCNAction.scale(to: 0.85, duration: 0.4),
        SCNAction.scale(to: 1.1, duration: 0.3)
    ])
    waterCore.runAction(SCNAction.repeatForever(wobble))

    // 물기둥 (아래에서 위로)
    for xPos in [-1.2, 0.0, 1.2] as [Float] {
        let ps = makeParticleSystem(
            birthRate: 120, lifetime: 1.0, velocity: 6, size: 0.12,
            color: UIColor(red: 0.6, green: 0.9, blue: 1, alpha: 1),
            endColor: UIColor(red: 0, green: 0.2, blue: 0.6, alpha: 0),
            spread: 12
        )
        ps.emittingDirection = SCNVector3(0, 1, 0)
        let node = SCNNode()
        node.position = SCNVector3(xPos, -2.5, 0)
        node.addParticleSystem(ps)
        scene.rootNode.addChildNode(node)
    }

    // 물방울 (위에서 아래로)
    let drops = makeParticleSystem(
        birthRate: 60, lifetime: 1.5, velocity: 4, size: 0.08,
        color: UIColor(red: 0.7, green: 0.95, blue: 1, alpha: 1),
        endColor: UIColor(red: 0, green: 0.1, blue: 0.5, alpha: 0),
        spread: 30
    )
    drops.emittingDirection = SCNVector3(0, -1, 0)
    drops.isAffectedByGravity = true
    let dropNode = SCNNode()
    dropNode.position = SCNVector3(0, 4, 0)
    dropNode.addParticleSystem(drops)
    scene.rootNode.addChildNode(dropNode)

    // 파도 안개
    let waveMist = makeParticleSystem(
        birthRate: 25, lifetime: 2, velocity: 1, size: 0.7,
        color: UIColor(red: 0, green: 0.4, blue: 1, alpha: 0.4),
        endColor: UIColor(red: 0, green: 0.1, blue: 0.3, alpha: 0),
        spread: 90
    )
    let mistNode = SCNNode()
    mistNode.position = SCNVector3(0, -2, 0)
    mistNode.addParticleSystem(waveMist)
    scene.rootNode.addChildNode(mistNode)

    scheduleCleanup(scene: scene)
    return scene
}

// MARK: - 🌪️ 회오리 (풍)

private func buildTyphoonStormScene() -> SCNScene {
    let scene = SCNScene()

    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(0, 2, 8)
    cameraNode.look(at: SCNVector3(0, 0, 0))
    scene.rootNode.addChildNode(cameraNode)

    let light = SCNNode()
    light.light = SCNLight()
    light.light!.type = .omni
    light.light!.color = UIColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 1)
    light.light!.intensity = 1500
    light.position = SCNVector3(0, 4, 3)
    scene.rootNode.addChildNode(light)

    // 회오리 토러스 (3D 링)
    let torus = SCNTorus(ringRadius: 1.5, pipeRadius: 0.15)
    let torusMat = SCNMaterial()
    torusMat.diffuse.contents = UIColor(red: 0.1, green: 0.7, blue: 0.2, alpha: 0.5)
    torusMat.emission.contents = UIColor(red: 0.3, green: 1, blue: 0.4, alpha: 1)
    torusMat.transparency = 0.4
    torus.materials = [torusMat]
    let torusNode = SCNNode(geometry: torus)
    torusNode.eulerAngles.x = .pi / 6
    scene.rootNode.addChildNode(torusNode)

    // 토러스 회전
    let spin = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 1.0)
    torusNode.runAction(SCNAction.repeatForever(spin))

    // 토러스 크기 변화
    let breathe = SCNAction.sequence([
        SCNAction.scale(to: 1.3, duration: 0.5),
        SCNAction.scale(to: 0.8, duration: 0.4),
        SCNAction.scale(to: 1.0, duration: 0.3)
    ])
    torusNode.runAction(SCNAction.repeatForever(breathe))

    // 바람 파티클 (나선 형태)
    let vortex = makeParticleSystem(
        birthRate: 100, lifetime: 1.2, velocity: 5, size: 0.08,
        color: UIColor(red: 0.4, green: 1, blue: 0.5, alpha: 1),
        endColor: UIColor(red: 0, green: 0.3, blue: 0.1, alpha: 0),
        spread: 180
    )
    torusNode.addParticleSystem(vortex)

    // 나뭇잎/파편 파티클
    let debris = makeParticleSystem(
        birthRate: 50, lifetime: 1.0, velocity: 8, size: 0.04,
        color: UIColor(red: 0.5, green: 1, blue: 0.3, alpha: 1),
        endColor: UIColor(red: 0.1, green: 0.5, blue: 0.1, alpha: 0),
        spread: 180
    )
    debris.isAffectedByGravity = true
    scene.rootNode.addParticleSystem(debris)

    // 바람 줄기 (위아래)
    let streaks = makeParticleSystem(
        birthRate: 40, lifetime: 1.5, velocity: 6, size: 0.2,
        color: UIColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 0.3),
        endColor: UIColor(red: 0, green: 0.3, blue: 0.1, alpha: 0),
        spread: 20
    )
    streaks.emittingDirection = SCNVector3(0, 1, 0)
    let streakNode = SCNNode()
    streakNode.position = SCNVector3(0, -3, 0)
    streakNode.addParticleSystem(streaks)
    scene.rootNode.addChildNode(streakNode)

    scheduleCleanup(scene: scene)
    return scene
}

// MARK: - ⛰️ 지진 (지)

private func buildEarthquakeScene() -> SCNScene {
    let scene = SCNScene()

    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(0, 3, 8)
    cameraNode.look(at: SCNVector3(0, 0, 0))
    scene.rootNode.addChildNode(cameraNode)

    let light = SCNNode()
    light.light = SCNLight()
    light.light!.type = .omni
    light.light!.color = UIColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1)
    light.light!.intensity = 1800
    light.position = SCNVector3(0, 4, 3)
    scene.rootNode.addChildNode(light)

    // 바위 덩어리 (여러 개)
    let rockPositions: [(Float, Float, Float, CGFloat)] = [
        (-1.5, -1, 0.5, 0.4),
        (1.2, -0.5, -0.3, 0.3),
        (0, 0, 0, 0.6),
        (-0.8, 0.8, 0.2, 0.25),
        (1.5, 1, -0.5, 0.35)
    ]

    for (i, pos) in rockPositions.enumerated() {
        let box = SCNBox(width: pos.3, height: pos.3, length: pos.3, chamferRadius: pos.3 * 0.15)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(red: 0.5, green: 0.35, blue: 0.15, alpha: 1)
        mat.emission.contents = UIColor(red: 0.7, green: 0.5, blue: 0.2, alpha: 0.3)
        box.materials = [mat]
        let node = SCNNode(geometry: box)
        node.position = SCNVector3(pos.0, pos.1 - 3, pos.2)
        node.eulerAngles = SCNVector3(
            Float.random(in: 0...Float.pi),
            Float.random(in: 0...Float.pi),
            Float.random(in: 0...Float.pi)
        )
        scene.rootNode.addChildNode(node)

        // 바위 솟아오르기 + 회전
        let delay = Double(i) * 0.1
        let rise = SCNAction.sequence([
            SCNAction.wait(duration: delay),
            SCNAction.moveBy(x: 0, y: CGFloat(pos.1 + 3), z: 0, duration: 0.4)
        ])
        let rotate = SCNAction.rotateBy(
            x: CGFloat.random(in: -2...2),
            y: CGFloat.random(in: -2...2),
            z: CGFloat.random(in: -2...2),
            duration: 2
        )
        node.runAction(SCNAction.group([rise, rotate]))
    }

    // 먼지 파티클
    let dust = makeParticleSystem(
        birthRate: 60, lifetime: 2.0, velocity: 3, size: 0.3,
        color: UIColor(red: 0.6, green: 0.45, blue: 0.2, alpha: 0.4),
        endColor: UIColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 0),
        spread: 90
    )
    let dustNode = SCNNode()
    dustNode.position = SCNVector3(0, -2, 0)
    dustNode.addParticleSystem(dust)
    scene.rootNode.addChildNode(dustNode)

    // 암석 파편 (사방으로)
    let fragments = makeParticleSystem(
        birthRate: 80, lifetime: 1.0, velocity: 7, size: 0.06,
        color: UIColor(red: 0.9, green: 0.7, blue: 0.3, alpha: 1),
        endColor: UIColor(red: 0.3, green: 0.15, blue: 0.05, alpha: 0),
        spread: 180
    )
    fragments.isAffectedByGravity = true
    scene.rootNode.addParticleSystem(fragments)

    scheduleCleanup(scene: scene)
    return scene
}

// MARK: - 🌑 암흑 공허 (암)

private func buildDarkVoidScene() -> SCNScene {
    let scene = SCNScene()

    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(0, 0, 8)
    cameraNode.look(at: SCNVector3(0, 0, 0))
    scene.rootNode.addChildNode(cameraNode)

    let light = SCNNode()
    light.light = SCNLight()
    light.light!.type = .omni
    light.light!.color = UIColor(red: 0.4, green: 0, blue: 0.6, alpha: 1)
    light.light!.intensity = 1200
    light.position = SCNVector3(0, 0, 5)
    scene.rootNode.addChildNode(light)

    // 블랙홀 구체
    let voidCore = makeSphereNode(
        radius: 0.6,
        color: UIColor(red: 0.05, green: 0, blue: 0.1, alpha: 1),
        emission: UIColor(red: 0.2, green: 0, blue: 0.3, alpha: 1),
        transparency: 0.9
    )
    scene.rootNode.addChildNode(voidCore)

    // 블랙홀 맥동 (크기 팽창)
    let expand = SCNAction.sequence([
        SCNAction.scale(to: 2.0, duration: 0.6),
        SCNAction.scale(to: 1.5, duration: 0.3),
        SCNAction.scale(to: 1.8, duration: 0.3)
    ])
    voidCore.runAction(SCNAction.repeatForever(expand))

    // 보라 회전 링
    let ring = SCNTorus(ringRadius: 2.0, pipeRadius: 0.08)
    let ringMat = SCNMaterial()
    ringMat.diffuse.contents = UIColor(red: 0.5, green: 0, blue: 0.8, alpha: 0.6)
    ringMat.emission.contents = UIColor(red: 0.7, green: 0.2, blue: 1, alpha: 1)
    ringMat.transparency = 0.5
    ring.materials = [ringMat]
    let ringNode = SCNNode(geometry: ring)
    ringNode.eulerAngles.x = .pi / 4
    scene.rootNode.addChildNode(ringNode)

    let ringRotate = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 1.5)
    ringNode.runAction(SCNAction.repeatForever(ringRotate))

    // 두 번째 링 (반대 각도)
    let ring2Node = ringNode.clone()
    ring2Node.eulerAngles.x = -.pi / 3
    ring2Node.eulerAngles.z = .pi / 6
    scene.rootNode.addChildNode(ring2Node)
    let ringRotate2 = SCNAction.rotateBy(x: 0, y: -CGFloat.pi * 2, z: 0, duration: 1.2)
    ring2Node.runAction(SCNAction.repeatForever(ringRotate2))

    // 보라색 스파크
    let sparks = makeParticleSystem(
        birthRate: 70, lifetime: 1.0, velocity: 4, size: 0.05,
        color: UIColor(red: 0.8, green: 0.3, blue: 1, alpha: 1),
        endColor: UIColor(red: 0.1, green: 0, blue: 0.2, alpha: 0),
        spread: 180
    )
    voidCore.addParticleSystem(sparks)

    // 검은 안개
    let darkMist = makeParticleSystem(
        birthRate: 20, lifetime: 2.5, velocity: 1.5, size: 0.6,
        color: UIColor(red: 0.15, green: 0, blue: 0.25, alpha: 0.5),
        endColor: UIColor(red: 0.05, green: 0, blue: 0.1, alpha: 0),
        spread: 180
    )
    scene.rootNode.addParticleSystem(darkMist)

    scheduleCleanup(scene: scene)
    return scene
}

// MARK: - ✨ 빛의 강림 (광)

private func buildHolyRadianceScene() -> SCNScene {
    let scene = SCNScene()

    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(0, 2, 8)
    cameraNode.look(at: SCNVector3(0, 1, 0))
    scene.rootNode.addChildNode(cameraNode)

    let light = SCNNode()
    light.light = SCNLight()
    light.light!.type = .omni
    light.light!.color = UIColor(red: 1, green: 0.9, blue: 0.5, alpha: 1)
    light.light!.intensity = 2500
    light.position = SCNVector3(0, 5, 3)
    scene.rootNode.addChildNode(light)

    // 빛 구체 (상단)
    let holyCore = makeSphereNode(
        radius: 0.7,
        color: UIColor(red: 1, green: 0.95, blue: 0.7, alpha: 1),
        emission: UIColor(red: 1, green: 0.9, blue: 0.5, alpha: 1),
        transparency: 0.4,
        position: SCNVector3(0, 3, 0)
    )
    scene.rootNode.addChildNode(holyCore)

    // 구체 빛 맥동
    let glow = SCNAction.sequence([
        SCNAction.scale(to: 1.5, duration: 0.4),
        SCNAction.scale(to: 0.8, duration: 0.3),
        SCNAction.scale(to: 1.2, duration: 0.3)
    ])
    holyCore.runAction(SCNAction.repeatForever(glow))

    // 빛 기둥 (위에서 아래로) — 실린더 3개
    for xPos in [-1.0, 0.0, 1.0] as [Float] {
        let cylinder = SCNCylinder(radius: 0.15, height: 8)
        let cylMat = SCNMaterial()
        cylMat.diffuse.contents = UIColor(red: 1, green: 0.9, blue: 0.5, alpha: 0.3)
        cylMat.emission.contents = UIColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
        cylMat.transparency = 0.3
        cylMat.isDoubleSided = true
        cylinder.materials = [cylMat]
        let cylNode = SCNNode(geometry: cylinder)
        cylNode.position = SCNVector3(xPos, 0, Float.random(in: -0.5...0.5))
        scene.rootNode.addChildNode(cylNode)

        // 빛 기둥 내려오기
        cylNode.opacity = 0
        let fadeIn = SCNAction.sequence([
            SCNAction.wait(duration: Double(abs(xPos)) * 0.15),
            SCNAction.fadeIn(duration: 0.3)
        ])
        cylNode.runAction(fadeIn)
    }

    // 금색 입자 (하강)
    let goldDust = makeParticleSystem(
        birthRate: 80, lifetime: 1.5, velocity: 3, size: 0.06,
        color: UIColor(red: 1, green: 0.9, blue: 0.5, alpha: 1),
        endColor: UIColor(red: 0.8, green: 0.5, blue: 0.1, alpha: 0),
        spread: 40
    )
    goldDust.emittingDirection = SCNVector3(0, -1, 0)
    let goldNode = SCNNode()
    goldNode.position = SCNVector3(0, 4, 0)
    goldNode.addParticleSystem(goldDust)
    scene.rootNode.addChildNode(goldNode)

    // 흰색 깜빡임 (전체)
    let flare = makeParticleSystem(
        birthRate: 30, lifetime: 0.8, velocity: 2, size: 0.15,
        color: UIColor(red: 1, green: 1, blue: 0.9, alpha: 1),
        endColor: UIColor(red: 1, green: 0.8, blue: 0.3, alpha: 0),
        spread: 180
    )
    scene.rootNode.addParticleSystem(flare)

    // 후광 링
    let halo = SCNTorus(ringRadius: 1.5, pipeRadius: 0.06)
    let haloMat = SCNMaterial()
    haloMat.diffuse.contents = UIColor(red: 1, green: 0.9, blue: 0.5, alpha: 0.4)
    haloMat.emission.contents = UIColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
    haloMat.transparency = 0.5
    halo.materials = [haloMat]
    let haloNode = SCNNode(geometry: halo)
    haloNode.position = SCNVector3(0, 3, 0)
    haloNode.eulerAngles.x = .pi / 2
    scene.rootNode.addChildNode(haloNode)

    let haloSpin = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat.pi * 2, duration: 2.0)
    haloNode.runAction(SCNAction.repeatForever(haloSpin))

    scheduleCleanup(scene: scene)
    return scene
}

// MARK: - ⚡ 낙뢰 (뇌)

private func buildThunderStrikeScene() -> SCNScene {
    let scene = SCNScene()

    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(0, 2, 8)
    cameraNode.look(at: SCNVector3(0, 0, 0))
    scene.rootNode.addChildNode(cameraNode)

    // 기본 조명 (어두운)
    let ambient = SCNNode()
    ambient.light = SCNLight()
    ambient.light!.type = .ambient
    ambient.light!.color = UIColor(white: 0.1, alpha: 1)
    scene.rootNode.addChildNode(ambient)

    // 번개 플래시 조명
    let flash = SCNNode()
    flash.light = SCNLight()
    flash.light!.type = .omni
    flash.light!.color = UIColor(red: 0.8, green: 0.9, blue: 1, alpha: 1)
    flash.light!.intensity = 3000
    flash.position = SCNVector3(0, 5, 3)
    scene.rootNode.addChildNode(flash)

    // 번개 깜빡임
    let flashBlink = SCNAction.sequence([
        SCNAction.customAction(duration: 0.05) { node, _ in node.light?.intensity = 5000 },
        SCNAction.customAction(duration: 0.05) { node, _ in node.light?.intensity = 500 },
        SCNAction.customAction(duration: 0.08) { node, _ in node.light?.intensity = 4000 },
        SCNAction.customAction(duration: 0.1) { node, _ in node.light?.intensity = 800 },
        SCNAction.customAction(duration: 0.05) { node, _ in node.light?.intensity = 6000 },
        SCNAction.customAction(duration: 0.3) { node, _ in node.light?.intensity = 1000 },
        SCNAction.wait(duration: 0.3),
    ])
    flash.runAction(SCNAction.repeatForever(flashBlink))

    // 번개 줄기 (실린더)
    for xPos in [-1.0, 0.3, 1.2] as [Float] {
        let bolt = SCNCylinder(radius: 0.06, height: 8)
        let boltMat = SCNMaterial()
        boltMat.diffuse.contents = UIColor(red: 0.9, green: 0.95, blue: 1, alpha: 0.9)
        boltMat.emission.contents = UIColor(red: 0.7, green: 0.85, blue: 1, alpha: 1)
        boltMat.transparency = 0.7
        boltMat.isDoubleSided = true
        bolt.materials = [boltMat]
        let boltNode = SCNNode(geometry: bolt)
        boltNode.position = SCNVector3(xPos, 0, Float.random(in: -1...1))
        boltNode.eulerAngles.z = Float.random(in: -0.15...0.15)
        scene.rootNode.addChildNode(boltNode)

        // 번개 볼트 파티클
        let boltParticles = makeParticleSystem(
            birthRate: 100, lifetime: 0.5, velocity: 8, size: 0.05,
            color: UIColor(red: 1, green: 1, blue: 0.9, alpha: 1),
            endColor: UIColor(red: 0.3, green: 0.5, blue: 1, alpha: 0),
            spread: 15
        )
        boltParticles.emittingDirection = SCNVector3(0, -1, 0)
        let particleNode = SCNNode()
        particleNode.position = SCNVector3(xPos, 4, boltNode.position.z)
        particleNode.addParticleSystem(boltParticles)
        scene.rootNode.addChildNode(particleNode)
    }

    // 전기 구체 (충격파 중앙)
    let impactSphere = makeSphereNode(
        radius: 0.5,
        color: UIColor(red: 0.7, green: 0.85, blue: 1, alpha: 1),
        emission: UIColor(red: 0.9, green: 0.95, blue: 1, alpha: 1),
        transparency: 0.5,
        position: SCNVector3(0, -1.5, 0)
    )
    scene.rootNode.addChildNode(impactSphere)

    let impactPulse = SCNAction.sequence([
        SCNAction.scale(to: 2.5, duration: 0.2),
        SCNAction.scale(to: 1.0, duration: 0.2),
        SCNAction.scale(to: 2.0, duration: 0.15)
    ])
    impactSphere.runAction(SCNAction.repeatForever(impactPulse))

    // 전기 스파크
    let sparks = makeParticleSystem(
        birthRate: 90, lifetime: 0.6, velocity: 10, size: 0.04,
        color: UIColor(red: 0.8, green: 0.9, blue: 1, alpha: 1),
        endColor: UIColor(red: 0.3, green: 0.5, blue: 1, alpha: 0),
        spread: 180
    )
    impactSphere.addParticleSystem(sparks)

    scheduleCleanup(scene: scene)
    return scene
}

// MARK: - 씬 클린업

private func scheduleCleanup(scene: SCNScene) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
        // 파티클 방출 정지
        scene.rootNode.enumerateChildNodes { node, _ in
            for ps in node.particleSystems ?? [] {
                ps.birthRate = 0
            }
        }
        for ps in scene.rootNode.particleSystems ?? [] {
            ps.birthRate = 0
        }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
        scene.rootNode.enumerateChildNodes { node, _ in
            node.removeFromParentNode()
        }
    }
}

// MARK: - 범용 풀스크린 소환 오버레이 (3D)

struct SummonFullscreenOverlay: View {
    let effectType: SummonEffectType
    @State private var shakeOffset: CGFloat = 0
    @State private var vignetteOpacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SceneView(
                    scene: makeScene(),
                    options: [.rendersContinuously]
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

    private func makeScene() -> SCNScene {
        let scene: SCNScene
        switch effectType {
        case .lavaEruption:  scene = buildLavaEruptionScene()
        case .tidalWave:     scene = buildTidalWaveScene()
        case .typhoonStorm:  scene = buildTyphoonStormScene()
        case .earthquake:    scene = buildEarthquakeScene()
        case .darkVoid:      scene = buildDarkVoidScene()
        case .holyRadiance:  scene = buildHolyRadianceScene()
        case .thunderStrike: scene = buildThunderStrikeScene()
        }
        scene.background.contents = UIColor.clear
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

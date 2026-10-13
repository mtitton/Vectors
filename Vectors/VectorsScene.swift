//
//  VectorsScene.swift
//  Vectors
//
//  Created by Marcus Titton on 13/10/26.
//

import SpriteKit
import UIKit

// SpriteKit-based deterministic movement/collision loop. No external artwork or physics bodies.
enum GameEffect { case redirect, match, combo(Int), damage, record, gameOver }

private final class VectorParticle {
    let identifier = UUID()
    let kind: ParticleColor
    let node = SKNode()
    let selectionRing = SKShapeNode(circleOfRadius: 25)
    let dangerRing = SKShapeNode(circleOfRadius: 21)
    let radius: CGFloat = 13
    var position: CGPoint
    var velocity: CGVector
    private let glowHalo = SKShapeNode(circleOfRadius: 24)
    private let energyTail: SKShapeNode
    private let sparkle = SKShapeNode(circleOfRadius: 3.3)
    private let visualOffset: CGFloat

    init(kind: ParticleColor, position: CGPoint, velocity: CGVector) {
        self.kind = kind
        self.position = position
        self.velocity = velocity
        visualOffset = CGFloat(Int.random(in: 0...100)) * 0.045
        let tint = kind.uiColor
        let length = min(CGFloat(40), max(CGFloat(25), hypot(velocity.dx, velocity.dy) * 0.28))

        // Tapered, luminous tail; drawn locally so rotation remains inexpensive.
        let wedge = CGMutablePath()
        wedge.move(to: CGPoint(x: -9, y: 2.3))
        wedge.addQuadCurve(to: CGPoint(x: -length, y: 0), control: CGPoint(x: -length*0.58, y: 1.8))
        wedge.addQuadCurve(to: CGPoint(x: -9, y: -2.3), control: CGPoint(x: -length*0.58, y: -1.8))
        wedge.closeSubpath()
        let plume = SKShapeNode(path: wedge)
        plume.fillColor = tint.withAlphaComponent(0.055)
        plume.strokeColor = .clear
        plume.glowWidth = 0
        node.addChild(plume)
        energyTail = plume

        let strand = CGMutablePath()
        strand.move(to: CGPoint(x: -12, y: 0))
        strand.addLine(to: CGPoint(x: -length * 0.92, y: 0))
        let line = SKShapeNode(path: strand)
        line.strokeColor = tint.withAlphaComponent(0.32)
        line.lineWidth = 1.2
        line.lineCap = .round
        line.glowWidth = 0
        node.addChild(line)

        glowHalo.fillColor = tint.withAlphaComponent(0.018)
        glowHalo.strokeColor = tint.withAlphaComponent(0.045)
        glowHalo.lineWidth = 1.3
        glowHalo.glowWidth = 0
        node.addChild(glowHalo)

        let outer = SKShapeNode(circleOfRadius: 16)
        outer.fillColor = tint.withAlphaComponent(0.025)
        outer.strokeColor = tint.withAlphaComponent(0.18)
        outer.lineWidth = 1.3
        outer.glowWidth = 0
        node.addChild(outer)

        let ring = SKShapeNode(circleOfRadius: radius)
        ring.fillColor = UIColor(red: 0.018, green: 0.045, blue: 0.105, alpha: 0.95)
        ring.strokeColor = tint
        ring.lineWidth = 2.1
        ring.glowWidth = 1.1
        node.addChild(ring)

        let shape: SKShapeNode
        switch kind {
        case .cyan: shape = SKShapeNode(circleOfRadius: 3.8)
        case .crimson:
            let diamond = CGMutablePath()
            diamond.move(to: CGPoint(x: 0, y: 5))
            diamond.addLine(to: CGPoint(x: 5, y: 0))
            diamond.addLine(to: CGPoint(x: 0, y: -5))
            diamond.addLine(to: CGPoint(x: -5, y: 0))
            diamond.closeSubpath()
            shape = SKShapeNode(path: diamond)
        case .lime:
            let triangle = CGMutablePath()
            triangle.move(to: CGPoint(x: 0, y: 5.5))
            triangle.addLine(to: CGPoint(x: 5, y: -4))
            triangle.addLine(to: CGPoint(x: -5, y: -4))
            triangle.closeSubpath()
            shape = SKShapeNode(path: triangle)
        case .amber: shape = SKShapeNode(rectOf: CGSize(width: 8, height: 8), cornerRadius: 1)
        case .violet:
            // Plus symbol distinguishes violet even when color perception is limited.
            let cross = CGMutablePath()
            cross.move(to: CGPoint(x: -1.5, y: 5))
            cross.addLine(to: CGPoint(x: 1.5, y: 5))
            cross.addLine(to: CGPoint(x: 1.5, y: 1.5))
            cross.addLine(to: CGPoint(x: 5, y: 1.5))
            cross.addLine(to: CGPoint(x: 5, y: -1.5))
            cross.addLine(to: CGPoint(x: 1.5, y: -1.5))
            cross.addLine(to: CGPoint(x: 1.5, y: -5))
            cross.addLine(to: CGPoint(x: -1.5, y: -5))
            cross.addLine(to: CGPoint(x: -1.5, y: -1.5))
            cross.addLine(to: CGPoint(x: -5, y: -1.5))
            cross.addLine(to: CGPoint(x: -5, y: 1.5))
            cross.addLine(to: CGPoint(x: -1.5, y: 1.5))
            cross.closeSubpath()
            shape = SKShapeNode(path: cross)
        }
        shape.fillColor = .white
        shape.strokeColor = tint
        shape.lineWidth = 0.9
        shape.glowWidth = 0
        node.addChild(shape)

        sparkle.fillColor = tint.withAlphaComponent(0.25)
        sparkle.strokeColor = .clear
        sparkle.glowWidth = 0
        sparkle.position = CGPoint(x: 3, y: 4)
        node.addChild(sparkle)

        let arrowPath = CGMutablePath()
        arrowPath.move(to: CGPoint(x: 17, y: 0))
        arrowPath.addLine(to: CGPoint(x: 35, y: 0))
        arrowPath.move(to: CGPoint(x: 27, y: 6))
        arrowPath.addLine(to: CGPoint(x: 35, y: 0))
        arrowPath.addLine(to: CGPoint(x: 27, y: -6))
        let arrow = SKShapeNode(path: arrowPath)
        arrow.strokeColor = tint
        arrow.lineWidth = 1.8
        arrow.lineCap = .round
        arrow.lineJoin = .round
        arrow.glowWidth = 0
        node.addChild(arrow)

        selectionRing.fillColor = .clear
        selectionRing.strokeColor = .white
        selectionRing.lineWidth = 1.6
        selectionRing.glowWidth = 1
        selectionRing.isHidden = true
        node.addChild(selectionRing)

        dangerRing.fillColor = .clear
        dangerRing.strokeColor = UIColor.systemOrange.withAlphaComponent(0.74)
        dangerRing.lineWidth = 1.8
        dangerRing.glowWidth = 0
        dangerRing.isHidden = true
        node.addChild(dangerRing)
        node.zPosition = 10
        refreshVisual()
    }

    var speed: CGFloat { hypot(velocity.dx, velocity.dy) }

    func refreshVisual() {
        node.position = position
        node.zRotation = atan2(velocity.dy, velocity.dx)
    }

    func updateAppearance(time: TimeInterval, effectsEnabled: Bool) {
        glowHalo.isHidden = !effectsEnabled
        energyTail.isHidden = !effectsEnabled
        guard effectsEnabled else { return }
        let pulse = (sin(CGFloat(time) * 3.2 + visualOffset) + 1) * 0.5
        glowHalo.alpha = 0.42 + 0.16 * pulse
        glowHalo.setScale(0.98 + 0.025 * pulse)
        sparkle.alpha = 0.22 + 0.17 * pulse
        if !selectionRing.isHidden {
            selectionRing.alpha = 0.78 + 0.16 * pulse
        }
    }

    func refreshEdgeWarning(in arenaSize: CGSize) {
        let tx: CGFloat = velocity.dx > 0
            ? (arenaSize.width - position.x) / velocity.dx
            : (velocity.dx < 0 ? -position.x / velocity.dx : .greatestFiniteMagnitude)
        let ty: CGFloat = velocity.dy > 0
            ? (arenaSize.height - position.y) / velocity.dy
            : (velocity.dy < 0 ? -position.y / velocity.dy : .greatestFiniteMagnitude)
        let remaining = min(tx, ty)
        dangerRing.isHidden = remaining < 0 || remaining > 0.88
        if !dangerRing.isHidden {
            dangerRing.alpha = max(0.25, 1 - remaining / 0.88)
        }
    }
}

final class VectorsScene: SKScene {
    var languageCode = "en"
    var effectsEnabled = true {
        didSet { particles.forEach { $0.updateAppearance(time: elapsed, effectsEnabled: effectsEnabled) } }
    }
    private let arenaArtwork = SKNode()
    private var randomState: UInt64 = 1
    // Gameplay uses a dedicated seeded PRNG. Visual effects use their own random values.
    private func nextRandom() -> Double {
        randomState &+= 0x9E3779B97F4A7C15
        var z = randomState
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return Double(z ^ (z >> 31)) / Double(UInt64.max)
    }
    private func randomInt(_ range: Range<Int>) -> Int { range.lowerBound + Int(nextRandom() * Double(range.count)) }
    private func randomCGFloat(_ range: ClosedRange<CGFloat>) -> CGFloat {
        range.lowerBound + CGFloat(nextRandom()) * (range.upperBound - range.lowerBound)
    }
    var onHUD: ((Int, Int, Int, Int, Int) -> Void)?
    var onEffect: ((GameEffect) -> Void)?
    var onGameOver: (() -> Void)?

    private var particles: [VectorParticle] = []
    private var active = false
    private var elapsed: TimeInterval = 0
    private var lastFrame: TimeInterval = 0
    private var spawnClock: TimeInterval = 0
    private var comboDeadline: TimeInterval = 0
    private var lastDamageTime: TimeInterval = -100
    private var selected: VectorParticle?
    private var gestureOrigin: CGPoint?
    private var hasRedirectedThisGesture = false
    private let minimumSwipeDistance: CGFloat = 13
    private let gesturePath = SKShapeNode()
    private let forecastMarker = SKShapeNode(circleOfRadius: 10)
    private let forecastLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let comboWindow: TimeInterval = 4.9
    private(set) var score = 0
    private(set) var combo = 0
    private(set) var lives = 3
    private(set) var matches = 0
    private(set) var redirects = 0

    override init(size: CGSize) {
        super.init(size: size)
        anchorPoint = CGPoint(x: 0, y: 0)
        gesturePath.strokeColor = UIColor.white.withAlphaComponent(0.60)
        gesturePath.lineWidth = 1.5
        gesturePath.glowWidth = 0
        gesturePath.zPosition = 40
        gesturePath.lineCap = .round
        forecastMarker.lineWidth = 2.0
        forecastMarker.fillColor = .clear
        forecastMarker.glowWidth = 0
        forecastMarker.zPosition = 42
        forecastMarker.isHidden = true
        forecastLabel.fontSize = 12
        forecastLabel.horizontalAlignmentMode = .center
        forecastLabel.verticalAlignmentMode = .center
        forecastLabel.zPosition = 43
        forecastLabel.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) { fatalError("Create VectorsScene programmatically") }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard oldSize.width > 0, oldSize.height > 0 else { return }
        for particle in particles {
            particle.position.x *= size.width / oldSize.width
            particle.position.y *= size.height / oldSize.height
            particle.refreshVisual()
        }
        installArenaArtwork()
    }

    // The gradient comes from SwiftUI behind the transparent scene.
    // Keep a single understated circle for spatial reference, not a radar/grid.
    private func installArenaArtwork() {
        arenaArtwork.removeAllChildren()
        arenaArtwork.removeFromParent()
        arenaArtwork.zPosition = -25
        let guide = UIColor(red: 0.23, green: 0.56, blue: 0.71, alpha: 1)
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        let circle = SKShapeNode(circleOfRadius: min(size.width, size.height) * 0.39)
        circle.position = center
        circle.strokeColor = guide.withAlphaComponent(0.085)
        circle.lineWidth = 0.85
        circle.fillColor = .clear
        arenaArtwork.addChild(circle)
        addChild(arenaArtwork)
    }

    func startNewGame(seed: Int? = nil) {
        randomState = seed.map { UInt64($0) } ?? UInt64.random(in: 1...UInt64.max)
        isPaused = false
        removeAllChildren()
        installArenaArtwork()
        particles.removeAll()
        selected = nil
        gestureOrigin = nil
        hasRedirectedThisGesture = false
        active = true
        elapsed = 0
        lastFrame = 0
        spawnClock = 0
        comboDeadline = 0
        lastDamageTime = -100
        score = 0; combo = 0; lives = 3; matches = 0; redirects = 0
        addChild(gesturePath)
        addChild(forecastMarker)
        addChild(forecastLabel)
        gesturePath.path = nil
        forecastMarker.isHidden = true
        forecastLabel.isHidden = true
        seedOpening()
        // Two readable opening particles; the first newcomer arrives after a full
        // introductory interval. Never front-load the arena at 0 points.
        spawnClock = 0
        reportHUD()
    }

    func pauseSimulation() {
        clearGesture()
        isPaused = true
        lastFrame = 0
    }

    func resumeSimulation() {
        lastFrame = 0
        isPaused = false
    }

    // A short learning window is essential: only one color and two particles
    // at the beginning. All difficulty changes depend on SCORE, never playtime.
    // Both Endless and Daily use this same profile.
    private var stage: Int {
        switch score {
        case ..<40: return 0
        case ..<110: return 1
        case ..<220: return 2
        case ..<370: return 3
        case ..<550: return 4
        case ..<750: return 5
        case ..<1000: return 6
        case ..<1400: return 7
        case ..<1900: return 8
        default: return 9
        }
    }
    private var numberOfColors: Int {
        switch stage {
        case 0: return 1
        case 1...2: return 2
        case 3...4: return 3
        case 5...6: return 4  // New fourth color from 550 points
        default: return 5       // Violet joins from 1,000 points
        }
    }
    private var particleLimit: Int { [3, 4, 6, 8, 10, 12, 15, 18, 21, 24][stage] }
    private var spawnInterval: TimeInterval {
        [3.25, 2.85, 2.45, 2.10, 1.85, 1.58, 1.34, 1.15, 0.96, 0.82][stage]
    }
    private var spawnSpeed: CGFloat {
        [50, 53, 57, 61, 65, 70, 76, 82, 88, 93][stage]
    }

    private func seedOpening() {
        let w = size.width, h = size.height
        // Same color, comfortably separated and with different horizontal
        // paths. The player has time to steer them into a match.
        let speed: CGFloat = 46
        addParticle(kind: .cyan, location: CGPoint(x: w * 0.24, y: h * 0.61),
                    vector: CGVector(dx: speed * 0.86, dy: speed * 0.06))
        addParticle(kind: .cyan, location: CGPoint(x: w * 0.76, y: h * 0.44),
                    vector: CGVector(dx: -speed * 0.78, dy: speed * 0.08))
    }

    private func addParticle(kind: ParticleColor, location: CGPoint, vector: CGVector) {
        let p = VectorParticle(kind: kind, position: location, velocity: vector)
        particles.append(p)
        addChild(p.node)
        p.node.alpha = 0
        p.node.run(.fadeIn(withDuration: 0.14))
    }

    override func update(_ currentTime: TimeInterval) {
        guard active, !isPaused else { return }
        defer { lastFrame = currentTime }
        guard lastFrame > 0 else { return }
        let dt = min(1.0 / 25.0, max(0, currentTime - lastFrame))
        elapsed += dt
        spawnClock += dt
        if combo > 0, elapsed > comboDeadline {
            combo = 0
            reportHUD()
        }
        let interval = spawnInterval
        if spawnClock >= interval {
            spawnClock -= interval
            if particles.count < particleLimit {
                let wasEmpty = particles.isEmpty
                spawnParticle()
                // Avoid a stalled, single-particle arena after a successful match.
                // The pair arrives together only when the arena was empty.
                if wasEmpty, particles.count == 1, particles.count < particleLimit {
                    spawnParticle()
                }
            }
        }
        for p in particles {
            p.position.x += p.velocity.dx * dt
            p.position.y += p.velocity.dy * dt
            p.refreshVisual()
            p.refreshEdgeWarning(in: size)
            p.updateAppearance(time: elapsed, effectsEnabled: effectsEnabled)
        }
        if let selected, hasRedirectedThisGesture, selected.speed > 0.01 {
            // Keep the projected heading attached to the moving selected particle.
            refreshTrajectoryForecast(for: selected)
        }
        checkCollisionsAndEscapes()
    }

    private func spawnParticle() {
        let w = size.width, h = size.height
        guard w > 100, h > 150 else { return }
        let existing = particles.filter { ParticleColor.allCases.prefix(numberOfColors).contains($0.kind) }
        let kind: ParticleColor
        if !existing.isEmpty, randomInt(0..<100) < 68 {
            kind = existing[randomInt(0..<existing.count)].kind
        } else {
            kind = ParticleColor.allCases[randomInt(0..<numberOfColors)]
        }
        let base = spawnSpeed
        for _ in 0..<40 {
            let edge = randomInt(0..<4)
            let margin: CGFloat = 23
            let location: CGPoint
            let heading: CGFloat
            switch edge {
            case 0:
                location = CGPoint(x: margin, y: randomCGFloat(40...(h-40)))
                heading = 0
            case 1:
                location = CGPoint(x: w-margin, y: randomCGFloat(40...(h-40)))
                heading = .pi
            case 2:
                location = CGPoint(x: randomCGFloat(35...(w-35)), y: margin)
                heading = .pi/2
            default:
                location = CGPoint(x: randomCGFloat(35...(w-35)), y: h-margin)
                heading = -.pi/2
            }
            let angle = heading + randomCGFloat(-0.70...0.70)
            let velocity = CGVector(dx: cos(angle) * base * randomCGFloat(0.85...1.18),
                                    dy: sin(angle) * base * randomCGFloat(0.85...1.18))
            // Continuous closest-approach test prevents unavoidable immediate hits,
            // while allowing denser arenas at higher scores than the old 1.8s rule.
            let safe = particles.allSatisfy { other in
                let rx = location.x - other.position.x
                let ry = location.y - other.position.y
                // Never spawn directly over any existing particle.
                if hypot(rx, ry) < 40 { return false }
                if kind == other.kind { return true }
                let vx = velocity.dx - other.velocity.dx
                let vy = velocity.dy - other.velocity.dy
                let magnitude = vx * vx + vy * vy
                let t = magnitude > 0.01
                    ? max(CGFloat(0), min(CGFloat(1.05), -(rx * vx + ry * vy) / magnitude))
                    : CGFloat(0)
                return hypot(rx + vx * t, ry + vy * t) > 38
            }
            if safe {
                addParticle(kind: kind, location: location, vector: velocity)
                return
            }
        }
        // If no fair entry is available, do not force an unavoidable spawn.
    }

    private func checkCollisionsAndEscapes() {
        var removed = Set<UUID>()
        let snapshot = particles
        for i in snapshot.indices {
            let a = snapshot[i]
            guard !removed.contains(a.identifier) else { continue }
            if i + 1 < snapshot.count {
                for j in (i+1)..<snapshot.count {
                    let b = snapshot[j]
                    guard !removed.contains(b.identifier) else { continue }
                    let distance = hypot(a.position.x - b.position.x, a.position.y - b.position.y)
                    if distance <= a.radius + b.radius {
                        removed.insert(a.identifier)
                        removed.insert(b.identifier)
                        let whereAt = CGPoint(x: (a.position.x+b.position.x)/2,
                                              y: (a.position.y+b.position.y)/2)
                        if a.kind == b.kind {
                            registerMatch(at: whereAt, color: a.kind.uiColor)
                        } else {
                            damage(at: whereAt)
                        }
                        break
                    }
                }
            }
            if !removed.contains(a.identifier) {
                let p = a.position
                if p.x < -18 || p.x > size.width+18 || p.y < -18 || p.y > size.height+18 {
                    removed.insert(a.identifier)
                    damage(at: p)
                }
            }
            if !active { break }
        }
        if !removed.isEmpty {
            for p in particles where removed.contains(p.identifier) { p.node.removeFromParent() }
            particles.removeAll { removed.contains($0.identifier) }
            if let selected, removed.contains(selected.identifier) { clearGesture() }
            // Refill gently if almost everything was cleared. Otherwise players
            // could spend multiple seconds with no possible match to create.
            if active, particles.count < 2 {
                spawnClock = max(spawnClock, spawnInterval - 0.55)
            }
        }
    }

    private func registerMatch(at point: CGPoint, color: UIColor) {
        combo = elapsed <= comboDeadline ? min(combo + 1, 12) : 1
        comboDeadline = elapsed + comboWindow
        matches += 1
        let gained = 10 * combo
        score += gained
        showBurst(at: point, color: color, points: gained)
        if [3, 5, 8, 12].contains(combo) {
            showChainCelebration(at: point, multiplier: combo)
        }
        onEffect?(combo >= 3 ? .combo(combo) : .match)
        reportHUD()
    }

    private func damage(at point: CGPoint) {
        showDamage(at: point)
        guard elapsed - lastDamageTime >= 0.70 else { return }
        lastDamageTime = elapsed
        lives = max(0, lives - 1)
        combo = 0
        onEffect?(.damage)
        reportHUD()
        if lives == 0 {
            active = false
            clearGesture()
            onGameOver?()
        }
    }

    private func showBurst(at point: CGPoint, color: UIColor, points: Int) {
        // Clean, localized feedback: bright center, single ring, few tiny sparks.
        let core = SKShapeNode(circleOfRadius: 6)
        core.position = point
        core.fillColor = color.withAlphaComponent(0.70)
        core.strokeColor = color
        core.lineWidth = 1.8
        core.glowWidth = 2
        core.zPosition = 32
        addChild(core)
        core.run(.sequence([.group([.scale(to: 1.8, duration: 0.17), .fadeOut(withDuration: 0.17)]), .removeFromParent()]))

        let ring = SKShapeNode(circleOfRadius: 12)
        ring.position = point
        ring.strokeColor = color.withAlphaComponent(0.65)
        ring.glowWidth = 0
        ring.lineWidth = 1.6
        ring.zPosition = 29
        addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 2.3, duration: 0.24), .fadeOut(withDuration: 0.24)]),
            .removeFromParent()
        ]))

        if effectsEnabled {
            for index in 0..<6 {
                let angle = CGFloat(index) * (.pi / 3) + CGFloat.random(in: -0.16...0.16)
                let distance = CGFloat.random(in: 15...32)
                let spark = SKShapeNode(circleOfRadius: 1.9)
                spark.fillColor = color.withAlphaComponent(0.8)
                spark.strokeColor = .clear
                spark.position = point
                spark.zPosition = 29
                addChild(spark)
                spark.run(.sequence([
                    .group([
                        .move(by: CGVector(dx: cos(angle) * distance, dy: sin(angle) * distance), duration: 0.22),
                        .fadeOut(withDuration: 0.22)
                    ]),
                    .removeFromParent()
                ]))
            }
        }
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "+\(points)"
        label.fontSize = 16
        label.fontColor = color
        label.position = CGPoint(x: max(34, min(size.width - 34, point.x)),
                                 y: max(25, min(size.height - 22, point.y + 26)))
        label.zPosition = 36
        addChild(label)
        label.run(.sequence([.group([.moveBy(x: 0, y: 25, duration: 0.52), .fadeOut(withDuration: 0.52)]), .removeFromParent()]))
    }

    private func showChainCelebration(at point: CGPoint, multiplier: Int) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "\(VectorStrings.value("CHAIN", code: languageCode)) ×\(multiplier)"
        label.fontSize = 17
        label.fontColor = UIColor.systemYellow
        label.position = CGPoint(x: max(65, min(size.width - 65, point.x)),
                                 y: max(24, min(size.height - 24, point.y - 29)))
        label.zPosition = 36
        label.alpha = 0
        // No full-screen flash for combos: it used to obscure active particles.
        addChild(label)
        label.run(.sequence([
            .group([.fadeIn(withDuration: 0.12), .scale(to: 1.12, duration: 0.12)]),
            .wait(forDuration: 0.28),
            .group([.moveBy(x: 0, y: 16, duration: 0.32), .fadeOut(withDuration: 0.32)]),
            .removeFromParent()
        ]))
    }

    private func showDamage(at point: CGPoint) {
        let warning = SKShapeNode(circleOfRadius: 14)
        warning.position = point
        warning.strokeColor = .systemRed
        warning.lineWidth = 3
        warning.glowWidth = 1
        warning.zPosition = 28
        addChild(warning)
        warning.run(.sequence([.group([.scale(to: 3.4, duration: 0.27), .fadeOut(withDuration: 0.27)]), .removeFromParent()]))
    }

    private func reportHUD() { onHUD?(score, combo, lives, matches, redirects) }

    private func nearestParticle(to point: CGPoint, excluding exception: UUID? = nil) -> VectorParticle? {
        let nearby = particles.filter { $0.identifier != exception }
        guard let closest = nearby.min(by: {
            hypot($0.position.x-point.x, $0.position.y-point.y) < hypot($1.position.x-point.x, $1.position.y-point.y)
        }) else { return nil }
        let distance = hypot(closest.position.x-point.x, closest.position.y-point.y)
        return distance <= 43 ? closest : nil
    }

    // Controls: start on one particle, then swipe in the desired travel direction.
    // No other particle is required, and the new heading is applied while dragging.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard active, !isPaused, touches.count == 1,
              let point = touches.first?.location(in: self),
              let found = nearestParticle(to: point) else { return }
        clearGesture()
        selected = found
        gestureOrigin = point
        found.selectionRing.isHidden = false
        gesturePath.strokeColor = found.kind.uiColor.withAlphaComponent(0.64)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard active, !isPaused, let point = touches.first?.location(in: self) else { return }
        redirectSelected(towards: point)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if active, !isPaused, let point = touches.first?.location(in: self) {
            // Short flicks can send touchesEnded without an intermediate touchesMoved.
            redirectSelected(towards: point)
        }
        clearGesture()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        clearGesture()
    }

    private func redirectSelected(towards touch: CGPoint) {
        guard let selected, let origin = gestureOrigin else { return }
        let dx = touch.x - origin.x
        let dy = touch.y - origin.y
        let length = hypot(dx, dy)
        guard length >= minimumSwipeDistance else { return }

        let originalSpeed = selected.speed
        guard originalSpeed > 0.01 else { return }
        let unitX = dx / length
        let unitY = dy / length
        selected.velocity = CGVector(dx: unitX * originalSpeed, dy: unitY * originalSpeed)
        selected.refreshVisual()
        selected.refreshEdgeWarning(in: size)
        refreshTrajectoryForecast(for: selected)

        if !hasRedirectedThisGesture {
            hasRedirectedThisGesture = true
            redirects += 1
            showRedirectPulse(at: selected.position, color: selected.kind.uiColor)
            onEffect?(.redirect)
            reportHUD()
        }
    }

    // Preview is purely informative: the player always chooses the heading.
    // It estimates the *first* encounter under constant current velocities;
    // no magnetic steering or course correction occurs behind the scenes.
    private func refreshTrajectoryForecast(for particle: VectorParticle) {
        let horizon: CGFloat = 2.8
        let tEdge = timeUntilExit(of: particle)
        var encounter: (time: CGFloat, kind: ParticleColor)?

        for other in particles where other.identifier != particle.identifier {
            guard let t = timeUntilContact(between: particle, and: other),
                  t > 0, t <= min(horizon, tEdge),
                  t <= timeUntilExit(of: other) else { continue }
            if encounter == nil || t < encounter!.time {
                encounter = (t, other.kind)
            }
        }

        let projectedTime = max(0, min(horizon, encounter?.time ?? tEdge))
        let point = CGPoint(x: particle.position.x + particle.velocity.dx * projectedTime,
                            y: particle.position.y + particle.velocity.dy * projectedTime)
        let path = CGMutablePath()
        path.move(to: particle.position)
        path.addLine(to: point)
        gesturePath.path = path
        gesturePath.alpha = encounter == nil ? 0.38 : 0.66

        if let encounter {
            let isMatch = encounter.kind == particle.kind
            forecastMarker.strokeColor = isMatch ? UIColor.systemGreen : UIColor.systemOrange
            forecastLabel.fontColor = forecastMarker.strokeColor
            forecastLabel.text = VectorStrings.value(isMatch ? "MATCH" : "RISK", code: languageCode)
            forecastMarker.isHidden = false
            forecastLabel.isHidden = false
        } else if tEdge <= horizon {
            forecastMarker.strokeColor = UIColor.systemOrange
            forecastLabel.fontColor = UIColor.systemOrange
            forecastLabel.text = VectorStrings.value("EDGE", code: languageCode)
            forecastMarker.isHidden = false
            forecastLabel.isHidden = false
        } else {
            forecastMarker.isHidden = true
            forecastLabel.isHidden = true
        }
        forecastMarker.position = point
        forecastLabel.position = CGPoint(x: max(36, min(size.width - 36, point.x)),
                                         y: max(24, min(size.height - 12, point.y + 26)))
    }

    private func timeUntilExit(of particle: VectorParticle) -> CGFloat {
        let v = particle.velocity
        let p = particle.position
        let x = v.dx > 0 ? (size.width + 18 - p.x) / v.dx :
            (v.dx < 0 ? (-18 - p.x) / v.dx : CGFloat.greatestFiniteMagnitude)
        let y = v.dy > 0 ? (size.height + 18 - p.y) / v.dy :
            (v.dy < 0 ? (-18 - p.y) / v.dy : CGFloat.greatestFiniteMagnitude)
        return max(0, min(x, y))
    }

    private func timeUntilContact(between a: VectorParticle, and b: VectorParticle) -> CGFloat? {
        let rx = a.position.x - b.position.x
        let ry = a.position.y - b.position.y
        let vx = a.velocity.dx - b.velocity.dx
        let vy = a.velocity.dy - b.velocity.dy
        let radius = a.radius + b.radius
        let aa = vx * vx + vy * vy
        guard aa > 0.0001 else { return nil }
        let bb = 2 * (rx * vx + ry * vy)
        let cc = rx * rx + ry * ry - radius * radius
        guard cc > 0 else { return nil } // Already overlapping; not a future contact.
        let discriminant = bb * bb - 4 * aa * cc
        guard discriminant >= 0 else { return nil }
        let t = (-bb - sqrt(discriminant)) / (2 * aa)
        return t > 0 ? t : nil
    }

    private func clearGesture() {
        selected?.selectionRing.isHidden = true
        selected = nil
        gestureOrigin = nil
        hasRedirectedThisGesture = false
        gesturePath.path = nil
        forecastMarker.isHidden = true
        forecastLabel.isHidden = true
    }

    private func flashArena(color: UIColor, opacity: CGFloat) {
        let overlay = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        overlay.fillColor = color
        overlay.strokeColor = .clear
        overlay.alpha = opacity
        overlay.zPosition = 24
        addChild(overlay)
        overlay.run(.sequence([.fadeOut(withDuration: 0.20), .removeFromParent()]))
    }

    // Played only when a previous personal best is surpassed for the first time in a run.
    func celebrateRecord() {
        guard active else { return }
        if effectsEnabled { flashArena(color: .systemYellow, opacity: 0.035) }
        let container = SKNode()
        container.position = CGPoint(x: size.width * 0.5, y: size.height * 0.75)
        container.zPosition = 60
        let backdrop = SKShapeNode(rectOf: CGSize(width: min(242, size.width - 24), height: 57), cornerRadius: 16)
        backdrop.fillColor = UIColor(red: 0.04, green: 0.06, blue: 0.13, alpha: 0.93)
        backdrop.strokeColor = UIColor.systemYellow.withAlphaComponent(0.9)
        backdrop.lineWidth = 1.2
        backdrop.glowWidth = 1
        container.addChild(backdrop)
        let text = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        text.text = VectorStrings.value("NEW BEST!", code: languageCode)
        text.fontSize = 21
        text.fontColor = .systemYellow
        text.verticalAlignmentMode = .center
        text.horizontalAlignmentMode = .center
        container.addChild(text)
        container.setScale(0.82)
        container.alpha = 0
        addChild(container)
        container.run(.sequence([
            .group([.fadeIn(withDuration: 0.16), .scale(to: 1.04, duration: 0.16)]),
            .scale(to: 1, duration: 0.12),
            .wait(forDuration: 0.82),
            .group([.moveBy(x: 0, y: 16, duration: 0.27), .fadeOut(withDuration: 0.27)]),
            .removeFromParent()
        ]))
    }

    private func showRedirectPulse(at point: CGPoint, color: UIColor) {
        let flash = SKShapeNode(circleOfRadius: 21)
        flash.position = point
        flash.strokeColor = color.withAlphaComponent(0.52)
        flash.lineWidth = 2
        flash.glowWidth = 0
        flash.zPosition = 30
        addChild(flash)
        flash.run(.sequence([
            .group([.scale(to: 1.4, duration: 0.16), .fadeOut(withDuration: 0.16)]),
            .removeFromParent()
        ]))
    }
}

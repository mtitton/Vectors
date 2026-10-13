//
//  Theme.swift
//  Vectors
//
//  Created by Marcus Titton on 13/10/26.
//

import SwiftUI
import SpriteKit

// MARK: - Design system (all visuals are drawn in code)
enum VectorTheme {
    static let background = Color(red: 0.018, green: 0.056, blue: 0.115)
    static let panel = Color(red: 0.025, green: 0.070, blue: 0.140)
    static let blue = Color(red: 0.27, green: 0.71, blue: 1.0)
    static let cyan = Color(red: 0.40, green: 0.91, blue: 1.0)
    static let gold = Color(red: 1.0, green: 0.75, blue: 0.26)
    static let red = Color(red: 1.0, green: 0.28, blue: 0.39)
    static let muted = Color(red: 0.55, green: 0.69, blue: 0.81)
}

enum ParticleColor: Int, CaseIterable {
    case cyan, crimson, lime, amber, violet

    var uiColor: UIColor {
        switch self {
        case .cyan: return UIColor(red: 0.20, green: 0.74, blue: 1.0, alpha: 1)
        case .crimson: return UIColor(red: 1.0, green: 0.27, blue: 0.42, alpha: 1)
        case .lime: return UIColor(red: 0.26, green: 0.98, blue: 0.52, alpha: 1)
        case .amber: return UIColor(red: 1.0, green: 0.75, blue: 0.18, alpha: 1)
        // Fifth color: deliberately softer than the old neon look, and
        // clearly distinct from the existing red/blue particles.
        case .violet: return UIColor(red: 0.72, green: 0.52, blue: 1.0, alpha: 1)
        }
    }

    var color: Color { Color(uiColor: uiColor) }
}

struct VectorTitle: View {
    var size: CGFloat = 38

    var body: some View {
        Text("VECTORS")
            .font(.system(size: size, weight: .bold, design: .rounded))
            .tracking(size * 0.17)
            .foregroundStyle(.white)
            .shadow(color: VectorTheme.blue.opacity(0.9), radius: 15)
            .shadow(color: VectorTheme.blue.opacity(0.4), radius: 28)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
    }
}

struct NeonButton: View {
    let title: String
    let symbol: String
    var prominent: Bool = false
    var tint: Color = VectorTheme.blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 28)
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .tracking(3)
                Spacer(minLength: 0)
                if !prominent {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .frame(height: prominent ? 65 : 55)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(prominent ? tint.opacity(0.24) : VectorTheme.panel.opacity(0.86))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(tint.opacity(prominent ? 0.94 : 0.60), lineWidth: prominent ? 2 : 1)
                    }
                    .shadow(color: tint.opacity(prominent ? 0.48 : 0.16), radius: prominent ? 18 : 8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct NeonPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 22)
                    .fill(VectorTheme.panel.opacity(0.94))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(VectorTheme.blue.opacity(0.55), lineWidth: 1)
                    }
                    .shadow(color: VectorTheme.blue.opacity(0.17), radius: 15)
            }
    }
}

/// Animated arcade ambience for menus. Unlike concept images, everything here renders natively.
struct VectorBackdrop: View {
    var animated: Bool = true

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: animated ? 1.0 / 30.0 : 2.0)) { timeline in
                Canvas(rendersAsynchronously: true) { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let center = CGPoint(x: size.width / 2, y: size.height * 0.44)
                    for index in 1...5 {
                        let r = CGFloat(index) * min(size.width, size.height) * 0.19
                        let circle = CGRect(x: center.x-r, y: center.y-r, width: r*2, height: r*2)
                        context.stroke(Path(ellipseIn: circle), with: .color(VectorTheme.blue.opacity(0.09)), lineWidth: 1)
                    }
                    for i in 0...12 {
                        let x = CGFloat(i) * size.width / 12
                        var line = Path()
                        line.move(to: CGPoint(x: x, y: 0))
                        line.addLine(to: CGPoint(x: x, y: size.height))
                        context.stroke(line, with: .color(VectorTheme.blue.opacity(0.055)), lineWidth: 0.6)
                    }
                    for index in 0..<21 {
                        let fi = Double(index)
                        let speed = animated ? time * (0.25 + Double(index % 5) * 0.05) : 0
                        let orbit = 75.0 + Double(index % 8) * 38.0
                        let angle = fi * 2.39996 + speed
                        let x = center.x + CGFloat(cos(angle) * orbit)
                        let y = center.y + CGFloat(sin(angle) * orbit * 1.35)
                        let position = CGPoint(x: x, y: y)
                        guard position.x > 10, position.x < size.width - 10,
                              position.y > 20, position.y < size.height - 20 else { continue }
                        let tint = ParticleColor.allCases[index % ParticleColor.allCases.count].color
                        var trail = Path()
                        trail.move(to: CGPoint(x: x - CGFloat(cos(angle + 0.8)) * 22, y: y - CGFloat(sin(angle + 0.8)) * 22))
                        trail.addLine(to: position)
                        context.stroke(trail, with: .color(tint.opacity(0.18)), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        context.stroke(trail, with: .color(tint.opacity(0.46)), style: StrokeStyle(lineWidth: 2.3, lineCap: .round))
                        context.fill(Path(ellipseIn: CGRect(x: x-13, y: y-13, width: 26, height: 26)), with: .color(tint.opacity(0.06)))
                        context.fill(Path(ellipseIn: CGRect(x: x-4, y: y-4, width: 8, height: 8)), with: .color(tint.opacity(0.94)))
                        context.stroke(Path(ellipseIn: CGRect(x: x-10, y: y-10, width: 20, height: 20)), with: .color(tint.opacity(0.48)), lineWidth: 2)
                        let dir = angle + CGFloat.pi * 0.5
                        let dx = CGFloat(cos(dir)), dy = CGFloat(sin(dir))
                        let arrowStart = CGPoint(x: x + dx * 12, y: y + dy * 12)
                        let arrowEnd = CGPoint(x: x + dx * 26, y: y + dy * 26)
                        var arrow = Path()
                        arrow.move(to: arrowStart)
                        arrow.addLine(to: arrowEnd)
                        arrow.move(to: CGPoint(x: arrowEnd.x - dx * 7 - dy * 5, y: arrowEnd.y - dy * 7 + dx * 5))
                        arrow.addLine(to: arrowEnd)
                        arrow.addLine(to: CGPoint(x: arrowEnd.x - dx * 7 + dy * 5, y: arrowEnd.y - dy * 7 - dx * 5))
                        context.stroke(arrow, with: .color(tint.opacity(0.83)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                    }
                }
                .drawingGroup()
            }
        }
        .background {
            RadialGradient(colors: [Color(red: 0.035, green: 0.115, blue: 0.22), VectorTheme.background, .black],
                           center: .center, startRadius: 5, endRadius: 600)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

//
//  RootGameView.swift
//  Vectors
//
//  Created by Marcus Titton on 13/10/26.
//

import SwiftUI
import SpriteKit

struct RootGameView: View {
    @StateObject private var game = GameSession()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            if game.phase == .home {
                VectorBackdrop(animated: game.effectsOn)
            } else {
                VectorTheme.background.ignoresSafeArea()
            }
            switch game.phase {
            case .home: HomeScreen(game: game)
            case .tutorial: TutorialScreen(game: game)
            case .settings: SettingsScreen(game: game)
            case .statistics: StatisticsScreen(game: game)
            case .rankings: RankingsScreen(game: game)
            case .dailyIntro: DailyIntroScreen(game: game)
            case .playing, .paused, .gameOver: GameScreen(game: game)
            }
        }
        .tint(VectorTheme.cyan)
        .environment(\.locale, Locale(identifier: game.languageCode))
        .onAppear { game.authenticateGameCenter() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Retry pending Game Center uploads after returning online.
                game.authenticateGameCenter()
            }
        }
    }
}

private struct HomeScreen: View {
    @ObservedObject var game: GameSession
    @State private var spinPlayRing = false

    var body: some View {
        GeometryReader { layout in
            ScrollView(.vertical) {
            VStack(spacing: 0) {
                HStack {
                    Label(game.text("HIGH SCORE"), systemImage: "trophy.fill")
                        .foregroundStyle(VectorTheme.gold)
                    Spacer()
                    Text(game.bestScore.formatted())
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .tracking(1.5)
                .padding(16)
                .background(VectorTheme.panel.opacity(0.72), in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(VectorTheme.blue.opacity(0.25)))
                Spacer(minLength: 8)
                VectorTitle(size: min(49, layout.size.width * 0.12))
                Text(game.text("REDIRECT PARTICLES. BUILD COMBOS."))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(1.4)
                    .foregroundStyle(VectorTheme.muted)
                    .padding(.top, 13)
                Spacer(minLength: 13)
                Button { game.startGame() } label: {
                    ZStack {
                        Circle()
                            .fill(VectorTheme.blue.opacity(0.13))
                            .overlay(Circle().stroke(VectorTheme.cyan.opacity(0.95), lineWidth: 2.5))
                            .shadow(color: VectorTheme.blue.opacity(0.85), radius: 27)
                        Circle().stroke(VectorTheme.cyan.opacity(0.20), lineWidth: 11).padding(8)
                        Circle()
                            .trim(from: 0.02, to: 0.31)
                            .stroke(VectorTheme.cyan.opacity(0.87), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(spinPlayRing ? 360 : 0))
                            .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: spinPlayRing)
                            .padding(-11)
                        Circle()
                            .trim(from: 0.03, to: 0.27)
                            .stroke(VectorTheme.gold.opacity(0.68), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                            .rotationEffect(.degrees(spinPlayRing ? -360 : 0))
                            .animation(.linear(duration: 14).repeatForever(autoreverses: false), value: spinPlayRing)
                            .padding(12)
                        Circle().stroke(VectorTheme.blue.opacity(0.23), style: StrokeStyle(lineWidth: 1, dash: [5, 9])).padding(-17)
                        VStack(spacing: 9) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 47))
                            Text(game.text("PLAY"))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .tracking(4)
                        }
                        .foregroundStyle(.white)
                    }
                    .frame(width: min(184, layout.size.height * 0.26), height: min(184, layout.size.height * 0.26))
                }
                .accessibilityLabel(game.text("Play Vectors"))
                .onAppear { spinPlayRing = game.effectsOn }
                .onDisappear { spinPlayRing = false }
                Spacer(minLength: 12)
                VStack(spacing: 10) {
                    NeonButton(title: game.text("DAILY CHALLENGE"), symbol: "calendar", tint: VectorTheme.gold) { game.openDaily() }
                    if game.gameCenterAvailable {
                        NeonButton(title: game.text("RANKINGS & ACHIEVEMENTS"), symbol: "trophy.fill") { game.rankings() }
                    }
                    NeonButton(title: game.text("HOW TO PLAY"), symbol: "hand.draw") { game.tutorial() }
                    NeonButton(title: game.text("MY STATS"), symbol: "chart.bar.xaxis", tint: VectorTheme.gold) { game.statistics() }
                    NeonButton(title: game.text("SETTINGS"), symbol: "gearshape") { game.settings() }
                }
                .frame(maxWidth: 340)
                Spacer(minLength: 12)
                Text(game.text("ONE SWIPE CAN CHANGE EVERYTHING"))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(VectorTheme.muted)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity)
            .frame(minHeight: layout.size.height)
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct GameScreen: View {
    @ObservedObject var game: GameSession

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Button { game.pause() } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(VectorTheme.cyan)
                        .frame(width: 46, height: 46)
                        .background(VectorTheme.panel.opacity(0.88), in: Circle())
                        .overlay(Circle().stroke(VectorTheme.blue.opacity(0.65)))
                }
                .disabled(game.phase != .playing)
                Spacer(minLength: 3)
                VStack(spacing: 3) {
                    if game.mode == .daily {
                        Text(game.text("DAILY"))
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(VectorTheme.gold)
                    }
                    Text(game.score.formatted())
                        .font(.system(size: 36, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.easeOut(duration: 0.18), value: game.score)
                        .foregroundStyle(.white)
                    Text("\(game.text("BEST")) \(max(game.mode == .daily ? game.dailyBestScore : game.bestScore, game.score).formatted())")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(VectorTheme.muted)
                }
                .accessibilityElement(children: .combine)
                Spacer(minLength: 3)
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: index < game.lives ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundStyle(VectorTheme.red)
                    }
                }
                .frame(minWidth: 75)
                .accessibilityLabel("\(game.lives) \(game.text("lives remaining"))")
            }
            .padding(.horizontal, 2)

            HStack {
                Text(game.text("COMBO"))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(VectorTheme.gold)
                Text(game.combo > 1 ? "×\(game.combo)" : game.text("READY"))
                    .font(.system(size: game.combo > 1 ? 28 : 14, weight: .black, design: .rounded))
                    .foregroundStyle(game.combo > 1 ? VectorTheme.gold : VectorTheme.muted)
                    .shadow(color: game.combo > 1 ? VectorTheme.gold.opacity(0.17) : .clear, radius: 4)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.27, dampingFraction: 0.65), value: game.combo)
                Spacer()
                Text("\(game.text("MATCHES"))  \(game.matches)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(VectorTheme.muted)
            }
            .padding(.horizontal, 7)

            ZStack {
                SpriteView(scene: game.scene, options: [.allowsTransparency, .ignoresSiblingOrder])
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        RadialGradient(
                            colors: [
                                Color(red: 0.055, green: 0.135, blue: 0.225),
                                Color(red: 0.028, green: 0.083, blue: 0.155),
                                Color(red: 0.016, green: 0.053, blue: 0.111)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 440
                        )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .accessibilityLabel(game.text("Game arena. Swipe on a particle to send it in any direction."))
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(colors: [VectorTheme.cyan.opacity(0.62), VectorTheme.blue.opacity(0.38), VectorTheme.cyan.opacity(0.48)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.0
                    )
                    .allowsHitTesting(false)
                VStack(spacing: 0) {
                    Capsule()
                        .fill(VectorTheme.cyan.opacity(0.38))
                        .frame(width: 65, height: 2)
                    Spacer()
                    Capsule()
                        .fill(VectorTheme.blue.opacity(0.32))
                        .frame(width: 45, height: 2)
                }
                .allowsHitTesting(false)
                if game.phase == .paused {
                    Color.black.opacity(0.78)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    PauseOverlay(game: game)
                        .padding(20)
                }
                if game.phase == .gameOver {
                    Color.black.opacity(0.82)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    ResultOverlay(game: game)
                        .padding(16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                Image(systemName: "hand.draw")
                Text(game.text("SWIPE TO STEER • FOLLOW THE TRAJECTORY"))
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .tracking(0.2)
            .foregroundStyle(VectorTheme.muted)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)
            .opacity(game.phase == .playing ? 1 : 0)
            .accessibilityHidden(game.phase != .playing)
        }
        .padding(.horizontal, 17)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
}

private struct PauseOverlay: View {
    @ObservedObject var game: GameSession

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "pause.circle")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(VectorTheme.cyan)
            Text(game.text("PAUSED"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .tracking(5)
            Text("\(game.text("SCORE"))  \(game.score.formatted())")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(VectorTheme.muted)
            NeonButton(title: game.text("RESUME"), symbol: "play.fill", prominent: true) { game.resume() }
            NeonButton(title: game.text("RESTART"), symbol: "arrow.clockwise") { game.restart() }
            NeonButton(title: game.text("HOME"), symbol: "house") { game.home() }
        }
        .frame(maxWidth: 320)
        .padding(22)
        .background(VectorTheme.background.opacity(0.96), in: RoundedRectangle(cornerRadius: 23))
        .overlay(RoundedRectangle(cornerRadius: 23).stroke(VectorTheme.blue.opacity(0.60)))
    }
}

private struct ResultOverlay: View {
    @ObservedObject var game: GameSession
    @State private var recordVisible = false

    var body: some View {
        VStack(spacing: 9) {
            Text(game.text("GAME OVER"))
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundStyle(VectorTheme.red)
                .shadow(color: VectorTheme.red.opacity(0.44), radius: 12)
            Text(game.score.formatted())
                .font(.system(size: 50, weight: .light, design: .rounded))
                .monospacedDigit()
            if game.lastRun?.isNewRecord == true {
                Label(game.text(game.mode == .daily ? "NEW DAILY BEST!" : "NEW BEST!"), systemImage: "trophy.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(VectorTheme.gold)
                    .padding(.horizontal, 17)
                    .padding(.vertical, 7)
                    .background(VectorTheme.gold.opacity(0.10), in: Capsule())
                    .overlay(Capsule().stroke(VectorTheme.gold.opacity(0.7), lineWidth: 1))
                    .shadow(color: VectorTheme.gold.opacity(0.7), radius: 18)
                    .scaleEffect(recordVisible ? 1 : 0.75)
                    .opacity(recordVisible ? 1 : 0)
            } else {
                Text("\(game.text("BEST")) \((game.mode == .daily ? game.dailyBestScore : game.bestScore).formatted())")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(VectorTheme.muted)
            }
            Rectangle().fill(VectorTheme.blue.opacity(0.45)).frame(height: 1)
                .padding(.vertical, 5)
            resultLine(game.text("LONGEST COMBO"), value: "×\(game.lastRun?.maxCombo ?? 0)")
            resultLine(game.text("MATCHES"), value: "\(game.matches)")
            resultLine(game.text("REDIRECTS"), value: "\(game.redirects)")
            if game.matches > 0 {
                resultLine(game.text("SWIPES PER MATCH"), value: String(format: "%.1f", Double(game.redirects) / Double(game.matches)))
            }
            NeonButton(title: game.text("RETRY"), symbol: "arrow.clockwise", prominent: true) { game.restart() }
                .padding(.top, 8)
            NeonButton(title: game.text("HOME"), symbol: "house") { game.home() }
        }
        .frame(maxWidth: 320)
        .padding(17)
        .background(VectorTheme.background.opacity(0.97), in: RoundedRectangle(cornerRadius: 23))
        .overlay(RoundedRectangle(cornerRadius: 23).stroke(VectorTheme.blue.opacity(0.7)))
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.60).delay(0.12)) { recordVisible = true } }
    }

    private func resultLine(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(VectorTheme.muted)
            Spacer()
            Text(value).foregroundStyle(.white)
        }
        .font(.system(size: 13, weight: .medium, design: .monospaced))
    }
}

private struct DailyIntroScreen: View {
    @ObservedObject var game: GameSession

    var body: some View {
        VStack(spacing: 20) {
            ScreenHeader(title: game.text("DAILY CHALLENGE"), back: game.home)
            Spacer(minLength: 0)
            NeonPanel {
                VStack(spacing: 17) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 45, weight: .light))
                        .foregroundStyle(VectorTheme.gold)
                    Text(game.text("TODAY'S CHALLENGE"))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(Date.now, format: .dateTime.day().month(.wide).year())
                        .font(.system(size: 14))
                        .foregroundStyle(VectorTheme.muted)
                    Text(game.text("Today’s particles follow a reproducible sequence. Aim for the highest score!"))
                        .font(.system(size: 14))
                        .foregroundStyle(VectorTheme.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(game.text("DAILY BEST"))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(VectorTheme.gold)
                    Text(game.dailyBestScore.formatted())
                        .font(.system(size: 50, weight: .light, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
            }
            Text(game.text("No attempt limit. The daily sequence resets at 00:00 UTC."))
                .font(.system(size: 12))
                .foregroundStyle(VectorTheme.muted)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            NeonButton(title: game.text("START DAILY"), symbol: "play.fill", prominent: true, tint: VectorTheme.gold) {
                game.startGame(mode: .daily)
            }
        }
        .padding(20)
    }
}

// MARK: - Game Center
private struct RankingsScreen: View {
    @ObservedObject var game: GameSession

    var body: some View {
        VStack(spacing: 18) {
            ScreenHeader(title: game.text("GAME CENTER"), back: game.home)
            Spacer(minLength: 0)
            NeonPanel {
                VStack(spacing: 10) {
                    Image(systemName: game.gameCenterSignedIn ? "checkmark.shield.fill" : "person.crop.circle.badge.questionmark")
                        .font(.system(size: 37, weight: .light))
                        .foregroundStyle(game.gameCenterSignedIn ? VectorTheme.cyan : VectorTheme.gold)
                    Text(game.text(game.gameCenterSignedIn ? "CONNECTED TO GAME CENTER" : "CONNECT TO GAME CENTER"))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(game.text(game.gameCenterSignedIn ? "Compare your best scores with other players." : "Sign in to Game Center to compare scores and unlock achievements."))
                        .font(.system(size: 12))
                        .foregroundStyle(VectorTheme.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            if VectorsGameCenterIDs.hasEndless {
                NeonButton(title: game.text("ENDLESS RANKING"), symbol: "infinity", tint: VectorTheme.cyan) {
                    game.showLeaderboard(mode: .endless)
                }
            }
            if VectorsGameCenterIDs.hasDaily {
                NeonButton(title: game.text("DAILY RANKING"), symbol: "calendar", tint: VectorTheme.gold) {
                    game.showLeaderboard(mode: .daily)
                }
            }
            if VectorsGameCenterIDs.hasAchievements {
                NeonButton(title: game.text("ACHIEVEMENTS"), symbol: "medal.fill", tint: VectorTheme.gold) {
                    game.showAchievements()
                }
            }
            Spacer(minLength: 0)
            NeonButton(title: game.text("BACK HOME"), symbol: "house") { game.home() }
        }
        .padding(20)
    }
}

private struct TutorialScreen: View {
    @ObservedObject var game: GameSession

    var body: some View {
        VStack(spacing: 16) {
            ScreenHeader(title: game.text("HOW TO PLAY"), back: game.home)
            ScrollView {
                VStack(spacing: 15) {
                    TutorialStep(number: "01", title: game.text("SWIPE TO STEER"), detail: game.text("Touch any particle and swipe where you want it to go. Its direction changes instantly, keeping its speed."), color: VectorTheme.cyan, icon: "hand.draw")
                    TutorialStep(number: "02", title: game.text("FOLLOW THE PREVIEW"), detail: game.text("While swiping, a preview shows the first predicted encounter: green for a match, orange for a risk or the edge. It never steers for you."), color: .green, icon: "point.topleft.down.curvedto.point.bottomright.up")
                    TutorialStep(number: "03", title: game.text("MATCH COLORS"), detail: game.text("Steer particles independently so matching colors meet. You have more time to chain matches into combos."), color: VectorTheme.gold, icon: "circle.hexagongrid.fill")
                    TutorialStep(number: "04", title: game.text("AVOID HAZARDS"), detail: game.text("Avoid different-color collisions and escapes. An orange ring warns when a particle is near an edge. You have three lives."), color: VectorTheme.red, icon: "heart.fill")
                    NeonPanel {
                        VStack(spacing: 12) {
                            Text(game.text("EACH PARTICLE MOVES INDEPENDENTLY"))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundStyle(VectorTheme.muted)
                            TutorialGraphic()
                                .frame(height: 142)
                            Text(game.text("Swipe from a particle towards its new heading"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(VectorTheme.cyan)
                        }
                    }
                }
                .padding(.bottom, 10)
            }
            .scrollIndicators(.hidden)
            NeonButton(title: game.text("LET'S PLAY"), symbol: "play.fill", prominent: true) { game.startGame() }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
}

private struct TutorialStep: View {
    let number: String
    let title: String
    let detail: String
    let color: Color
    let icon: String

    var body: some View {
        NeonPanel {
            HStack(alignment: .top, spacing: 15) {
                VStack(spacing: 8) {
                    Text(number)
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                    Image(systemName: icon)
                        .font(.system(size: 24))
                }
                .foregroundStyle(color)
                .frame(width: 45)
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(.white)
                    Text(detail)
                        .font(.system(size: 14))
                        .foregroundStyle(VectorTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private struct TutorialGraphic: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { ctx, s in
                let blue = CGPoint(x: s.width*0.25, y: s.height*0.53)
                let blueTarget = CGPoint(x: s.width*0.62, y: s.height*0.27)
                let secondBlue = CGPoint(x: s.width*0.77, y: s.height*0.18)
                let red = CGPoint(x: s.width*0.67, y: s.height*0.79)

                // A single cyan particle is steered directly towards a second cyan particle.
                var swipe = Path()
                swipe.move(to: blue)
                swipe.addLine(to: blueTarget)
                ctx.stroke(swipe, with: .color(VectorTheme.cyan.opacity(0.85)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [6, 4]))
                drawNode(ctx: ctx, point: blue, tint: VectorTheme.cyan, direction: CGPoint(x: 1, y: -0.70))
                drawNode(ctx: ctx, point: secondBlue, tint: VectorTheme.cyan, direction: CGPoint(x: -0.7, y: 0.6))
                drawNode(ctx: ctx, point: red, tint: VectorTheme.red, direction: CGPoint(x: 0.8, y: -0.4))
            }
            .background(VectorTheme.background.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func drawNode(ctx: GraphicsContext, point: CGPoint, tint: Color, direction: CGPoint) {
        ctx.stroke(Path(ellipseIn: CGRect(x: point.x-13, y: point.y-13, width: 26, height: 26)), with: .color(tint), lineWidth: 3)
        ctx.fill(Path(ellipseIn: CGRect(x: point.x-3, y: point.y-3, width: 6, height: 6)), with: .color(.white))
        let end = CGPoint(x: point.x + direction.x*28, y: point.y + direction.y*28)
        var arrow = Path()
        arrow.move(to: point)
        arrow.addLine(to: end)
        ctx.stroke(arrow, with: .color(tint), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
    }
}

private struct StatisticsScreen: View {
    @ObservedObject var game: GameSession

    var body: some View {
        VStack(spacing: 20) {
            ScreenHeader(title: game.text("MY STATS"), back: game.home)
            Spacer(minLength: 0)
            NeonPanel {
                VStack(spacing: 16) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(VectorTheme.gold)
                    Text(game.text("PERSONAL BEST"))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(VectorTheme.muted)
                    Text(game.bestScore.formatted())
                        .font(.system(size: 54, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
            }
            NeonPanel {
                VStack(spacing: 19) {
                    statRow(game.text("GAMES PLAYED"), value: game.played.formatted())
                    statRow(game.text("TOTAL MATCHES"), value: game.lifetimeMatches.formatted())
                    statRow(game.text("BEST COMBO"), value: "×\(game.lifetimeBestCombo)")
                    statRow(game.text("DAILY BEST"), value: game.dailyBestScore.formatted())
                }
            }
            Spacer(minLength: 0)
            NeonButton(title: game.text("PLAY"), symbol: "play.fill", prominent: true) { game.startGame() }
        }
        .padding(20)
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(VectorTheme.muted)
            Spacer()
            Text(value).foregroundStyle(.white)
        }
        .font(.system(size: 14, weight: .medium, design: .monospaced))
    }
}

private struct SettingsScreen: View {
    @ObservedObject var game: GameSession

    var body: some View {
        VStack(spacing: 16) {
            ScreenHeader(title: game.text("SETTINGS"), back: game.home)
            ScrollView {
                VStack(spacing: 16) {
                    NeonPanel {
                        VStack(spacing: 21) {
                            Toggle(isOn: $game.soundOn) {
                                Label(game.text("GAME SOUNDS"), systemImage: "speaker.wave.2")
                            }
                            Divider().overlay(VectorTheme.blue.opacity(0.2))
                            Toggle(isOn: $game.hapticsOn) {
                                Label(game.text("HAPTIC FEEDBACK"), systemImage: "hand.tap")
                            }
                            Divider().overlay(VectorTheme.blue.opacity(0.2))
                            Toggle(isOn: $game.effectsOn) {
                                Label(game.text("VISUAL EFFECTS"), systemImage: "sparkles")
                            }
                            Divider().overlay(VectorTheme.blue.opacity(0.2))
                            VStack(alignment: .leading, spacing: 12) {
                                Label(game.text("LANGUAGE"), systemImage: "globe")
                                Picker(game.text("LANGUAGE"), selection: $game.languagePreference) {
                                    ForEach(GameLanguagePreference.allCases) { option in
                                        Text(option.displayName).tag(option)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .environment(\.locale, Locale(identifier: game.languageCode))
                            }
                        }
                        .tint(VectorTheme.cyan)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }

                    NeonPanel {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(game.text("HELP & PRIVACY"))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .tracking(1.3)
                                .foregroundStyle(VectorTheme.muted)

                            if let privacyURL = URL(string: "https://mtitton.github.io/Vectors/privacy.html?lang=\(game.languageCode)") {
                                Link(destination: privacyURL) {
                                    HStack {
                                        Label(game.text("PRIVACY POLICY"), systemImage: "hand.raised")
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                    }
                                    .contentShape(Rectangle())
                                }
                            }
                            Divider().overlay(VectorTheme.blue.opacity(0.2))
                            if let supportURL = URL(string: "https://mtitton.github.io/Vectors/support.html?lang=\(game.languageCode)") {
                                Link(destination: supportURL) {
                                    HStack {
                                        Label(game.text("SUPPORT"), systemImage: "envelope")
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                    }
                                    .contentShape(Rectangle())
                                }
                            }
                            Text("mvtitton@gmail.com")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(VectorTheme.muted)
                                .textSelection(.enabled)
                        }
                        .tint(VectorTheme.cyan)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }

                    Text("Vectors 1.0  •  iPhone")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(VectorTheme.muted)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            NeonButton(title: game.text("BACK HOME"), symbol: "house") { game.home() }
        }
        .padding(20)
    }
}

private struct ScreenHeader: View {
    let title: String
    let back: () -> Void

    var body: some View {
        HStack {
            Button(action: back) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 19, weight: .semibold))
                    .frame(width: 46, height: 46)
                    .background(VectorTheme.panel.opacity(0.8), in: Circle())
                    .overlay(Circle().stroke(VectorTheme.blue.opacity(0.6)))
            }
            Spacer()
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 46, height: 46)
        }
    }
}

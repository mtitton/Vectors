//
//  GameSession.swift
//  Vectors
//
//  Created by Marcus Titton on 13/10/26.
//

import SwiftUI
import SpriteKit
import UIKit

enum GamePhase {
    case home, tutorial, playing, paused, gameOver, statistics, settings, dailyIntro, rankings
}

enum GameRunMode { case endless, daily }

struct RunResult {
    let score: Int
    let matches: Int
    let redirects: Int
    let maxCombo: Int
    let isNewRecord: Bool
}

final class GameSession: ObservableObject {
    @Published var phase: GamePhase = .home
    @Published private(set) var mode: GameRunMode = .endless
    @Published var languagePreference: GameLanguagePreference {
        didSet {
            UserDefaults.standard.set(languagePreference.rawValue, forKey: "vectors.language")
            scene.languageCode = languagePreference.effectiveCode
        }
    }
    var languageCode: String { languagePreference.effectiveCode }
    func text(_ value: String) -> String { VectorStrings.value(value, code: languageCode) }
    var gameCenterAvailable: Bool { VectorsGameCenterIDs.isConfigured }
    @Published private(set) var gameCenterSignedIn = false
    func showLeaderboard(mode: GameRunMode) { GameCenterService.shared.showLeaderboard(mode: mode) }
    func showAchievements() { GameCenterService.shared.showAchievements() }
    func authenticateGameCenter() { GameCenterService.shared.authenticate() }
    // Daily seeds and Game Center's recurring leaderboard both reset at 00:00 UTC.
    var todayKey: Int { GameCenterService.currentUTCKey }
    @Published private(set) var dailyBestScore = 0
    @Published private(set) var score = 0
    @Published private(set) var bestScore: Int
    @Published private(set) var lives = 3
    @Published private(set) var combo = 0
    @Published private(set) var matches = 0
    @Published private(set) var redirects = 0
    @Published private(set) var played: Int
    @Published private(set) var lifetimeMatches: Int
    @Published private(set) var lifetimeRedirects: Int
    @Published private(set) var lifetimeBestCombo: Int
    @Published private(set) var lastRun: RunResult?
    @Published var soundOn: Bool {
        didSet { UserDefaults.standard.set(soundOn, forKey: "vectors.soundOn") }
    }
    @Published var hapticsOn: Bool {
        didSet { UserDefaults.standard.set(hapticsOn, forKey: "vectors.hapticsOn") }
    }
    @Published var effectsOn: Bool {
        didSet {
            UserDefaults.standard.set(effectsOn, forKey: "vectors.effectsOn")
            scene.effectsEnabled = effectsOn
        }
    }

    private var runRecordCelebrated = false
    private let audio = VectorAudio()
    private var runMaxCombo = 0
    private var runDailyUTCKey = 0

    lazy var scene: VectorsScene = {
        let scene = VectorsScene(size: CGSize(width: 390, height: 630))
        scene.scaleMode = .resizeFill
        scene.languageCode = languageCode
        scene.effectsEnabled = effectsOn
        scene.backgroundColor = .clear
        scene.onHUD = { [weak self] score, combo, lives, matches, redirects in
            self?.score = score
            self?.combo = combo
            self?.lives = lives
            self?.matches = matches
            self?.redirects = redirects
            self?.runMaxCombo = max(self?.runMaxCombo ?? 0, combo)
            guard let self, !self.runRecordCelebrated else { return }
            let previousBest = self.mode == .daily ? self.dailyBestScore : self.bestScore
            if previousBest > 0, score > previousBest {
                self.runRecordCelebrated = true
                self.scene.celebrateRecord()
                self.playEffect(.record)
            }
        }
        scene.onEffect = { [weak self] effect in self?.playEffect(effect) }
        scene.onGameOver = { [weak self] in self?.finishRun() }
        return scene
    }()

    init() {
        let defaults = UserDefaults.standard
        bestScore = defaults.integer(forKey: "vectors.bestScore")
        languagePreference = GameLanguagePreference(rawValue: defaults.string(forKey: "vectors.language") ?? "automatic") ?? .automatic
        let key = GameCenterService.currentUTCKey
        dailyBestScore = defaults.integer(forKey: "vectors.dailyDay") == key ? defaults.integer(forKey: "vectors.dailyBestScore") : 0
        played = defaults.integer(forKey: "vectors.played")
        lifetimeMatches = defaults.integer(forKey: "vectors.lifetimeMatches")
        lifetimeRedirects = defaults.integer(forKey: "vectors.lifetimeRedirects")
        lifetimeBestCombo = defaults.integer(forKey: "vectors.lifetimeBestCombo")
        soundOn = defaults.object(forKey: "vectors.soundOn") as? Bool ?? true
        hapticsOn = defaults.object(forKey: "vectors.hapticsOn") as? Bool ?? true
        effectsOn = defaults.object(forKey: "vectors.effectsOn") as? Bool ?? !UIAccessibility.isReduceMotionEnabled
        gameCenterSignedIn = GameCenterService.shared.isAuthenticated
        GameCenterService.shared.onAuthenticationChange = { [weak self] authenticated in
            self?.gameCenterSignedIn = authenticated
        }
        GameCenterService.shared.prepareLocalProgress(
            bestScore: bestScore, dailyBest: dailyBestScore, dailyUTCKey: todayKey,
            lifetimeMatches: lifetimeMatches, lifetimeRedirects: lifetimeRedirects,
            lifetimeBestCombo: lifetimeBestCombo, gamesPlayed: played)
    }

    func startGame(mode requestedMode: GameRunMode = .endless) {
        mode = requestedMode
        runDailyUTCKey = todayKey
        if mode == .daily { refreshDailyBest() }
        score = 0; lives = 3; combo = 0; matches = 0; redirects = 0
        runMaxCombo = 0
        runRecordCelebrated = false
        lastRun = nil
        phase = .playing
        scene.languageCode = languageCode
        scene.startNewGame(seed: mode == .daily ? runDailyUTCKey : nil)
    }

    func restart() { startGame(mode: mode) }
    func openDaily() { refreshDailyBest(); phase = .dailyIntro }
    private func refreshDailyBest() {
        let defaults = UserDefaults.standard
        dailyBestScore = defaults.integer(forKey: "vectors.dailyDay") == todayKey
            ? defaults.integer(forKey: "vectors.dailyBestScore") : 0
    }

    func pause() {
        guard phase == .playing else { return }
        scene.pauseSimulation()
        phase = .paused
    }

    func resume() {
        guard phase == .paused else { return }
        phase = .playing
        scene.resumeSimulation()
    }

    func home() {
        refreshDailyBest()
        scene.pauseSimulation()
        phase = .home
    }

    func tutorial() { phase = .tutorial }
    func settings() { phase = .settings }
    func statistics() { phase = .statistics }
    func rankings() { phase = .rankings }

    private func finishRun() {
        guard phase == .playing else { return }
        let newRecord: Bool
        if mode == .daily {
            refreshDailyBest()
            newRecord = runDailyUTCKey == todayKey && score > dailyBestScore
            if newRecord {
                dailyBestScore = score
                UserDefaults.standard.set(todayKey, forKey: "vectors.dailyDay")
                UserDefaults.standard.set(score, forKey: "vectors.dailyBestScore")
            }
        } else {
            newRecord = score > bestScore
            if newRecord {
                bestScore = score
                UserDefaults.standard.set(bestScore, forKey: "vectors.bestScore")
            }
        }
        played += 1
        lifetimeMatches += matches
        lifetimeRedirects += redirects
        lifetimeBestCombo = max(lifetimeBestCombo, runMaxCombo)
        UserDefaults.standard.set(played, forKey: "vectors.played")
        UserDefaults.standard.set(lifetimeMatches, forKey: "vectors.lifetimeMatches")
        UserDefaults.standard.set(lifetimeRedirects, forKey: "vectors.lifetimeRedirects")
        UserDefaults.standard.set(lifetimeBestCombo, forKey: "vectors.lifetimeBestCombo")
        lastRun = RunResult(score: score, matches: matches, redirects: redirects,
                            maxCombo: runMaxCombo, isNewRecord: newRecord)
        GameCenterService.shared.recordResult(
            score: score, mode: mode, dailyUTCKey: runDailyUTCKey,
            lifetimeMatches: lifetimeMatches, lifetimeRedirects: lifetimeRedirects,
            lifetimeBestCombo: lifetimeBestCombo, gamesPlayed: played)
        phase = .gameOver
        if hapticsOn { UINotificationFeedbackGenerator().notificationOccurred(newRecord ? .success : .warning) }
        if soundOn { audio.play(newRecord && !runRecordCelebrated ? .record : .gameOver) }
    }

    private func playEffect(_ effect: GameEffect) {
        if soundOn { audio.play(effect) }
        guard hapticsOn else { return }
        switch effect {
        case .redirect: UISelectionFeedbackGenerator().selectionChanged()
        case .match: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .combo(let level):
            UIImpactFeedbackGenerator(style: level >= 5 ? .medium : .light).impactOccurred()
        case .damage: UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .record: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .gameOver: break
        }
    }
}

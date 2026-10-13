//
//  GameCenterService.swift
//  Vectors
//
//  Created by Marcus Titton on 13/10/26.
//

import Foundation
import GameKit
import UIKit

/// Use the exact identifiers created in App Store Connect. Keeping an ID empty
/// deliberately disables that item; a local build must never pretend to have
/// an active online leaderboard or achievement.
enum VectorsGameCenterIDs {
    // Classic, highest score first, integer points.
    static let endlessLeaderboard = ""
    // Recurring, start 00:00 UTC, duration/restart interval of 24 hours.
    static let dailyLeaderboard = ""

    static let firstMatch = ""
    static let hundredRedirects = ""
    static let fiveCombo = ""
    static let tenCombo = ""
    static let fiveThousandPoints = ""
    static let hundredGames = ""

    static var hasEndless: Bool { !endlessLeaderboard.isEmpty }
    static var hasDaily: Bool { !dailyLeaderboard.isEmpty }
    static var hasLeaderboards: Bool { hasEndless || hasDaily }
    static var hasAchievements: Bool {
        [firstMatch, hundredRedirects, fiveCombo, tenCombo,
         fiveThousandPoints, hundredGames].contains { !$0.isEmpty }
    }
    static var isConfigured: Bool { hasLeaderboards || hasAchievements }
}

/// Owns GameKit UI and network calls; the game remains fully playable offline.
/// Score queues survive restarts. A stale daily score is NEVER submitted to a
/// later occurrence of the recurring leaderboard.
final class GameCenterService: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterService()
    private override init() { super.init() }

    var onAuthenticationChange: ((Bool) -> Void)?
    var isAuthenticated: Bool { GKLocalPlayer.local.isAuthenticated }
    private enum Destination {
        case leaderboard(GameRunMode)
        case achievements
    }
    private var pendingDestination: Destination?
    private var authenticationStarted = false
    private var syncingEndless = false
    private var syncingDaily = false
    private var syncingAchievements = false

    private let endlessQueueKey = "vectors.gc.pending.endless"
    private let dailyQueueKey = "vectors.gc.pending.daily"
    private let dailyQueueDateKey = "vectors.gc.pending.dailyUTCDate"
    private let earnedMilestonesKey = "vectors.gc.earnedMilestones"

    func authenticate() {
        guard VectorsGameCenterIDs.isConfigured else { return }
        guard !authenticationStarted else {
            onAuthenticationChange?(GKLocalPlayer.local.isAuthenticated)
            if GKLocalPlayer.local.isAuthenticated { flush() }
            return
        }
        authenticationStarted = true
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let viewController {
                    self.topController()?.present(viewController, animated: true)
                    return
                }
                let authenticated = GKLocalPlayer.local.isAuthenticated
                self.onAuthenticationChange?(authenticated)
                if authenticated {
                    self.flush()
                    if let destination = self.pendingDestination {
                        self.pendingDestination = nil
                        self.navigate(to: destination)
                    }
                } else {
                    self.pendingDestination = nil
                    if let error {
                        print("[Vectors][Game Center] Authentication: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    func showLeaderboard(mode: GameRunMode) {
        let id = mode == .daily ? VectorsGameCenterIDs.dailyLeaderboard : VectorsGameCenterIDs.endlessLeaderboard
        guard !id.isEmpty else { return }
        navigate(to: .leaderboard(mode))
    }

    func showAchievements() {
        guard VectorsGameCenterIDs.hasAchievements else { return }
        navigate(to: .achievements)
    }

    private func navigate(to destination: Destination) {
        guard GKLocalPlayer.local.isAuthenticated else {
            pendingDestination = destination
            authenticate()
            return
        }
        guard let presenter = topController(), !(presenter is GKGameCenterViewController) else { return }
        let viewController: GKGameCenterViewController
        switch destination {
        case .leaderboard(let mode):
            let id = mode == .daily ? VectorsGameCenterIDs.dailyLeaderboard : VectorsGameCenterIDs.endlessLeaderboard
            guard !id.isEmpty else { return }
            if #available(iOS 18.0, *) {
                viewController = GKGameCenterViewController(leaderboardID: id,
                    playerScope: .global, timeScope: .allTime)
            } else {
                // iOS 17: opening the leaderboard dashboard is a safe fallback.
                // Do not use iOS 18-only initializers without an availability check.
                viewController = GKGameCenterViewController(state: .leaderboards)
            }
        case .achievements:
            viewController = GKGameCenterViewController(state: .achievements)
        }
        viewController.gameCenterDelegate = self
        presenter.present(viewController, animated: true)
    }

    /// Called on EVERY completed run, even without connectivity or Game Center login.
    func recordResult(score: Int, mode: GameRunMode, dailyUTCKey: Int,
                      lifetimeMatches: Int, lifetimeRedirects: Int,
                      lifetimeBestCombo: Int, gamesPlayed: Int) {
        let defaults = UserDefaults.standard
        if mode == .endless {
            let previous = defaults.integer(forKey: endlessQueueKey)
            defaults.set(max(previous, score), forKey: endlessQueueKey)
        } else if dailyUTCKey == Self.currentUTCKey {
            let sameDay = defaults.integer(forKey: dailyQueueDateKey) == dailyUTCKey
            defaults.set(max(sameDay ? defaults.integer(forKey: dailyQueueKey) : 0, score),
                         forKey: dailyQueueKey)
            defaults.set(dailyUTCKey, forKey: dailyQueueDateKey)
        }

        let bestEver = max(defaults.integer(forKey: "vectors.gc.bestEverScore"), score)
        defaults.set(bestEver, forKey: "vectors.gc.bestEverScore")
        updateEarnedMilestones(lifetimeMatches: lifetimeMatches,
                               lifetimeRedirects: lifetimeRedirects,
                               lifetimeBestCombo: lifetimeBestCombo,
                               gamesPlayed: gamesPlayed, bestScore: bestEver)
        flush()
    }

    /// Recover previous local milestones when Game Center is enabled on a later build.
    func prepareLocalProgress(bestScore: Int, dailyBest: Int, dailyUTCKey: Int,
                              lifetimeMatches: Int, lifetimeRedirects: Int,
                              lifetimeBestCombo: Int, gamesPlayed: Int) {
        let defaults = UserDefaults.standard
        defaults.set(max(bestScore, defaults.integer(forKey: endlessQueueKey)),
                     forKey: endlessQueueKey)
        if dailyUTCKey == Self.currentUTCKey, dailyBest > 0 {
            let sameDay = defaults.integer(forKey: dailyQueueDateKey) == dailyUTCKey
            defaults.set(max(sameDay ? defaults.integer(forKey: dailyQueueKey) : 0, dailyBest),
                         forKey: dailyQueueKey)
            defaults.set(dailyUTCKey, forKey: dailyQueueDateKey)
        }
        let bestEver = max(bestScore, dailyBest, defaults.integer(forKey: "vectors.gc.bestEverScore"))
        defaults.set(bestEver, forKey: "vectors.gc.bestEverScore")
        updateEarnedMilestones(lifetimeMatches: lifetimeMatches,
                               lifetimeRedirects: lifetimeRedirects,
                               lifetimeBestCombo: lifetimeBestCombo,
                               gamesPlayed: gamesPlayed, bestScore: bestEver)
    }

    private func updateEarnedMilestones(lifetimeMatches: Int, lifetimeRedirects: Int,
                                        lifetimeBestCombo: Int, gamesPlayed: Int, bestScore: Int) {
        let defaults = UserDefaults.standard
        var earned = Set(defaults.stringArray(forKey: earnedMilestonesKey) ?? [])
        if lifetimeMatches >= 1 { earned.insert("firstMatch") }
        if lifetimeRedirects >= 100 { earned.insert("hundredRedirects") }
        if lifetimeBestCombo >= 5 { earned.insert("fiveCombo") }
        if lifetimeBestCombo >= 10 { earned.insert("tenCombo") }
        if bestScore >= 5_000 { earned.insert("fiveThousandPoints") }
        if gamesPlayed >= 100 { earned.insert("hundredGames") }
        defaults.set(Array(earned).sorted(), forKey: earnedMilestonesKey)
    }

    private func flush() {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        flushScore(mode: .endless)
        flushScore(mode: .daily)
        flushAchievements()
    }

    private func flushScore(mode: GameRunMode) {
        let isDaily = mode == .daily
        let id = isDaily ? VectorsGameCenterIDs.dailyLeaderboard : VectorsGameCenterIDs.endlessLeaderboard
        guard !id.isEmpty else { return }
        if isDaily && syncingDaily || !isDaily && syncingEndless { return }

        let defaults = UserDefaults.standard
        let key = isDaily ? dailyQueueKey : endlessQueueKey
        if isDaily && defaults.integer(forKey: dailyQueueDateKey) != Self.currentUTCKey {
            // Do not leak a previous UTC day's score into today's recurring leaderboard.
            defaults.removeObject(forKey: dailyQueueKey)
            defaults.removeObject(forKey: dailyQueueDateKey)
            return
        }
        let value = defaults.integer(forKey: key)
        guard value > 0 else { return }
        if isDaily { syncingDaily = true } else { syncingEndless = true }
        GKLeaderboard.submitScore(value, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [id]) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                if isDaily { self.syncingDaily = false } else { self.syncingEndless = false }
                if let error {
                    print("[Vectors][Game Center] Score \(id): \(error.localizedDescription)")
                    return  // Keep queued score; retry on next launch / completed run.
                }
                let stillSameDay = !isDaily || defaults.integer(forKey: self.dailyQueueDateKey) == Self.currentUTCKey
                if stillSameDay && defaults.integer(forKey: key) <= value {
                    defaults.removeObject(forKey: key)
                } else {
                    self.flushScore(mode: mode) // A higher score arrived during the upload.
                }
            }
        }
    }

    private func flushAchievements() {
        guard VectorsGameCenterIDs.hasAchievements, !syncingAchievements else { return }
        let defaults = UserDefaults.standard
        let earned = Set(defaults.stringArray(forKey: earnedMilestonesKey) ?? [])
        let reportedKey = "vectors.gc.reported.\(GKLocalPlayer.local.gamePlayerID)"
        let reported = Set(defaults.stringArray(forKey: reportedKey) ?? [])
        let definitions: [(String, String)] = [
            ("firstMatch", VectorsGameCenterIDs.firstMatch),
            ("hundredRedirects", VectorsGameCenterIDs.hundredRedirects),
            ("fiveCombo", VectorsGameCenterIDs.fiveCombo),
            ("tenCombo", VectorsGameCenterIDs.tenCombo),
            ("fiveThousandPoints", VectorsGameCenterIDs.fiveThousandPoints),
            ("hundredGames", VectorsGameCenterIDs.hundredGames)
        ]
        let newIDs = definitions.compactMap { key, id -> String? in
            earned.contains(key) && !id.isEmpty && !reported.contains(id) ? id : nil
        }
        guard !newIDs.isEmpty else { return }
        syncingAchievements = true
        let reports = newIDs.map { id -> GKAchievement in
            let item = GKAchievement(identifier: id)
            item.percentComplete = 100
            item.showsCompletionBanner = true
            return item
        }
        GKAchievement.report(reports) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.syncingAchievements = false
                if let error {
                    print("[Vectors][Game Center] Achievements: \(error.localizedDescription)")
                    return
                }
                var updated = Set(defaults.stringArray(forKey: reportedKey) ?? [])
                updated.formUnion(newIDs)
                defaults.set(Array(updated).sorted(), forKey: reportedKey)
                self.flushAchievements()
            }
        }
    }

    static var currentUTCKey: Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        return (components.year ?? 0) * 10000 + (components.month ?? 0) * 100 + (components.day ?? 0)
    }

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }

    private func topController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        var root = keyWindow?.rootViewController
        while let presented = root?.presentedViewController { root = presented }
        return root
    }
}

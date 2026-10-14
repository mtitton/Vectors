//
//  GameLanguage.swift
//  Vectors
//
//  Created by Marcus Titton on 13/10/26.
//

import Foundation

enum GameLanguagePreference: String, CaseIterable, Identifiable {
    case automatic, portuguese, english
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: return "Automatic / Automático"
        case .portuguese: return "Português"
        case .english: return "English"
        }
    }

    var effectiveCode: String {
        switch self {
        case .portuguese: return "pt"
        case .english: return "en"
        case .automatic:
            return Locale.preferredLanguages.first?.lowercased().hasPrefix("pt") == true ? "pt" : "en"
        }
    }
}

/// Text is resolved at runtime, so changing language in Settings updates every screen immediately.
/// The device preference is used when set to automatic, with English as the fallback.
enum VectorStrings {
    static func value(_ english: String, code: String) -> String {
        guard code == "pt" else { return english }
        return portuguese[english] ?? english
    }

    private static let portuguese: [String: String] = [
        "HIGH SCORE": "RECORDE",
        "BEST": "RECORDE",
        "REDIRECT PARTICLES. BUILD COMBOS.": "MUDE DIREÇÕES. FAÇA COMBOS.",
        "PLAY": "JOGAR",
        "HOW TO PLAY": "COMO JOGAR",
        "MY STATS": "ESTATÍSTICAS",
        "SETTINGS": "CONFIGURAÇÕES",
        "ONE SWIPE CAN CHANGE EVERYTHING": "UM GESTO MUDA TUDO",
        "DAILY CHALLENGE": "DESAFIO DIÁRIO",
        "SAME PATTERN FOR EVERYONE": "MESMA SEQUÊNCIA PARA TODOS",
        "DAILY BEST": "RECORDE DO DIA",
        "LEADERBOARD": "RANKING",
        "RANKINGS & ACHIEVEMENTS": "RANKINGS E CONQUISTAS",
        "CONNECTED TO GAME CENTER": "CONECTADO AO GAME CENTER",
        "CONNECT TO GAME CENTER": "CONECTAR AO GAME CENTER",
        "Compare your best scores with other players.": "Compare seus recordes com outros jogadores.",
        "Sign in to Game Center to compare scores and unlock achievements.": "Entre no Game Center para comparar pontuações e desbloquear conquistas.",
        "ENDLESS RANKING": "RANKING INFINITO",
        "DAILY RANKING": "RANKING DIÁRIO",
        "ACHIEVEMENTS": "CONQUISTAS",
        "GAME CENTER": "GAME CENTER",
        "COMBO": "COMBO",
        "READY": "PRONTO",
        "MATCHES": "ENCONTROS",
        "SWIPE TO STEER • FOLLOW THE TRAJECTORY": "DESLIZE PARA GUIAR • OBSERVE A TRAJETÓRIA",
        "PAUSED": "PAUSADO",
        "SCORE": "PONTOS",
        "RESUME": "CONTINUAR",
        "RESTART": "REINICIAR",
        "HOME": "INÍCIO",
        "GAME OVER": "FIM DE JOGO",
        "NEW BEST!": "NOVO RECORDE!",
        "NEW DAILY BEST!": "NOVO RECORDE DIÁRIO!",
        "LONGEST COMBO": "MAIOR COMBO",
        "REDIRECTS": "DESVIOS",
        "SWIPES PER MATCH": "GESTOS POR ENCONTRO",
        "RETRY": "JOGAR DE NOVO",
        "SWIPE TO STEER": "DESLIZE PARA GUIAR",
        "Touch any particle and swipe where you want it to go. Its direction changes instantly, keeping its speed.": "Toque em uma partícula e deslize na direção desejada. Ela muda de rumo na hora, sem perder velocidade.",
        "FOLLOW THE PREVIEW": "SIGA A PREVISÃO",
        "While swiping, a preview shows the first predicted encounter: green for a match, orange for a risk or the edge. It never steers for you.": "Ao deslizar, a previsão mostra o primeiro encontro esperado: verde para combinar e laranja para risco ou borda. Você continua no controle.",
        "MATCH COLORS": "UNA CORES IGUAIS",
        "Steer particles independently so matching colors meet. You have more time to chain matches into combos.": "Guie cada partícula separadamente para unir cores iguais. Faça encontros seguidos para aumentar o combo.",
        "AVOID HAZARDS": "EVITE PERIGOS",
        "Avoid different-color collisions and escapes. An orange ring warns when a particle is near an edge. You have three lives.": "Evite colisões de cores diferentes e fugas. Um anel laranja avisa quando uma partícula está perto da borda. Você tem três vidas.",
        "EACH PARTICLE MOVES INDEPENDENTLY": "CADA PARTÍCULA É INDEPENDENTE",
        "Swipe from a particle towards its new heading": "Deslize uma partícula para definir seu rumo",
        "LET'S PLAY": "VAMOS JOGAR",
        "PERSONAL BEST": "RECORDE PESSOAL",
        "GAMES PLAYED": "PARTIDAS JOGADAS",
        "TOTAL MATCHES": "TOTAL DE ENCONTROS",
        "BEST COMBO": "MELHOR COMBO",
        "GAME SOUNDS": "SONS DO JOGO",
        "HAPTIC FEEDBACK": "RESPOSTA TÁTIL",
        "VISUAL EFFECTS": "EFEITOS VISUAIS",
        "LANGUAGE": "IDIOMA",
        "HELP & PRIVACY": "AJUDA E PRIVACIDADE",
        "PRIVACY POLICY": "POLÍTICA DE PRIVACIDADE",
        "SUPPORT": "SUPORTE",
        "FOLLOW DEVICE LANGUAGE": "SEGUIR IDIOMA DO APARELHO",
        "AUTO": "AUTOMÁTICO",
        "BACK HOME": "VOLTAR AO INÍCIO",
        "MATCH": "CERTO",
        "RISK": "RISCO",
        "EDGE": "BORDA",
        "CHAIN": "SEQUÊNCIA",
        "Play Vectors": "Jogar Vectors",
        "Game arena. Swipe on a particle to send it in any direction.": "Arena do jogo. Deslize sobre uma partícula para mudar sua direção.",
        "lives remaining": "vidas restantes",
        "DAILY": "DIÁRIO",
        "ENDLESS": "INFINITO",
        "DAY": "DIA",
        "GAME CENTER UNAVAILABLE": "GAME CENTER INDISPONÍVEL",
        "Configure leaderboard IDs in GameCenterService.swift and in App Store Connect to enable online rankings.": "Configure os IDs dos rankings em GameCenterService.swift e no App Store Connect para ativar o ranking online.",
        "TODAY'S CHALLENGE": "DESAFIO DE HOJE",
        "Today’s particles follow a reproducible sequence. Aim for the highest score!": "As partículas de hoje seguem uma sequência reproduzível. Busque a maior pontuação!",
        "START DAILY": "JOGAR DIÁRIO",
        "DAILY MODE": "MODO DIÁRIO",
        "No attempt limit. The daily sequence resets at 00:00 UTC.": "Sem limite de tentativas. O desafio muda às 00:00 UTC (21h de Brasília).",
        "MATCHES MADE": "ENCONTROS REALIZADOS",
        "Achievements": "Conquistas"
    ]
}

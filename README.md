# Vectors 🎯

**Vectors** é um jogo arcade para iPhone em que você guia partículas coloridas com gestos simples, provoca encontros entre cores iguais e tenta superar seu recorde. Cada partida é diferente — a arena ganha novas cores e mais partículas conforme a sua pontuação aumenta.

**Vectors is an arcade game for iPhone.** Swipe to redirect colorful particles, match identical colors, create combos, and beat your high score.

## Como jogar / How to play

1. **Deslize sobre uma partícula** para mudar imediatamente sua direção. / **Swipe a particle** to redirect it instantly.
2. **Una partículas da mesma cor** para fazer pontos. / **Match identical colors** to score.
3. **Crie combos** com encontros consecutivos. / **Build combos** by chaining matches.
4. **Evite colisões de cores diferentes e fugas da arena**: você tem três vidas. / **Avoid mismatched collisions and escapes**: you have three lives.
5. A dificuldade aumenta de acordo com a **pontuação**, e não apenas pelo tempo. / Difficulty scales with your **score**.

## Funcionalidades / Features

- **Infinito / Endless:** recorde pessoal e placar global no Game Center.
- **Desafio Diário / Daily Challenge:** sequência determinística por dia (UTC), tentativas ilimitadas e pontuação diária separada.
- **Combos e previsão de trajetória:** uma indicação visual ajuda a identificar `MATCH`, `RISK` ou `EDGE`, sem controlar a partícula automaticamente.
- **Cinco cores:** introduzidas progressivamente conforme o jogador pontua, com símbolos centrais para melhorar a diferenciação visual.
- **Game Center:** rankings para Infinito e Diário, além de seis conquistas. Os IDs devem coincidir com os cadastrados no App Store Connect.
- **Localização:** Português (Brasil) e English (US), selecionados automaticamente pelo idioma do dispositivo ou manualmente no menu Configurações.
- **Acessibilidade e preferências:** sons, resposta tátil, efeitos visuais e idioma configuráveis.
- **Suporte e privacidade no aplicativo:** links dentro de **Configurações** para as páginas públicas em PT/EN.

## Requisitos técnicos / Requirements

| Item | Valor |
| --- | --- |
| Plataforma / Platform | iPhone apenas / iPhone only |
| Deployment target | iOS 17.0+ |
| Interface | SwiftUI |
| Gameplay | SpriteKit |
| Idioma do código / Language | Swift 5 |
| Versão / Version | `1.0` |
| Build | `3` |
| Bundle identifier | `com.marcustitton.vectors` |
| Dependências externas | Nenhuma no projeto fornecido / No third-party packages |

## Executando / Run locally

1. Clone o repositório: `git clone https://github.com/mtitton/Vectors.git`.
2. Abra `Vectors.xcodeproj` no Xcode.
3. Selecione seu **Team** em *Signing & Capabilities*; confira **Game Center** habilitado.
4. Escolha um simulador ou dispositivo **iPhone** e pressione `⌘R`.
5. Para publicar, use **Product → Archive** e envie pelo Xcode Organizer.

## Organização do repositório / Structure

```text
.
├── Vectors.xcodeproj/              # Projeto Xcode
├── Vectors/                        # SwiftUI, SpriteKit, recursos e Game Center
│   ├── RootGameView.swift          # Telas, menus e Configurações
│   ├── VectorsScene.swift          # Arena, toque, vetores e colisões
│   ├── GameSession.swift           # Estado da partida, recordes, preferências
│   ├── GameLanguage.swift          # Strings PT/EN
│   ├── GameCenterService.swift     # Rankings e conquistas
│   └── Assets.xcassets/            # Ícone do app
├── Docs/                           # GitHub Pages: site, suporte e privacidade
└── README.md
```

## Suporte / Support

- **E-mail / Email:** [mvtitton@gmail.com](mailto:mvtitton@gmail.com)
- **Página de suporte / Support:** [Vectors Support](https://mtitton.github.io/Vectors/support.html)
- **Política de privacidade / Privacy policy:** [Vectors Privacy](https://mtitton.github.io/Vectors/privacy.html)

As páginas suportam **PT/EN** e podem ser publicadas gratuitamente via **GitHub Pages**. Para configurar: **Settings → Pages → Deploy from a branch → main → /docs**. Confirme que os links estão públicos antes de informar as URLs no App Store Connect.

## Privacidade / Privacy

O Vectors armazena preferências e estatísticas de jogo localmente no dispositivo. Rankings e conquistas são processados pelo **Apple Game Center** quando utilizado. A versão 1.0 fornecida não contém SDKs próprios de publicidade ou analytics de terceiros. Consulte a [política completa](https://mtitton.github.io/Vectors/privacy.html) e confirme as declarações no App Store Connect com base no build efetivamente enviado.

---

Desenvolvido por **Marcus Titton** · © 2026 · [Contato](mailto:mvtitton@gmail.com).

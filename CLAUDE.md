# Barrel (Cellar) — macOS Wine Gaming App

> ⚠️ **PROJETO DESCONTINUADO em 2026-07-19.** Ver `PROGRESS.md` (seção "Descontinuação") para o motivo completo e `PLANO-GPTK-MIGRACAO.md` para o caminho de retomada, caso um dia valha a pena voltar a mexer nisso. Resumo: a engine Wine usada (Gcenx/wine-crossover) tem bugs reais e não contornáveis (Steam nunca loga, Battle.net trava, até jogos simples travam) — hoje o app é só uma interface bonita para baixar um Wine que não funciona de verdade.

App nativo macOS para rodar jogos Windows via Wine, similar ao CrossOver. Nome no código: **Barrel**. Nome na UI (design): **Cellar**.

## Stack

| Camada | Tecnologia |
|---|---|
| Linguagem | Swift 5.9+ |
| UI | SwiftUI (macOS 13+) |
| Build | Xcode + xcodegen (`project.yml` é a fonte de verdade) |
| Wine | Gcenx/wine-crossover (builds para macOS) |
| DirectX 9/10/11 | DXVK + MoltenVK |
| DirectX 12 | VKD3D-Proton + MoltenVK |
| Dependências Windows | Winetricks |
| Arte dos jogos | SteamGridDB API |

## Armazenamento

Dados pesados **sempre no SSD externo**. O `StorageManager` detecta automaticamente:

```
/Volumes/icaro_ssd/barrel-data/   ← prioridade (SSD externo)
  bottles/   — WINEPREFIXes
  wine/      — binários Wine
  cache/     — downloads temporários

~/Library/Application Support/Barrel/  ← fallback se SSD não montado
```

## Estrutura do projeto

```
barrel/
├── project.yml              ← FONTE DE VERDADE do Xcode project
├── Barrel.xcodeproj         ← gerado por: xcodegen generate
├── Barrel/
│   ├── App/
│   │   ├── BarrelApp.swift
│   │   └── ContentView.swift       ← roteamento principal (HStack sidebar + content)
│   ├── Models/
│   │   ├── Bottle.swift            ← WINEPREFIX isolado
│   │   ├── Game.swift              ← jogo instalado
│   │   ├── WineBuild.swift         ← versão Wine + Dependency enum
│   │   └── BarrelError.swift       ← erros tipados
│   ├── Services/
│   │   ├── StorageManager.swift    ← detecta SSD, resolve paths
│   │   ├── WineService.swift       ← executa Wine, stream de logs (actor)
│   │   ├── BottleService.swift     ← CRUD de garrafas (actor)
│   │   ├── DownloadService.swift   ← baixa Wine builds do Gcenx (actor)
│   │   ├── DependencyService.swift ← DXVK manual + Winetricks (actor)
│   │   └── GameService.swift       ← biblioteca de jogos (actor)
│   └── Views/
│       ├── Shared/
│       │   ├── DesignTokens.swift  ← cores, gradientes, WallpaperView, TrafficLights
│       │   └── CoverArtView.swift  ← arte procedural + GameData + sampleGames
│       ├── Bottle/
│       │   ├── BottleSidebarView.swift   ← sidebar 248px translúcida, busca real, delete de garrafa
│       │   └── CreateBottleSheet.swift   ← modal criação de garrafa
│       ├── Library/
│       │   ├── LibraryView.swift         ← grid 5 colunas + toolbar + navegação pro GameDetailView
│       │   └── GameCardView.swift        ← tile com cover art procedural
│       ├── Dependencies/
│       │   └── DependencyListView.swift  ← tab "Components" da garrafa (conectada via botão na toolbar da Library)
│       └── Game/
│           ├── GameDetailView.swift      ← hero + config real + console com logs reais (GameDetailViewModel)
│           └── InstallAppSheet.swift     ← catálogo de apps conhecidos (Steam/Epic/GOG/Battle.net) + instalador custom
└── BarrelTests/
    └── BarrelTests.swift
```

`SteamService.swift` (Services/) também existe: instala um wrapper `.exe` compilado (`Tools/steamwebhelper_wrapper.c`) que substitui o `steamwebhelper.exe` real dentro da garrafa e injeta `--no-sandbox --disable-gpu --disable-gpu-sandbox` — fix permanente para o crash "Failed creating offscreen shared JS context" que trava a Steam sob Wine. Ver `.agent/especialista-wine-macos.md` para o contexto completo desse problema.

## Arquitetura

- `ContentView` — `NavigationSplitView` com `BottleSidebarView` (sidebar) + área de conteúdo. Roteamento simples via `enum ContentTab { case library, dependencies }` (não existe `AppRoute` — a navegação real é: Library ↔ Components por bottle selecionada, e Library → GameDetailView por clique no card).
- Todos os services são `actor` (thread-safe).
- `WineService.run()` retorna `AsyncStream<LogEntry>` para log em tempo real.
- Garrafa = diretório com `barrel.json` (metadata) + `prefix/` (WINEPREFIX).
- `WineBuild` resolve o binário `wine` por busca recursiva (`WineBuild.findBinDirectory`), não por caminho fixo — o layout dos releases do Gcenx já mudou entre versões, então nunca assuma `Contents/Resources/wine/bin/wine` como garantido.
- `Bottle.installedDependencyIds` persiste quais dependências (winetricks/DXVK) já foram instaladas — sem isso, o app esquecia o estado a cada reinício.

## Design

Baseado no design **Cellar** gerado pelo Claude Design em 2026-06-10.
Paleta: fundo `#1c1c1e`, accent `#8b6bff` → `#7c5cff` → `#ff7a3d` (gradiente).
Referência visual: Arc Browser, Whisky app, macOS Sequoia dark.

## Comandos úteis

```bash
# Regenerar .xcodeproj após alterar project.yml ou adicionar arquivos
xcodegen generate

# Abrir no Xcode
open Barrel.xcodeproj

# Instalar winetricks (dependência de runtime)
brew install winetricks
```

## Verify

O LSP dá falso positivo em erros cross-file ("Cannot find X in scope" para tipos que existem em outro arquivo do mesmo target) — **nunca confie nisso**, só no build real:

```bash
xcodegen generate && xcodebuild -scheme Barrel -configuration Debug build
```

Precisa do Xcode completo instalado (não funciona só com Command Line Tools — `xcodebuild` falha com "requires Xcode" se `xcode-select` estiver apontando pra `/Library/Developer/CommandLineTools`). Pra rodar os testes:

```bash
xcodebuild test -scheme Barrel
```

## Regras de código

- Sem sandbox (`com.apple.security.app-sandbox = false`) — necessário para executar Wine
- Distribuição fora da App Store — `.dmg` direto
- Erros do LSP sobre tipos não encontrados são falsos positivos cross-file; resolvem no build do Xcode
- Não adicionar `Co-Authored-By` nos commits

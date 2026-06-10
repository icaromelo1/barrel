# Barrel (Cellar) — macOS Wine Gaming App

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
│       │   ├── BottleSidebarView.swift   ← sidebar 248px translúcida
│       │   └── CreateBottleSheet.swift   ← modal criação de garrafa
│       ├── Library/
│       │   ├── LibraryView.swift         ← grid 5 colunas + toolbar
│       │   └── GameCardView.swift        ← tile com cover art procedural
│       ├── Dependencies/
│       │   └── DependencyListView.swift  ← components tab da garrafa
│       └── Game/
│           └── GameDetailView.swift      ← hero + config + console animado
└── BarrelTests/
    └── BarrelTests.swift
```

## Arquitetura

- `ContentView` — `HStack` com `BottleSidebarView` + área de conteúdo. Roteamento via `AppRoute` enum (`library`, `dependencies`, `gameDetail`).
- Todos os services são `actor` (thread-safe).
- `WineService.run()` retorna `AsyncStream<LogEntry>` para log em tempo real.
- Garrafa = diretório com `barrel.json` (metadata) + `prefix/` (WINEPREFIX).

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

## Regras de código

- Sem sandbox (`com.apple.security.app-sandbox = false`) — necessário para executar Wine
- Distribuição fora da App Store — `.dmg` direto
- Erros do LSP sobre tipos não encontrados são falsos positivos cross-file; resolvem no build do Xcode
- Não adicionar `Co-Authored-By` nos commits

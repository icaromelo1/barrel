# Progress — Barrel

_Atualizado: 2026-06-10_

## Estado atual

**Fase 1 concluída** — Core services + UI completa implementada.

Xcode **não está instalado** na máquina — primeiro build pendente após instalação.

---

## O que está feito

### Core Services (Fase 1)
- [x] `StorageManager` — detecta SSD externo, fallback automático
- [x] `WineService` — executa Wine via `Process`, stream de logs em tempo real (`AsyncStream<LogEntry>`)
- [x] `BottleService` — criar/deletar/persistir garrafas (WINEPREFIX)
- [x] `DownloadService` — baixa Wine builds do Gcenx via GitHub API
- [x] `DependencyService` — DXVK manual (download + cópia de DLLs + registry) + Winetricks
- [x] `GameService` — biblioteca de jogos em `games.json`
- [x] Modelos: `Bottle`, `Game`, `WineBuild`, `Dependency`, `BarrelError`

### UI (design Cellar implementado)
- [x] `DesignTokens` — todos os tokens de cor + gradientes + `WallpaperView`
- [x] `CoverArtView` — arte procedural com 6 motifs (peak, grid, orbit, slash, ring, bolt)
- [x] **Tela 1 — Library** — grid 5 colunas, sidebar translúcida, toolbar com botão Add Game
- [x] **Tela 2 — New Bottle** — sheet com seleção de API gráfica e quick setup presets
- [x] **Tela 3 — Components** — dependency cards com estados installed/installing/available
- [x] **Tela 4 — Game Detail** — hero com cover art, config panel, console animado em tempo real
- [x] `BottleSidebarView` — sidebar 248px com material blur, traffic lights, seleção de garrafa

### Infraestrutura
- [x] `project.yml` para xcodegen
- [x] `.gitignore`
- [x] Git inicializado com 2 commits
- [x] Dados pesados em `/Volumes/icaro_ssd/barrel-data/`

---

## Pendente

### Fase 2 — Dependências reais
- [ ] Testar `DependencyService.installDXVK()` com garrafa real
- [ ] Integrar `winetricks` para VCRedist, .NET
- [ ] Verificar versão de Wine disponível no Gcenx e testar download
- [ ] `wineboot --init` funcional

### Fase 3 — Jogos
- [ ] `GameService.add()` + seleção de `.exe` via `NSOpenPanel`
- [ ] `ArtworkService` — busca arte no SteamGridDB por nome
- [ ] Launcher real conectado ao `WineService`

### Fase 4 — UI conectada aos services
- [ ] `LibraryView` usando dados reais do `GameService`
- [ ] `BottleSidebarView` usando dados reais do `BottleService`
- [ ] `CreateBottleSheet` chamando `BottleService.create()`
- [ ] `DependencyListView` chamando `DependencyService`
- [ ] `GameDetailView` com log real do `WineService`
- [ ] Progress/loading states durante operações lentas

### Fase 5 — CS2 como validação
- [ ] Fluxo completo: garrafa DX12 → DXVK + VKD3D + VCRedist → Steam → CS2
- [ ] Investigar estado atual do VAC com wine-crossover

### Infraestrutura pendente
- [ ] Instalar Xcode para primeiro build
- [ ] Testar no simulador/device real
- [ ] `brew install winetricks` para testes de dependências

---

## Decisões tomadas

| Decisão | Escolha | Motivo |
|---|---|---|
| Wine build | Gcenx/wine-crossover | Melhor suporte macOS/ARM |
| DirectX | DXVK + MoltenVK (não GPTK) | Open-source, não precisa de conta dev Apple |
| UI | SwiftUI nativo | Performance, design macOS nativo |
| Distribuição | Fora da App Store (.dmg) | Sandbox impede execução de Wine |
| Nome UI | Cellar | Sugerido pelo Claude Design, mais premium |
| Nome código | Barrel | Mantido no bundle ID e projeto |
| Dados | SSD externo primeiro | Disco interno com pouco espaço |

---

## Próxima sessão — por onde começar

1. Instalar Xcode e fazer o primeiro build
2. Corrigir qualquer erro de compilação real
3. Começar Fase 2: testar `DownloadService` baixando Wine do Gcenx

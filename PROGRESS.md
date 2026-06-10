# Progress — Barrel

_Atualizado: 2026-06-10_

## Estado atual

**UI rodando.** Design Cellar implementado com NavigationSplitView, toolbar nativa macOS, CreateBottleSheet com presets. Serviços escritos mas **Wine real ainda não testado**.

---

## O que está pronto

### Core Services (escritos, não testados com Wine real)
- [x] `StorageManager` — detecta SSD externo, fallback automático
- [x] `WineService` — executa Wine via `Process`, `AsyncStream<LogEntry>` para logs
- [x] `BottleService` — criar/deletar/persistir garrafas; wineboot roda em background
- [x] `DownloadService` — baixa Wine builds do Gcenx via GitHub API
- [x] `DependencyService` — DXVK manual + Winetricks
- [x] `GameService` — biblioteca de jogos em `games.json`
- [x] Modelos: `Bottle`, `Game`, `WineBuild`, `Dependency`, `BarrelError`

### ViewModels (wired)
- [x] `BottleViewModel`, `LibraryViewModel`, `DependencyViewModel`
- [x] `GameDetailViewModel`, `WineSetupViewModel`

### UI
- [x] Design Cellar completo em SwiftUI
- [x] `NavigationSplitView` — sidebar real + toolbar nativa macOS
- [x] `CreateBottleSheet` — presets Steam / Gaming / Compatibility + seção Advanced
- [x] `LibraryView` — grid 5 colunas + toolbar nativa com `.toolbar {}`
- [x] `BottleSidebarView` — garrafas reais + footer New Bottle
- [x] `DependencyListView` — `DependencyCard` wired ao `DependencyViewModel`
- [x] `GameDetailView` — hero + config panel + console

---

## Plano de 6 Waves

### Wave 1 — Fixes de UX (próximo)
- [ ] Separar "Add Game" (pick `.exe` da biblioteca) de "New Bottle" (criar garrafa)
- [ ] Sidebar mostra garrafas reais em tempo real após criar
- [ ] Indicador de status Wine na UI (instalado / baixando / ausente)

### Wave 2 — Wine funcionando
- [ ] Testar `DownloadService` + extração correta do tar.xz do Gcenx
- [ ] Verificar que `wineboot --init` cria WINEPREFIX real
- [ ] `brew install winetricks`

### Wave 3 — Auto-deps por preset (modelo Bottles/CrossOver)
- [ ] Preset **Gaming** → auto-instala DXVK + VCRedist 2022 + d3dcompiler_47
- [ ] Preset **Steam** → auto-instala deps + baixa e roda instalador Steam
- [ ] Preset **Compatibility** → auto-instala VCRedist + corefonts + config OpenGL
- [ ] Garrafa fica "Pronta" só quando deps terminarem; progresso visível na sidebar

### Wave 4 — Instalar app na garrafa
- [ ] "Install App" na garrafa → `NSOpenPanel` escolhe `.exe` instalador
- [ ] Roda instalador com console de log ao vivo
- [ ] "Add to Library" → escolhe `.exe` principal → aparece na biblioteca

### Wave 5 — Biblioteca + launcher
- [ ] Play button funcional → `WineService.runExecutable()`
- [ ] Logs em tempo real no `GameDetailView`
- [ ] Status: rodando / parado / erro

### Wave 6 — CS2 como validação final
- [ ] Preset Gaming → deps auto → Steam → CS2 rodando

---

## Decisões tomadas

| Decisão | Escolha | Motivo |
|---|---|---|
| Wine build | Gcenx/wine-crossover | Melhor suporte macOS/ARM |
| DirectX | DXVK + MoltenVK | Open-source, sem conta dev Apple |
| UI | SwiftUI + NavigationSplitView | Pattern nativo macOS correto |
| Window | hiddenTitleBar + unified toolbar | Estilo Whisky/Arc |
| UX deps | Presets ocultam DirectX/DXVK | Modelo Bottles/CrossOver |
| Distribuição | Fora da App Store (.dmg) | Sandbox impede Wine |
| Dados | SSD externo primeiro | Disco interno com pouco espaço |

## Referências úteis
- Whisky (fork ativo): https://frankea.github.io/Whisky/
- Bottles docs (modelo de deps): https://docs.usebottles.com
- Gcenx Wine builds: https://github.com/Gcenx/macOS_Wine_builds

---

## Próxima sessão — Wave 1

1. Separar "Add Game" de "New Bottle" na `LibraryView`
2. Garantir sidebar atualiza em tempo real ao criar garrafa
3. Mostrar status Wine em algum lugar da UI

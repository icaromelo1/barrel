# Progress — Barrel

_Atualizado: 2026-07-19 — projeto descontinuado após sessão de testes reais_

## ⚠️ Descontinuação (2026-07-19)

**Motivo:** o app foi tirado do portfólio. Depois de uma revisão de ponta a ponta que deixou toda a UI/serviços conectados (ver seções abaixo), a próxima sessão finalmente testou o Wine **de verdade** (não só por leitura de código) — criando bottles reais, instalando Steam/Battle.net/jogos — e encontrou bugs de fundo, não contornáveis por configuração, que tornam o app inutilizável como está hoje. Na prática: **o Barrel é uma interface bonita para baixar um Wine que não funciona.**

### Bugs reais encontrados (build `wine-staging` do `Gcenx/macOS_Wine_builds`, que o Barrel baixa automaticamente)

1. **Steam nunca consegue logar.** O handshake WebSocket com o CM (Connection Manager) da Steam completa normalmente (confirmado via `curl` manual fora do Wine — `101 Switching Protocols` limpo), mas a mensagem de login em si é sempre rejeitada pelo servidor com `'Try another CM' / 'Failure'` (log `LogonFailure No Connection` no próprio `console_log.txt`/`connection_log.txt` da Steam). Reproduzido de forma idêntica em duas bottles diferentes, incluindo uma instalação 100% do zero — não é corrupção de bottle nem de instalação.
2. **Battle.net trava para sempre ao abrir.** O launcher (`Battle.net.exe`) fica travado em 0% CPU, nunca cria janela, logo depois de logar `Opening IPC shared memory. queueName=User:...:Battle.net IPC ShMem mode=server` — um deadlock na criação de memória compartilhada nomeada (IPC) usada pra comunicação `Battle.net.exe` ↔ `Agent.exe`. O fix documentado da comunidade Lutris ("Sleeping Agent": matar tudo + apagar `ProgramData/Battle.net` + reinstalar limpo) foi testado e **não resolveu** — reproduz idêntico até numa instalação limpa.
3. **Até jogos simples travam.** Spelunky Classic (GameMaker 7, DirectX9, freeware) trava em 0% CPU sem nunca desenhar janela, mesmo depois de 70+ segundos.
4. Dois benchmarks antigos (Unigine Heaven, 3DMark03) saem silenciosamente sem criar janela — esse caso é diferente dos acima: são checagens internas rígidas de capacidade de GPU desses instaladores específicos rejeitando o que o DXVK/MoltenVK reporta, não um crash do Wine em si.

### O que foi investigado e descartado como causa

- **Não é bug de renderização/compositor** — winecfg, notepad e explorer.exe desenham perfeitamente dentro da mesma bottle.
- **Rosetta 2 não é a causa raiz.** O build do Gcenx é x86_64 puro (roda via Rosetta 2 em Apple Silicon — confirmado via `lipo -info` no binário `wine` e via inspeção de thread mostrando `com.apple.rosetta.exceptionserver`). A hipótese óbvia era "roda traduzido, por isso quebra" — mas pesquisa confirmou que até a **CrossOver paga atual (v27, 2026)** ainda roda sob Rosetta 2 em Apple Silicon (arm64 nativo só existe em "Preview"). Ou seja: os bugs acima são falhas de correção genuínas do próprio Wine vanilla usado pelo Gcenx, não artefato da camada de tradução.
- **Whisky foi avaliado e descartado** como alternativa direta — o projeto original foi arquivado pelo criador em abril/2025 (decisão voluntária, não disputa de licença). Existem forks ativos (`frankea/Whisky`, `Sikarugir`), mas nenhum resolve o problema de fundo: todos ainda dependem de um motor Wine com os mesmos tipos de bug, a não ser que usem o GPTK por baixo.

### Caminho de retomada: Apple Game Porting Toolkit (GPTK)

Pesquisa aprofundada (ver `PLANO-GPTK-MIGRACAO.md` para o plano completo já aprovado) apontou o **Apple Game Porting Toolkit** como a alternativa mais promissora: é uma distribuição Wine derivada do código-fonte da própria CrossOver (mesmos patches de compatibilidade que fazem CrossOver funcionar de verdade), com D3DMetal (DirectX→Metal) nativo embutido. É gratuito (conta Apple ID free, sem assinatura paga), mas a licença da Apple **não permite** que apps de terceiros baixem/redistribuam automaticamente — o download do `.dmg` tem que ser manual pelo usuário; o resto (montar, localizar o wine, copiar, desmontar) pode ser automatizado pelo próprio Barrel via `hdiutil`.

**Se um dia eu (Icaro) voltar a mexer nisso:** o plano completo de migração (Waves A→G, decisões já tomadas: substituição total do Gcenx, import automático via `hdiutil`) está em `PLANO-GPTK-MIGRACAO.md` na raiz do projeto — comece por lá, não do zero. **Importante:** se essas mudanças forem feitas, o `GPTK` de fato resolve os bugs acima é a própria Wave G do plano (verificação manual) — nunca assumido, só testado empiricamente.

---

## Estado atual (pré-descontinuação, ainda válido como referência de arquitetura)

**UI + serviços conectados de ponta a ponta.** Todas as telas do design Cellar estão navegáveis (Library, Components/Dependencies, GameDetail) e ligadas a dados reais. `SteamService`/`InstallAppSheet`/catálogo de apps conhecidos (Steam/Epic/GOG/Battle.net) já existiam e não estavam documentados aqui. **Wine real ainda precisa de verificação manual num Mac com Xcode completo** — esta sessão não teve Xcode instalado (só Command Line Tools), então as mudanças abaixo foram feitas por leitura cuidadosa do código, não validadas rodando o app.

---

## O que está pronto e verificado por leitura

### Core Services
- [x] `StorageManager` — detecta SSD externo, fallback automático; agora com `overrideRoot` pra testes isolados
- [x] `WineService` — executa Wine via `Process`, `AsyncStream<LogEntry>` para logs
- [x] `BottleService` — criar/deletar/persistir garrafas; wineboot roda em background
- [x] `DownloadService` — baixa Wine builds do Gcenx via GitHub API; download agora via `URLSessionDownloadDelegate` (era byte-a-byte, corrigido)
- [x] `DependencyService` — DXVK manual + Winetricks
- [x] `GameService` — biblioteca de jogos em `games.json`
- [x] `SteamService` — wrapper `.exe` (`Tools/steamwebhelper_wrapper.c`) que injeta `--no-sandbox --disable-gpu` no steamwebhelper real, evitando o crash-loop "Failed creating offscreen shared JS context"
- [x] Modelos: `Bottle` (+ `installedDependencyIds` persistido), `Game`, `WineBuild` (+ busca resiliente do binário wine), `Dependency`, `BarrelError`

### ViewModels
- [x] `BottleViewModel`, `LibraryViewModel` (+ `pickExeFile` reusado no fluxo de installer custom), `DependencyViewModel` (+ `load(from:)` e persistência real)
- [x] `GameDetailViewModel` — **agora usado de verdade** (antes era código morto, nunca instanciado)
- [x] `WineSetupViewModel`

### UI — todas as telas navegáveis
- [x] `NavigationSplitView` — sidebar real + toolbar nativa macOS
- [x] `CreateBottleSheet` — presets Steam / Gaming / Compatibility + seção Advanced (D3DMetal removido do picker — não implementado ainda)
- [x] `LibraryView` — grid 5 colunas, busca real (antes decorativa), botão "Components", clique no card abre `GameDetailView`
- [x] `BottleSidebarView` — garrafas reais, busca real, **delete de garrafa** (context menu + confirmação)
- [x] `DependencyListView` — **agora conectada** via botão "Components" na toolbar da Library (antes órfã, inalcançável)
- [x] `GameDetailView` — **reescrita**: recebe `Game`+`Bottle` reais, usa `GameDetailViewModel`, console mostra logs reais (antes era 100% mock hardcoded pro jogo fictício "Ashfall")
- [x] `InstallAppSheet` — catálogo de apps conhecidos + instalador custom (fix: agora pede o `.exe` real do jogo em vez de registrar o caminho do instalador)

### Testes
- [x] `BottleService` CRUD contra diretório temporário
- [x] `GameService` CRUD
- [x] `WineBuild.findBinDirectory` — cobre layout legado do Gcenx, layout alternativo, ausência de binário, falso-positivo (arquivo não-executável chamado `wine`)
- [x] `Bottle` — encode/decode + retrocompatibilidade com JSON antigo sem `installedDependencyIds`

---

## Pendências reais (não fechadas nesta sessão)

- [ ] **Rodar o build real** (`xcodegen generate && xcodebuild -scheme Barrel build`) — precisa de Xcode completo, não só Command Line Tools
- [ ] **Validar a hipótese do caminho do Wine na prática** — a busca resiliente foi escrita e testada com estrutura fake, mas nunca contra um build real baixado do Gcenx
- [ ] **Testar o fluxo completo rodando**: criar garrafa → instalar Steam → abrir Components → instalar dependência → reabrir app e confirmar que persiste → abrir GameDetailView → dar play
- [ ] **D3DMetal (DX12)** — opção removida da UI até ter implementação real via VKD3D-Proton + MoltenVK (escopo maior, não iniciado)
- [ ] Configuration panel do `GameDetailView` hoje é só leitura (renderer/sync/exe/launch args reais) — não tem edição de config por jogo ainda

---

## Decisões tomadas

| Decisão | Escolha | Motivo |
|---|---|---|
| Wine build | Gcenx/wine-crossover | Melhor suporte macOS/ARM |
| Caminho do binário wine | Busca recursiva, não caminho fixo | Layout do Gcenx já mudou entre releases; nunca validado antes |
| DirectX 9/10/11 | DXVK + MoltenVK | Open-source, sem conta dev Apple |
| DirectX 12 | Ainda não implementado | Opção D3DMetal tirada da UI até ter VKD3D-Proton real |
| UI | SwiftUI + NavigationSplitView | Pattern nativo macOS correto |
| Roteamento | `ContentTab` simples (library/dependencies) + navegação local na Library pro GameDetail | Suficiente pro app atual; não precisa do `AppRoute` genérico imaginado antes (nunca foi construído) |
| Window | hiddenTitleBar + unified toolbar | Estilo Whisky/Arc |
| UX deps | Presets ocultam DirectX/DXVK | Modelo Bottles/CrossOver |
| Distribuição | Fora da App Store (.dmg) | Sandbox impede Wine |
| Dados | SSD externo primeiro | Disco interno com pouco espaço |
| Download de arquivos | `URLSessionDownloadDelegate` | A iteração byte-a-byte anterior (`for try await byte in asyncBytes`) tinha overhead sério pra arquivos de 100MB+ |

## Referências úteis
- Whisky (descontinuado, sem fork mantido): https://frankea.github.io/Whisky/
- Bottles docs (modelo de deps): https://docs.usebottles.com
- Gcenx Wine builds: https://github.com/Gcenx/macOS_Wine_builds
- `.agent/especialista-wine-macos.md` — contexto de debugging de Wine/Steam/D3DMetal acumulado numa sessão inteira de troubleshooting real (CrossOver + Sikarugir)

---

## Próxima sessão

1. Rodar `xcodegen generate && xcodebuild -scheme Barrel build` num Mac com Xcode completo e corrigir o que aparecer de erro real (distinto dos falsos positivos de LSP documentados no `CLAUDE.md`).
2. Rodar `xcodebuild test -scheme Barrel`.
3. Testar o fluxo fim a fim manualmente (criar garrafa → instalar Steam → jogar) — é a única forma de validar a hipótese do caminho do binário wine.
4. Se tudo passar, retomar o roadmap de auto-deps por preset mais robusto (verificar se instala corretamente em cada preset, não só que o código compila).

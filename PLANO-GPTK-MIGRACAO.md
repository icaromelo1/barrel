# Plano — Migrar Barrel de Gcenx Wine para Apple GPTK

## Contexto

Depois de uma sessão inteira de testes reais (Steam, Battle.net, Spelunky, Heaven Benchmark, 3DMark03) rodando dentro de uma bottle criada com o build `wine-staging` do `Gcenx/macOS_Wine_builds`, encontramos bugs reais e reproduzíveis: login da Steam sempre rejeitado no handshake CM (`'Try another CM'`), Battle.net travando para sempre na criação de memória compartilhada nomeada (IPC), e até um jogo simples (Spelunky/GameMaker) travando em 0% CPU sem nunca desenhar janela. Pesquisa confirmou que esse Wine build do Gcenx é x86_64 puro (roda via Rosetta 2), mas que isso **não é a causa raiz** — até a CrossOver paga atual roda via Rosetta 2 no Apple Silicon. Os bugs são falhas de correção do próprio Wine vanilla, não de tradução de arquitetura.

O **Apple Game Porting Toolkit (GPTK)** é uma distribuição Wine completa derivada do código-fonte da CrossOver (mesmos patches de compatibilidade), com D3DMetal (DirectX→Metal) embutido. É gratuito (conta Apple ID free, sem precisar de assinatura paga), mas a licença da Apple não permite que apps de terceiros baixem/redistribuam automaticamente — o usuário precisa baixar o `.dmg` manualmente pelo site da Apple após logar.

Decisão tomada com o usuário: **substituir completamente** o fluxo do Gcenx (não manter os dois), e o **Barrel monta/desmonta o `.dmg` sozinho via `hdiutil`** depois que o usuário aponta pro arquivo baixado — só o download em si fica manual (exigência da licença), o resto do processo (montar, localizar o wine, copiar, desmontar) é automático.

Projeto: `/Volumes/icaro_ssd/projetos/pessoal/barrel`. Build via `xcodegen generate && xcodebuild -scheme Barrel build` (LSP dá falso positivo cross-file — regra já documentada no `CLAUDE.md`).

---

## Wave A — Serviço de importação do GPTK (novo)

Criar `Barrel/Services/GPTKImportService.swift` (actor, seguindo o padrão de `DownloadService`/`WineService`):

1. `pickDMG() async -> URL?` — `NSOpenPanel` restrito a `UTType(filenameExtension: "dmg")`, seguindo exatamente o padrão já usado em `LibraryViewModel.pickExeFile` (`ViewModels/LibraryViewModel.swift:49-66`) e `InstallAppSheet.pickInstaller` (`Views/Game/InstallAppSheet.swift:364-385`): `withCheckedContinuation` + `DispatchQueue.main.async` + `panel.runModal()`.
2. `importGPTK(from dmg: URL, progress: @escaping @Sendable (String) -> Void) async throws -> WineBuild`:
   - `hdiutil attach <dmg.path> -nobrowse -plist` via `Process`, parse o plist de saída (`PropertyListSerialization`) pra achar o `mount-point` real (não assumir caminho fixo).
   - Reusar `WineBuild.findBinDirectory(named:under:)` (já genérico, `Models/WineBuild.swift:43-57`) apontando pro mount point, pra localizar o binário `wine`/`wine64` de verdade dentro do volume montado — **sem assumir a estrutura interna do GPTK**, já que nunca vimos o bundle de verdade ainda.
   - Copiar o diretório-pai relevante (a raiz da instalação, não só o `bin/`) para `StorageManager.shared.wineDirectory.appending(path: "gptk-<versão-ou-data>")`, via `FileManager.copyItem`.
   - `hdiutil detach <mountpoint>` no fim (usar `defer` pra garantir desmonte mesmo se a cópia falhar no meio).
   - Retornar um `WineBuild` apontando pro novo diretório copiado.
3. Erros novos em `BarrelError.swift`: `.dmgMountFailed`, `.dmgVolumeNotFound(String)` (binário wine não encontrado dentro do volume montado), `.dmgCopyFailed`.

**Verificação necessária durante implementação (não assumir agora):** a estrutura interna real do `.dmg` do GPTK (nome exato do binário — `wine` ou `wine64` —, se vem como `.app` bundle ou pasta solta, se há mais de um volume/pacote dentro do dmg). Baixar o GPTK de verdade e inspecionar antes de finalizar o parsing do plist e a lógica de cópia.

---

## Wave B — `WineBuild` e `WineSetupViewModel`: substituir fluxo de download por fluxo de import

`Models/WineBuild.swift`:
- Nenhuma mudança estrutural necessária — `findBinDirectory` já é genérico o bastante pra funcionar com o layout do GPTK (validar no Wave A). Remover o comentário/`legacyBinDir` específico do Gcenx (linhas 13-17) já que não haverá mais fallback pra layout do Gcenx.
- Trocar `arch: "x86_64"` fixo por resolução real do binário encontrado (não crítico, mas fica mais honesto).

`ViewModels/WineSetupViewModel.swift` — reescrever o `SetupState` e `setup()`:
- Novos estados: `idle` (nada instalado ainda), `checking` (procurando build local), `mounting` (montando o dmg), `copying` (copiando pro destino), `ready`, `failed(String)`. Remover `.downloading`/`.extracting` (eram HTTP-específicos).
- `setup()`: mantém a lógica de achar build local existente (`findLocalBuild()`, já genérica e reaproveitável sem mudança — só troca `"wine-"` por procurar qualquer pasta com binário válido, já que a pasta agora se chama `gptk-*`). Se não achar nada, vai pro estado `idle`/"GPTK não instalado" — **sem disparar nenhuma rede automaticamente**.
- Novo método `importFromDMG()`: chama `GPTKImportService.shared.pickDMG()` → se usuário cancelar, não faz nada; senão chama `importGPTK(from:progress:)` atualizando `state`/`progressMessage` a cada etapa (mounting → copying → ready).
- `retry()` deixa de re-tentar HTTP e passa a chamar `importFromDMG()` de novo.

`Services/DownloadService.swift`: remover `gcenxReleasesURL`, `latestWineBuild()`, `downloadWine()`, `extractWine()` e o `GithubRelease`/`GithubAsset` decoders — esse arquivo fica só com `downloadFile()` (helper genérico de download por URL, ainda usado por `InstallAppSheet` pra baixar instaladores de apps) e o `ProgressDownloadDelegate`. Se o arquivo ficar pequeno demais, considerar mover `downloadFile`/`ProgressDownloadDelegate` pra dentro de `InstallAppSheet.swift` ou um novo `Services/HTTPDownloadHelper.swift` — decidir no momento da implementação olhando o tamanho final.

`Models/BarrelError.swift`: remover `.noWineBuildFound` (era Gcenx-específico), adicionar os três novos casos do Wave A.

---

## Wave C — UI: sidebar badge/banner viram fluxo de import

`Views/Bottle/BottleSidebarView.swift`:
- `WineStatusBadge` (linhas 201-240): atualizar `label`/`dotColor` pros novos estados (`"GPTK ausente"`, `"Verificando..."`, `"Montando .dmg..."`, `"Copiando..."`, `"GPTK pronto"`, `"Falhou — toque pra importar"`). O tap gesture (213-217) passa a chamar `vm.importFromDMG()` tanto no estado `.failed` quanto no `.idle` (hoje só reage a `.failed`).
- `WineDownloadBanner` (linhas 244+): renomear conceitualmente pra refletir import em vez de download; como não dá pra medir progresso byte-a-byte de uma cópia de pasta facilmente, trocar a barra de progresso por um `ProgressView` indeterminado + `vm.progressMessage`. Isso é uma simplificação intencional em relação ao banner antigo (que tinha % real de download HTTP) — aceitável dado que a cópia local é rápida.
- Adicionar um pequeno texto/link explicando o passo manual: "Baixe o GPTK em developer.apple.com/games/game-porting-toolkit (conta Apple gratuita), depois toque aqui" — usar `Link` do SwiftUI apontando pra URL oficial.

---

## Wave D — Renderer: D3DMetal vira o padrão real

`Models/Bottle.swift`:
- `BottlePreset.defaultRenderer` (linhas 21-23): trocar `.steam`/`.gaming` de `.dxvk` para `.metal`, já que o GPTK traz D3DMetal nativo — é o caminho de renderização real agora, DXVK vira opção secundária/manual.
- `BottlePreset.depIds` (linhas 35-41): remover `"dxvk"` da lista fixa do preset `gaming` — a instalação de dependências passa a depender do renderer escolhido, não só do preset (ver próximo item).

`Views/Bottle/CreateBottleSheet.swift` (linhas 88-101): reativar `.metal` no `Picker` (remover o comentário que a desabilitava), deixá-la como primeira opção / selecionada por padrão quando `showAdvanced` está fechado.

`Services/DependencyService.swift` `installForPreset` (linhas 8-31): passar a receber `bottle.config.renderer` e só incluir `"dxvk"` no fluxo de instalação se `renderer == .dxvk`. Quando `renderer == .metal`, pular a etapa de DXVK inteiramente (D3DMetal já vem pronto dentro do próprio build do GPTK, sem DLL pra copiar).

`Views/Dependencies/DependencyListView.swift` (linhas 91-95): filtrar `Dependency.all` pra esconder o card de DXVK quando `bottle.config.renderer != .dxvk` (hoje aparece sempre, independente do renderer — bug pré-existente que vale corrigir nessa passada).

**Verificação necessária durante implementação:** confirmar se D3DMetal do GPTK precisa de alguma variável de ambiente/registro extra pra ativar (ex.: variáveis tipo `D3DM_SUPPORT_DX11` citadas em configurações da comunidade) — não inventar nomes de variável sem confirmar. Melhor fonte pra isso: ler o próprio README/documentação que vem dentro do `.dmg` do GPTK uma vez baixado, e/ou o código-fonte do fork `frankea/Whisky` (que já integra GPTK de verdade) como referência de configuração real.

---

## Wave E — `WineService.swift`: ambiente de execução

`buildEnvironment()` (linhas 93-113): revisar se as variáveis atuais (`DYLD_FALLBACK_LIBRARY_PATH`, `PATH`, `WINEDLLOVERRIDES`, `WINE_LARGE_ADDRESS_AWARE`) continuam corretas apontando pro layout do GPTK (devem continuar funcionando sem mudança, já que são derivadas de `build.wineLibPath`/`wineBinPath`, que por sua vez vêm da busca genérica do Wave A/B — mas só confirma rodando de verdade). Adicionar as variáveis específicas de D3DMetal identificadas no Wave D aqui, condicionadas a `bottle.config.renderer == .metal` (a função hoje não recebe o `Bottle` inteiro, só `prefix: URL` — vai precisar passar o `renderer` como parâmetro extra ou o `Bottle` inteiro pra essa decisão).

---

## Wave F — Limpeza e documentação

- `BarrelTests/BarrelTests.swift`: `WineBuildResolutionTests` (linhas 109-172) continuam válidos como estão (testam `findBinDirectory` genericamente, não dependem do Gcenx especificamente) — não precisam mudar. Remover qualquer teste que dependesse especificamente do fluxo de download HTTP do Gcenx (não encontramos nenhum na varredura, mas confirmar ao implementar).
- `CLAUDE.md`: atualizar a tabela de stack (`Wine: Gcenx/wine-crossover` → `Wine: Apple Game Porting Toolkit (import manual de .dmg)`), atualizar a árvore de arquivos (`DownloadService.swift` reduzido, novo `GPTKImportService.swift`), atualizar a seção de arquitetura sobre resolução do binário Wine.
- `.agent/especialista-wine-macos.md`: adicionar seção nova documentando (a) a troca de engine e o motivo (bugs reais no Gcenx/wine-staging: Steam CM rejection, Battle.net IPC deadlock), (b) que Rosetta 2 não é a causa raiz (CrossOver também roda sob Rosetta), (c) o fluxo de import manual do GPTK e as restrições de licença da Apple, (d) revisar/corrigir a seção antiga "GPTK vs CX" que tinha a suposição errada de que o Gcenx é derivado da CX.

---

## Wave G — Verificação manual (rodar de verdade)

1. Build real: `xcodegen generate && xcodebuild -scheme Barrel -configuration Debug build`.
2. Baixar o GPTK de verdade em developer.apple.com (conta gratuita), testar o fluxo `importFromDMG()` fim a fim pela UI do Barrel — confirmar que monta, acha o binário, copia, desmonta, e o badge mostra "GPTK pronto".
3. Criar uma bottle nova com renderer D3DMetal (padrão) e rodar o Spelunky (já baixado em `/Volumes/icaro_ssd/barrel-data/cache/spelunky.zip`) — confirmar que abre janela e renderiza (esse foi o teste que travou hoje no Gcenx).
4. Se Spelunky funcionar: testar Steam e Battle.net (instaladores já em cache: `Battle.net-Setup.exe`, e reinstalar Steam do zero) pra ver se os bugs de rede/IPC de hoje também desaparecem sob o GPTK.
5. Rodar `xcodebuild test -scheme Barrel` pra confirmar que os testes existentes continuam passando.

---

## Ordem de execução recomendada

A (serviço de import) → B (model/viewmodel) → C (UI) → D (renderer/deps) → E (ambiente) → F (docs/limpeza) → G (verificação manual, é onde as suposições não-confirmadas do GPTK são validadas de verdade).

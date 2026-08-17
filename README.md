# Barrel

Aplicativo macOS nativo para rodar jogos de Windows, escrito em SwiftUI.

## O que é

Um gerenciador de prefixos do Wine com interface nativa: baixa a build do Wine, cria e
administra os ambientes, instala lojas (Steam, Epic, GOG, Battle.net) ou executáveis
avulsos, e mantém a biblioteca de jogos instalados.

## Por que existe

O programa que eu usava foi descontinuado em 2025, as alternativas ou são de outro sistema
operacional ou estão abandonadas. Fiz nativo de propósito, sem camada web, para aprender a
plataforma pelo caminho difícil.

## A parte difícil

Rodar o instalador é a parte fácil; o problema é o ciclo de vida do processo. Um clique no
play conseguia disparar várias cópias do mesmo jogo, então existe um bloqueio por
identificador mais um monitor em duas fases que confirma se o processo realmente subiu.
E os dados pesados — prefixos do Wine, builds e jogos — ficam fora do disco interno por
decisão de projeto.

## Estado

**Pausado**, num problema já diagnosticado e não resolvido: o cliente da Steam abre com a
janela em branco. A causa é o processo gráfico do framework embutido dele falhando em
silêncio sob a camada de compatibilidade. O que já foi tentado e descartado está em
`PROGRESS.md`.

## Como abrir

Abrir `Barrel.xcodeproj` no Xcode e compilar. Requer macOS com Apple Silicon.

## Stack

Swift · SwiftUI · Wine

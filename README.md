# Barrel

Aplicativo macOS nativo para execução de jogos de Windows, escrito em SwiftUI.

## Descrição

Gerenciador de prefixos do Wine com interface nativa. Realiza o download da build do Wine,
cria e administra os ambientes, instala lojas (Steam, Epic, GOG, Battle.net) ou
executáveis avulsos, e mantém a biblioteca de jogos instalados.

## Motivação

O programa utilizado anteriormente foi descontinuado em 2025, e as alternativas disponíveis
destinam-se a outro sistema operacional ou estão sem manutenção. A implementação é nativa,
sem camada web, por decisão de estudo da plataforma.

## Descontinuado em 19/07/2026

Após a conclusão da interface e dos serviços, o motor Wine foi testado empiricamente, com
criação de prefixos reais e instalação de clientes e jogos. Os defeitos encontrados são do
próprio motor e não são contornáveis por configuração:

* A Steam completa o handshake com o servidor, mas tem o login rejeitado de forma
  consistente, reproduzido em instalações independentes e do zero.
* O launcher da Battle.net entra em deadlock na criação de memória compartilhada nomeada,
  sem criar janela. A correção documentada pela comunidade foi testada e não resolveu.
* Títulos simples e antigos também não desenham janela.

Foram descartadas como causa a camada de renderização, que funciona corretamente para
aplicativos do próprio Wine, e a tradução por Rosetta 2, já que produtos comerciais em
operação utilizam a mesma camada.

O diagnóstico e o caminho de retomada avaliado, baseado no Apple Game Porting Toolkit,
estão documentados em `PROGRESS.md` e `PLANO-GPTK-MIGRACAO.md`.

## Execução

Abrir `Barrel.xcodeproj` no Xcode e compilar. Requer macOS com Apple Silicon.

## Stack

Swift, SwiftUI, Wine

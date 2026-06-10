import Foundation

enum BarrelError: LocalizedError {
    case noWineInstalled
    case noWineBuildFound
    case downloadFailed
    case extractionFailed
    case wineBootFailed
    case registryWriteFailed
    case bottleNotFound
    case gameNotFound

    var errorDescription: String? {
        switch self {
        case .noWineInstalled:       return "Wine não está instalado. Baixe um build primeiro."
        case .noWineBuildFound:      return "Nenhum build Wine encontrado nos releases do Gcenx."
        case .downloadFailed:        return "Falha ao baixar o arquivo."
        case .extractionFailed:      return "Falha ao extrair o Wine."
        case .wineBootFailed:        return "Falha ao inicializar o prefixo Wine (wineboot)."
        case .registryWriteFailed:   return "Falha ao escrever no registro Wine."
        case .bottleNotFound:        return "Garrafa não encontrada."
        case .gameNotFound:          return "Jogo não encontrado."
        }
    }
}

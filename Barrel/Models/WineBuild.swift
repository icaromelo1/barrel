import Foundation

struct WineBuild: Codable, Identifiable {
    var id: String { version }
    let version: String
    let downloadURL: URL
    let arch: String

    var localURL: URL {
        StorageManager.shared.wineDirectory.appending(path: "wine-\(version)")
    }

    // Gcenx builds are macOS .app bundles: Contents/Resources/wine/bin/wine
    var wineBinary: URL {
        localURL.appending(path: "Contents/Resources/wine/bin/wine")
    }

    var wineLibPath: String {
        localURL.appending(path: "Contents/Resources/wine/lib").path
    }

    var wineBinPath: String {
        localURL.appending(path: "Contents/Resources/wine/bin").path
    }

    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: wineBinary.path)
    }
}

struct Dependency: Identifiable, Codable {
    let id: String
    let displayName: String
    let description: String
    let winetricksVerb: String?
    let type: DependencyType

    static let all: [Dependency] = [
        Dependency(id: "dxvk", displayName: "DXVK", description: "DirectX 9/10/11 via Vulkan", winetricksVerb: nil, type: .graphics),
        Dependency(id: "vcrun2022", displayName: "VCRedist 2022", description: "Visual C++ Redistributable", winetricksVerb: "vcrun2022", type: .runtime),
        Dependency(id: "dotnet48", displayName: ".NET Framework 4.8", description: "Microsoft .NET 4.8", winetricksVerb: "dotnet48", type: .runtime),
        Dependency(id: "dotnetdesktop6", displayName: ".NET Desktop 6", description: "Microsoft .NET Desktop Runtime 6", winetricksVerb: "dotnetdesktop6", type: .runtime),
        Dependency(id: "d3dcompiler_47", displayName: "D3D Compiler 47", description: "DirectX shader compiler", winetricksVerb: "d3dcompiler_47", type: .graphics),
        Dependency(id: "corefonts", displayName: "Core Fonts", description: "Microsoft Core Fonts", winetricksVerb: "corefonts", type: .font),
    ]
}

enum DependencyType: String, Codable {
    case graphics, runtime, font, other
}

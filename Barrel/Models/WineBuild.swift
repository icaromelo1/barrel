import Foundation

struct WineBuild: Codable, Identifiable {
    var id: String { version }
    let version: String
    let downloadURL: URL
    let arch: String

    var localURL: URL {
        StorageManager.shared.wineDirectory.appending(path: "wine-\(version)")
    }

    // Gcenx macOS builds have historically shipped as `Contents/Resources/wine/bin/wine`,
    // but the exact layout has changed across releases. Resolve the real bin directory by
    // searching for the `wine` executable rather than trusting a hardcoded path; fall back
    // to the legacy guess only if nothing is found (e.g. FileManager enumeration fails).
    private static let legacyBinDir = "Contents/Resources/wine/bin"

    private var resolvedBinDir: URL {
        Self.findBinDirectory(named: "wine", under: localURL)
            ?? localURL.appending(path: Self.legacyBinDir)
    }

    var wineBinary: URL {
        resolvedBinDir.appending(path: "wine")
    }

    var wineBinPath: String {
        resolvedBinDir.path
    }

    var wineLibPath: String {
        resolvedBinDir.deletingLastPathComponent().appending(path: "lib").path
    }

    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: wineBinary.path)
    }

    /// Recursively searches `root` for an executable file named `name`, returning
    /// its containing directory. Used to locate the real Wine binary without
    /// assuming a fixed release layout.
    static func findBinDirectory(named name: String, under root: URL) -> URL? {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isExecutableKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        for case let url as URL in enumerator where url.lastPathComponent == name {
            let values = try? url.resourceValues(forKeys: [.isExecutableKey, .isRegularFileKey])
            if values?.isRegularFile == true, values?.isExecutable == true {
                return url.deletingLastPathComponent()
            }
        }
        return nil
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

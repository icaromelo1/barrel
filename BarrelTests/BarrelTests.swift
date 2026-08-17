import XCTest
@testable import Barrel

final class BarrelTests: XCTestCase {

    func testStorageManagerFallback() {
        let storage = StorageManager.shared
        XCTAssertNotNil(storage.rootDirectory)
        print("Storage location: \(storage.storageInfo())")
    }

    func testBottleModelEncoding() throws {
        let bottle = Bottle(name: "Test", config: .default)
        let encoder = JSONEncoder()
        let data = try encoder.encode(bottle)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Bottle.self, from: data)
        XCTAssertEqual(bottle.id, decoded.id)
        XCTAssertEqual(bottle.name, decoded.name)
        XCTAssertEqual(decoded.installedDependencyIds, [])
    }

    /// Old, pre-`installedDependencyIds` JSON must still decode with an empty default.
    func testBottleBackwardCompatibleDecoding() throws {
        let oldJSON = """
        {
            "id": "\(UUID().uuidString)",
            "name": "Legacy",
            "wineVersion": "",
            "config": { "arch": "win64", "renderer": "DXVK", "esync": true, "msync": true },
            "createdAt": "2026-01-01T00:00:00Z",
            "games": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Bottle.self, from: oldJSON)
        XCTAssertEqual(decoded.installedDependencyIds, [])
        XCTAssertEqual(decoded.initStatus, .ready)
    }
}

// MARK: - Service tests (isolated temp storage via StorageManager.overrideRoot)

final class BarrelServiceTests: XCTestCase {
    private var tempRoot: URL!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appending(path: "BarrelTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        StorageManager.shared.overrideRoot = tempRoot
    }

    /// BottleService/GameService are process-wide singleton actors — their in-memory
    /// state doesn't reset just because `overrideRoot` points at a fresh directory.
    /// Force a reload against the (empty) temp directory so tests are isolated from
    /// whatever ran before them in the same test process.
    private func resetServiceState() async throws {
        _ = try await BottleService.shared.loadAll()
        _ = try await GameService.shared.loadAll()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
        StorageManager.shared.overrideRoot = nil
    }

    func testBottleServiceCRUD() async throws {
        try await resetServiceState()
        let service = BottleService.shared

        let created = try await service.create(name: "CRUD Bottle", config: .default, preset: .gaming)
        XCTAssertEqual(created.name, "CRUD Bottle")
        XCTAssertTrue(FileManager.default.fileExists(atPath: created.prefixURL.path))

        let loaded = try await service.loadAll()
        XCTAssertTrue(loaded.contains { $0.id == created.id })

        var updated = created
        updated.name = "Renamed Bottle"
        try await service.update(updated)
        let reloaded = try await service.loadAll()
        XCTAssertEqual(reloaded.first { $0.id == created.id }?.name, "Renamed Bottle")

        try await service.delete(updated)
        let afterDelete = try await service.loadAll()
        XCTAssertFalse(afterDelete.contains { $0.id == created.id })
    }

    func testGameServiceCRUD() async throws {
        try await resetServiceState()
        let service = GameService.shared
        let bottleId = UUID()

        let game = try await service.add(name: "Test Game", exePath: "C:\\game.exe", bottleId: bottleId)
        let afterAdd = try await service.loadAll()
        XCTAssertEqual(afterAdd.count, 1)
        let forBottle = await service.games(for: bottleId)
        XCTAssertEqual(forBottle.count, 1)

        try await service.remove(id: game.id)
        let afterRemove = try await service.loadAll()
        XCTAssertEqual(afterRemove.count, 0)
    }
}

// MARK: - WineBuild bin-directory resolution

final class WineBuildResolutionTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appending(path: "WineBuildTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    /// `/var` is a symlink to `/private/var` on macOS, and Foundation's
    /// `resolvingSymlinksInPath()` deliberately leaves `/tmp`, `/var`, `/etc`
    /// unresolved (documented quirk) — but `FileManager`'s directory enumerator
    /// returns the canonical `/private/var/...` form. Normalize both sides before
    /// comparing paths so this discrepancy doesn't cause false test failures.
    private func normalized(_ path: String?) -> String? {
        guard let path else { return nil }
        return path.hasPrefix("/private") ? String(path.dropFirst("/private".count)) : path
    }

    private func makeExecutable(at url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: url.path, contents: Data("#!/bin/sh\n".utf8))
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }

    func testFindsBinaryAtLegacyGcenxPath() throws {
        let binary = tempDir.appending(path: "Contents/Resources/wine/bin/wine")
        try makeExecutable(at: binary)

        let found = WineBuild.findBinDirectory(named: "wine", under: tempDir)
        XCTAssertEqual(normalized(found?.path), normalized(binary.deletingLastPathComponent().path))
    }

    func testFindsBinaryAtDifferentLayout() throws {
        // Simulates a Gcenx release that changed its internal structure —
        // this is exactly the assumption that was never validated before.
        let binary = tempDir.appending(path: "wine-9.0/bin/wine")
        try makeExecutable(at: binary)

        let found = WineBuild.findBinDirectory(named: "wine", under: tempDir)
        XCTAssertEqual(normalized(found?.path), normalized(binary.deletingLastPathComponent().path))
    }

    func testReturnsNilWhenNoBinaryPresent() {
        let found = WineBuild.findBinDirectory(named: "wine", under: tempDir)
        XCTAssertNil(found)
    }

    func testIgnoresNonExecutableFileNamedWine() throws {
        let notExecutable = tempDir.appending(path: "docs/wine")
        try FileManager.default.createDirectory(at: notExecutable.deletingLastPathComponent(), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: notExecutable.path, contents: Data("just text".utf8))
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: notExecutable.path)

        let found = WineBuild.findBinDirectory(named: "wine", under: tempDir)
        XCTAssertNil(found)
    }
}

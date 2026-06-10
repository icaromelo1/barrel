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
    }
}

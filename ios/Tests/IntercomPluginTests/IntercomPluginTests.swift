import XCTest
@testable import IntercomPlugin

class IntercomTests: XCTestCase {
    func testPluginIsBridgedUnderItsJavaScriptName() {
        let plugin = IntercomPlugin()

        XCTAssertEqual(plugin.identifier, "IntercomPlugin")
        XCTAssertEqual(plugin.jsName, "Intercom")
        XCTAssertTrue(plugin.pluginMethods.contains { $0.name == "registerIdentifiedUser" })
    }
}

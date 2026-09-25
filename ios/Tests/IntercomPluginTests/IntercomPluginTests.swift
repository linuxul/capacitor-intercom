import XCTest
import Capacitor
@testable import IntercomPlugin

class IntercomTests: XCTestCase {
    func testPluginIsBridgedUnderItsJavaScriptName() {
        let plugin = IntercomPlugin()

        XCTAssertEqual(plugin.identifier, "IntercomPlugin")
        XCTAssertEqual(plugin.jsName, "Intercom")
        XCTAssertTrue(plugin.pluginMethods.contains { $0.name == "registerIdentifiedUser" })
    }

    func testEveryMethodIsAPromiseMethod() {
        let methods = IntercomPlugin().pluginMethods
        XCTAssertEqual(methods.map(\.name), [
            "loadWithKeys", "registerIdentifiedUser", "registerUnidentifiedUser", "updateUser", "logout", "logEvent",
            "displayMessenger", "displayMessageComposer", "displayHelpCenter", "hideMessenger", "displayLauncher",
            "hideLauncher", "displayInAppMessages", "hideInAppMessages", "displayCarousel", "setUserHash", "setUserJwt",
            "setBottomPadding", "displayArticle"
        ])
        XCTAssertTrue(methods.allSatisfy { $0.returnType == .promise })
    }

    func testMissingArgumentsThrowWithTheSameMessagesAndNoCode() {
        let plugin = IntercomPlugin()
        let cases: [MissingArgument] = [
            MissingArgument("displayMessageComposer", plugin.displayMessageComposer, [:], "Enter an initial message"),
            MissingArgument("displayCarousel", plugin.displayCarousel, [:], "carouselId not provided to displayCarousel."),
            MissingArgument("setUserHash", plugin.setUserHash, [:], "No hmac found. Read intercom docs and generate it."),
            MissingArgument("setUserJwt", plugin.setUserJwt, [:], "No jwt found. Read intercom docs and generate it."),
            MissingArgument("setBottomPadding", plugin.setBottomPadding, [:], "Enter a value for padding bottom"),
            MissingArgument("setBottomPadding", plugin.setBottomPadding, ["value": "not a number"], "Enter a value for padding bottom"),
            MissingArgument("displayArticle", plugin.displayArticle, [:], "articleId not provided to presentArticle.")
        ]
        for item in cases {
            let name = item.name
            let call = CAPPluginCall(callbackId: "test", methodName: name, options: item.options, success: { _, _ in
                XCTFail("\(name) must not resolve")
            }, error: { _ in
                XCTFail("\(name) answers by throwing")
            })
            XCTAssertThrowsError(try item.method(call), name) { error in
                XCTAssertEqual((error as? CAPPluginError)?.message, item.message, name)
                XCTAssertNil((error as? CAPPluginError)?.code, name)
            }
        }
    }
}

/// A method called with options that lack what it needs, and the message it rejects with.
private struct MissingArgument {
    let name: String
    let method: (CAPPluginCall) throws -> Void
    let options: JSObject
    let message: String

    init(_ name: String, _ method: @escaping (CAPPluginCall) throws -> Void, _ options: JSObject, _ message: String) {
        self.name = name
        self.method = method
        self.options = options
        self.message = message
    }
}

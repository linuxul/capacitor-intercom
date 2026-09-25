import Foundation
import Capacitor
import Intercom

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(IntercomPlugin)
public class IntercomPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "IntercomPlugin"
    public let jsName = "Intercom"
    // Every method stays synchronous on the bridge queue, where the plugin has always called the Intercom SDK: the
    // SDK presents its own UI, and the bridge queue keeps the calls in order (login before update and logout, a
    // display before the hide that follows it). Async methods would not keep that order.
    public let pluginMethods: [CAPPluginMethod] = [
        .promise("loadWithKeys", IntercomPlugin.loadWithKeys),
        .promise("registerIdentifiedUser", IntercomPlugin.registerIdentifiedUser),
        .promise("registerUnidentifiedUser", IntercomPlugin.registerUnidentifiedUser),
        .promise("updateUser", IntercomPlugin.updateUser),
        .promise("logout", IntercomPlugin.logout),
        .promise("logEvent", IntercomPlugin.logEvent),
        .promise("displayMessenger", IntercomPlugin.displayMessenger),
        .promise("displayMessageComposer", IntercomPlugin.displayMessageComposer),
        .promise("displayHelpCenter", IntercomPlugin.displayHelpCenter),
        .promise("hideMessenger", IntercomPlugin.hideMessenger),
        .promise("displayLauncher", IntercomPlugin.displayLauncher),
        .promise("hideLauncher", IntercomPlugin.hideLauncher),
        .promise("displayInAppMessages", IntercomPlugin.displayInAppMessages),
        .promise("hideInAppMessages", IntercomPlugin.hideInAppMessages),
        .promise("displayCarousel", IntercomPlugin.displayCarousel),
        .promise("setUserHash", IntercomPlugin.setUserHash),
        .promise("setUserJwt", IntercomPlugin.setUserJwt),
        .promise("setBottomPadding", IntercomPlugin.setBottomPadding),
        .promise("displayArticle", IntercomPlugin.displayArticle)
    ]
    private var observers: [NSObjectProtocol] = []

    override public func load() {
        let apiKey = getConfig().getString("iosApiKey") ?? "ADD_IN_CAPACITOR_CONFIG_JSON"
        let appId = getConfig().getString("iosAppId") ?? "ADD_IN_CAPACITOR_CONFIG_JSON"
        Intercom.setApiKey(apiKey, forAppId: appId)

        #if DEBUG
        Intercom.enableLogging()
        #endif

        NotificationCenter.default.addObserver(self, selector: #selector(self.didRegisterWithToken(notification:)), name: Notification.Name.capacitorDidRegisterForRemoteNotifications, object: nil)

        observers.append(
            NotificationCenter.default.addObserver(forName: .IntercomWindowDidShow, object: nil, queue: OperationQueue.main) { [weak self] (_) in
                self?.notifyListeners("windowDidShow", data: nil)
            })

        observers.append(NotificationCenter.default.addObserver(forName: .IntercomWindowDidHide, object: nil, queue: OperationQueue.main) { [weak self] (_) in
            self?.notifyListeners("windowDidHide", data: nil)
        })

    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    @objc func didRegisterWithToken(notification: NSNotification) {
        guard let deviceToken = notification.object as? Data else {
            return
        }
        Intercom.setDeviceToken(deviceToken)
    }

    func loadWithKeys(_ call: CAPPluginCall) {
        let appId = call.getString("appId") ?? "NO_APP_ID_PASSED"
        let apiKey = call.getString("apiKeyIOS") ?? "NO_API_KEY_PASSED"

        Intercom.setApiKey(apiKey, forAppId: appId)

        NotificationCenter.default.addObserver(self, selector: #selector(self.didRegisterWithToken(notification:)), name: Notification.Name.capacitorDidRegisterForRemoteNotifications, object: nil)
        call.resolve()
    }

    func registerIdentifiedUser(_ call: CAPPluginCall) {
        let userId = call.getString("userId")
        let email = call.getString("email")
        let attributes = ICMUserAttributes()
        if email != nil {
            attributes.email = email
        }
        if userId != nil {
            attributes.userId = userId
        }

        // One login with every identifier given; the SDK needs email, userId or both, and reports a login it refuses
        // through the completion.
        Intercom.loginUser(with: attributes) { result in
            switch result {
            case .success: call.resolve()
            case .failure(let error): call.reject("Error logging in: \(error.localizedDescription)")
            }
        }
    }

    func registerUnidentifiedUser(_ call: CAPPluginCall) {
        Intercom.loginUnidentifiedUser()
        call.resolve()
    }

    func updateUser(_ call: CAPPluginCall) {
        let userAttributes = ICMUserAttributes()
        let userId = call.getString("userId")
        if userId != nil {
            userAttributes.userId = userId
        }
        let email = call.getString("email")
        if email != nil {
            userAttributes.email = email
        }
        let name = call.getString("name")
        if name != nil {
            userAttributes.name = name
        }
        let phone = call.getString("phone")
        if phone != nil {
            userAttributes.phone = phone
        }
        let languageOverride = call.getString("languageOverride")
        if languageOverride != nil {
            userAttributes.languageOverride = languageOverride
        }
        let customAttributes = call.getObject("customAttributes")
        userAttributes.customAttributes = customAttributes
        Intercom.updateUser(with: userAttributes)
        call.resolve()
    }

    func logout(_ call: CAPPluginCall) {
        Intercom.logout()
        call.resolve()
    }

    func logEvent(_ call: CAPPluginCall) {
        let eventName = call.getString("name")
        let metaData = call.getObject("data")

        if let eventName, let metaData {
            Intercom.logEvent(withName: eventName, metaData: metaData)
        } else if let eventName {
            Intercom.logEvent(withName: eventName)
        }

        call.resolve()
    }

    func displayMessenger(_ call: CAPPluginCall) {
        Intercom.present()
        call.resolve()
    }

    func displayMessageComposer(_ call: CAPPluginCall) throws {
        guard let initialMessage = call.getString("message") else {
            throw CAPPluginError("Enter an initial message")
        }
        Intercom.presentMessageComposer(initialMessage)
        call.resolve()
    }

    func displayHelpCenter(_ call: CAPPluginCall) {
        Intercom.present(.helpCenter)
        call.resolve()
    }

    func hideMessenger(_ call: CAPPluginCall) {
        Intercom.hide()
        call.resolve()
    }

    func displayLauncher(_ call: CAPPluginCall) {
        Intercom.setLauncherVisible(true)
        call.resolve()
    }

    func hideLauncher(_ call: CAPPluginCall) {
        Intercom.setLauncherVisible(false)
        call.resolve()
    }

    func displayInAppMessages(_ call: CAPPluginCall) {
        Intercom.setInAppMessagesVisible(true)
        call.resolve()
    }

    func hideInAppMessages(_ call: CAPPluginCall) {
        Intercom.setInAppMessagesVisible(false)
        call.resolve()
    }

    func displayCarousel(_ call: CAPPluginCall) throws {
        guard let carouselId = call.getString("carouselId") else {
            throw CAPPluginError("carouselId not provided to displayCarousel.")
        }
        let carouselToPresent = Intercom.Content.carousel(id: carouselId)
        Intercom.presentContent(carouselToPresent)
        call.resolve()
    }

    func setUserHash(_ call: CAPPluginCall) throws {
        guard let hmac = call.getString("hmac") else {
            throw CAPPluginError("No hmac found. Read intercom docs and generate it.")
        }
        Intercom.setUserHash(hmac)
        call.resolve()
        print("hmac sent to intercom")
    }

    func setUserJwt(_ call: CAPPluginCall) throws {
        guard let jwt = call.getString("jwt") else {
            throw CAPPluginError("No jwt found. Read intercom docs and generate it.")
        }
        Intercom.setUserJwt(jwt)
        call.resolve()
        print("jwt sent to intercom")
    }

    func setBottomPadding(_ call: CAPPluginCall) throws {
        guard let value = call.getString("value"),
              let number = NumberFormatter().number(from: value) else {
            throw CAPPluginError("Enter a value for padding bottom")
        }
        Intercom.setBottomPadding(CGFloat(truncating: number))
        call.resolve()
        print("set bottom padding")
    }

    func displayArticle(_ call: CAPPluginCall) throws {
        guard let articleId = call.getString("articleId") else {
            throw CAPPluginError("articleId not provided to presentArticle.")
        }
        let articleToPresent = Intercom.Content.article(id: articleId)
        Intercom.presentContent(articleToPresent)
        call.resolve()
    }
}

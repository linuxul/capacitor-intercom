// swift-tools-version: 5.9
import Foundation
import PackageDescription

// Apps override this dependency with the @capacitor/ios they installed. To build this package on its own
// against a local runtime, point CAPACITOR_IOS_PATH at it.
let capacitor: Package.Dependency
if let path = ProcessInfo.processInfo.environment["CAPACITOR_IOS_PATH"] {
    capacitor = .package(name: "capacitor-swift-pm", path: path)
} else {
    capacitor = .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
}

let package = Package(
    name: "CapacitorCommunityIntercom",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "CapacitorCommunityIntercom",
            targets: ["IntercomPlugin"])
    ],
    dependencies: [
        capacitor,
        .package(url: "https://github.com/intercom/intercom-ios-sp.git", from: "18.0.0")
    ],
    targets: [
        .target(
            name: "IntercomPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Intercom", package: "intercom-ios-sp")
            ],
            path: "ios/Sources/IntercomPlugin"),
        .testTarget(
            name: "IntercomPluginTests",
            dependencies: ["IntercomPlugin"],
            path: "ios/Tests/IntercomPluginTests")
    ]
)
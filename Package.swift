// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FirebaseSampleIntegration",
    platforms: [
        .iOS(.v15),
                .macOS(.v12),
                .tvOS(.v15),
                .watchOS(.v8)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FirebaseSampleIntegration",
            targets: ["FirebaseSampleIntegration"]
        ),
    ],
    dependencies: [
        // ✅ Firebase via SPM
        .package(url: "https://github.com/firebase/firebase-ios-sdk", .upToNextMajor(from: "12.5.0")),
        .package(url: "https://github.com/rudderlabs/rudder-sdk-swift.git", branch: "chore/test-firebase-integration")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FirebaseSampleIntegration",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "RudderStackAnalytics", package: "rudder-sdk-swift")
                // Add other Firebase modules if needed
                // .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                // .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
            ]
        ),
        .testTarget(
            name: "FirebaseSampleIntegrationTests",
            dependencies: ["FirebaseSampleIntegration"]
        ),
    ]
)

// swift-tools-version: 5.10
import PackageDescription

// Dependency rules (enforced by this manifest):
// - Feature modules depend only on HopCore and HopDesignSystem.
// - Feature modules never import HopData or each other.
// - Only the app target wires concrete implementations to features.
let strictConcurrency: [SwiftSetting] = [.enableExperimentalFeature("StrictConcurrency")]

let package = Package(
    name: "HopKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "HopCore", targets: ["HopCore"]),
        .library(name: "HopData", targets: ["HopData"]),
        .library(name: "HopDesignSystem", targets: ["HopDesignSystem"]),
        .library(name: "RideHistoryFeature", targets: ["RideHistoryFeature"]),
        .library(name: "BookingFeature", targets: ["BookingFeature"]),
    ],
    targets: [
        .target(name: "HopCore", swiftSettings: strictConcurrency),
        .target(name: "HopData", dependencies: ["HopCore"], swiftSettings: strictConcurrency),
        .target(name: "HopDesignSystem", dependencies: ["HopCore"], swiftSettings: strictConcurrency),
        .target(
            name: "RideHistoryFeature",
            dependencies: ["HopCore", "HopDesignSystem"],
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "BookingFeature",
            dependencies: ["HopCore", "HopDesignSystem"],
            swiftSettings: strictConcurrency
        ),
        .testTarget(name: "HopDataTests", dependencies: ["HopCore", "HopData"]),
        .testTarget(name: "RideHistoryFeatureTests", dependencies: ["HopCore", "RideHistoryFeature"]),
        .testTarget(name: "BookingFeatureTests", dependencies: ["HopCore", "BookingFeature"]),
    ]
)

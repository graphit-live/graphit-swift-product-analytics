// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "GraphitProductAnalytics",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "GraphitProductAnalytics", targets: ["GraphitProductAnalytics"])
    ],
    targets: [
        .target(
            name: "GraphitProductAnalytics",
            dependencies: [],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GraphitProductAnalyticsTests",
            dependencies: ["GraphitProductAnalytics"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)

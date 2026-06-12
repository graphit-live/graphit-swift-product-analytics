# Package layout

## Manifest target

```swift
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
```

Reason: one public product keeps v1 small. iOS 18 is the primary product target. macOS 15 keeps local SwiftPM builds/tests straightforward on the same modern Swift floor.

No public testing product in v1.

## Source tree

Start flat and small. Do not copy GraphitCache's storage tree; this package has no storage engine.

```text
Sources/GraphitProductAnalytics/
  ProductAnalyticsTextValues.swift      // ProductAnalyticsEventName, ProductAnalyticsPropertyKey
  ProductAnalyticsPropertyValue.swift
  ProductAnalyticsProperties.swift
  ProductAnalyticsEvent.swift
  ProductAnalyticsBatch.swift
  ProductAnalyticsError.swift
  ProductAnalyticsValidation.swift

Tests/GraphitProductAnalyticsTests/
  TextValueTests.swift
  PropertyValueCodableTests.swift
  PropertiesValidationTests.swift
  EventValidationTests.swift
  BatchValidationTests.swift
  CodableTests.swift
  READMEExamplesTests.swift
```

The tree is a guide, not a mandate. Prefer fewer files when fewer files are clearer. Split files only around real cohesive boundaries.

## Import rules

- `Sources/GraphitProductAnalytics`: import Foundation only where needed, primarily for `Date`.
- No SwiftUI, UIKit, AppKit, Combine, Observation, OSLog, networking, persistence, GraphitCache, PostHog, Google Analytics, or vendor imports in core.
- Tests may import Foundation for `JSONEncoder`, `JSONDecoder`, `Data`, and `Date` utilities.

## Access rules

- `public` only for the exact v1 API contract.
- Every public type and public member needs a documentation comment.
- Implementation details stay `internal` or `private`.
- Prefer `private` for helper types such as `CodingKeys`, custom dynamic coding keys, and validation contexts when possible.
- Use `package` only if a future multi-target package creates a real cross-target collaboration need; v1 should not need it.

## No generated code

No code generation, macros, or generated schemas in v1. Apps can define explicit event and property constants such as:

```swift
enum AppAnalytics {
    enum Events {
        static let signupCompleted = ProductAnalyticsEventName("signup_completed")
    }

    enum Properties {
        static let plan = ProductAnalyticsPropertyKey("plan")
    }
}
```

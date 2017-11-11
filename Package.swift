// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MailLogCount",
    targets: [
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "MailLogCount",
            dependencies: []),
        .testTarget(
            name: "MailLogCountTests",
            dependencies: ["MailLogCount"]),
    ]
)

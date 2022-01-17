// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "bcheckbook",
    dependencies: [
        .package(name: "gir2swift", url: "https://github.com/rhx/gir2swift.git", .branch("main")),
        .package(name: "Gtk", url: "https://github.com/rhx/SwiftGtk.git", .branch("gtk3")),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.13.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "bcheckbook",
            dependencies: ["Gtk",
            .product(name: "SQLite", package: "SQLite.swift")
            ],
            resources: [
                .process("Resources/window.ui"),
                .process("Resources/menus.ui"),
                .copy("Resources/register.db")
            ]),
        .testTarget(
            name: "bcheckbookTests",
            dependencies: ["bcheckbook"]),
    ]
)

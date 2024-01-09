// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "geometrizebot",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.90.0"),
        .package(url: "https://github.com/vapor/leaf", from: "4.2.4"),
        .package(url: "https://github.com/vapor/leaf-kit", from: "1.10.2"),
        .package(url: "https://github.com/nerzh/telegram-vapor-bot", from: "2.5.0"),
        // As remainder how to add local package as dependency:
        // https://stackoverflow.com/questions/49819552/swift-4-local-dependencies-with-swift-package-manager
        // .package(name: "MyPackage", path: "/local/path/to/package"),
        // .package(path: "../Modules/MySwiftLib"),
        // .package(url: "file:///path/to/MySwiftLib", from: "1.0.0"),
        .package(url: "https://github.com/valeriyvan/swift-geometrize.git", branch: "feature/asynciterator"),
        //.package(url: "../swift-geometrize/", branch: "feature/asynciterator"),
        .package(url: "https://github.com/valeriyvan/jpeg.git", from: "1.0.2"),
        .package(url: "https://github.com/kelvin13/swift-png.git", from: "4.0.2"),
        .package(url: "https://github.com/awslabs/aws-sdk-swift", exact: "0.17.0")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "LeafKit", package: "leaf-kit"),
                .product(name: "TelegramVaporBot", package: "telegram-vapor-bot"),
                .product(name: "Geometrize", package: "swift-geometrize"),
                .product(name: "JPEG", package: "jpeg"),
                .product(name: "PNG", package: "swift-png"),
                .product(name: "AWSS3", package: "aws-sdk-swift"),

            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://www.swift.org/server/guides/building.html#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)

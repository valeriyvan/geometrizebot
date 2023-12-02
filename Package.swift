// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "geometrizebot",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
        .package(url: "https://github.com/vapor/leaf", from: "4.2.4"),
        .package(url: "https://github.com/vapor/leaf-kit", from: "1.10.2"),
        .package(url: "https://github.com/nerzh/telegram-vapor-bot", from: "2.4.3"),
        .package(url: "https://github.com/valeriyvan/swift-geometrize.git", from: "1.0.1"),
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

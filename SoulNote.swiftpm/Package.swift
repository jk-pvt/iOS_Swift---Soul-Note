// swift-tools-version: 5.9

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "SoulNote",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "SoulNote",
            targets: ["AppModule"],
            bundleIdentifier: "com.yourname.soulnote",
            teamIdentifier: "YJXTP7SQ48",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .asset("AppIcon"),
            accentColor: .asset("AccentColor"),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft
            ],
            appCategory: .lifestyle,
            additionalInfoPlistContentFilePath: "Info.plist"
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            exclude: ["Package.swift", "Info.plist"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)

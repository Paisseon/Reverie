// swift-tools-version:5.8

import Darwin.POSIX
import PackageDescription

let theosPath: String = .init(cString: getenv("HOME")) + "/theos"
let minFirmware: String = "12.2"

let swiftFlags: [String] = [
    "-F\(theosPath)/vendor/lib",
    "-F\(theosPath)/lib",
    "-I\(theosPath)/vendor/include",
    "-I\(theosPath)/include",
    "-target", "arm64-apple-ios\(minFirmware)",
    "-sdk", "\(theosPath)/sdks/iPhoneOS16.0.sdk",
    "-resource-dir", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift"
]

let package: Package = .init(
    name: "ReveriePrefs",
    platforms: [.iOS(minFirmware)],
    products: [
        .library(
            name: "ReveriePrefs",
            targets: ["ReveriePrefs"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Paisseon/JinxPrefs.git", branch: "emt")
    ],
    targets: [
        .target(
            name: "ReveriePrefs",
            dependencies: [.product(name: "JinxPrefs", package: "JinxPrefs")],
            swiftSettings: [.unsafeFlags(swiftFlags)]
        )
    ]
)

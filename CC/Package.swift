// swift-tools-version:5.8

import Darwin.POSIX
import PackageDescription

let theosPath: String = .init(cString: getenv("HOME")) + "/theos"
let minFirmware: String = "13.0"

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
    name: "ReverieCC",
    platforms: [.iOS(minFirmware)],
    products: [
        .library(
            name: "ReverieCC",
            targets: ["ReverieCC"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ReverieCC",
            dependencies: [],
            swiftSettings: [.unsafeFlags(swiftFlags)]
        )
    ]
)

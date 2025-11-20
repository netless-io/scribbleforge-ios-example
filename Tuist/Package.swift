// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,]
        productTypes: [:]
    )
#endif

let package = Package(
    name: "S11E-SPM-Example",
    dependencies: [
        .package(url: "https://github.com/AgoraIO/AgoraRtm_Apple.git", from: .init(2, 2, 3)),
        .package(url: "https://github.com/marmelroy/Zip.git", .upToNextMinor(from: "2.1.2")),
        .package(url: "https://github.com/DebugSwift/DebugSwift.git", .upToNextMajor(from: "0.3.9")),
        .package(url: "https://github.com/vince-hz/BenchmarkKit.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/EmergeTools/ETTrace", branch: "main"),
        .package(url: "https://github.com/SnapKit/SnapKit.git", .upToNextMajor(from: "5.7.1")),
        .package(url: "https://github.com/scalessec/Toast-Swift.git", .upToNextMajor(from: "5.1.1")),
        .package(url: "https://github.com/y-crdt/yswift", .upToNextMajor(from: "0.2.1"))
    ]
)

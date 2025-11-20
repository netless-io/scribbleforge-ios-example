import ProjectDescription

let envTeamId = Environment.appTeamId.getString(default: "")
let mode = IntegrationMode(rawValue: Environment.spmMode.getString(default: "")) ?? .source
let remoteVersion = Environment.remoteVersion.getString(default: "1.1.0-canary.3")
let isSourceIntegration = mode == .source

enum IntegrationMode: String {
    case source
    case localframework
    case remote
}

let sourceDependency = TargetDependency.project(target: "ScribbleForge", path: "../../../scribbleforge-ios")
let localfilePackage = Package.local(path: "../../../scribbleforge-ios/ci-scripts/ScribbleLocalFramework")
let remotePackage = Package.remote(
    url: "https://github.com/netless-io/scribbleforge-ios-release.git",
    requirement: .exact(.init(stringLiteral: remoteVersion))
)

let (packages, scribbleDependency): ([Package], TargetDependency) = {
    switch mode {
    case .source:
        return ([], sourceDependency)
    case .localframework:
        return ([localfilePackage], .package(product: "ScribbleForgeRTM"))
    case .remote:
        return ([remotePackage], .package(product: "ScribbleForgeRTM"))
    }
}()

let project = Project(
    name: "S11E-SPM",
    packages: packages,
    targets: [
        .target(
            name: "S11E-SPM",
            destinations: .iOS,
            product: .app,
            bundleId: "scribbleforge.test.agora",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["../../ShareExample/Sources/**"],
            resources: ["../../ShareExample/Resources/**"],
            dependencies: [
                scribbleDependency,
                .external(name: "Zip", condition: nil),
                .external(name: "DebugSwift", condition: nil),
                .external(name: "BenchmarkKit", condition: nil),
                .external(name: "ETTrace", condition: nil),
                .external(name: "SnapKit", condition: nil),
                .external(name: "Toast", condition: nil),
                .external(name: "YSwift", condition: nil)
            ],
            settings: .settings(base: {
                var baseSettings: [String: SettingValue] = [
                    "DEVELOPMENT_TEAM": .string(envTeamId)
                ]

                if isSourceIntegration {
                    baseSettings["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "SOURCE_INTEGRATION"
                }

                return baseSettings
            }())
        )
    ]
)

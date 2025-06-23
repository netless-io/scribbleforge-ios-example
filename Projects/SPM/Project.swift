import ProjectDescription

let project = Project(
    name: "S11E-SPM-Example",
    targets: [
        .target(
            name: "S11E-SPM-Example",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.s11e-spm-example",
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
                .project(target: "ScribbleForge", path: "../../../scribbleforge-ios"),
                .external(name: "Zip", condition: nil),
                .external(name: "DebugSwift", condition: nil),
                .external(name: "BenchmarkKit", condition: nil),
                .external(name: "ETTrace", condition: nil),
                .external(name: "SnapKit", condition: nil),
                .external(name: "Toast", condition: nil),
                .external(name: "YSwift", condition: nil)
            ]
        )
    ]
)

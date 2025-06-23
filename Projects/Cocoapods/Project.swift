import ProjectDescription

let project = Project(
    name: "S11E-Cocoapods-Example",
    targets: [
        .target(
            name: "S11E-Cocoapods-Example",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.S11E-Cocoapods-Example",
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
            dependencies: []
        )
    ]
)

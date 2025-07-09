import ProjectDescription

let project = Project(
    name: "S11E-Pod",
    targets: [
        .target(
            name: "S11E-Pod",
            destinations: .iOS,
            product: .app,
            bundleId: "-",
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

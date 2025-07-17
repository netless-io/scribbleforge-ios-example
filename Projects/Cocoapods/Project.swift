import ProjectDescription

let envTeamId = Environment.appTeamId.getString(default: "")
let project = Project(
    name: "S11E-Pod",
    targets: [
        .target(
            name: "S11E-Pod",
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
            dependencies: [],
            settings: .settings(base: [
                "DEVELOPMENT_TEAM": .string(envTeamId)
            ])
        )
    ]
)

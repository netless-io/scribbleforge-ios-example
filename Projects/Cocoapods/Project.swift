import ProjectDescription

let envTeamId = Environment.appTeamId.getString(default: "")
let isSourceIntegration = Environment.sourceIntegration.getString(default: "false") == "true"

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

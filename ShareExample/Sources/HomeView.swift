import ScribbleForge
import SwiftUI
import Zip

extension ScribbleForge.Region: @retroactive Hashable, @retroactive Identifiable {
    public var id: String {
        endPoint
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(endPoint)
    }

    var display: String {
        switch self {
        case .cn_hz:
            return "cn-hz"
        case .custom:
            return "dev"
        }
    }
}

extension ScribbleForge.Region: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let endPoint = try container.decode(String.self)
        if endPoint == Region.cn_hz.endPoint {
            self = .cn_hz
        } else {
            self = .custom(endPoint: endPoint)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(endPoint)
    }
}

struct RoomPrepareConfig: Codable, Equatable {
    var roomId = ""
    var userId = ""
    var roomToken = ""
    var rtmToken = ""
    var fetchSnapshot = true
    var useRtm = true
    var showVerboseLog = false
    var roomCount = 1
    var useLocalServer = false {
        didSet {
            syncExtraOptions()
        }
    }
    var useLocalSnapshot = true
    var writable = true
    var region: ScribbleForge.Region = Self.availableRegions[0]

    func syncExtraOptions() {
        if useLocalServer {
            ApplicationManager.appExtraOptionProvider = { type, _ in
                return ["customServer": URL(string: localWhiteboardSrc)!]
            }
        } else {
            ApplicationManager.appExtraOptionProvider = { type, _ in
                return [:]
            }
        }
    }
    
    static var availableRegions = [
        ScribbleForge.Region.custom(endPoint: "https://forge-persistence.netless.group"),
        ScribbleForge.Region.cn_hz,
    ]

    func toData() -> Data {
        try! JSONEncoder().encode(self)
    }

    static func fromData(_ data: Data) -> RoomPrepareConfig {
        if let config = try? JSONDecoder().decode(Self.self, from: data) {
            return config
        }
        return .init()
    }

    func toJoinRoomOptions() -> JoinRoomOptions {
        let options = JoinRoomOptions(
            writable: writable,
            authOption: .init(
                roomId: roomId,
                token: roomToken,
                userId: userId,
                nickName: userId,
                region: region
            ),
            logOption: .init(
                logDirPath: nil,
                allowRemoteLog: true,
                allowConsoleLog: true,
                allowConsoleVerboseLog: showVerboseLog,
                allowPerfLog: true
            ),
            useSnapshotFetch: fetchSnapshot,
            mergeThrottleLevel: .high,
        )
        return options
    }
}

struct RtmPair: Identifiable, Hashable {
    var id: String { rtmUserId }
    let rtmUserId: String
    let rtmToken: String
}

struct HomeView: View {
    init(enterCallback: ((RoomPrepareConfig) -> Void)? = nil, startPerformanceCallback: (()->Void)? = nil) {
        config = .init()
        let storedConfigData = self.storedConfigData
        if let data = storedConfigData {
            var config = RoomPrepareConfig.fromData(data)
            config.roomId = globalRoomId
            config.roomToken = globalRoomToken
            config.rtmToken = globalUsersConfigs.isEmpty ? "" : globalUsersConfigs[0].1
            _config = .init(initialValue: config)
        } else {
            let defaultConfig: RoomPrepareConfig = .init(
                roomId: globalRoomId,
                userId: globalUsersConfigs.isEmpty ? "" : globalUsersConfigs[0].0,
                roomToken: globalRoomToken,
                rtmToken: globalUsersConfigs.isEmpty ? "" : globalUsersConfigs[0].1
            )
            _config = .init(initialValue: defaultConfig)
        }
        _config.wrappedValue.syncExtraOptions()
        self.enterCallback = enterCallback
        self.startPerformanceCallback = startPerformanceCallback
    }

    @AppStorage("storedRoomPrepareConfig") var storedConfigData: Data?
    @State var showShare = false
    @State var config: RoomPrepareConfig
    let rtmPairs: [RtmPair] = globalUsersConfigs.map { .init(rtmUserId: $0.0, rtmToken: $0.1) }
    var enterCallback: ((RoomPrepareConfig) -> Void)? = nil
    var startPerformanceCallback: (()->Void)? = nil

    var body: some View {
        ScrollView {
            VStack {
                debugView()
                
                if config.useRtm {
                    roomInfoView()
                } else {
                    HStack {
                        Stepper("RoomCount", value: $config.roomCount, in: 1 ... 3)
                        Text(config.roomCount.description)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                Toggle(isOn: $config.showVerboseLog, label: {
                    Text("Show Verbose Log")
                }).animation(.default, value: config.showVerboseLog)
                Toggle(isOn: $config.useLocalServer, label: {
                    Text("Use \(localWhiteboardSrc)")
                })
                Toggle(isOn: $config.useLocalSnapshot, label: {
                    Text("Use LocalSnapshot")
                })
                Toggle(isOn: $config.writable, label: {
                    Text("Writable")
                })
                Toggle(isOn: $config.useRtm, label: {
                    Text("Use RTM")
                }).animation(.default, value: config.useRtm)
            }
            .padding(.horizontal)
            .padding(.bottom, 144)
        }
        .overlay(alignment: .bottom) {
            Button(action: {
                enterCallback?(config)
            }, label: {
                Text("Enter")
                    .frame(maxWidth: .infinity)
                    .padding()
            })
            .buttonStyle(BorderedProminentButtonStyle())
            .tint(.blue)
            .padding(.horizontal)
        }
        .fontWeight(.medium)
        .onChange(of: config) { newValue in
            storedConfigData = newValue.toData()
        }
    }

    func roomInfoView() -> some View {
        VStack(spacing: 12) {
            Group {
                TextField("RoomId", text: $config.roomId)
                HStack {
                    TextField("UserId", text: $config.userId)
                    Menu {
                        ForEach(rtmPairs) { pair in
                            Button(action: {
                                config.userId = pair.rtmUserId
                                config.rtmToken = pair.rtmToken
                            }, label: {
                                Text(pair.rtmUserId)
                            })
                        }
                    } label: {
                        Text("Configs")
                        Image(systemName: "chevron.right")
                    }.fontWeight(.heavy)
                }
                TextField("RoomToken", text: $config.roomToken)
                TextField("RTMToken", text: $config.rtmToken)

                HStack {
                    Text("Region")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Picker("Region Selection", selection: $config.region) {
                        ForEach(RoomPrepareConfig.availableRegions, id: \.self) { region in
                            Text(region.display)
                        }
                    }
                }.fontWeight(.bold)
            }.fontWeight(.light)

            VStack {
                Text("Detail Options").fontWeight(.regular)
                Toggle(isOn: $config.fetchSnapshot, label: {
                    Text("FetchSnapshot")
                })
            }.padding(.horizontal)
        }
    }

    func debugView() -> some View {
        HStack {
            Button(action: {
                if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first {
                    let files = (try? FileManager.default.contentsOfDirectory(atPath: cacheDir.path)) ?? []
                    let logs = files
                        .filter { $0.starts(with: "agorartmsdk") }
                        .map { cacheDir.appendingPathComponent($0) }
                    for log in logs {
                        try? FileManager.default.removeItem(at: log)
                    }
                    print("log cleaned")
                }
            }, label: {
                Text("CleanLogs")
                    .padding()
            })
            .buttonStyle(BorderedButtonStyle())
            
            Button(action: {
                if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first {
                    if FileManager.default.fileExists(atPath: zipUrl.path) {
                        try? FileManager.default.removeItem(at: zipUrl)
                    }
                    let files = (try? FileManager.default.contentsOfDirectory(atPath: cacheDir.path)) ?? []
                    let logs = files
                        .filter { $0.starts(with: "agorartmsdk") }
                        .map { cacheDir.appendingPathComponent($0) }
                    try! Zip.zipFiles(paths: logs, zipFilePath: zipUrl, password: nil, progress: nil)
                    showShare.toggle()
                }
            }, label: {
                Text("PackLogs")
                    .padding()
            })
            .buttonStyle(BorderedButtonStyle())
            
            Button(action: {
                startPerformanceCallback?()
            }, label: {
                Text("Performance")
                    .padding()
            })
            .buttonStyle(BorderedButtonStyle())
            .tint(.orange)

            if showShare {
                ShareLink(item: zipUrl)
            }
        }.tint(.purple)
    }
}
//
//#Preview {
//    HomeView()
//}

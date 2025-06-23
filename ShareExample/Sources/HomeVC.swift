import AgoraRtmKit
import ScribbleForge
import SwiftUI
#if canImport(Toast)
import Toast
#elseif canImport(Toast_Swift)
import Toast_Swift
#endif
import UIKit

let localWhiteboardSrc = "http://vince-mac.local:8080"
var globalHome: UIViewController?
class HomeVC: UIViewController {
    var rtm: AgoraRtmClientKit?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let homeView = HomeView { config in
            self.enterRoom(config: config)
        } startPerformanceCallback: {
            self.enterPerformance()
        }
        let configView = UIHostingController(rootView: homeView)
        addChild(configView)
        view.addSubview(configView.view)
        configView.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        globalHome = self
    }

    func generateRtmToken(region: ScribbleForge.Region, netlessToken: String, roomId: String, userId: String, completionHandler: ((Result<String, Error>) -> Void)?) {
        let url = URL(string: "\(region.endPoint)/\(roomId)/\(userId)/rtm/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(netlessToken, forHTTPHeaderField: "Token")
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    completionHandler?(.failure(error))
                }
                return
            }
            if let data = data {
                let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                let rtmToken = json["token"] as! String
                DispatchQueue.main.async {
                    completionHandler?(.success(rtmToken))
                }
            }
        }
        task.resume()
    }
    
    func enterRoom(config: RoomPrepareConfig) {
        if config.useRtm {
            updateIndicator(show: true)
            if config.rtmToken.isEmpty {
                print("Try generate rtmToken")
                generateRtmToken(region: config.region, netlessToken: config.roomToken, roomId: config.roomId, userId: config.userId) { result in
                    switch result {
                    case let .success(rtmToken):
                        var new = config
                        new.rtmToken = rtmToken
                        self.enterRoom(config: new)
                    case let .failure(error):
                        print("Generate rtm token error", error)
                        self.updateIndicator(show: false)
                    }
                }
                return
            }
            let rtmConfig = AgoraRtmClientConfig(appId: "d578d862f85a4545bab8d1f416e4fbd2", userId: config.userId)
            rtmConfig.presenceTimeout = 30
            let provider = try! AgoraRtmClientKit(rtmConfig, delegate: nil)
            rtm = provider
            print("[RTM] [DEMO] login")
            provider.login(config.rtmToken) { response, errorInfo in
                self.updateIndicator(show: false)
                if let errorInfo, errorInfo.errorCode != .ok {
                    print("Rtm error", errorInfo.errorCode.rawValue)
                    self.view.makeToast("Rtm error code \(errorInfo.errorCode.rawValue)")
                    return
                }
                if let _ = response {
                    let room = Room(joinRoomOptions: config.toJoinRoomOptions(), agoraRtmKit: provider)
                    room.addDelegate(self)
                    let vc = RoomViewController(room: room, prepareConfig: config)
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true)
                    return
                }
                print("RTM login error", errorInfo?.errorCode.rawValue.description ?? "unknow error code")
            }
        } else {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = MultiRoomVC(config: config)
            }
        }
    }
    
    func enterPerformance() {
//        let vc = UIHostingController(rootView: PerformanceView())
//        present(vc, animated: true)
    }

    func updateIndicator(show: Bool) {
        if indicatorView.superview == nil {
            indicatorView.backgroundColor = .gray.withAlphaComponent(0.3)
            view.addSubview(indicatorView)
            indicatorView.snp.makeConstraints { $0.edges.equalToSuperview() }
        }
        if show {
            indicatorView.startAnimating()
        } else {
            indicatorView.stopAnimating()
        }
        indicatorView.isHidden = !show
    }

    lazy var indicatorView = UIActivityIndicatorView(style: .medium)
}

// Rtm delegate
extension HomeVC: RoomDelegate {
    func roomUserJoinRoom(_: ScribbleForge.Room, user _: ScribbleForge.RoomUser) {}

    func roomApplicationDidLaunch(_: ScribbleForge.Room, application _: any ScribbleForge.Application) {}

    func roomApplicationDidTerminal(_: ScribbleForge.Room, application _: any ScribbleForge.Application) {}

    func roomConnectionStateDidUpdate(_: ScribbleForge.Room, connectionState: ScribbleForge.NetworkConnectionState, info _: [String: Any]) {
        if connectionState == .disconnected {
            print("[RTM] [DEMO] logout")
            rtm?.logout()
        }
    }

    func roomUserLeaveRoom(_: Room, userId _: String) {}
}

import Combine
import JavaScriptCore
import ScribbleForge
import SnapKit
import SwiftUI
import UIKit

let zipUrl = FileManager.default.temporaryDirectory.appendingPathComponent("sf.zip")

let images = (1 ..< 8).map {
    let src = URL(string: "https://conversion-demo-cn.oss-cn-hangzhou.aliyuncs.com/demo/staticConvert/88ac7994327647b99357ebce8e352aa6/\($0).png")!
    return ImageDocLaunchOption.Image(src: src, width: 572, height: 854)
}

let testDocOption = ImageDocLaunchOption(images: images, displayMode: .single, inheritWhiteboardId: "MainWhiteboard")

let testSlideOption = SlideLaunchOption(
    prefix: "https://white-cover.oss-cn-hangzhou.aliyuncs.com/flat/dynamicConvert",
    taskId: "46e8ff5db5714fec818f5594a6c55083",
    inheritWhiteboardId: "MainWhiteboard"
)

class RoomViewController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .phone ? .landscape : .all
    }
    
    var apps: [Int: Application] = [:]
    weak var whiteboard: Whiteboard? {
        didSet {
            if let whiteboard {
                setupWhitebard(whiteboard)
            }
        }
    }

    let room: Room
    var windowManager: WindowManager { room.windowManager }
    var monitorNetworkRandomLoss = false
    var windowManagerRandomMoving = false
    var applicationErrorObserver: Any?
    
    var ratio: CGFloat = 16.0 / 9.0 {
        didSet {
            syncRatio()
        }
    }

    func syncRatio() {
        roomStageContainer.snp.remakeConstraints { make in
            make.height.equalTo(roomStageContainer.snp.width).multipliedBy(1 / ratio).priority(.required)
            make.width.equalTo(view.safeAreaLayoutGuide).priority(.high)
        }
    }

    var joinRoomSuccessHandler: ((Room) -> Void)?
    var settingStrokeColor = true
    let prepareConfig: RoomPrepareConfig

    init(room: Room, prepareConfig: RoomPrepareConfig) {
        self.room = room
        self.prepareConfig = prepareConfig
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("room vc deinit")
        if let _ = self.whiteboard {
            whiteboardControlView.toolBarView.subMenuView.dismiss()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateExampleItems()
        initAction()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let isVertical = view.frame.height > view.frame.width
        exampleStackView.axis = isVertical ? .vertical : .horizontal

        if isVertical {
            exampleControlView.snp.remakeConstraints { make in
                make.height.equalTo(144)
            }
            sdkStatusView.snp.remakeConstraints { make in
                make.height.equalTo(50)
            }
        } else {
            exampleControlView.snp.remakeConstraints { make in
                make.width.equalTo(144)
            }
            sdkStatusView.snp.remakeConstraints { make in
                make.width.equalTo(120)
            }
        }
    }
    
    func setupViews() {
        view.backgroundColor = .black
        view.addSubview(exampleStackView)
        exampleStackView.snp.makeConstraints { make in
            make.width.height.lessThanOrEqualTo(view.safeAreaLayoutGuide)
            make.center.equalTo(view.safeAreaLayoutGuide)
        }
        
        roomStageContainer.layer.borderColor = UIColor.red.withAlphaComponent(0.45).cgColor
        roomStageContainer.layer.borderWidth = 1

        view.addSubview(showMenuButton)
        showMenuButton.snp.makeConstraints { make in
            make.centerY.equalTo(view.safeAreaLayoutGuide)
            make.right.equalTo(roomStageContainer.snp.right)
            make.width.height.equalTo(32)
        }

        syncRatio()
        
        var d = Bundle.scribbleForgeDependencies
        d[" ScribbleForge"] = Room.sdkVersion()
        let dd = d.sorted { $0.key < $1.key }
        sdkStatusView.updateDependencies(dd)
    }

    func initAction() {
        if let context = room.value(forKey: "__context") as? JSContext {
            if #available(iOS 16.4, *) {
                context.isInspectable = true
            }
        }
        applicationErrorObserver = NotificationCenter.default.addObserver(forName: roomApplicationErrorNotification, object: nil, queue: nil) { noti in
            print("roomApplicationErrorNotification", noti)
        }
        view.makeToastActivity(.center)
        room.addDelegate(self)
        room.joinRoom { [weak self] result in
            guard let self else { return }
            self.view.hideToastActivity()
            self.view.makeToast("Join room success. \(prepareConfig.useLocalSnapshot ? "Launching Apps..." : "Waiting for apps...")", position: .center)
            switch result {
            case .success:
                self.launchWhiteboard()
                self.setupViews()
                self.setupWindowManager()
                joinRoomSuccessHandler?(self.room)
                return
            case let .failure(error):
                print("join room fail error \(error)")
            }
        }
    }

    func onAppTerminal(_ app: String) {
        let hash = app.hashValue
        apps[hash]?.applicationView?.removeFromSuperview()
        apps.removeValue(forKey: hash)
    }

    func onAppAdd(_ app: Application) {
        setupAppMenu(app)
        if let whiteboard = app as? Whiteboard, whiteboard.appId == "MainWhiteboard" {
            self.whiteboard = whiteboard
        }
    }

    func reloadExampleItems() {
        updateExampleItems()
        exampleControlView.items = exampleItems
        exampleControlView.reloadData()
    }

    var exampleItems: [ExampleItem] = [] {
        didSet {
            exampleControlView.items = exampleItems
            exampleControlView.reloadData()
        }
    }

    lazy var whiteboardControlView = WhiteboardControlView()
    lazy var exampleControlView = ExampleControlView(items: exampleItems)
    lazy var roomStageContainer = UIView()
    lazy var sdkStatusView = StatusView()
    lazy var exampleStackView: UIStackView = {
        let containerStack = UIStackView(arrangedSubviews: [
            sdkStatusView,
            roomStageContainer,
            exampleControlView,
        ])
        containerStack.axis = .horizontal
        containerStack.spacing = 4
        exampleControlView.isHidden = true
        return containerStack
    }()
    lazy var showMenuButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.addAction(.init(handler: { [weak self] _ in
            UIView.animate(withDuration: 0.3) {
                self?.exampleControlView.isHidden.toggle()
            }
        }), for: .touchUpInside)
        btn.setImage(UIImage(systemName: "button.programmable"), for: .normal)
        btn.tintColor = .systemBlue
        return btn
    }()
}

// MARK: - RoomDelegate
extension RoomViewController: RoomDelegate {
    func roomConnectionStateDidUpdate(_: ScribbleForge.Room, connectionState: ScribbleForge.NetworkConnectionState, info: [String: Any]) {
        sdkStatusView.updateConnectionState(connectionState)
        print(#function)
    }

    func roomUserJoinRoom(_: ScribbleForge.Room, user _: ScribbleForge.RoomUser) {
        print(#function)
    }

    func roomUserLeaveRoom(_: ScribbleForge.Room, userId _: String) {
        print(#function)
    }

    func roomApplicationDidLaunch(_: Room, application: any Application) {
        print(#function, application.appId)
        onAppAdd(application)
    }

    func roomApplicationDidTerminal(_: Room, application app: any Application) {
        print(#function)
        onAppTerminal(app.appId)
    }
}

import UIKit
import ScribbleForge

class MultiRoomVC: UIViewController {
    let config: RoomPrepareConfig
    var rooms: [RoomViewController] = []
    init(config: RoomPrepareConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        if rooms.count <= 1 {
            sameHeight = true
        } else {
            updateRoomsHeight()
        }
    }
    
    func setupViews() {
        let existButton = UIButton(type: .system)
        existButton.addTarget(self, action: #selector(onExist), for: .touchUpInside)
        existButton.setImage(UIImage(systemName: "x.circle"), for: .normal)
        existButton.tintColor = .red
        let arrangeButton = UIButton(type: .system)
        arrangeButton.setImage(UIImage(systemName: "space"), for: .normal)
        arrangeButton.addTarget(self, action: #selector(onClickSpace), for: .touchUpInside)
        arrangeButton.tintColor = .blue
        let operationButtonsStackView = UIStackView(arrangedSubviews: [existButton, arrangeButton])
        operationButtonsStackView.axis = .horizontal
        operationButtonsStackView.distribution = .fillEqually
        // give a blur background.
        operationButtonsStackView.backgroundColor = .white
        operationButtonsStackView.layer.borderWidth = 1
        operationButtonsStackView.layer.borderColor = UIColor.lightGray.cgColor
        operationButtonsStackView.layer.cornerRadius = 8
        operationButtonsStackView.clipsToBounds = true
        
        view.addSubview(operationButtonsStackView)
        operationButtonsStackView.snp.makeConstraints { make in
            make.left.top.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(32)
        }
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.left.equalTo(view.safeAreaLayoutGuide)
            make.right.equalTo(view.safeAreaLayoutGuide)
            make.top.equalTo(operationButtonsStackView.snp.bottom)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        var mainProvider: TestProvider?
        for index in 0 ..< config.roomCount {
            let roomId = "room-instanc-test"
            let userId = "user-\(index)"
            let provider = TestProvider(userId: userId)

            let fetcher: MockSnapshotFetcher
            if config.useLocalSnapshot {
                let data = UserDefaults.standard.data(forKey: "localSnapshot")
                fetcher = .init(data: data)
            } else {
                fetcher = .init(data: nil)
            }
            
            let room = Room(
                roomId: roomId,
                userId: userId,
                nickName: userId + "-nickname",
                snapshotFetcher: fetcher,
                uploaderExecutor: MockExecutor(type: .success),
                remoteLogger: nil,
                networkProvider: provider,
                historyProvider: nil,
                writableProvider: provider,
                windowManagerOption: nil,
                mergeThrottleTime: 0,
                allowConsoleVerboseLog: config.showVerboseLog,
                jscPerfObserveEnable: true
            )
            room.set(key: "allowMultiRoom", value: true)
            let i = RoomViewController(room: room, prepareConfig: config)
            i.joinRoomSuccessHandler = { _ in
                if let mainProvider {
                    mainProvider.connect(provider)
                    provider.connect(mainProvider)
                } else {
                    mainProvider = provider
                }
            }
            
            rooms.append(i)
            addChild(i)
            stack.addArrangedSubview(i.view)
        }
    }

    var stack: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .fillEqually
        return view
    }()
    
    var sameHeight = false {
        didSet {
            updateRoomsHeight()
        }
    }
    
    func updateRoomsHeight() {
        if sameHeight {
            stack.distribution = .fillEqually
            stack.arrangedSubviews.forEach {
                $0.snp.remakeConstraints { _ in }
            }
        } else {
            stack.distribution = .fill
            stack.arrangedSubviews.enumerated().forEach { index, element in
                element.snp.remakeConstraints { make in
                    let ratio: CGFloat
                    if index == 0 {
                        ratio = 0.6
                    } else {
                        ratio = 0.4 /  CGFloat(stack.arrangedSubviews.count - 1)
                    }
                    make.height.equalTo(stack).multipliedBy(ratio)
                }
            }
        }
    }
    
    @objc
    func onClickSpace() {
        guard stack.arrangedSubviews.count > 1 else { return }
        sameHeight.toggle()
    }
    
    @objc
    func onExist() {
        rooms.forEach {
            $0.removeFromParent()
            $0.room.leaveRoom { _ in }
        }
        UIApplication.shared.keyWindow?.rootViewController = globalHome
    }
}

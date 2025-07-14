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
    
    var bag: Set<AnyCancellable> = .init()
    var apps: [Int: Application] = [:]
    weak var whiteboard: Whiteboard? {
        didSet {
            whiteboard?.delegate = self
            if let whiteboard {
                setupWhitebard(wb: whiteboard)
            }
        }
    }

    weak var windowManager: WindowManager? {
        didSet {
            windowManager?.delegate = self
            if let windowManager, let applicationView = windowManager.applicationView {
                mainStageContainer.addSubview(applicationView)
                applicationView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                mainContainer.bringSubviewToFront(applicationView)

                let menuButton = UIButton(type: .system)
                menuButton.backgroundColor = .systemRed.withAlphaComponent(0.65)
                windowManager.applicationView?.addSubview(menuButton)
                menuButton.showsMenuAsPrimaryAction = true
                menuButton.snp.makeConstraints { make in
                    make.left.top.equalToSuperview()
                }

                menuButton.setImage(
                    UIImage(systemName: "macwindow.on.rectangle", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 14))),
                    for: .normal
                )
                menuButton.addTarget(self, action: #selector(setupWindowManager), for: .menuActionTriggered)
                setupWindowManager(menuButton)
            }
        }
    }

    var hideMenu: Bool = false {
        didSet {
            showMenuButton.isHidden = !hideMenu
            exampleControlView.isHidden = hideMenu
        }
    }

    var joinRoomSuccessHandler: ((Room) -> Void)?
    var settingStrokeColor = true
    var randomLoss = false
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

    var ob: Any?

    lazy var mainStageContainer = UIView()
    lazy var statusView: StatusView = {
        let view = StatusView()
        return view
    }()
    
    lazy var mainContainer: UIStackView = {
        let containerStack = UIStackView(arrangedSubviews: [
            statusView,
            mainStageContainer,
            exampleControlView,
        ])
        containerStack.axis = .horizontal
        containerStack.spacing = 8
        return containerStack
    }()

    var ratio: CGFloat = 16.0 / 9.0 {
        didSet {
            syncRatio()
        }
    }

    func syncRatio() {
        mainStageContainer.snp.remakeConstraints { make in
            make.height.equalTo(mainStageContainer.snp.width).multipliedBy(1 / ratio).priority(.required)
            make.width.equalTo(view.safeAreaLayoutGuide).priority(.high)
        }
    }

    func setupViews() {
        view.backgroundColor = .black
        mainStageContainer.layer.borderColor = UIColor.red.withAlphaComponent(0.45).cgColor
        mainStageContainer.layer.borderWidth = 1

        view.addSubview(mainContainer)
        mainContainer.snp.makeConstraints { make in
            make.width.height.lessThanOrEqualTo(view.safeAreaLayoutGuide)
            make.center.equalTo(view.safeAreaLayoutGuide)
        }

        view.addSubview(showMenuButton)
        showMenuButton.snp.makeConstraints { make in
            make.right.centerY.equalTo(view.safeAreaLayoutGuide)
            make.width.height.equalTo(32)
        }

        syncRatio()
    }

    func launchWhiteboard() {
        room.launchWhiteboard(
            appId: "MainWhiteboard",
            option: .init(
                width: 1920,
                height: 1080,
                maxScaleRatio: 1,
                defaultToolInfo: .init(tool: .curve, strokeColor: UIColor.blue.toHexString())
            )
        ) { r in
            switch r {
            case let .success(wb):
                wb.setPermission(permission: .all)
            case .failure:
                return
            }
        }
    }

    func initAction() {
        if let context = room.value(forKey: "__context") as? JSContext {
            if #available(iOS 16.4, *) {
                context.isInspectable = true
            }
        }
        ob = NotificationCenter.default.addObserver(forName: roomApplicationErrorNotification, object: nil, queue: nil) { noti in
            print("roomApplicationErrorNotification", noti)
        }
        view.makeToastActivity(.center)
        room.addDelegate(self)
        room.joinRoom { [weak self] result in
            guard let self else { return }
            self.view.hideToastActivity()
            self.view.makeToast("Join room success. \(prepareConfig.launchDefault ? "Launching Apps..." : "Waiting for apps...")", position: .center)
            switch result {
            case .success:
                self.setupViews()
                self.hideMenu = true
                if self.prepareConfig.launchDefault {
//                    self.launchWhiteboard()
//                    self.launchWindowManager()
                }
                joinRoomSuccessHandler?(self.room)
                return
            case let .failure(error):
                print("join room fail error \(error)")
            }
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
        mainContainer.axis = isVertical ? .vertical : .horizontal

        if isVertical {
            exampleControlView.snp.remakeConstraints { make in
                make.height.equalTo(144)
            }
            statusView.snp.remakeConstraints { make in
                make.height.equalTo(50)
            }
        } else {
            exampleControlView.snp.remakeConstraints { make in
                make.width.equalTo(144)
            }
            statusView.snp.remakeConstraints { make in
                make.width.equalTo(120)
            }
        }
    }

    func setupWhitebard(wb: Whiteboard) {
        guard let applicationView = wb.applicationView else { return }
        mainStageContainer.addSubview(applicationView)
        mainStageContainer.sendSubviewToBack(applicationView)
        applicationView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        applicationView.addSubview(whiteboardControlView)
        whiteboardControlView.whiteboard = wb
        whiteboardControlView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
            
            if self.windowManager == nil {
                self.windowManager = self.room.windowManager
            }
        }
    }

    let room: Room

    var followId: String?
    @objc func onFollowSomeOne(_ tf: UITextField) {
        followId = tf.text
    }

    @objc func onUpdateStrokeWidth(_ tf: UITextField) {
        if let f = Float(tf.text ?? "") {
            whiteboard?.setStrokeWidth(f)
        }
    }

    func reloadExampleItems() {
        updateExampleItems()
        exampleControlView.items = exampleItems
        exampleControlView.reloadData()
    }
    
    @objc func onShowMenu() {
        hideMenu = false
    }

    lazy var showMenuButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.addTarget(self, action: #selector(onShowMenu), for: .touchUpInside)
        btn.setImage(UIImage(systemName: "button.programmable"), for: .normal)
        btn.tintColor = .systemBlue
        return btn
    }()

    var exampleItems: [ExampleItem] = [] {
        didSet {
            exampleControlView.items = exampleItems
            exampleControlView.reloadData()
        }
    }

    lazy var whiteboardControlView = WhiteboardControlView()
    lazy var exampleControlView = ExampleControlView(items: exampleItems)


    var randomMoving = false
    @objc func randomMoveLoop() {
        randomMoving = true
        let x = CGFloat.random(in: 0 ... 1)
        let y = CGFloat.random(in: 0 ... 1)
        if let appId = windowManager?.windowsInfo.randomElement()?.key {
            windowManager?.moveApp(appId, to: .init(x: x, y: y))
        }
        perform(#selector(randomMoveLoop), with: nil, afterDelay: 2)
    }

    var targetUserPage: Int?
}

// MARK: - RoomDelegate
extension RoomViewController: RoomDelegate {
    @objc func onSetUserPageTfUpdate(_ tf: UITextField) {
        if let page = Int(tf.text ?? "") {
            targetUserPage = page - 1
        }
    }

    func setUserPage(_ userId: String) {
        let alert = UIAlertController(title: "SetUserPage(\(userId))", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.keyboardType = .numberPad
            tf.addTarget(self, action: #selector(self.onSetUserPageTfUpdate), for: .editingChanged)
        }
        alert.addAction(.init(title: "Cancel", style: .cancel))
        alert.addAction(.init(title: "Confirm", style: .default, handler: { _ in
            guard let page = self.targetUserPage else { return }
            self.whiteboard?.setFreeModeUserPageIndex(index: page, userId: userId)
        }))
        present(alert, animated: true)
    }

    func roomConnectionStateDidUpdate(_: ScribbleForge.Room, connectionState: ScribbleForge.NetworkConnectionState, info: [String: Any]) {
        statusView.updateConnectionState(connectionState)
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

extension RoomViewController: WhiteboardDelegate {
    func whiteboardUndoStackLengthUpdate(_: ScribbleForge.Whiteboard, undoStackLength: Int) {
        print("[whiteboard delegate]", #function, undoStackLength)
        whiteboardControlView.undoRedoView.undoStep = undoStackLength
    }

    func whiteboardRedoStackLengthUpdate(_: ScribbleForge.Whiteboard, redoStackLength: Int) {
        print("[whiteboard delegate]", #function, redoStackLength)
        whiteboardControlView.undoRedoView.redoStep = redoStackLength
    }

    func whiteboardError(_: ScribbleForge.Whiteboard, errorCode: Int, errorMessage: String) {
        print("[whiteboard delegate]", #function, errorCode, errorMessage)
    }

    func whiteboardToolInfoUpdate(_: ScribbleForge.Whiteboard, toolInfo: ScribbleForge.WhiteboardToolInfo) {
        print("[whiteboard delegate]", #function, toolInfo)
        whiteboardControlView.toolBarView.syncCurrentTool(
            toolType: toolInfo.tool,
            strokeColor: UIColor(hex: toolInfo.strokeColor),
            fillColor: toolInfo.fillColor.map { UIColor(hex: $0) },
            strokeWidth: toolInfo.strokeWidth,
            textSize: toolInfo.fontSize,
            dash: toolInfo.dashArray
        )
    }

    func whiteboardPagePermissionUpdate(_: ScribbleForge.Whiteboard, userId: String, permission: ScribbleForge.WhiteboardPermission) {
        print("[whiteboard delegate]", #function, permission, userId)
        whiteboardControlView.whiteboard = whiteboard
    }

    func whiteboardElementSelected(_ whiteboard: ScribbleForge.Whiteboard, info: ScribbleForge.WhiteboardSelectInfo) {
        print("[whiteboard delegate]", #function, info)
        var attributes: [ElementAttributesKey: Any] = [:]

        for attribute in info.attributes {
            whiteboard.getElementAttribute(sceneId: info.layerId, elementId: info.uuid, attributeKey: attribute) { value in
                attributes[attribute] = value

                if attributes.count == info.attributes.count {
                    print("Attributes", attributes)
                    let popOverView = PopOver(attributes: attributes) { color in
                        if let color {
                            whiteboard.setElementAttribute(layerId: info.layerId, elementId: info.uuid, attributeKey: .strokeColor, value: color.toHexString())
                        }
                    } strokeWidthUpdate: { width in
                        whiteboard.setElementAttribute(layerId: info.layerId, elementId: info.uuid, attributeKey: .strokeWidth, value: width)
                    } fillColorUpdate: { color in
                        if let color {
                            whiteboard.setElementAttribute(layerId: info.layerId, elementId: info.uuid, attributeKey: .fillColor, value: color.toHexString())
                        }
                    } fontSizeUpdate: { size in
                        whiteboard.setElementAttribute(layerId: info.layerId, elementId: info.uuid, attributeKey: .fontSize, value: size)
                    } dashStyleUpdate: { array in
                        whiteboard.setElementAttribute(layerId: info.layerId, elementId: info.uuid, attributeKey: .dashArray, value: array)
                    } headArrowUpdate: {
                        whiteboard.setElementAttribute(layerId: info.layerId, elementId: info.uuid, attributeKey: .headArrow, value: $0 ? "normal" : "none")
                    } tailArrowUpdate: {
                        whiteboard.setElementAttribute(layerId: info.layerId, elementId: info.uuid, attributeKey: .tailArrow, value: $0 ? "normal" : "none")
                    }
                    let popoverContent = UIHostingController(rootView: popOverView)
                    popoverContent.preferredContentSize = CGSize(width: 200, height: 0)
                    popoverContent.modalPresentationStyle = .popover
                    if let popoverPresentationController = popoverContent.popoverPresentationController {
                        popoverPresentationController.permittedArrowDirections = .any
                        popoverPresentationController.sourceView = whiteboard.applicationView
                        popoverPresentationController.sourceRect = info.boundingRect
                        popoverPresentationController.delegate = self
                    }
                    self.present(popoverContent, animated: true)
                }
            }
        }
    }

    func whiteboardElementDeselected(_: ScribbleForge.Whiteboard) {
//        print("[whiteboard delegate]", #function)
        
        whiteboardControlView.toolBarView.subMenuView.dismiss()
    }

    func whiteboardPageInfoUpdate(_: Whiteboard, activePageIndex: Int, pageCount: Int) {
        print("[whiteboard delegate]", #function, activePageIndex, pageCount)
        whiteboardControlView.pagesView.updatePageLabel(current: activePageIndex, total: pageCount)
    }
}

extension RoomViewController: ImageDocDelegate {
    func imageDoc(_: ScribbleForge.ImageDoc, didPermissionUpdate permission: ScribbleForge.ImageDocPermission, userId: String) {
        print("[image doc delegate]", #function, permission, userId)
    }

    func imageDoc(_: ImageDoc, didChangePageIndex pageInt: Int) {
        print("[image doc delegate]", #function, pageInt)
    }
}

extension RoomViewController: WindowManagerDelegate {
    func windowManager(_: WindowManager, didTerminal application: any Application) {
        print("[wm delegate]", #function, application)
        onAppTerminal(application.appId)
    }

    func windowManager(_: ScribbleForge.WindowManager, didLaunchApp application: any ScribbleForge.Application) {
        print("[wm delegate]", #function, application)
        onAppAdd(application)
    }

    func windowManager(_: ScribbleForge.WindowManager, focusedAppUpdate appId: String) {
        print("[wm delegate]", #function, appId)
    }

    func windowManager(_: ScribbleForge.WindowManager, permissionUpdate permission: ScribbleForge.WindowManagerPermission, userId: String) {
        print("[wm delegate]", #function, userId, permission)
    }

    func windowManager(_: ScribbleForge.WindowManager, windowStateUpdate windowState: ScribbleForge.WindowState) {
        print("[wm delegate]", #function, windowState)
    }
}

// MARK: - Slide delegate
extension RoomViewController: SlideDelegate {
    func slidePermissionChange(_: Slide, userId: String, permission: SlidePermission) {
        print("[slide delegate]", #function, userId, permission)
    }

    func slideRenderStart(_: Slide, index: Int) {
        print("[slide delegate]", #function, index)
    }

    func slideRenderEnd(_: Slide, index: Int) {
        print("[slide delegate]", #function, index)
    }

    func slideMainSeqStepStart(_: Slide, index: Int) {
        print("[slide delegate]", #function, index)
    }

    func slideMainSeqStepEnd(_: Slide, index: Int) {
        print("[slide delegate]", #function, index)
    }
}

extension RoomViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        if settingStrokeColor {
            whiteboard?.setStrokeColor(viewController.selectedColor)
        } else {
            whiteboard?.setFillColor(viewController.selectedColor)
        }
    }
}

extension RoomViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for _: UIPresentationController) -> UIModalPresentationStyle {
        .none
    }
}

extension WhiteboardPermission {
    var localizedDescription: String {
        switch self {
        case .draw: "draw"
        case .editSelf: "editSelf"
        case .editOthers: "editOthers"
        case .deleteSelf: "deleteSelf"
        case .deleteOthers: "deleteOthers"
        case .setOthersView: "setOthersView"
        case .mainView: "mainView"
        default:
            "Unknown"
        }
    }
}

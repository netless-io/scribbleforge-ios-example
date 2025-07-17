import Foundation
import UIKit
import ScribbleForge

extension RoomViewController {
    @objc func randomMoveLoop() {
        windowManagerRandomMoving = true
        let x = CGFloat.random(in: 0 ... 1)
        let y = CGFloat.random(in: 0 ... 1)
        if let appId = windowManager.windowsInfo.randomElement()?.key {
            windowManager.moveApp(appId, to: .init(x: x, y: y))
        }
        perform(#selector(randomMoveLoop), with: nil, afterDelay: 2)
    }
    
    func setupWindowManager() {
        windowManager.delegate = self
        if let applicationView = windowManager.applicationView {
            roomStageContainer.addSubview(applicationView)
            applicationView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            exampleStackView.bringSubviewToFront(applicationView)

            let menuButton = UIButton(type: .system)
            menuButton.backgroundColor = .systemRed.withAlphaComponent(0.65)
            menuButton.showsMenuAsPrimaryAction = true
            menuButton.setImage(
                UIImage(systemName: "macwindow.on.rectangle", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 14))),
                for: .normal
            )
            menuButton.addTarget(self, action: #selector(setupWindowManagerButtons), for: .menuActionTriggered)
            windowManager.applicationView?.addSubview(menuButton)
            
            menuButton.snp.makeConstraints { make in
                make.left.top.equalToSuperview()
            }
            setupWindowManagerButtons(menuButton)
        }
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

//
//  WindowManagerMenu.swift
//  S11E-Pod
//
//  Created by vince on 2025/7/31.
//

import Foundation
import UIKit
import ScribbleForge

extension RoomViewController {
    @objc
    func setupWindowManagerButtons(_ menuButton: UIButton) {
        let app = windowManager

        let ratioMenu = UIMenu(title: "Ratio", children: [
            UIAction(title: "1:1", handler: { [unowned app] _ in
                app.updateRatio(1)
            }),
            UIAction(title: "16:9", handler: { [unowned app] _ in
                app.updateRatio(16.0 / 9.0)
            }),
            UIAction(title: "9:16", handler: { [unowned app] _ in
                app.updateRatio(9.0 / 16.0)
            }),
            UIAction(title: "4:3", handler: { [unowned app] _ in
                app.updateRatio(4.0 / 3.0)
            }),
            UIAction(title: "Auto", handler: { [unowned app] _ in
                app.updateRatio(nil)
            }),
        ])

        let docsMenu = UIMenu(title: "ImageDocs", children: [
            UIAction(title: "ImageDoc", handler: { [unowned app] _ in
                app.launchImageDoc(option: testDocOption)
            }),
            UIAction(title: "ImageDoc(Continous)", handler: { [unowned app] _ in
                var o = testDocOption
                o.displayMode = .continuous
                app.launchImageDoc(option: o)
            }),
        ])
        let launchMenu = UIMenu(title: "Launch", children: [
            docsMenu,
            UIAction(title: "Whiteboard", handler: { [unowned app] _ in
                app.launchWhiteboard()
            }),
            UIAction(title: "Slide", handler: { [unowned app] _ in
                app.launchSlide(option: testSlideOption)
            }),
            UIAction(title: "NativePDF", handler: { [unowned app] _ in
//                app.launchTestNativePdf()
            }),
            UIAction(title: "MediaPlayer", handler: { [unowned app] _ in
//                app.launchTestMediaPlayer()
            }),
        ])
        let permissionMenu = UIMenu(title: "Permission", children:
            room.userManager.idList().map { [unowned app, unowned self] userId in
                let enable = app.getPermission(userId).contains(.operating)
                return UIAction(title: userId + (userId == self.room.userId ? "    (Self)" : ""), state: enable ? .on : .off) { _ in
                    let enable = app.getPermission(userId).contains(.operating)
                    app.setPermission(userId, permission: enable ? .none : .operating)
                }
            })
        menuButton.menu = .init(children: [
            launchMenu,
            permissionMenu,
            ratioMenu,
            UIAction(title: "Random Drag", state: windowManagerRandomMoving ? .on : .off, handler: { [unowned self] _ in
                if self.windowManagerRandomMoving {
                    self.windowManagerRandomMoving = false
                    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.randomMoveLoop), object: nil)
                } else {
                    self.randomMoveLoop()
                }
            }),
        ])
    }
}

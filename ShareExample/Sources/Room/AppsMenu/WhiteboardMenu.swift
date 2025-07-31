//
//  WhiteboardMenu.swift
//  S11E-Pod
//
//  Created by vince on 2025/7/31.
//

import Foundation
import UIKit
import ScribbleForge
import SwiftUI

extension RoomViewController {
    @objc
    func setupWhiteboard(_ menuButton: UIButton) {
        let app = apps[menuButton.tag] as! Whiteboard

        let tool = app.currentTool()
        let toolStr = tool?.rawValue.uppercased() ?? ""
        let toolsMenu = UIMenu(
            title: "Tools(\(toolStr))",
            children: WhiteboardToolType.allCases.map { type in
                UIAction(
                    title: type.rawValue,
                    image: UIImage(
                        systemName: type.systemImage
                    ),
                    state: tool == type ? .on : .off
                ) { [unowned app] _ in
                app.setCurrentTool(type)
            }
        })

        let detailMenu = UIMenu(title: "More", children: [
            UIAction(title: "Use Transparent Background", handler: { [unowned whiteboard] _ in
                whiteboard?.applicationView?.isOpaque = false
                whiteboard?.setBackgroundColor(.clear)
            }),
            UIAction(title: "Update Background Color", handler: { [unowned app] _ in
                app.setBackgroundColor(.randomColor)
            }),
            UIAction(title: "Update Theme Color", handler: { [unowned app] _ in
                app.setThemeColor(.randomColor)
            }),
            UIAction(title: "Update Fill COlor", handler: { [unowned self] _ in
                let vc = UIColorPickerViewController()
                vc.supportsAlpha = false
                vc.delegate = self
                self.present(vc, animated: true)
                self.settingStrokeColor = false
            }),
            UIAction(title: "Update Cursor Visible", handler: { [unowned app] _ in
                app.setLiveCursorVisible(false)
            }),
            UIAction(title: "Update Stroke Color", handler: { [unowned self] _ in
                let vc = UIColorPickerViewController()
                vc.supportsAlpha = false
                vc.delegate = self
                self.present(vc, animated: true)
                self.settingStrokeColor = true
            }),
            UIAction(title: "Update Stroke Width", handler: { [unowned self, unowned app] _ in
                let alert = UIAlertController(title: "StrokeWidth", message: nil, preferredStyle: .alert)
                alert.addTextField { tf in
                    tf.keyboardType = .numberPad
                }
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { _ in
                    guard let text = alert.textFields?.first?.text, let width = Float(text) else { return }
                    app.setStrokeWidth(width)
                }))
                self.present(alert, animated: true)
            }),
        ])
        let viewModeMenu = UIMenu(title: "ViewMode(\(app.getViewMode()))", children: [
            UIAction(title: "Free", handler: { [unowned app] _ in app.setViewMode(.free) }),
            UIAction(title: "Main", handler: { [unowned app] _ in app.setViewMode(.mainView) }),
            UIAction(title: "someOne", handler: { [unowned self, unowned app] _ in
                let alert = UIAlertController(title: "FollowSomeOne", message: nil, preferredStyle: .alert)
                alert.addTextField { tf in
                    tf.keyboardType = .default
                }
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { [unowned app] _ in
                    guard let id = alert.textFields?.first?.text else { return }
                    app.setViewMode(.follow(userId: id))
                }))
                self.present(alert, animated: true)
            }),
        ])
        let permission = app.getPermission()
        let allPermissions: [WhiteboardPermission] = [.draw, .editSelf, .editOthers, .deleteSelf, .deleteOthers, .setOthersView, .mainView]
        let permissionMenu = UIMenu(
            title: "Permission(\(permission.rawValue))",
            children: allPermissions.map { p in
                let selected = permission.contains(p)
                return UIAction(title: p.localizedDescription, state: selected ? .on : .off) { [unowned app] _ in
                    var target = permission
                    if selected {
                        target.remove(p)
                    } else {
                        target.insert(p)
                    }
                    app.setPermission(permission: target)
                }
            }
        )

        var userPermissions: [String: WhiteboardPermission] = [:]
        let onlineUsers = room.userManager.idList().compactMap { self.room.userManager.getUser(userId: $0) }.filter(\.online)
        onlineUsers.forEach { user in
            let p = app.getPermission(userId: user.id)
            userPermissions[user.id] = p
        }
        let userMenus = onlineUsers.map { user in
            let allPermissionTypes: [WhiteboardPermission] = [.draw, .editSelf, .editOthers, .deleteSelf, .deleteOthers, .setOthersView, .mainView]
            var actions = allPermissionTypes.map { p in
                let userPermission = userPermissions[user.id]!
                let selected = userPermission.contains(p)
                return UIAction(title: p.localizedDescription, attributes: .keepsMenuPresented, state: selected ? .on : .off) { [unowned app] _ in
                    var target = permission
                    if selected {
                        target.remove(p)
                    } else {
                        target.insert(p)
                    }
                    app.setPermission(userId: user.id, permission: target)
                }
            }
            actions.append(.init(title: "SetUserPage", handler: { [unowned self] _ in
                self.setUserPage(user.id)
            }))
            return UIMenu(title: user.nickName + "(\(user.id))" + (user.id == self.room.userId ? "(Self)" : ""), children: actions)
        }
        
        menuButton.menu = .init(children: [
            toolsMenu,
            detailMenu,
            permissionMenu,
            viewModeMenu,
            UIAction(title: "Insert Image", handler: { [unowned whiteboard] _ in
                whiteboard?.insert(image: .init(string: "https://convertcdn.netless.link/dynamicConvert/2d50ba6075dd46d0817dfe518d089a07/preview/1.png")!)
            }),
            UIMenu(title: "Users", children: userMenus),
            UIMenu(title: "Pages", children: [
                UIAction(title: "Go To", handler: { [unowned app] _ in
                    app.indexedNavigation.gotoPage(index: 0)
                }),
                UIAction(title: "Insert", handler: { [unowned app] _ in
                    app.indexedNavigation.insertPage(after: 1)
                }),
            ]),
            UIMenu(title: "Rasterize", children: [
                UIAction(title: "Normal Rasterize") { [unowned app, unowned self] _ in
                    app.rasterize { result in
                        switch result {
                        case let .success(image):
                            let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                            vc.popoverPresentationController?.sourceView = app.applicationView
                            self.present(vc, animated: true)
                        case let .failure(failure):
                            print(failure)
                        }
                    }
                },
                UIAction(title: "Advance Rasterize") { [unowned app, unowned self] _ in
                    let view = RasterizeOptionPickView(cancel: {
                        self.dismiss(animated: true)
                    }, confirm: { option in
                        self.dismiss(animated: true)
                        app.rasterize(option: option, completionHandler: { result in
                            switch result {
                            case let .success(image):
                                let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                                vc.popoverPresentationController?.sourceView = app.applicationView
                                self.present(vc, animated: true)
                            case .failure:
                                return
                            }
                        })
                    })
                    let vc = UIHostingController(rootView: view)
                    vc.modalPresentationStyle = .formSheet
                    vc.sheetPresentationController?.detents = [.medium()]
                    self.present(vc, animated: true)
                },
            ]),
            UIAction(title: "Update ViewPort") { [unowned app] _ in
                app.updateViewPort(.init(width: 144, height: 144))
            },
        ])
    }
}

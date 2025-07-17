import ScribbleForge
import SwiftUI
import UIKit

extension RoomViewController {
    func setupAppMenu(_ app: Application) {
        apps[app.appId.hashValue] = app

        let menuButton = UIButton(type: .system)
        menuButton.backgroundColor = .systemRed.withAlphaComponent(0.65)
        app.applicationView?.addSubview(menuButton)
        menuButton.setImage(
            UIImage(systemName: "slider.horizontal.3", withConfiguration: UIImage.SymbolConfiguration.init(font: .systemFont(ofSize: 14))),
            for: .normal)
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.tag = app.appId.hashValue
        menuButton.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
        }
        
        let reloadButton = UIButton(type: .system)
        reloadButton.backgroundColor = .systemMint
        app.applicationView?.addSubview(reloadButton)
        reloadButton.setImage(
            UIImage(systemName: "arrow.clockwise.circle", withConfiguration: UIImage.SymbolConfiguration.init(font: .systemFont(ofSize: 14))),
            for: .normal)
        reloadButton.tag = app.appId.hashValue
        reloadButton.addTarget(self, action: #selector(reloadApp), for: .touchUpInside)
        reloadButton.snp.makeConstraints { make in
            make.right.top.equalToSuperview()
        }
        reloadButton.isHidden = app.getWebView() == nil
        
        if let app = app as? Slide {
            app.delegate = self
            menuButton.addTarget(self, action: #selector(setupSlide), for: .menuActionTriggered)
            setupSlide(menuButton)
        }
        if let app = app as? ImageDoc {
            app.delegate = self
        }
        if app is Whiteboard {
            menuButton.addTarget(self, action: #selector(setupWhiteboard), for: .menuActionTriggered)
            setupWhiteboard(menuButton)
            menuButton.snp.remakeConstraints { make in
                make.left.bottom.equalToSuperview()
            }
        }
        if app is ImageDoc {
            menuButton.addTarget(self, action: #selector(setupImageDoc), for: .menuActionTriggered)
            setupImageDoc(menuButton)
        }
    }
    
    @objc
    func reloadApp(_ sender: UIButton) {
        let app = apps[sender.tag]!
        if let webView = app.getWebView() {
            webView.reload()
        }
    }

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
            UIAction(title: "Update Stroke Width", handler: { [unowned self] _ in
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
                app.launchTestWhiteboard()
            }),
            UIAction(title: "Slide", handler: { [unowned app] _ in
                app.launchSlide(option: testSlideOption)
            }),
            UIAction(title: "NativePDF", handler: { [unowned app] _ in
                app.launchTestNativePdf()
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

    @objc
    func setupImageDoc(_ menuButton: UIButton) {
        let imageDoc = apps[menuButton.tag] as! ImageDoc
        let permissionMenu = UIMenu(title: "Permission", children:
            room.userManager.idList().map { [unowned imageDoc, unowned self] userId in
                let enable = imageDoc.getPermission(userId: userId) == .all
                return UIAction(title: userId + (userId == self.room.userId ? "    (Self)" : ""), state: enable ? .on : .off) { _ in
                    let enable = !enable
                    imageDoc.setPermission(userId: userId, permission: enable ? .all : .none)
                }
            })
        menuButton.menu = .init(children: [
            permissionMenu,
            UIAction(title: "Next Page", handler: { [unowned imageDoc] _ in
                imageDoc.go(to: imageDoc.pageIndex + 1)
            }),
            UIAction(title: "Previous Page", handler: { [unowned imageDoc] _ in
                imageDoc.go(to: imageDoc.pageIndex - 1)
            }),
            UIAction(title: "Go to Page...", handler: { [unowned imageDoc] _ in
                // Example - go to first page
                imageDoc.go(to: 0)
            }),
            UIAction(title: "Page Info", handler: { [unowned imageDoc] _ in
                print("Current page: \(imageDoc.pageIndex) of \(imageDoc.pageCount)")
            })
        ])
    }

    @objc
    func setupSlide(_ menuButton: UIButton) {
        let slide = apps[menuButton.tag] as! Slide
        let permissionMenu = UIMenu(title: "Permission", children:
            room.userManager.idList().map { [unowned slide, unowned self] userId in
                let enable = slide.getPermission(userId: userId) == .all
                return UIAction(title: userId + (userId == self.room.userId ? "    (Self)" : ""), state: enable ? .on : .off) { _ in
                    let enable = !enable
                    slide.setPermission(userId: userId, permission: enable ? .all : .none)
                }
            })
        menuButton.menu = .init(children: [
            permissionMenu,
            UIAction(title: "Next Step", handler: { [unowned slide] _ in
                slide.nextStep()
            }),
            UIAction(title: "Previous Step", handler: { [unowned slide] _ in
                slide.prevStep()
            }),
            UIAction(title: "Next Page", handler: { [unowned slide] _ in
                slide.nextPage()
            }), 
            UIAction(title: "Previous Page", handler: { [unowned slide] _ in
                slide.prevPage()
            }),
            UIAction(title: "Go to Page...", handler: { [unowned slide] _ in
                // Example - go to first page
                slide.go(to: 0)
            }),
            UIAction(title: "Page Info", handler: { [unowned slide] _ in
                print("Current page: \(slide.pageIndex) of \(slide.pageCount)")
            })
        ])
    }
}

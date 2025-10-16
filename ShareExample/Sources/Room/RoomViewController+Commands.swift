import NTLBridge
import ScribbleForge
import SwiftUI
import UIKit
import Zip

extension Application {
    func getWebView() -> NTLDWKWebView? {
        if let view = applicationView {
            if let webView = view as? NTLDWKWebView {
                return webView
            }
            for subView in view.subviews {
                if let webView = subView as? NTLDWKWebView {
                    return webView
                }
            }
            return nil
        } else {
            return nil
        }
    }
}

extension RoomViewController {
    func updateExampleItems() {
        var items: [ExampleItem] = [
            .init(title: "Leave", backgroundColor: .systemRed, clickBlock: { [unowned self] _ in
                self.dismiss(animated: true)
                self.room.leaveRoom { _ in }
            }),
            .init(title: "Debug", subMenuAction: { [unowned self] debugBtn in
                let logsMenu = UIMenu(title: "Logs", children: [
                    UIAction(title: "Export Log", handler: { _ in
                        if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first {
                            if FileManager.default.fileExists(atPath: zipUrl.path) {
                                try? FileManager.default.removeItem(at: zipUrl)
                            }
                            let files = (try? FileManager.default.contentsOfDirectory(atPath: cacheDir.path)) ?? []
                            let logs = files
                                .filter { $0.starts(with: "scribe_forge") }
                                .map { cacheDir.appendingPathComponent($0) }
                            try! Zip.zipFiles(paths: logs, zipFilePath: zipUrl, password: nil, progress: nil)
                            let vc = UIActivityViewController(activityItems: [zipUrl], applicationActivities: nil)
                            vc.excludedActivityTypes = [.addToReadingList, .assignToContact]
                            self.present(vc, animated: true)
                        }
                    }),
                    UIAction(title: "Copy Log Path", handler: { _ in
                        if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first {
                            let str = "code " + cacheDir.path()
                            UIPasteboard.general.string = str
                        }
                    }),
                ])
                var docsActions: [UIAction] = [
                    UIAction(title: "Export Doc", handler: { [unowned self] _ in
                        guard let doc = self.room.perform(NSSelectorFromString("_debugDoc")).takeUnretainedValue() as? YDoc
                        else { return }
                        let sel = NSSelectorFromString("generateRoomSnapshotFromMaindoc:")
                        if Room.responds(to: sel) {
                            if let snapshot = Room.perform(sel, with: doc).takeUnretainedValue() as? Data {
                                let fileName = "doc-\(self.room.roomId)-\(Date().timeIntervalSince1970).ydoc"
                                let fileUrl = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                                do {
                                    try snapshot.write(to: fileUrl)
                                    print("save doc to", fileUrl)
                                } catch {
                                    print("save doc error", error)
                                }
                            }
                            return
                        }
                    }),
                ]

#if SOURCE_INTEGRATION
                docsActions.append(UIAction(title: "Save As Snapshot", handler: { [unowned self] _ in
                    if let data = self.room.snapshot() {
                        UserDefaults.standard.set(data, forKey: "localSnapshot")
                        self.view.makeToast("Snapshot saved to UserDefaults")
                    }
                }))
#endif
                let docsMenu = UIMenu(title: "Doc", children: docsActions)

                let appCrashMenus = UIMenu(title: "JSMemory Crash", image: UIImage(systemName: "exclamationmark.warninglight.fill"), children: self.apps.values.compactMap { app -> UIAction? in
                    if let webView = app.getWebView() {
                        let typeStr = type(of: app).typeIdentifier
                        let sel = NSSelectorFromString("testJsMemoryOverflow")
                        if webView.responds(to: sel) {
                            return UIAction(title: "\(typeStr)-\(app.appId)") { [unowned webView] _ in
                                webView.perform(sel)
                            }
                        }
                    }
                    return nil
                })

                var debugChildren: [UIMenuElement] = [
                    logsMenu,
                    docsMenu,
                    UIAction(title: "Clear KV Cache", handler: { _ in
                        do {
                            try WebExternalKVCache.clear()
                            self.view.makeToast("KV Cache cleared")
                        } catch {
                            print("clear fail", error)
                        }
                    }),
                    UIAction(title: "Web Link", handler: { [unowned self] _ in
                        if self.prepareConfig.useRtm {
                            let str = "http://localhost:5173/#/wb/ios_test_web/\(self.room.roomId)?roomToken=\(self.prepareConfig.roomToken)"
                            UIPasteboard.general.string = str
                            print(str)
                            self.view.makeToast("Web room link copied to clipboard")
                        } else {
                            self.view.makeToast("Not a rtm room")
                        }
                    }),
                ]

#if SOURCE_INTEGRATION
                debugChildren.append(appCrashMenus)
                debugChildren.append(UIAction(title: "Random Network Loss", state: self.monitorNetworkRandomLoss ? .on : .off, handler: { [unowned self] _ in
                    self.monitorNetworkRandomLoss.toggle()
                    self.room.set(key: "randomLoss", value: self.monitorNetworkRandomLoss)
                    self.reloadExampleItems()
                }))
                if #available(iOS 16.4, *) {
                    debugChildren.append(UIAction(title: "Toggle Inspect", state: self.room._debugDoc.context.isInspectable ? .on : .off, handler: { [unowned self] _ in
                        self.room._debugDoc.context.isInspectable.toggle()
                        for app in self.apps {
                            app.value.getWebView()?.isInspectable = self.room._debugDoc.context.isInspectable
                        }
                        self.view.makeToast("Inspect mode: \(self.room._debugDoc.context.isInspectable ? "ON" : "OFF")")
                    }))
                }
#endif
                debugBtn.menu = .init(children: debugChildren)
            }),
            .init(title: "Launch", subMenuAction: { [unowned self] btn in
                let menu = UIMenu(title: "Launch", children: [
                    UIAction(title: "Whiteboard", handler: { _ in
                        self.launchWhiteboard()
                    }),
                ])
                btn.menu = menu
            }),
            .init(title: "Terminal", subMenuAction: { [unowned self] btn in
                let actions = self.apps.values.map { app in
                    let typeStr = type(of: app).typeIdentifier
                    let title = "\(typeStr)-\(app.appId)"
                    let appId = app.appId
                    return UIAction(title: title) { [unowned self] _ in
                        self.room.applicationManager.terminalApp(appId)
                    }
                }
                let menu = UIMenu(title: "Terminal", children: actions)
                btn.menu = menu
            }),
            .init(title: "Writable", status: self.room.isWritable() ? "true" : "false", clickBlock: { [unowned self] _ in
                let i = self.room.isWritable()
                self.room.setWritable(writable: !i, completionHandler: { _ in })
            }),
            .init(title: "Users Writable", subMenuAction: { [unowned self] btn in
                let onlineUsers = room.userManager.idList().compactMap { self.room.userManager.getUser(userId: $0) }.filter(\.online)

                let userMenus = onlineUsers.map { user in
                    let isWritable = self.userWritableStates[user.id] ?? false
                    return UIAction(
                        title: user.nickName + "(\(user.id))" + (user.id == self.room.userId ? "(Self)" : ""),
                        state: isWritable ? .on : .off
                    ) { [unowned self] _ in
                        let newWritableState = !isWritable
                        self.room.setWritable(userId: user.id, writable: newWritableState, completionHandler: { result in
                            switch result {
                            case .success:
                                print("Successfully set user \(user.id) writable state to: \(newWritableState)")
                                self.view.makeToast("Set \(user.nickName) writable: \(newWritableState)")
                                // Reload menu
                                self.reloadExampleItems()
                            case .failure(let error):
                                print("Failed to set user writable state: \(error)")
                                self.view.makeToast("Set failed: \(error.localizedDescription)")
                            }
                        })
                    }
                }

                let menu = UIMenu(title: "User Writable Control", children: userMenus)
                btn.menu = menu
            })
        ]

        if responds(to: NSSelectorFromString("tempCommands")) {
            let tempCommands = perform(NSSelectorFromString("tempCommands"))!.takeUnretainedValue() as! [ExampleItem]
            items.append(contentsOf: tempCommands)
        }

        exampleItems = items
    }
}

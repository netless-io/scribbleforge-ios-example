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
            .init(title: "Debugs", subMenuAction: { [unowned self] btn in
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
                let docsMenu = UIMenu(title: "Doc", children: [
                    UIAction(title: "Save doc", handler: { [unowned self] _ in
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
                ])

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

                btn.menu = .init(children: [
                    logsMenu,
                    docsMenu,
                    appCrashMenus,
                    UIAction(title: "Random Network Loss", state: self.randomLoss ? .on : .off, handler: { [unowned self] _ in
                        self.randomLoss.toggle()
                        self.room.set(key: "randomLoss", value: self.randomLoss)
                        self.reloadExampleItems()
                    }),
                    UIAction(title: "Clear KV Cache", handler: { _ in
                        do {
                            try WebExternalKVCache.clear()
                        } catch {
                            print("clear fail", error)
                        }
                    }),
                    UIAction(title: "Web SameRoom Link", handler: { [unowned self] _ in
                        if self.prepareConfig.useRtm {
                            let str = "http://localhost:5173/#/wb/ios_test_web/\(self.room.roomId)?roomToken=\(self.prepareConfig.roomToken)"
                            UIPasteboard.general.string = str
                            print(str)
                        } else {
                            self.view.makeToast("Not a rtm room")
                        }
                    }),
                ])
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
                    return UIAction(title: title) { _ in
                        self.room.applicationManager.terminalApp(app.appId)
                    }
                }
                let menu = UIMenu(title: "Terminal", children: actions)
                btn.menu = menu
            }),
//            .init(title: "Save as default", clickBlock: { [unowned self] _ in
//                if let data = self.room.snapshot() {
//                    UserDefaults.standard.set(data, forKey: "localSnapshot")
//                }
//            }),
            .init(title: "Hide Menu", clickBlock: { [unowned self] _ in
                self.hideMenu.toggle()
            }),
        ]

        if responds(to: NSSelectorFromString("tempCommands")) {
            let tempCommands = perform(NSSelectorFromString("tempCommands"))!.takeUnretainedValue() as! [ExampleItem]
            items.append(contentsOf: tempCommands)
        }

        exampleItems = items
    }
}

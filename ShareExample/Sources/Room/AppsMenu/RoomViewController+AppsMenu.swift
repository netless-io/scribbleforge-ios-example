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
        if app is MediaPlayer {
            menuButton.addTarget(self, action: #selector(setupMediaPlayer), for: .menuActionTriggered)
            setupMediaPlayer(menuButton)
        }
    }
    
    @objc
    func reloadApp(_ sender: UIButton) {
        let app = apps[sender.tag]!
        if let webView = app.getWebView() {
            webView.reload()
        }
    }
}

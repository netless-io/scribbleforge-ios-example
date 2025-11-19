//
//  MediaPlayerMenu.swift
//  S11E-Pod
//
//  Created by vince on 2025/7/31.
//

import Foundation
import UIKit
import ScribbleForge

extension RoomViewController {
    @objc
    func setupMediaPlayer(_ menuButton: UIButton) {
        let player = apps[menuButton.tag] as! MediaPlayer
        menuButton.menu = .init(children: [
            UIAction(title: "Play", handler: { [unowned player] _ in
                player.play()
            }),
            UIAction(title: "Pause", handler: { [unowned player] _ in
                player.pause()
            }),
            UIAction(title: "CurrentTime", handler: { [unowned player, unowned self] _ in
                self.view.makeToast(player.currentTime.description)
            }),
            UIAction(title: "Duration", handler: { [unowned player, unowned self] _ in
                self.view.makeToast("Duration: \(player.duration.description)")
            }),
//            UIAction(title: "Mute", handler: { [unowned player, unowned self] _ in
//                player.muted { m in
//                    self.view.makeToast("Muted: \(m)")
//                }
//            }),
            UIAction(title: "Seek", handler: { [unowned player, unowned self] _ in
                player.seek(time: 3)
                self.view.makeToast("Seek to 3")
            }),
        ])
    }
}

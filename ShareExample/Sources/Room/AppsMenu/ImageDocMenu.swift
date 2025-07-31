//
//  ImageDocMenu.swift
//  S11E-Pod
//
//  Created by vince on 2025/7/31.
//

import Foundation
import UIKit
import ScribbleForge

extension RoomViewController {
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
}

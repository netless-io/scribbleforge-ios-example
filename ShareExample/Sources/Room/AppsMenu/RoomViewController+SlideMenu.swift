//
//  SlideMenu.swift
//  S11E-Pod
//
//  Created by vince on 2025/7/31.
//

import Foundation
import UIKit
import ScribbleForge

extension RoomViewController {
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

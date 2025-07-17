import Foundation
import ScribbleForge

extension RoomViewController: ImageDocDelegate {
    func imageDoc(_: ScribbleForge.ImageDoc, didPermissionUpdate permission: ScribbleForge.ImageDocPermission, userId: String) {
        print("[image doc delegate]", #function, permission, userId)
    }

    func imageDoc(_: ImageDoc, didChangePageIndex pageInt: Int) {
        print("[image doc delegate]", #function, pageInt)
    }
}

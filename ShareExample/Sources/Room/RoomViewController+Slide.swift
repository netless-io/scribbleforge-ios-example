import Foundation
import ScribbleForge

extension RoomViewController: SlideDelegate {
    func slidePermissionChange(_: Slide, userId: String, permission: SlidePermission) {
        print("[slide delegate]", #function, userId, permission)
    }

    func slideRenderStart(_: Slide, index: Int) {
        print("[slide delegate]", #function, index)
    }

    func slideRenderEnd(_: Slide, index: Int) {
        print("[slide delegate]", #function, index)
    }

    func slideMainSeqStepStart(_: Slide, index: Int) {
        print("[slide delegate]", #function, index)
    }

    func slideMainSeqStepEnd(_: Slide, index: Int) {
        print("[slide delegate]", #function, index)
    }
}

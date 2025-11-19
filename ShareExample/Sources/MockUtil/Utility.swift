import Foundation
import ScribbleForge

let roomId = "test-room"
let userId = "test-user"
let appId = "test-app"

func roomChannelId(roomId: String) -> String {
    "r_\(roomId)"
}

func userChannelId(roomId: String, _ userId: String) -> String {
    "\(roomChannelId(roomId: roomId))_u_\(userId)"
}

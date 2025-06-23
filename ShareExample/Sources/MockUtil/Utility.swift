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

func createDefaultRoom(
    userId: String = userId,
    nickName: String = "nick-name",
    networkProvider: NetworkProvider = TestProvider(userId: userId),
    mergeBufferCount: Int = 6,
    allowMultiRoom: Bool = true
) -> Room {
    let room = Room(
        roomId: roomId,
        userId: userId,
        nickName: nickName,
        snapshotFetcher: MockSnapshotFetcher(),
        uploaderExecutor: MockExecutor(type: .success),
        remoteLogger: nil,
        networkProvider: networkProvider,
        mergeBufferCount: mergeBufferCount
    )
    room.set(key: "allowMultiRoom", value: allowMultiRoom)
    return room
}

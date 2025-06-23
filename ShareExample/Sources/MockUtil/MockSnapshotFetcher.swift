import ScribbleForge
import Foundation

struct MockSnapshotFetcher: SnapshotFetcher {
    func getSnapshot(roomId: String, completionHandler: @escaping ((Result<Data, any Error>) -> Void)) {
        completionHandler(.success(.init()))
    }
}

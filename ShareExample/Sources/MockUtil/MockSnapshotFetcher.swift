import ScribbleForge
import Foundation

struct MockSnapshotFetcher: SnapshotFetcher {
    func getSnapshot(roomId: String, completionHandler: @escaping (Result<ScribbleForge.SnapshotResult, any Error>) -> Void) {
        if let data {
            completionHandler(.success(.init(data: data, timestamp: Date())))
        } else {
            completionHandler(.failure(NSError(domain: "MockSnapshotFetcher", code: 404, userInfo: [NSLocalizedDescriptionKey: "No snapshot data available"])))
        }
    }
    
    internal init(data: Data? = nil) {
        self.data = data
    }
    
    let data: Data?
}

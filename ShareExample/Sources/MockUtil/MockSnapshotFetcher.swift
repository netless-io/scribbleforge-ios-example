import ScribbleForge
import Foundation

struct MockSnapshotFetcher: SnapshotFetcher {
    internal init(data: Data? = nil) {
        self.data = data
    }
    
    let data: Data?
    func getSnapshot(roomId: String, completionHandler: @escaping ((Result<Data, any Error>) -> Void)) {
        if let data {
            completionHandler(.success(data))
        } else {
            completionHandler(.failure(NSError(domain: "MockSnapshotFetcher", code: 404, userInfo: [NSLocalizedDescriptionKey: "No snapshot data available"])))
        }
    }
}

import ScribbleForge
import Foundation

class MockExecutor: UploaderExecutor {
    internal init(type: MockExecutor.MockType) {
        self.type = type
    }
    
    enum MockType {
        case success
        case fail
    }
    let type: MockType
    var uploadHistoryExecuteTime = 0
    var uploadSnapshotExecuteTime = 0
    var listener: ((Result<Void, any Error>) -> Void)?
    
    func upload(snapshot: Data, completionHandler: @escaping ((Result<Void, any Error>) -> Void)) {
        uploadSnapshotExecuteTime += 1
        switch type {
        case .success:
            completionHandler(.success(()))
            self.listener?(.success(()))
        case .fail:
            completionHandler(.failure(NSError(domain: "test", code: 0)))
            self.listener?(.failure(NSError(domain: "test", code: 0)))
        }
    }
    
    func upload(historyData: Data, completionHandler: @escaping ((Result<Void, any Error>) -> Void)) {
        uploadHistoryExecuteTime += 1
        switch type {
        case .success:
            completionHandler(.success(()))
            self.listener?(.success(()))
        case .fail:
            completionHandler(.failure(NSError(domain: "test", code: 0)))
            self.listener?(.failure(NSError(domain: "test", code: 0)))
        }
    }
}

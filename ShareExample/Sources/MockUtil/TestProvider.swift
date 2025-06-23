import ScribbleForge
import Foundation

class TestProvider: NetworkProvider {
    var randomOrder = false
    func manualTriggerNetworkIsConnectedForSomeSpecialProduct() {
        
    }
    
    func networkProviderInitialize(completionHandler: @escaping (Result<Void, any Error>) -> Void) {
        // 模拟登录成功。
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.mockStatusUpdate(.connected)
            completionHandler(.success(()))
        }
    }
    
    func removeMessageListener(channelId: String) {
        listeners.removeValue(forKey: channelId)
    }
    
    func removeNetworkStatusListeners() {
        networkListeners.removeAll()
    }
    
    func addUserJoinListener(_ listener: @escaping ((String) -> Void)) {
    }
    
    func addUserLeaveListener(_ listener: @escaping ((String) -> Void)) {
    }
    
    func getUsersSnapshot(_ completionHandler: @escaping ((Result<[String], any Error>) -> Void)) {
        completionHandler(.success([]))
    }
    
    func addNetworkStatusListener(_ listener: @escaping ((ScribbleForge.NetworkConnectionState, [String : Any]) -> Void)) {
        networkListeners.append(listener)
    }
    
    func unsubscribe(channelId: String) {
        listeners.removeValue(forKey: channelId)
    }
    
    func networkProviderClose() {
        mockStatusUpdate(.disconnected)
    }
    
    internal init(userId: String) {
        self.userId = userId
    }
    
    struct Model {
        let id: String
        let msg: String
        let type: String
    }
    
    struct DataModel {
        let id: String
        let msg: Data
        let type: String
    }
    
    let userId: String

    var mockSubscribeFail = false
    var networkListeners: [((ScribbleForge.NetworkConnectionState, [String : Any]) -> Void)] = []
    var listeners: [String: [(NetworkMessage) ->Void]] = [:]
    
    func mockStatusUpdate(_ state: NetworkConnectionState) {
        networkListeners.forEach {
            $0(state, ["reason": "mocked"])
        }
    }
    
    func mockingReceive(_ model: DataModel, publisher: String, channel: String, proxys: Set<String> = .init()) {
        listeners[channel]?.forEach { lisener in
            func send() {
//                print("Provider user: \(self.userId) mock receive from user: \(publisher) channel: \(channel)")
                let m = NetworkMessage(publisher: publisher, customType: model.type, data: model.msg, message: nil)
                lisener(m)
            }
            if randomOrder {
                let delay = Double.random(in: 0.1...0.2)
//                print("making delay", delay)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    send()
                }
            } else {
                send()
            }
        }
        connected
            .filter { $0.userId != publisher && !proxys.contains($0.userId) }
            .forEach {
                var proxys = proxys
                proxys.insert(userId)
//                print("Provider user: \(self.userId) channel: \(channel) spread msg to proxy: \(proxys)")
                $0.mockingReceive(model, publisher: publisher, channel: channel, proxys: proxys)
            }
    }
    
    func mockingReceive(_ model: Model, publisher: String, channel: String, proxys: Set<String> = .init()) {
        listeners[channel]?.forEach { lisener in
            let m = NetworkMessage(publisher: publisher, customType: model.type, data: nil, message: model.msg)
            lisener(m)
        }
        connected
            .filter { $0.userId != publisher && !proxys.contains($0.userId) }
            .forEach {
//                print(userId, "spread message to", $0.userId)
                var proxys = proxys
                proxys.insert(userId)
                $0.mockingReceive(model, publisher: publisher, channel: channel, proxys: proxys)
            }
    }

    var connected: [TestProvider] = []
    
    func connect(_ provider: TestProvider) {
        connected.append(provider)
    }
    
    // MARK: - Protocol
    func publish(channelId: String, message: String, messageType: String, completionHandler: @escaping (Result<Void, any Error>) -> Void) {
        DispatchQueue.global().async {
//            print("test start send data.", Thread.current)
            let model = Model(id: channelId, msg: message, type: messageType)
            self.mockingReceive(model, publisher: self.userId, channel: channelId)
            completionHandler(.success(()))
        }
    }
    
    func publish(channelId: String, data: Data, messageType: String, completionHandler: @escaping (Result<Void, any Error>) -> Void) {
        DispatchQueue.global().async {
//            print("test start send data.", Thread.current)
            let model = DataModel(id: channelId, msg: data, type: messageType)
            self.mockingReceive(model, publisher: self.userId, channel: channelId)
            completionHandler(.success(()))
        }
    }
    
    func subscribe(mainPresence: Bool, channelId _: String, completionHandler: @escaping (Result<Void, any Error>) -> Void) {
        if mockSubscribeFail {
            completionHandler(.failure(NSError(domain: "mock", code: 0, userInfo: nil)))
        } else {
            completionHandler(.success(()))
        }
    }

    func addMessageListener(channelId: String, _ item: @escaping ((ScribbleForge.NetworkMessage) -> Void)) {
        var i = listeners[channelId] ?? []
        i.append(item)
        listeners[channelId] = i
    }
}

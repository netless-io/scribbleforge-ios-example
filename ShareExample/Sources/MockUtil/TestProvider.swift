import Foundation
import ScribbleForge

class TestProvider: NetworkProvider, WritableProvider {
    func addWritableStateListener(_ listener: @escaping (([String: Bool]) -> Void)) {
        writableListeners.append(listener)
    }
    
    func removeWritableStateListeners() {
        writableListeners.removeAll()
    }
    
    func setupMainChannelId(_ channelId: String) {}
    
    func addRemoteTimeListener(_ listener: @escaping (Date) -> Void) {}
    
    func removeRemoteTimeListener() {}

    var randomOrder = false
    func manualTriggerNetworkIsConnectedForSomeSpecialProduct() {}
    
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
    
    var userJoinListeners: [(String) -> Void] = []
    func addUserJoinListener(_ listener: @escaping ((String) -> Void)) {
        listener(userId)
        userJoinListeners.append(listener)
    }
    
    var userLeaveListeners: [(String) -> Void] = []
    func addUserLeaveListener(_ listener: @escaping ((String) -> Void)) {
        userLeaveListeners.append(listener)
    }
    
    func getUsersSnapshot(_ completionHandler: @escaping ((Result<[String], any Error>) -> Void)) {
        completionHandler(.success([]))
    }
    
    func addNetworkStatusListener(_ listener: @escaping ((ScribbleForge.NetworkConnectionState, [String: Any]) -> Void)) {
        networkListeners.append(listener)
    }
    
    func unsubscribe(channelId: String) {
        listeners.removeValue(forKey: channelId)
    }
    
    func networkProviderClose() {
        mockStatusUpdate(.disconnected)
    }
    
    init(userId: String) {
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
    private var _writableStateListeners: [([String: Bool]) -> Void] = []
    var writableListeners: [([String: Bool]) -> Void] {
        get { syncQueue.sync { _writableStateListeners } }
        set { syncQueue.async { self._writableStateListeners = newValue } }
    }

    private var _networkListeners: [(ScribbleForge.NetworkConnectionState, [String: Any]) -> Void] = []
    var networkListeners: [(ScribbleForge.NetworkConnectionState, [String: Any]) -> Void] {
        get { syncQueue.sync { _networkListeners } }
        set { syncQueue.sync { _networkListeners = newValue } }
    }

    private var _listeners: [String: [(NetworkMessage) -> Void]] = [:]
    var listeners: [String: [(NetworkMessage) -> Void]] {
        get { syncQueue.sync { _listeners } }
        set { syncQueue.sync { _listeners = newValue } }
    }
    
    func mockStatusUpdate(_ state: NetworkConnectionState) {
        for networkListener in networkListeners {
            networkListener(state, ["reason": "mocked"])
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
                let delay = Double.random(in: 0.1 ... 0.2)
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

    private var _connected: [TestProvider] = []
    var connected: [TestProvider] {
        get { syncQueue.sync { _connected } }
        set { syncQueue.sync { _connected = newValue } }
    }

    private var _writableState: [String: Bool] = [:]
    var writableStates: [String: Bool] {
        get { syncQueue.sync { _writableState } }
        set {
            syncQueue.sync {
                _writableState = newValue
            }
            self.writableListeners.forEach { $0(newValue) }
        }
    }
    
    func connect(_ provider: TestProvider) {
        connected.append(provider)
    }
    
    func removeConnected() {
        connected.removeAll()
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
    
    let syncQueue = DispatchQueue(label: "TestProviderQueue", qos: .userInitiated)
    func publish(channelId: String, data: Data, messageType: String, completionHandler: @escaping (Result<Void, any Error>) -> Void) {
//            print("test start send data.", Thread.current)
        let model = DataModel(id: channelId, msg: data, type: messageType)
        mockingReceive(model, publisher: userId, channel: channelId)
        completionHandler(.success(()))
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

    // MARK: - PersistenceProvider

    var mockSetWritableStateError = false

    func setWritable(userId: String, writable: Bool, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().async {
            if self.mockSetWritableStateError {
                completion(NSError(domain: "TestError", code: 1, userInfo: nil))
                return
            }

            self.writableStates[userId] = writable

            // 同步到其他 connected providers
            for provider in self.connected {
                provider.writableStates[userId] = writable
            }

            completion(nil)
        }
    }

    func getWritableStates(completion: @escaping (Result<[String: Bool], Error>) -> Void) {
        DispatchQueue.global().async {
            completion(.success(self.writableStates))
        }
    }
}

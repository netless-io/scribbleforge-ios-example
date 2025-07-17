import UIKit
import SnapKit
import ScribbleForge

class StatusView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        layer.cornerRadius = 8
        layer.masksToBounds = true
        
        let stacks = UIStackView(arrangedSubviews: [
            statusLabel,
            dependenciesLabel,
            UIView()
        ])
        stacks.axis = .vertical
        addSubview(stacks)
        stacks.spacing = 4
        stacks.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
    }
    
    lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.text = "Connecting..."
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    lazy var dependenciesLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.font = .systemFont(ofSize: 8, weight: .medium)
        label.textColor = .white
        label.text = ""
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    func updateConnectionState(_ state: String) {
        statusLabel.text = state
    }
    
    func updateConnectionState(_ state: NetworkConnectionState) {
        let networkText = "Network: \(state)"
        let currentText = statusLabel.text ?? ""
        
        if currentText.contains("Network:") {
            let components = currentText.components(separatedBy: "\n")
            var newComponents = components.filter { !$0.contains("Network:") }
            newComponents.insert(networkText, at: 0)
            statusLabel.text = newComponents.joined(separator: "\n")
        } else {
            statusLabel.text = networkText
        }
        
        switch state {
        case .connected:
            statusLabel.backgroundColor = .green.withAlphaComponent(0.7)
        case .connecting, .reconnecting:
            statusLabel.backgroundColor = .yellow.withAlphaComponent(0.7)
        default:
            statusLabel.backgroundColor = .red.withAlphaComponent(0.7)
        }
    }
    
    func updateDependencies(_ dependencies: [(key: String, value: String)]) {
        let depsText: String = dependencies.reduce(into: "Deps: \n") { partialResult, next in
            let w = "\n\(next.key): \n\(next.value)\n"
            partialResult += w
        }
        
        dependenciesLabel.text = depsText
    }
}

extension NetworkConnectionState: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected"
        case .reconnecting:
            return "Reconnecting..."
        case .failed:
            return "Connection Failed"
        }
    }
}

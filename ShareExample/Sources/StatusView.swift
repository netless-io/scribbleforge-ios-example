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
            UIView()
        ])
        stacks.axis = .vertical
        addSubview(stacks)
        stacks.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
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
    
    func updateConnectionState(_ state: String) {
        statusLabel.text = state
    }
    
    func updateConnectionState(_ state: NetworkConnectionState) {
        statusLabel.text = "Network: \(state)"
        switch state {
        case .connected:
            statusLabel.backgroundColor = .green.withAlphaComponent(0.7)
        case .connecting, .reconnecting:
            statusLabel.backgroundColor = .yellow.withAlphaComponent(0.7)
        default:
            statusLabel.backgroundColor = .red.withAlphaComponent(0.7)
        }
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

import UIKit

class FloatMenuView: UIView {
    // MARK: - Properties
    private var anchorView: UIView?
    private let blurEffect = UIBlurEffect(style: .systemThinMaterial)
    private lazy var blurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: blurEffect)
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        addSubview(blurView)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Public Methods
    func show(anchoredTo view: UIView) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        self.anchorView = view
        window.addSubview(self)
        
        // Convert anchor view frame to window coordinates
        let anchorFrame = view.convert(view.bounds, to: window)
        
        // Position the float menu above the anchor view
        frame = CGRect(
            x: anchorFrame.minX,
            y: anchorFrame.minY - frame.height - 8,
            width: frame.width,
            height: frame.height
        )
        
        // Add fade in animation
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
    }
    
    func dismiss() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { _ in
            self.anchorView = nil
            self.removeFromSuperview()
            self.transform = .identity
        }
    }
}

// 帮我完成这个基类。这个基类希望完成：
// 1. 这个 view 可以浮在 window 上。
// 2. 可以指定一个 view 作为锚点。
// 3. 毛玻璃背景，圆角。

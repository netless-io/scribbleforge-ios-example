import UIKit

class UndoRedoView: BlurBackgroundView {
    var undoHandler: (() -> Void)?
    var redoHandler: (() -> Void)?
    
    private var undoButton: UIButton!
    private var redoButton: UIButton!
    override var intrinsicContentSize: CGSize {
        CGSize(width: 44 * 2 + 8 * 2, height: 44)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButtons()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButtons()
    }

    private func setupButtons() {
        // Create undo button
        undoButton = createButton(imageName: "arrow.uturn.backward")
        undoButton.addTarget(self, action: #selector(undoButtonTapped), for: .touchUpInside)
        addArrangedSubview(undoButton)
        
        // Create redo button
        redoButton = createButton(imageName: "arrow.uturn.forward")
        redoButton.addTarget(self, action: #selector(redoButtonTapped), for: .touchUpInside)
        addArrangedSubview(redoButton)
    }
    
    private func createButton(imageName: String) -> UIButton {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
        button.tintColor = UIColor(white: 0.2, alpha: 0.9)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
        
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        return button
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
        }
    }
    
    @objc private func undoButtonTapped() {
        scrollToView(undoButton)
        undoHandler?()
    }
    
    @objc private func redoButtonTapped() {
        scrollToView(redoButton)
        redoHandler?()
    }
    
    var undoRedoPermission: Bool = false {
        didSet {
            syncUI()
        }
    }
    var undoStep = 0 {
        didSet {
            syncUI()
        }
    }
    var redoStep = 0 {
        didSet {
            syncUI()
        }
    }
    
    func syncUI() {
        let canUndo = undoStep > 0 && undoRedoPermission
        undoButton.alpha = canUndo ? 1.0 : 0.3
        undoButton.isEnabled = canUndo
        
        let canRedo = redoStep > 0 && undoRedoPermission
        redoButton.alpha = canRedo ? 1.0 : 0.3
        redoButton.isEnabled = canRedo
    }
}

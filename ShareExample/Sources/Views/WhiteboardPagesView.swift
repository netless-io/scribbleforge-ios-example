import UIKit

class WhiteboardPagesView: BlurBackgroundView {
    var prevHandler: (() -> Void)?
    var nextHandler: (() -> Void)?
    var addHandler: (() -> Void)?
    var removeHandler: (() -> Void)?
    
    private var prevButton: UIButton!
    private var nextButton: UIButton!
    private var addButton: UIButton!
    private var removeButton: UIButton!
    private var pageLabel: UILabel!
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: (44 * 4) + 32 + (self.margin * 2), height: 44)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        // Remove button
        removeButton = createButton(imageName: "minus")
        removeButton.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
        addArrangedSubview(removeButton)
        
        // Previous button
        prevButton = createButton(imageName: "chevron.backward") 
        prevButton.addTarget(self, action: #selector(prevButtonTapped), for: .touchUpInside)
        addArrangedSubview(prevButton)
        
        // Page label
        pageLabel = UILabel()
        pageLabel.text = "1/1"
        pageLabel.textColor = UIColor(white: 0, alpha: 0.9)
        pageLabel.textAlignment = .center
        pageLabel.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        pageLabel.widthAnchor.constraint(equalToConstant: 32).isActive = true
        addArrangedSubview(pageLabel)
        
        // Next button
        nextButton = createButton(imageName: "chevron.forward")
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        addArrangedSubview(nextButton)
        
        // Add button
        addButton = createButton(imageName: "plus")
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addArrangedSubview(addButton)
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
    
    @objc private func prevButtonTapped() {
        scrollToView(prevButton)
        prevHandler?()
    }
    
    @objc private func nextButtonTapped() {
        scrollToView(nextButton)
        nextHandler?()
    }
    
    @objc private func addButtonTapped() {
        scrollToView(addButton)
        addHandler?()
    }
    
    @objc private func removeButtonTapped() {
        scrollToView(removeButton)
        removeHandler?()
    }
    
    func updatePageLabel(current: Int, total: Int) {
        self.currentPage = current
        self.totalPage = total
        syncUI()
    }

    private var totalPage: Int = 0
    private var currentPage: Int = 0
    var permissionEnable = false {
        didSet {
            syncUI()
        }
    }
    
    func syncUI() {
        pageLabel.text = "\(currentPage + 1)/\(totalPage)"
        
        let canPrev = permissionEnable && currentPage > 0
        prevButton.alpha = canPrev ? 1.0 : 0.3
        prevButton.isEnabled = canPrev
        
        let canNext = permissionEnable && currentPage < totalPage - 1
        nextButton.alpha = canNext ? 1.0 : 0.3
        nextButton.isEnabled = canNext
        
        addButton.alpha = permissionEnable ? 1.0 : 0.3
        addButton.isEnabled = permissionEnable
        
        removeButton.alpha = permissionEnable && totalPage > 1 ? 1.0 : 0.3
        removeButton.isEnabled = permissionEnable && totalPage > 1
    }
}

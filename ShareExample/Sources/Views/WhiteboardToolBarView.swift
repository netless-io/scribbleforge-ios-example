import UIKit
import ScribbleForge

class WhiteboardToolBarView: BlurBackgroundView {
    private var buttons: [UIButton] = []

    var toolClickHandler: ((WhiteboardToolType) -> Void)?
    var strokeColorClickHandler: ((UIColor) -> Void)?
    var strokeWidthClickHandler: ((Float) -> Void)?
    var fillColorClickHandler: ((UIColor) -> Void)?
    var textSizeClickHandler: ((Float) -> Void)?
    var cleanClickHandler: (() -> Void)?
    var strokeStyleClickHandler: (([Float]) -> Void)?

    var operationEnable: Bool = false {
        didSet {
            syncUI()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        syncUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        syncUI()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 44 * CGFloat(types.count) + margin * 2, height: 44)
    }
    
    private func syncUI() {
        types.enumerated().forEach { (index, toolType) in
            let button = buttons[index]
            
            if self.toolType == toolType {
                UIView.animate(withDuration: 0.2) {
                    button.tintColor = .systemBlue.withAlphaComponent(0.9)
                }
            } else {
                button.tintColor = UIColor(white: 0.6, alpha: 0.9)
            }
        }
        
        buttons.forEach { $0.isEnabled = operationEnable }
    }

    var types: [WhiteboardToolType] = [
        .curve,
        .rectangle,
        .selector,
        .eraser,
        .text,
        .laser,
        .grab,
        .pointer
    ]
    
    private func setupUI() {
        types.forEach { toolType in
            let button = UIButton()
            button.setImage(toolType.image, for: .normal)
            button.tintColor = UIColor(white: 0.6, alpha: 0.9)
            button.layer.cornerRadius = 8
            button.clipsToBounds = true
            button.tag = buttons.count
            
            button.addScaleAnimation()
            button.addTarget(self, action: #selector(toolButtonTapped(_:)), for: .touchUpInside)
            
            button.widthAnchor.constraint(equalToConstant: 44).isActive = true
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            
            buttons.append(button)
            addArrangedSubview(button)
        }
    }
    
    @objc private func toolButtonTapped(_ sender: UIButton) {
        let toolType = types[sender.tag]
        
        triggerSubMenu(toolType: toolType, sender: sender)
        
        toolClickHandler?(toolType)
    }
    
    func triggerSubMenu(toolType: WhiteboardToolType, sender: UIButton) {
        let clickSame = toolType == self.toolType
        let subMenuShow = subMenuView.superview != nil
        let containSubMenu = toolType.containsSubMenu
        
        func show() {
            // Show.
            subMenuView.update(
                toolsHide: !toolType.isShape,
                strokeWidthHide: !toolType.containStrokeWidth,
                strokeColorHide: !toolType.containStrokeColor,
                textSizeHide: !toolType.containTextSize,
                fillColorHide: !toolType.isShape,
                cleanHide: !toolType.containClean,
                strokeStyleHide: !toolType.isShape
            )
            subMenuView.show(anchoredTo: sender)
        }
        switch (clickSame, subMenuShow, containSubMenu) {
        case (_, _, false):
            subMenuView.dismiss()
        case (true, _, _):
            if subMenuShow {
                subMenuView.dismiss()
            } else {
                show()
            }
        case (false, _, _):
            if subMenuShow {
                show()
            } else {
                // break
            }
        }
    }
    
    fileprivate var strokeColor: UIColor?
    fileprivate var fillColor: UIColor?
    fileprivate var toolType: WhiteboardToolType?
    
    lazy var subMenuView: SubMenuView = {
        let view = SubMenuView()
        view.toolTapHandler = { [weak self] toolType in
            self?.toolClickHandler?(toolType)
        }
        view.strokeColorTapHandler = { [weak self] color in
            self?.strokeColorClickHandler?(color)
        }
        view.strokeWidthTapHandler = { [weak self] strokeWidth in
            self?.strokeWidthClickHandler?(strokeWidth)
        }
        view.fillColorTapHandler = { [weak self] color in
            self?.fillColorClickHandler?(color)
        }
        view.textSizeTapHandler = { [weak self] textSize in
            self?.textSizeClickHandler?(textSize)
        }
        view.cleanTapHandler = { [weak self] in
            self?.cleanClickHandler?()
        }
        view.strokeStyleTapHandler = { [weak self] strokeStyle in
            self?.strokeStyleClickHandler?(strokeStyle)
        }
        
        return view
    }()

    func syncCurrentTool(toolType: WhiteboardToolType?, strokeColor: UIColor?, fillColor: UIColor?, strokeWidth: Float, textSize: Float?, dash: [Float]?) {
        guard let toolType else { return }
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.toolType = toolType
        
        subMenuView.strokeColor = strokeColor
        subMenuView.fillColor = fillColor
        subMenuView.strokeWidth = strokeWidth
        subMenuView.toolType = toolType
        subMenuView.textSize = textSize
        subMenuView.dash = dash
        
        if toolType.isShape {
            if let i = types.firstIndex(where: { $0.isShape }) {
                types[i] = toolType
                buttons[i].setImage(toolType.image, for: .normal)
            }
        }
        
        syncUI()
        subMenuView.syncUI()
        guard let index = types.firstIndex(of: toolType) else { return }
        scrollToView(buttons[index], animated: true)
    }
}


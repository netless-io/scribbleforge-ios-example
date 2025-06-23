import ScribbleForge
import UIKit

class SubMenuView: FloatMenuView {
    let toolTypeOptions: [WhiteboardToolType] = [.ellipse, .rectangle, .triangle, .line, .arrow]
    let strokeWidthOptions: [Float] = [1, 4, 6, 8]
    let textSizeOptions: [Float] = [14, 24, 32, 64]
    let strokeColorOptions: [UIColor] = [
        .blue,
        .red,
        .orange,
        .init(hex: "#000000")
    ]
    let fillColorOptions: [UIColor] = [
        .blue,
        .red,
        .orange,
        .init(hex: "#000000")
    ]
    let dashOptions: [[Float]] = [[], [8, 8], [4, 4]]

    var toolTapHandler: ((WhiteboardToolType) -> Void)?
    var strokeColorTapHandler: ((UIColor) -> Void)?
    var fillColorTapHandler: ((UIColor) -> Void)?
    var strokeWidthTapHandler: ((Float) -> Void)?
    var textSizeTapHandler: ((Float) -> Void)?
    var cleanTapHandler: (() -> Void)?
    var strokeStyleTapHandler: (([Float]) -> Void)?

    var toolType: WhiteboardToolType?
    var strokeColor: UIColor?
    var fillColor: UIColor?
    var strokeWidth: Float?
    var textSize: Float?
    var dash: [Float]?

    let columnCount = CGFloat(4)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func syncUI() {
        for toolButton in toolButtons {
            let toolType = toolTypeOptions[toolButton.tag]
            let isSelected = toolType == self.toolType
            if isSelected {
                UIView.animate(withDuration: 0.2) {
                    toolButton.tintColor = UIColor.systemBlue.withAlphaComponent(0.9)
                }
            } else {
                toolButton.tintColor = UIColor(white: 0.6, alpha: 0.9)
            }
        }

        for strokeColorButton in strokeColorButtons {
            let color = strokeColorOptions[strokeColorButton.tag]
            if color.almostSame(as: strokeColor) {
                let selectedImage = UIImage.createCircleWithCustomRingImage(
                    color: color,
                    size: .init(width: 26, height: 26),
                    circleRadius: 4,
                    ringRadius: 12
                )
                strokeColorButton.setImage(selectedImage, for: .normal)
            } else {
                let normalImage = UIImage.createCircleImage(
                    color: color,
                    size: .init(width: 8, height: 8)
                )
                strokeColorButton.setImage(normalImage, for: .normal)
            }
        }

        for strokeWidthButton in strokeWidthButtons {
            let buttonStrokeWidth = strokeWidthOptions[strokeWidthButton.tag]
            let w = CGFloat(buttonStrokeWidth) * 1.5
            if buttonStrokeWidth == strokeWidth {
                let selectedImage = UIImage.createCircleWithCustomRingImage(
                    color: .black,
                    size: .init(width: 26, height: 26),
                    circleRadius: w / 2,
                    ringRadius: 12
                )
                strokeWidthButton.setImage(selectedImage, for: .normal)
            } else {
                let image = UIImage.createCircleImage(color: .black, size: .init(width: w, height: w))
                strokeWidthButton.setImage(image, for: .normal)
            }
        }

        for fillColorButton in fillColorButtons {
            let color = fillColorOptions[fillColorButton.tag]
            if color.almostSame(as: fillColor) {
                let image = UIImage.createRectangleWithBorderImage(color: color, size: .init(width: 26, height: 26), rectSize: .init(width: 14, height: 14), borderWidth: 2)
                fillColorButton.setImage(image, for: .normal)
            } else {
                let image = UIImage.createRectangleImage(color: color, size: .init(width: 14, height: 14))
                fillColorButton.setImage(image, for: .normal)
            }
        }

        for textSizeButton in textSizeButtons {
            let size = textSizeOptions[textSizeButton.tag]
            let pointSize = CGFloat(textSizeButton.tag) * 6 + 12
            let image = UIImage(systemName: "textformat.size.smaller", withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize, weight: .regular))
            if size == textSize {
                textSizeButton.tintColor = UIColor.systemBlue.withAlphaComponent(0.9)
                textSizeButton.setImage(image, for: .normal)
            } else {
                textSizeButton.tintColor = UIColor(white: 0.6, alpha: 0.9)
                textSizeButton.setImage(image, for: .normal)
            }
        }

        for dashButton in dashButtons {
            let style = dashOptions[dashButton.tag]
            if style == dash {
                dashButton.tintColor = UIColor.systemBlue.withAlphaComponent(0.9)
            } else {
                dashButton.tintColor = UIColor(white: 0.6, alpha: 0.9)
            }
        }
    }

    func update(
        toolsHide: Bool,
        strokeWidthHide: Bool,
        strokeColorHide: Bool,
        textSizeHide: Bool,
        fillColorHide: Bool,
        cleanHide: Bool,
        strokeStyleHide: Bool
    ) {
        let margin = CGFloat(8)
        var startX = margin
        var startY = margin
        let buttonWidth = CGFloat(32)
        let buttonHeight = CGFloat(32)
        let maxX = buttonWidth * columnCount
        subviews.forEach { $0.frame = .zero }

        func arrange(item: UIView) {
            item.frame = CGRect(x: startX, y: startY, width: buttonWidth, height: buttonHeight)
            startX += buttonWidth
            if startX >= maxX {
                startX = margin
                startY += buttonHeight
            }
        }

        func newLine() {
            let maxY = subviews.max(by: { $0.frame.maxY < $1.frame.maxY })?.frame.maxY ?? 0
            let h = 1 / UIScreen.main.scale
            let lineView = UIView(frame: .init(x: margin, y: maxY + 4, width: maxX, height: h))
            lineView.backgroundColor = UIColor(white: 0.9, alpha: 0.9)
            addSubview(lineView)
            
            let maxY1 = subviews.max(by: { $0.frame.maxY < $1.frame.maxY })?.frame.maxY ?? 0
            startX = margin
            startY = maxY1 + 4
        }

        toolButtons.forEach { $0.isHidden = toolsHide }
        if !toolsHide {
            for button in toolButtons {
                arrange(item: button)
            }
            newLine()
        }

        strokeWidthButtons.forEach { $0.isHidden = strokeWidthHide }
        if !strokeWidthHide {
            for button in strokeWidthButtons {
                arrange(item: button)
            }
            newLine()
        }

        textSizeButtons.forEach { $0.isHidden = textSizeHide }
        if !textSizeHide {
            for button in textSizeButtons {
                arrange(item: button)
            }
            newLine()
        }

        strokeColorButtons.forEach { $0.isHidden = strokeColorHide }
        if !strokeColorHide {
            for button in strokeColorButtons {
                arrange(item: button)
            }
            newLine()
        }

        fillColorButtons.forEach { $0.isHidden = fillColorHide }
        if !fillColorHide {
            for button in fillColorButtons {
                arrange(item: button)
            }
            newLine()
        }

        dashButtons.forEach { $0.isHidden = strokeStyleHide }
        if !strokeStyleHide {
            for button in dashButtons {
                arrange(item: button)
            }
            newLine()
        }

        cleanButton.isHidden = cleanHide
        if !cleanHide {
            arrange(item: cleanButton)
        }

        let maxY = subviews.max(by: { $0.frame.maxY < $1.frame.maxY })?.frame.maxY ?? 0
        frame = .init(x: 0, y: 0, width: maxX + margin * 2, height: maxY + margin)
    }

    lazy var toolButtons = toolTypeOptions.map { createToolButton(toolType: $0) }
    lazy var strokeWidthButtons = strokeWidthOptions.map { createStrokeWidthButton(width: $0) }
    lazy var strokeColorButtons = strokeColorOptions.map { createStrokeColorButton(color: $0) }
    lazy var fillColorButtons = fillColorOptions.map { createFillColorButton(color: $0) }
    lazy var textSizeButtons = textSizeOptions.map { createTextSizeButton(size: $0) }
    lazy var dashButtons = dashOptions.map { createDashButton(style: $0) }
    lazy var cleanButton: UIButton = {
        let button = UIButton()
        button.addScaleAnimation()
        button.setImage(UIImage(systemName: "trash"), for: .normal)
        button.tintColor = .systemRed
        button.addTarget(self, action: #selector(cleanButtonTapped(_:)), for: .touchUpInside)
        return button
    }()

    func setupUI() {
        toolButtons.forEach { addSubview($0) }
        dashButtons.forEach { addSubview($0) }
        strokeWidthButtons.forEach { addSubview($0) }
        strokeColorButtons.forEach { addSubview($0) }
        fillColorButtons.forEach { addSubview($0) }
        textSizeButtons.forEach { addSubview($0) }
        addSubview(cleanButton)
    }

    @objc func cleanButtonTapped(_ sender: UIButton) {
        cleanTapHandler?()
    }

    @objc func textSizeButtonTapped(_ sender: UIButton) {
        textSizeTapHandler?(textSizeOptions[sender.tag])
    }

    func createTextSizeButton(size: Float) -> UIButton {
        let button = UIButton()
        button.addScaleAnimation()
        button.tag = textSizeOptions.firstIndex(of: size) ?? 0
        button.addTarget(self, action: #selector(textSizeButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc func fillColorButtonTapped(_ sender: UIButton) {
        fillColorTapHandler?(fillColorOptions[sender.tag])
    }

    func createFillColorButton(color: UIColor) -> UIButton {
        let button = UIButton()
        button.addScaleAnimation()
        button.tag = fillColorOptions.firstIndex(of: color) ?? 0
        button.addTarget(self, action: #selector(fillColorButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc func strokeColorButtonTapped(_ sender: UIButton) {
        strokeColorTapHandler?(strokeColorOptions[sender.tag])
    }

    func createStrokeColorButton(color: UIColor) -> UIButton {
        let button = UIButton()
        button.addScaleAnimation()
        button.tag = strokeColorOptions.firstIndex(of: color) ?? 0
        button.addTarget(self, action: #selector(strokeColorButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc func strokeWidthButtonTapped(_ sender: UIButton) {
        strokeWidthTapHandler?(strokeWidthOptions[sender.tag])
    }

    func createStrokeWidthButton(width: Float) -> UIButton {
        let button = UIButton()
        button.addScaleAnimation()
        button.tag = strokeWidthOptions.firstIndex(of: width) ?? 0
        button.addTarget(self, action: #selector(strokeWidthButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc func strokeStyleButtonTapped(_ sender: UIButton) {
        strokeStyleTapHandler?(dashOptions[sender.tag])
    }

    func createDashButton(style: [Float]) -> UIButton {
        let button = UIButton(type: .system)
        button.addScaleAnimation()
        button.tag = dashOptions.firstIndex(of: style) ?? 0
        let imageWidth = CGFloat(18)
        if style.isEmpty {
            button.setImage(UIImage.createHorizontalLineImage(color: .black, size: .init(width: imageWidth, height: imageWidth)), for: .normal)
        } else {
            let style = style.map { CGFloat($0 / 2) }
            button.setImage(UIImage.createHorizontalDashedLineImage(color: .black, size: .init(width: imageWidth, height: imageWidth), dashPattern: style), for: .normal)
        }
        button.addTarget(self, action: #selector(strokeStyleButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc func toolButtonTapped(_ sender: UIButton) {
        toolTapHandler?(toolTypeOptions[sender.tag])
    }

    func createToolButton(toolType: WhiteboardToolType) -> UIButton {
        let button = UIButton()
        button.addScaleAnimation()
        button.setImage(toolType.image, for: .normal)
        button.addTarget(self, action: #selector(toolButtonTapped(_:)), for: .touchUpInside)
        button.tag = toolTypeOptions.firstIndex(of: toolType) ?? 0
        button.backgroundColor = .clear
        return button
    }
}


import UIKit
import ScribbleForge

class WhiteboardControlView: UIView {
    let pagesView = WhiteboardPagesView()
    let undoRedoView = UndoRedoView()
    let toolBarView = WhiteboardToolBarView()
    
    weak var whiteboard: Whiteboard? {
        didSet {
            setupWhiteboardCallbacks()
            syncWhiteboardState()
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let origin = super.hitTest(point, with: event)
        if origin == self {
            return nil
        }
        return origin
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(pagesView)
        addSubview(undoRedoView)
        addSubview(toolBarView)
        
        pagesView.snp.makeConstraints { make in
            make.centerX.top.equalToSuperview()
        }
        
        toolBarView.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview()
        }
        
        undoRedoView.snp.makeConstraints { make in
            make.right.equalTo(toolBarView.snp.left).offset(-14)
            make.centerY.equalTo(toolBarView)
        }
    }
    
    private func setupWhiteboardCallbacks() {
        pagesView.addHandler = { [weak self] in
            self?.whiteboard?.indexedNavigation.pushPage()
        }
        pagesView.prevHandler = { [weak self] in
            self?.whiteboard?.indexedNavigation.prevPage()
        }
        pagesView.removeHandler = { [weak self] in
            self?.whiteboard?.indexedNavigation.removePage()
        }
        pagesView.nextHandler = { [weak self] in
            self?.whiteboard?.indexedNavigation.nextPage()
        }
        
        undoRedoView.redoHandler = { [weak self] in
            self?.whiteboard?.redo()
        }
        undoRedoView.undoHandler = { [weak self] in
            self?.whiteboard?.undo()
        }
        
        toolBarView.strokeStyleClickHandler = { [weak self] strokeStyle in
            self?.whiteboard?.setDashArray(strokeStyle)
        }
        toolBarView.cleanClickHandler = { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(title: "Clear Whiteboard", message: nil, preferredStyle: .alert)
            alert.addAction(.init(title: "Cancel", style: .cancel))
            alert.addAction(.init(title: "Confirm", style: .default, handler: { _ in
                self.whiteboard?.clean()
            }))
            var top: UIViewController? = self.window?.rootViewController
            
            while let presented = top?.presentedViewController {
                top = presented
            }
            
            top?.present(alert, animated: true)
        }
        toolBarView.textSizeClickHandler = { [weak self] textSize in
            self?.whiteboard?.setFontSize(textSize)
        }
        toolBarView.strokeColorClickHandler = { [weak self] color in
            self?.whiteboard?.setStrokeColor(color)
        }
        toolBarView.toolClickHandler = { [weak self] tool in
            self?.whiteboard?.setCurrentTool(tool)
        }
        toolBarView.fillColorClickHandler = { [weak self] color in
            if color.toHexString() == self?.whiteboard?.fillColor() {
                self?.whiteboard?.setFillColor(.clear)
                return
            }
            self?.whiteboard?.setFillColor(color)
        }
        toolBarView.strokeWidthClickHandler = { [weak self] width in
            self?.whiteboard?.setStrokeWidth(width)
        }
    }
    
    private func syncWhiteboardState() {
        guard let whiteboard = whiteboard else { return }
        
        let strokeColor = whiteboard.strokeColor().map { UIColor(hex: $0) }
        let fillColor = whiteboard.fillColor().map { UIColor(hex: $0) }
        let strokeWidth = whiteboard.strokeWidth() ?? 0
        let textSize = whiteboard.fontSize()
        let tool = whiteboard.currentTool()
        let dash = whiteboard.dashArray()
        
        toolBarView.syncCurrentTool(toolType: tool, strokeColor: strokeColor, fillColor: fillColor, strokeWidth: strokeWidth, textSize: textSize, dash: dash)
        
        whiteboard.indexedNavigation.currentPageIndex { [weak self] current in
            whiteboard.indexedNavigation.pageCount { [weak self] count in
                self?.pagesView.updatePageLabel(current: current, total: count)
            }
        }
        
        let permission = whiteboard.getPermission()
        toolBarView.operationEnable = permission.contains(.draw)
        undoRedoView.undoRedoPermission = permission.contains(.draw)
        pagesView.permissionEnable = permission.contains(.mainView)
    }
}

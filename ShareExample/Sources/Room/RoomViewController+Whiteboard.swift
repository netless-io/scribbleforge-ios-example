import Foundation
import ScribbleForge
import SwiftUI

extension WhiteboardPermission {
    var localizedDescription: String {
        switch self {
        case .draw: "draw"
        case .editSelf: "editSelf"
        case .editOthers: "editOthers"
        case .deleteSelf: "deleteSelf"
        case .deleteOthers: "deleteOthers"
        case .setOthersView: "setOthersView"
        case .mainView: "mainView"
        default:
            "Unknown"
        }
    }
}

extension RoomViewController {
    func launchWhiteboard() {
        if room.applicationManager.apps().contains(where: { $0.appId == "MainWhiteboard" }) {
            return
        }
        room.launchWhiteboard(
            appId: "MainWhiteboard",
            option: .init(
                width: 1920,
                height: 1080,
                maxScaleRatio: -1,
//                defaultToolInfo: .init(tool: .curve, strokeColor: UIColor.blue.toHexString())
            )
        ) { r in
            switch r {
            case .success:
                print("Launch whiteboard success")
            case .failure:
                print("Launch whiteboard failed")
            }
        }
    }
    
    func setupWhitebard(_ wb: Whiteboard) {
        guard let applicationView = wb.applicationView else { return }
        wb.delegate = self
        roomStageContainer.addSubview(applicationView)
        roomStageContainer.sendSubviewToBack(applicationView)
        applicationView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        applicationView.addSubview(whiteboardControlView)
        whiteboardControlView.whiteboard = wb
        whiteboardControlView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func setUserPage(_ userId: String) {
        let alert = UIAlertController(title: "SetUserPage(\(userId))", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.keyboardType = .numberPad
        }
        alert.addAction(.init(title: "Cancel", style: .cancel))
        alert.addAction(.init(title: "Confirm", style: .default, handler: { _ in
            guard let text = alert.textFields?.first?.text,
            let page = Int(text) else { return }
            self.whiteboard?.setFreeModeUserPageIndex(index: page, userId: userId)
        }))
        present(alert, animated: true)
    }
}

extension RoomViewController: WhiteboardDelegate {
    func whiteboardUndoStackLengthUpdate(_: ScribbleForge.Whiteboard, undoStackLength: Int) {
        print("[whiteboard delegate]", #function, undoStackLength)
        whiteboardControlView.undoRedoView.undoStep = undoStackLength
    }

    func whiteboardRedoStackLengthUpdate(_: ScribbleForge.Whiteboard, redoStackLength: Int) {
        print("[whiteboard delegate]", #function, redoStackLength)
        whiteboardControlView.undoRedoView.redoStep = redoStackLength
    }

    func whiteboardError(_: ScribbleForge.Whiteboard, errorCode: Int, errorMessage: String) {
        print("[whiteboard delegate]", #function, errorCode, errorMessage)
    }

    func whiteboardToolInfoUpdate(_: ScribbleForge.Whiteboard, toolInfo: ScribbleForge.WhiteboardToolInfo) {
        print("[whiteboard delegate]", #function, toolInfo)
        whiteboardControlView.toolBarView.syncCurrentTool(
            toolType: toolInfo.tool,
            strokeColor: UIColor(hex: toolInfo.strokeColor),
            fillColor: toolInfo.fillColor.map { UIColor(hex: $0) },
            strokeWidth: toolInfo.strokeWidth,
            textSize: toolInfo.fontSize,
            dash: toolInfo.dashArray
        )
    }

    func whiteboardPagePermissionUpdate(_: ScribbleForge.Whiteboard, userId: String, permission: ScribbleForge.WhiteboardPermission) {
        print("[whiteboard delegate]", #function, permission, userId)
        whiteboardControlView.whiteboard = whiteboard
    }

    func whiteboardElementSelected(_ whiteboard: ScribbleForge.Whiteboard, info: ScribbleForge.WhiteboardSelectInfo) {
        print("[whiteboard delegate]", #function, info)
        if info.userId != self.room.userId {
            return
        }
        
        var attributes: [ElementAttributesKey: Any] = [:]

        for attribute in info.attributes {
            whiteboard.getElementAttribute(sceneId: info.layerId, elementId: info.uuid, attributeKey: attribute) { value in
                attributes[attribute] = value

                if attributes.count == info.attributes.count {
                    print("Attributes", attributes)
                    let popOverView = PopOver(attributes: attributes) { color in
                        if let color {
                            whiteboard.setElementAttribute(layerId: info.layerId, elementId: info.uuid, attributeKey: .strokeColor, value: color.toHexString())
                        }
                    } strokeWidthUpdate: { width in
                        whiteboard.setElementAttribute(layerId: info.layerId, elementId: info.uuid, attributeKey: .strokeWidth, value: width)
                    } fillColorUpdate: { color in
                        if let color {
                            whiteboard.setElementAttribute(layerId: info.layerId, elementId: info.uuid, attributeKey: .fillColor, value: color.toHexString())
                        }
                    } fontSizeUpdate: { size in
                        whiteboard.setElementAttribute(layerId: info.layerId, elementId: info.uuid, attributeKey: .fontSize, value: size)
                    } dashStyleUpdate: { array in
                        whiteboard.setElementAttribute(layerId: info.layerId, elementId: info.uuid, attributeKey: .dashArray, value: array)
                    } headArrowUpdate: {
                        whiteboard.setElementAttribute(layerId: info.layerId, elementId: info.uuid, attributeKey: .headArrow, value: $0 ? "normal" : "none")
                    } tailArrowUpdate: {
                        whiteboard.setElementAttribute(layerId: info.layerId, elementId: info.uuid, attributeKey: .tailArrow, value: $0 ? "normal" : "none")
                    }
                    let popoverContent = UIHostingController(rootView: popOverView)
                    popoverContent.preferredContentSize = CGSize(width: 200, height: 0)
                    popoverContent.modalPresentationStyle = .popover
                    if let popoverPresentationController = popoverContent.popoverPresentationController {
                        popoverPresentationController.permittedArrowDirections = .any
                        popoverPresentationController.sourceView = whiteboard.applicationView
                        popoverPresentationController.sourceRect = info.boundingRect
                        popoverPresentationController.delegate = self
                    }
                    self.present(popoverContent, animated: true)
                }
            }
        }
    }

    func whiteboardElementDeselected(_: ScribbleForge.Whiteboard) {
//        print("[whiteboard delegate]", #function)

        whiteboardControlView.toolBarView.subMenuView.dismiss()
    }

    func whiteboardPageInfoUpdate(_: Whiteboard, activePageIndex: Int, pageCount: Int) {
        print("[whiteboard delegate]", #function, activePageIndex, pageCount)
        whiteboardControlView.pagesView.updatePageLabel(current: activePageIndex, total: pageCount)
    }
}

extension RoomViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        if settingStrokeColor {
            whiteboard?.setStrokeColor(viewController.selectedColor)
        } else {
            whiteboard?.setFillColor(viewController.selectedColor)
        }
    }
}

extension RoomViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

//
//  ExampleControlView.swift
//  Fastboard_Example
//
//  Created by xuyunshi on 2022/2/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

let minMargin: CGFloat = 3
let controlHeight: CGFloat = 44
let minControlWidth: CGFloat = 88
let maxControlWidth: CGFloat = 166

@objc
class ExampleItem: NSObject {
    override var debugDescription: String {
        title
    }
    
    init(
        title: String,
        status: String? = nil,
        enable: Bool = true,
        backgroundColor: UIColor? = nil,
        subMenuAction: ((UIButton) -> Void)? = nil,
        clickBlock: ((ExampleItem) -> Void)? = nil
    ) {
        self.title = title
        self.status = status
        self.clickBlock = clickBlock
        self.enable = enable
        self.backgroundColor = backgroundColor
        self.subMenuAction = subMenuAction
        super.init()
    }
    
    let title: String
    var status: String?
    var clickBlock: ((ExampleItem) ->Void)?
    var enable: Bool
    let backgroundColor: UIColor?
    let subMenuAction: ((UIButton) -> Void)?
}

class ExampleControlView: UICollectionView {
    var items: [ExampleItem]
    let layout: UICollectionViewFlowLayout
    var addtion: (()->Void)?
    
    override var intrinsicContentSize: CGSize {
        return .init(width: 0, height: controlHeight)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard !bounds.isEmpty else { return }
        let suitableRows: [CGFloat] = [5, 4, 3, 2, 1]
        let numberPerRow = suitableRows.first { r in
            let minWidth = minControlWidth * r
            let minMargin = minMargin * (r + 1)
            let estimateMinWidth = minWidth + minMargin
            return estimateMinWidth <= bounds.width
        }
        guard let numberPerRow else { return }
        
        let totalMargin = (numberPerRow - 1) * minMargin
        let estimateWidth = (bounds.width - totalMargin) / numberPerRow
        layout.minimumLineSpacing = minMargin
        layout.minimumInteritemSpacing = minMargin
        let width = estimateWidth >= maxControlWidth ? maxControlWidth : estimateWidth
        layout.itemSize = CGSize(width: width, height: controlHeight)
        
        layout.scrollDirection = bounds.height <= controlHeight ? .horizontal : .vertical
    }
    
    init(items: [ExampleItem]) {
        self.items = items
        
        layout = UICollectionViewFlowLayout()
        super.init(frame: .zero, collectionViewLayout: layout)
        register(UINib(nibName: .init(describing: ControlCell.self), bundle: nil), forCellWithReuseIdentifier: .init(describing: ControlCell.self))
        showsHorizontalScrollIndicator = false
        dataSource = self
        delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ExampleControlView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = items[indexPath.row]
        let cell = dequeueReusableCell(withReuseIdentifier: .init(describing: ControlCell.self), for: indexPath) as! ControlCell
        cell.controlTitleLabel.text = item.title
        cell.controlStatusLabel.text = item.status
        cell.controlStatusLabel.isHidden = item.status == nil
        cell.alpha = item.enable ? 1 : 0.5
        cell.backgroundColor = (item.backgroundColor != nil) ? item.backgroundColor : .lightGray
        if let block = item.subMenuAction {
            cell.btnActionBlock = block
            cell.actionBtn.isHidden = false
            block(cell.actionBtn)
        } else {
            cell.actionBtn.isHidden = true
        }
        return cell
    }
}

extension ExampleControlView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        item.clickBlock?(item)
        addtion?()
        collectionView.reloadData()
    }
}

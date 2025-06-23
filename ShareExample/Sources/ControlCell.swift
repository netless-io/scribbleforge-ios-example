//
//  ControlCell.swift
//  Fastboard_Example
//
//  Created by xuyunshi on 2022/2/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class ControlCell: UICollectionViewCell {
    var btnActionBlock: ((UIButton) -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = true
        layer.cornerRadius = 4
        
        controlTitleLabel.adjustsFontSizeToFitWidth = true
        controlTitleLabel.minimumScaleFactor = 0.5
        
        addSubview(actionBtn)
    }
    
    lazy var actionBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.showsMenuAsPrimaryAction = true
        btn.addTarget(self, action: #selector(t), for: .menuActionTriggered)
        return btn
    }()
    
    @objc func t() {
        btnActionBlock?(actionBtn)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        actionBtn.frame = bounds
    }
    
    @IBOutlet weak var controlStatusLabel: UILabel!
    @IBOutlet weak var controlTitleLabel: UILabel!
}

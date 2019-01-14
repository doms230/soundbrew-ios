//
//  MainCollectionViewCell.swift
//  soundbrew
//
//  Created by Dominic  Smith on 1/13/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit

class MainCollectionViewCell: UICollectionViewCell {
    
    let color = Color()
    let uiElement = UIElement()
    
    lazy var featureTagButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.backgroundColor = .black
        button.setTitle("Tag", for: .normal)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(featureTagButton)
        featureTagButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(200)
            make.width.equalTo(200)
            make.top.equalTo(self)
            make.left.equalTo(self)
            make.right.equalTo(self)
            make.bottom.equalTo(self)
        }
    }
    
    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

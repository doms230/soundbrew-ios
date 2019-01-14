//
//  ProfileTableViewCell.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/11/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit

class ProfileTableViewCell: UITableViewCell {

    let uiElement = UIElement()
    let color = Color()
    
    lazy var soundImage: UIImageView = {
        let image = UIImageView()
        return image
    }()
    
    lazy var soundLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: UIElement().mainFont, size: 17)
        return label
    }()
    
    lazy var soundPlays: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: UIElement().mainFont, size: 17)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.addSubview(soundImage)
        self.addSubview(soundLabel)
        
        soundImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(uiElement.buttonHeight)
            make.top.equalTo(self).offset(uiElement.topOffset)
            make.left.equalTo(self).offset(uiElement.leftOffset)
            make.bottom.equalTo(self).offset(uiElement.bottomOffset)
        }
        
        soundLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self).offset(uiElement.topOffset)
            make.left.equalTo(self.soundImage.snp.right).offset(5)
            make.right.equalTo(self).offset(uiElement.rightOffset)
            make.bottom.equalTo(self).offset(uiElement.bottomOffset)
        }
    }
    
    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
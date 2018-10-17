//
//  ArtistProfileTableViewCell.swift
//  soundbrew
//
//  Created by Dominic  Smith on 10/17/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit

class ArtistProfileTableViewCell: UITableViewCell {

    let uiElement = UIElement()
    let color = Color()
    
    lazy var socialStreamImage: UIImageView = {
        let image = UIImageView()
        return image
    }()
    
    lazy var socialStreamButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font =  UIFont(name: UIElement().mainFont, size: 17)
        button.titleLabel?.textAlignment = .left
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.addSubview(socialStreamImage)
        self.addSubview(socialStreamButton)
        
        socialStreamImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(uiElement.buttonHeight)
            make.top.equalTo(self).offset(uiElement.topOffset)
            make.left.equalTo(self).offset(uiElement.leftOffset)
            make.bottom.equalTo(self).offset(uiElement.bottomOffset)
        }
        
        socialStreamButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self).offset(uiElement.topOffset)
            make.left.equalTo(self.socialStreamImage.snp.right).offset(5)
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

//
//  PlayerTableViewCell.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/18/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit

class PlayerTableViewCell: UITableViewCell {
    let color = Color()
    let uiElement = UIElement()
    
    //player reuse
    lazy var soundArt: UIImageView = {
        return self.uiElement.soundbrewImageView(nil, cornerRadius: 3, backgroundColor: .black)
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(soundArt)
        soundArt.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self).offset(uiElement.topOffset)
           // make.centerX.equalTo(self)
            make.right.equalTo(self).offset(uiElement.rightOffset)
            make.left.equalTo(self).offset(uiElement.leftOffset)
            make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            make.height.equalTo(soundArt.snp.width)
        }
    }
    
    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

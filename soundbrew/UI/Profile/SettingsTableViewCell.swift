//
//  SettingsTableViewCell.swift
//  soundbrew
//
//  Created by Dominic  Smith on 5/6/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    
    lazy var settingsButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 20)
        button.setTitleColor(Color().black(), for: .normal)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.addSubview(self.settingsButton)
        settingsButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(75)
            make.top.equalTo(self).offset(UIElement().elementOffset)
            make.left.equalTo(self).offset(UIElement().leftOffset)
            make.right.equalTo(self).offset(UIElement().rightOffset)
            make.bottom.equalTo(self).offset(UIElement().bottomOffset)
        }
    }
    
    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }

}

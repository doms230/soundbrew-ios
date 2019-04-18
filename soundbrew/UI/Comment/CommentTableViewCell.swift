//
//  CommentTableViewCell.swift
//  soundbrew
//
//  Created by Dominic  Smith on 4/17/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit

class CommentTableViewCell: UITableViewCell {
    let color = Color()
    let uiElement = UIElement()
    
    let profileImageHeightWidth = 35
    
    lazy var userImage: UIImageView = {
        let image = UIImageView()
        image.layer.borderWidth = 1
        image.layer.borderColor = color.lightGray().cgColor
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.image = UIImage(named: "profile_icon")
        image.backgroundColor = color.darkGray()
        return image
    }()
    
    lazy var username: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        label.numberOfLines = 0
        return label
    }()
    
    lazy var atTime: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 17)
        button.setTitleColor(color.blue(), for: .normal)
        return button
    }()
    
    lazy var comment: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.numberOfLines = 0
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.addSubview(userImage)
        self.addSubview(username)
        self.addSubview(comment)
        self.addSubview(atTime)
        
        userImage.layer.cornerRadius = CGFloat(profileImageHeightWidth / 2)
        userImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(profileImageHeightWidth)
            make.top.equalTo(self).offset(uiElement.topOffset)
            make.left.equalTo(self).offset(uiElement.leftOffset)
        }
        
        username.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(userImage)
            make.left.equalTo(userImage.snp.right).offset(uiElement.leftOffset)
        }
        
        comment.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(username.snp.bottom)
            make.left.equalTo(username)
            make.right.equalTo(self).offset(uiElement.rightOffset)
        }
        
        atTime.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(comment.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(username)
            make.bottom.equalTo(self).offset(uiElement.bottomOffset)
        }
    }
    
    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

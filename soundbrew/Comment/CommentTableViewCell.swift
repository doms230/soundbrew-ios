//
//  CommentTableViewCell.swift
//  soundbrew
//
//  Created by Dominic Smith on 1/28/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit
import ActiveLabel

class CommentTableViewCell: UITableViewCell {
    let color = Color()
    let uiElement = UIElement()
    
    let profileImageHeightWidth = 35

    lazy var userImage: UIButton = {
        let button = UIButton()
        button.layer.borderWidth = 1
        button.clipsToBounds = true
        button.setImage(UIImage(named: "profile_icon"), for: .normal)
        button.backgroundColor = .white
        button.contentMode = .scaleAspectFill
        return button
    }()
    
    lazy var username: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    lazy var comment: ActiveLabel = {
        let label = ActiveLabel()
        label.enabledTypes = [.mention]
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.textColor = .white
        label.mentionColor = color.uicolorFromHex(0x91d0f5)
        label.numberOfLines = 0
        return label
    }()
    
    lazy var atTime: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 17)
        button.setTitleColor(color.blue(), for: .normal)
        return button
    }()
    
    lazy var replyButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 17)
        button.setTitleColor(.darkGray, for: .normal)
        button.setTitle("Reply", for: .normal)
        return button
    }()
    
    lazy var date: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.numberOfLines = 0
        label.textColor = .darkGray
        return label
    }()
    
    lazy var dividerLine: UIView = {
        let line = UIView()
        line.layer.borderWidth = 0.5
        line.layer.borderColor = UIColor.darkGray.cgColor
        return line
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(userImage)
        self.addSubview(username)
        self.addSubview(comment)
        self.addSubview(atTime)
        self.addSubview(date)
        self.addSubview(replyButton)
        
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
           // make.centerY.equalTo(userImage)
            make.right.equalTo(self).offset(uiElement.rightOffset)
            make.bottom.equalTo(self).offset(uiElement.bottomOffset)
        }
        
        replyButton.snp.makeConstraints { (make) -> Void in
            //make.left.equalTo(username)
            make.right.equalTo(atTime.snp.left).offset(uiElement.rightOffset)
            make.bottom.equalTo(atTime)
        }
        
        date.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(comment.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(username)
            //make.right.equalTo(replyButton.snp.left).offset(uiElement.rightOffset)
            make.bottom.equalTo(atTime)
        }
    }
    
    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

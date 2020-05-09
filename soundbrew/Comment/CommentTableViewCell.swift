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
        button.isOpaque = true
        return button
    }()
    
    lazy var username: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 15)
        button.setTitleColor(.white, for: .normal)
        button.isOpaque = true
        return button
    }()
    
    lazy var comment: ActiveLabel = {
        let label = ActiveLabel()
        label.enabledTypes = [.mention]
        label.font = UIFont(name: uiElement.mainFont, size: 15)
        label.textColor = .white
        label.mentionColor = color.blue()
        label.numberOfLines = 0
        label.isOpaque = true
        return label
    }()
    
    lazy var atTime: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 15)
        button.setTitleColor(color.blue(), for: .normal)
        button.isOpaque = true
        return button
    }()
    
    lazy var replyButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 15)
        button.setTitleColor(.darkGray, for: .normal)
        button.setTitle("Reply", for: .normal)
        button.isOpaque = true
        return button
    }()
    
    lazy var date: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 15)
        label.numberOfLines = 0
        label.textColor = .darkGray
        label.isOpaque = true
        return label
    }()
    
    lazy var dividerLine: UIView = {
        let line = UIView()
        line.layer.borderWidth = 0.5
        line.layer.borderColor = UIColor.darkGray.cgColor
        line.isOpaque = true 
        return line
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(userImage)
        self.addSubview(username)
        self.addSubview(comment)
        //self.comment.addSubview(username)
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
        
        date.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(comment.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(comment)
            make.bottom.equalTo(self)

        }
        replyButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(date)
            make.left.equalTo(date.snp.right).offset(uiElement.leftOffset)
            make.bottom.equalTo(date)
        }
        
        atTime.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(date)
            make.right.equalTo(self).offset(uiElement.rightOffset)
            make.bottom.equalTo(date)
            //make.top.equalTo(date)
        }
    }
    
    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

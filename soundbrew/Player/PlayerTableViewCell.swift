//
//  PlayerTableViewCell.swift
//  soundbrew
//
//  Created by Dominic Smith on 1/28/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit
import ActiveLabel

class PlayerTableViewCell: UITableViewCell {
    
    let uiElement = UIElement()
    var userImage: UIButton!
    var username: UIButton!
    var atTime: UIButton!
    var replyButton: UIButton!
    var date: UILabel!
    
    lazy var comment: ActiveLabel = {
        let label = ActiveLabel()
        label.enabledTypes = [.mention, .hashtag]
        label.textColor = .white
        label.numberOfLines = 0
        label.isOpaque = true
        return label
    }()
    
    lazy var soundArt: UIImageView = {
        return self.uiElement.soundbrewImageView(nil, cornerRadius: 3, backgroundColor: .black)
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let color = Color()
        
        if reuseIdentifier == "playerReuse" {
            self.addSubview(soundArt)
            soundArt.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
                make.height.equalTo(soundArt.snp.width)
            }
            
        } else {
            let profileImageHeightWidth = 35
            
            userImage = uiElement.soundbrewButton(nil, shouldShowBorder: true, backgroundColor: .white, image: UIImage(named: "profile_icon"), titleFont: nil, titleColor: .white, cornerRadius: CGFloat(profileImageHeightWidth / 2))
            self.addSubview(userImage)
            userImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(profileImageHeightWidth)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }

            username = uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: .clear, image: nil, titleFont: UIFont(name: "\(uiElement.mainFont)-bold", size: 15), titleColor: .white, cornerRadius: nil)
            self.addSubview(username)
            username.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(userImage)
                make.left.equalTo(userImage.snp.right).offset(uiElement.leftOffset)
            }
            
            self.addSubview(comment)
            comment.font = UIFont(name: uiElement.mainFont, size: 15)
            comment.textColor = .white
            comment.mentionColor = color.blue()
            comment.hashtagColor = color.blue()
            comment.mentionSelectedColor = .darkGray
            
            comment.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(username.snp.bottom)
                make.left.equalTo(username)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            date = uiElement.soundbrewLabel(nil, textColor: .darkGray, font: UIFont(name: uiElement.mainFont, size: 15)!, numberOfLines: 0)
            self.addSubview(date)
            date.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(comment.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(comment)
                make.bottom.equalTo(self)
            }
            
            replyButton = uiElement.soundbrewButton("Reply", shouldShowBorder: false, backgroundColor: .clear, image: nil, titleFont: UIFont(name: uiElement.mainFont, size: 15), titleColor: .darkGray, cornerRadius: nil)
            self.addSubview(replyButton)
            replyButton.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(date)
                make.left.equalTo(date.snp.right).offset(uiElement.leftOffset)
                make.bottom.equalTo(date)
            }

            atTime = uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: .clear, image: nil, titleFont: UIFont(name: uiElement.mainFont, size: 15), titleColor: color.blue(), cornerRadius: nil)
            self.addSubview(atTime)
            atTime.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(date)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(date)
            }
        }
    }
    
    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

//
//  WhoToFollowTableViewCell.swift
//  soundbrew
//
//  Created by Dominic  Smith on 3/14/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit

class WhoToFollowTableViewCell: UITableViewCell {

    let color = Color()
    let uiElement = UIElement()
    
    lazy var profileImage: UIImageView = {
        let image = UIImageView()
        image.layer.borderWidth = 1
        image.layer.borderColor = color.purpleBlack().cgColor
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.image = UIImage(named: "profile_icon")
        image.backgroundColor = .black
        return image
    }()
    
    lazy var seperatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderColor = UIColor.darkGray.cgColor
        view.layer.borderWidth = 0.5
        view.clipsToBounds = true
        return view
    }()
    
    lazy var followButton: UIButton = {
        let button = UIButton()
        button.setTitle("Follow", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = color.blue()
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 17)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    var displayNameLabel: UILabel!
    var usernameLabel: UILabel!
    var bioLabel: UILabel!
    var cityLabel: UILabel!
    
    func label(_ text: String?, font: UIFont, textColor: UIColor) -> UILabel {
        let label = UILabel()
        label.font = font
        label.numberOfLines = 0
        label.textColor = textColor
        if let text = text {
            label.text = text
        }
        return label
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        if reuseIdentifier == "titleReuse" {
            
            let suggestionsDescription = label("When you follow someone, you'll see a playlist of their latest uploads, likes, and credits on your homepage.", font: UIFont(name: uiElement.mainFont, size: 17)!, textColor: .lightGray)
            self.addSubview(suggestionsDescription)
            
            suggestionsDescription.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(seperatorLine)
            seperatorLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(suggestionsDescription.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
        } else {
            self.addSubview(profileImage)
            profileImage.layer.cornerRadius = 50/2
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(50)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            displayNameLabel = label(nil, font: UIFont(name: "\(uiElement.mainFont)-Bold", size: 15)!, textColor: .white)
            self.addSubview(displayNameLabel)
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(profileImage).offset(uiElement.elementOffset)
                make.left.equalTo(profileImage.snp.right).offset(uiElement.elementOffset)
            }
            
            usernameLabel = label(nil, font: UIFont(name: uiElement.mainFont, size: 15)!, textColor: .darkGray)
            self.addSubview(usernameLabel)
            usernameLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayNameLabel.snp.bottom)
                make.left.equalTo(displayNameLabel)
            }
            
            self.addSubview(followButton)
            followButton.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(85)
                make.height.equalTo(30)
                make.top.equalTo(displayNameLabel)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            bioLabel = label(nil, font: UIFont(name: uiElement.mainFont, size: 15)!, textColor: .white)
            self.addSubview(bioLabel)
            bioLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(usernameLabel.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(usernameLabel)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            cityLabel = label(nil, font: UIFont(name: uiElement.mainFont, size: 15)!, textColor: .lightGray)
            self.addSubview(cityLabel)
            cityLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(bioLabel.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(usernameLabel)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(seperatorLine)
            seperatorLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(cityLabel.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
        }
    }
    
    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

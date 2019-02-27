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
    
    //profile
    lazy var artistImage: UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = 75/2
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.image = UIImage(named: "profile_icon")
        return image
    }()
    
    lazy var artistName: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 17)
        return label
    }()
    
    lazy var artistBio: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.text = "This is My Bio"
        return label
    }()
    
    lazy var artistCity: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        return label
    }()
    
    lazy var artistLink: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 17)
        button.setTitle("https://www.soundbrew.app", for: .normal)
        button.setTitleColor(color.blue(), for: .normal)
        return button
    }()
    
    lazy var followerCount: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        label.text = "100"
        return label
    }()
    
    lazy var followerCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.text = "Followers"
        return label
    }()
    
    lazy var actionButton: UIButton = {
        let button = UIButton()
        button.setTitle("Some Action", for: .normal)
        button.backgroundColor = .lightGray
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 17)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        switch reuseIdentifier {
        case "profileReuse":
            self.addSubview(artistImage)
            self.addSubview(artistName)
            self.addSubview(artistCity)
            self.addSubview(artistBio)
            self.addSubview(artistLink)
            self.addSubview(actionButton)
            self.addSubview(followerCount)
            self.addSubview(followerCountLabel)
            
            artistImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(75)
                make.top.equalTo(self).offset(uiElement.elementOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            followerCount.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistImage)
                make.left.equalTo(self.artistImage.snp.right).offset(uiElement.leftOffset)
            }
            followerCountLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(followerCount.snp.bottom)
                make.left.equalTo(followerCount)
            }
            
            actionButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(35)
                make.top.equalTo(followerCountLabel.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(followerCount)
                make.left.equalTo(followerCount)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            artistName.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistImage.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(artistImage)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            artistCity.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistName.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(artistName)
                make.right.equalTo(artistName)
            }
            
            artistBio.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistCity.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(artistName)
                make.right.equalTo(artistName)
            }
            
            artistLink.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistBio.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(artistName)
                //make.right.equalTo(artistName)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
    
            break
            
            
        default:
            break
        }
    }
    
    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
}

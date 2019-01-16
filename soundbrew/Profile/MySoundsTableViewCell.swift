//
//  MySoundsTableViewCell.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/11/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit

class MySoundsTableViewCell: UITableViewCell {

    let uiElement = UIElement()
    let color = Color()
    
    lazy var playFilterScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    lazy var soundArtImage: UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = 3
        image.clipsToBounds = true
        return image
    }()
    
    lazy var soundTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        return label
    }()
    
    lazy var soundArtist: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        return label
    }()
    
    lazy var soundPlaysImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "playIcon")
        return image
    }()
    
    lazy var soundPlays: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 15)
        return label
    }()
    
    lazy var menuButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "menu"), for: .normal)
        return button 
    }()
    
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
        return label
    }()
    
    lazy var artistCity: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        return label
    }()
    
    lazy var uploadsButton: UIButton = {
        let button = UIButton()
        button.setTitle("Uploads", for: .normal)
        button.setTitleColor(color.blue(), for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 20)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    lazy var likesButton: UIButton = {
        let button = UIButton()
        button.setTitle("Likes", for: .normal)
        button.setTitleColor(color.black(), for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 20)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    lazy var editProfileButton: UIButton = {
        let button = UIButton()
        button.setTitle("Edit Profile", for: .normal)
        button.backgroundColor = color.blue()
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 17)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        switch reuseIdentifier {
        case "reuse":
            self.addSubview(menuButton)
            self.addSubview(soundArtImage)
            self.addSubview(soundTitle)
            self.addSubview(soundArtist)
            self.addSubview(soundPlaysImage)
            self.addSubview(soundPlays)
            
            soundArtImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(100)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            menuButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(25)
                make.top.equalTo(soundArtImage)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            soundTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundArtImage).offset(uiElement.elementOffset)
                make.left.equalTo(soundArtImage.snp.right).offset(uiElement.elementOffset)
                make.right.equalTo(menuButton.snp.left).offset(-(uiElement.elementOffset))
            }
            
            soundArtist.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundTitle.snp.bottom)
                make.left.equalTo(soundTitle)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            soundPlaysImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(25)
                make.top.equalTo(soundArtist.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(soundTitle)
                //make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            soundPlays.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundPlaysImage).offset(2)
                make.left.equalTo(soundPlaysImage.snp.right)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                //make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            break
            
        case "profileReuse":
            self.addSubview(artistImage)
            self.addSubview(artistName)
            self.addSubview(artistCity)
            self.addSubview(artistBio)
            self.addSubview(uploadsButton)
            self.addSubview(likesButton)
            
            artistImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(75)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            artistName.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistImage.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
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
            
            uploadsButton.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(100)
                make.height.equalTo(uiElement.buttonHeight)
                make.top.equalTo(artistBio.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(artistName)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            likesButton.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(100)
                make.height.equalTo(uiElement.buttonHeight)
                make.top.equalTo(uploadsButton)
                make.left.equalTo(uploadsButton.snp.right).offset(uiElement.leftOffset)
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

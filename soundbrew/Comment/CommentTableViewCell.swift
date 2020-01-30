//
//  CommentTableViewCell.swift
//  soundbrew
//
//  Created by Dominic Smith on 1/28/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit

class CommentTableViewCell: UITableViewCell {
    let color = Color()
    let uiElement = UIElement()
    
    let profileImageHeightWidth = 35
    
    //
    lazy var songTitle: UILabel = {
        let label = UILabel()
        label.text = "Welcome"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        return label
    }()
    
    lazy var artistName: UILabel = {
        let label = UILabel()
        label.text = "Press Play"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 15)
        return label
    }()
    
    lazy var songArt: UIImageView = {
        let image = UIImageView()
        image.backgroundColor = .clear
        image.image = UIImage(named: "sound")
        return image
    }()
    
    lazy var activitySpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .white
        spinner.startAnimating()
        spinner.isHidden = true
        return spinner
    }()
    
    lazy var playBackButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "play"), for: .normal)
        return button
    }()
    
    lazy var playBackSlider: UISlider = {
        let slider = UISlider()
        slider.value = 0
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.tintColor = .white
        slider.setThumbImage(UIImage(), for: .normal)
        slider.isEnabled = false
        return slider
     }()
    
    
    //
    
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
    
    lazy var comment: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    lazy var atTime: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 17)
        button.setTitleColor(color.blue(), for: .normal)
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
        if reuseIdentifier == "commentReuse" {
            self.addSubview(userImage)
            self.addSubview(username)
            self.addSubview(comment)
            self.addSubview(atTime)
            self.addSubview(date)
            
            userImage.layer.cornerRadius = CGFloat(profileImageHeightWidth / 2)
            userImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(profileImageHeightWidth)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            atTime.snp.makeConstraints { (make) -> Void in
                make.centerY.equalTo(userImage)
                make.right.equalTo(self).offset(uiElement.rightOffset)
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
                make.left.equalTo(username)
                make.right.equalTo(atTime.snp.left).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
        } else if reuseIdentifier == "miniPlayerReuse" {
            self.addSubview(songArt)
            songArt.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(50)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                //make.bottom.equalTo(self)
            }
            
            self.addSubview(playBackButton)
            playBackButton.snp.makeConstraints { (make) -> Void in
                make.width.height.equalTo(30)
                make.centerY.equalTo(songArt)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(activitySpinner)
            activitySpinner.snp.makeConstraints { (make) -> Void in
                make.width.height.equalTo(30)
                make.centerY.equalTo(songArt)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            activitySpinner.isHidden = true
            
            self.addSubview(artistName)
            artistName.snp.makeConstraints { (make) -> Void in
                make.centerY.equalTo(self.songArt).offset(uiElement.topOffset)
                make.left.equalTo(songArt.snp.right).offset(uiElement.elementOffset)
                make.right.equalTo(playBackButton.snp.left).offset(uiElement.rightOffset)
            }
            
            self.addSubview(songTitle)
            songTitle.snp.makeConstraints { (make) -> Void in
                make.left.equalTo(artistName)
                make.right.equalTo(artistName)
                make.bottom.equalTo(artistName.snp.top).offset(-(uiElement.elementOffset))
            }
            
            self.addSubview(dividerLine)
            dividerLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(1)
                make.top.equalTo(songArt.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
        } else {
            self.addSubview(playBackSlider)
            playBackSlider.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(1)
                make.top.equalTo(self).offset(uiElement.topOffset)
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

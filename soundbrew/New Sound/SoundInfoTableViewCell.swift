//
//  SoundInfoTableViewCell.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/8/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit

class SoundInfoTableViewCell: UITableViewCell {

    let color = Color()
    let uiElement = UIElement()
    
    lazy var soundArt: UIButton = {
        let localizedAddArt = NSLocalizedString("addArt", comment: "")
       let image = UIButton()
        image.setTitle(localizedAddArt, for: .normal)
        image.titleLabel?.textColor = .black
        image.layer.borderWidth = 1
        image.layer.borderColor = UIColor.black.cgColor
        image.layer.cornerRadius = 3
        image.clipsToBounds = true
        image.backgroundColor = .lightGray
        image.contentMode = .scaleAspectFill
        return image
    }()
    
    lazy var soundTagLabel: UILabel = {
        let localizedTags = NSLocalizedString("tags", comment: "")
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        label.text = localizedTags
        label.textColor = .white
        return label
    }()
    
    lazy var chosenSoundTagLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        return label
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 20)
        label.numberOfLines = 0 
        return label
    }()
    
    lazy var inputTitle: UITextView = {
        let label = UITextView()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        label.textColor = .white
        label.backgroundColor = color.black()
        label.isScrollEnabled = false 
        return label
    }()
    
   lazy var progressSlider: UISlider = {
        let slider = UISlider()
        slider.value = 0
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.tintColor = .white 
        return slider
    }()
    
    lazy var socialSwitch: UISwitch = {
       let socialSwitch = UISwitch()
        socialSwitch.onTintColor = color.blue()
        return socialSwitch
    }()
    
    lazy var twitterMessageTitle: UILabel = {
        let localizedTwitterMessageTitle = NSLocalizedString("twitterMessage", comment: "")
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        label.text = localizedTwitterMessageTitle
        label.textColor = .white
        return label
    }()
    
    lazy var twitterMessage: UITextView = {
        let label = UITextView()
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = .white
        label.backgroundColor = color.black()
        label.isScrollEnabled = false
        label.text = "Listen to Untitled on @soundbrew"
        label.layer.cornerRadius = 3
        label.clipsToBounds = true
        label.layer.borderWidth = 1
        label.layer.borderColor = color.darkGray().cgColor
        return label
    }()
    
    lazy var artistTypeButton: UIButton = {
        let localizedArtist = NSLocalizedString("artist", comment: "")
        let button = UIButton()
        button.setTitleColor(.darkGray, for: .normal)
        button.setTitle(localizedArtist, for: .normal)
        return button
    }()
    
    lazy var dividerLine: UIView = {
        let line = UIView()
        line.layer.borderWidth = 1
        line.layer.borderColor = color.darkGray().cgColor
        return line
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        switch reuseIdentifier {
            
        case "dividerReuse":
            self.addSubview(dividerLine)
            dividerLine.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            break
            
        case "soundProgressReuse":
            self.addSubview(progressSlider)
            self.addSubview(titleLabel)
            
            titleLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            progressSlider.isEnabled = false
            progressSlider.setThumbImage(UIImage(), for: .normal)
            progressSlider.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(titleLabel.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self)
            }
            
            break
            
        case "soundInfoReuse":
            self.addSubview(soundArt)
            self.addSubview(inputTitle)
            
            soundArt.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(100)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            inputTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundArt)
                make.left.equalTo(soundArt.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(soundArt)
            }
            
            break
            
        case "soundTagReuse":
            self.addSubview(soundTagLabel)
            self.addSubview(chosenSoundTagLabel)
            
            soundTagLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            chosenSoundTagLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundTagLabel)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            break
            
        case "soundSocialReuse":
            self.addSubview(soundTagLabel)
            self.addSubview(socialSwitch)
            self.addSubview(twitterMessage)
            self.addSubview(twitterMessageTitle)
            
            socialSwitch.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                //make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            soundTagLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(socialSwitch)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            twitterMessageTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(socialSwitch.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            twitterMessage.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(twitterMessageTitle.snp.bottom).offset(uiElement.topOffset)
                make.height.equalTo(150)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            break
            
        case "creditPeopleReuse":
            self.addSubview(progressSlider)
            self.addSubview(titleLabel)
            self.addSubview(soundArt)
            self.addSubview(soundTagLabel)
            self.addSubview(artistTypeButton)
            
            //artist profile picture
            soundArt.layer.cornerRadius = 25
            soundArt.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(50)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            //artist name
            soundTagLabel.snp.makeConstraints { (make) -> Void in
                make.centerY.equalTo(soundArt)
                make.left.equalTo(soundArt.snp.right).offset(uiElement.elementOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            artistTypeButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(20)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(soundTagLabel)
                make.bottom.equalTo(soundTagLabel.snp.top).offset(-(uiElement.elementOffset))
            }
            
            //percentage tip
            titleLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundTagLabel.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(soundTagLabel)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            //percentage chooser
            progressSlider.snp.makeConstraints { (make) -> Void in
                make.centerY.equalTo(titleLabel)
                make.left.equalTo(titleLabel.snp.right)
                make.right.equalTo(self).offset(uiElement.rightOffset)
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

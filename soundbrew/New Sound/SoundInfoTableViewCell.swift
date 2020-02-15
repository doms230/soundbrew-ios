//
//  SoundInfoTableViewCell.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/8/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit
import UICircularProgressRing

class SoundInfoTableViewCell: UITableViewCell {

    let color = Color()
    let uiElement = UIElement()
    
    lazy var artistImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "profile_icon")
        image.clipsToBounds = true
        image.backgroundColor = .black
        return image
    }()
    
    lazy var audioProgress: UICircularProgressRing = {
       let audioProgress = UICircularProgressRing()
        audioProgress.maxValue = 100
        audioProgress.innerRingColor = color.darkGray()
        audioProgress.innerRingWidth = 3
        audioProgress.outerRingColor = color.black()
        return audioProgress
    }()
    
    lazy var soundArtImageButton: UIButton = {
        let image = UIButton()
        image.setImage(UIImage(named: "add_image"), for: .normal)
        image.layer.cornerRadius = 5
        image.clipsToBounds = true 
        return image
    }()
    
    lazy var soundTagLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        label.textColor = .white
        return label
    }()
    
    lazy var username: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.textColor = .darkGray
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
    
    lazy var inputTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = .white
        label.backgroundColor = color.black()
        label.numberOfLines = 0
        return label
    }()
    
   lazy var percentageSlider: UISlider = {
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
    
    lazy var artistTypeButton: UIButton = {
        let localizedArtist = NSLocalizedString("artist", comment: "")
        let button = UIButton()
        button.setTitleColor(.white, for: .normal)
        button.setTitle(localizedArtist, for: .normal)
        button.setTitleColor(color.blue(), for: .normal)
        //button.layer.borderWidth = 0.5
        //button.layer.borderColor = color.darkGray().cgColor
        button.clipsToBounds = true
        return button
    }()
    
    lazy var dividerLine: UIView = {
        let line = UIView()
        line.layer.borderWidth = 0.5
        line.layer.borderColor = UIColor.darkGray.cgColor
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
            
        case "soundInfoReuse":
            self.addSubview(dividerLine)
            self.addSubview(inputTitle)
            self.addSubview(audioProgress)
            self.addSubview(soundArtImageButton)
            
            audioProgress.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(150)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            soundArtImageButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(75)
                make.centerX.centerY.equalTo(audioProgress)
            }
            
            inputTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(audioProgress)
                make.left.equalTo(audioProgress.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(dividerLine).offset(uiElement.bottomOffset)
            }
            
            dividerLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(audioProgress.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
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
            self.addSubview(dividerLine)
            
            dividerLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            socialSwitch.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(dividerLine.snp.bottom).offset(uiElement.topOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            soundTagLabel.snp.makeConstraints { (make) -> Void in
               // make.top.equalTo(socialSwitch)
                make.centerY.equalTo(socialSwitch)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            break
            
        case "creditReuse":
            self.addSubview(percentageSlider)
            self.addSubview(titleLabel)
            self.addSubview(artistImage)
            self.addSubview(soundTagLabel)
            self.addSubview(artistTypeButton)
            self.addSubview(dividerLine)
            self.addSubview(username)
            //artist profile picture
            artistImage.layer.cornerRadius = 35/2
            artistImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(35)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            //username
            soundTagLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistImage).offset(-5)
                make.left.equalTo(artistImage.snp.right).offset(uiElement.elementOffset)
               // make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            //artist name 
            username.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundTagLabel)
                make.left.equalTo(soundTagLabel.snp.right).offset(uiElement.elementOffset)
               // make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            //credit name
            artistTypeButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(20)
                make.top.equalTo(soundTagLabel.snp.bottom)
                make.left.equalTo(soundTagLabel)
            }
            
            //percentage tip
            titleLabel.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
            titleLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistTypeButton.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            //percentage chooser
            percentageSlider.snp.makeConstraints { (make) -> Void in
                make.centerY.equalTo(titleLabel)
                make.left.equalTo(titleLabel.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            dividerLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(titleLabel.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self)
            }
            
            break
            
        case "newCreditReuse":
            self.addSubview(titleLabel)
            self.addSubview(dividerLine)
            titleLabel.text = "Add Credit"
            titleLabel.textColor = .darkGray
            titleLabel.textAlignment = .center
            titleLabel.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(50)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                //make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            dividerLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(titleLabel.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
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

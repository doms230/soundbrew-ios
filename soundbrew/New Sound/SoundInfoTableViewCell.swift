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
    
    var artistImage: UIImageView!
    var soundArtImageButton: UIButton!
    var soundTagLabel: UILabel!
    var username: UILabel!
    var chosenSoundTagLabel: UILabel!
    var titleLabel: UILabel!
    var inputTitle: UILabel!
    var artistTypeButton: UIButton!
    
    lazy var audioProgress: UICircularProgressRing = {
       let audioProgress = UICircularProgressRing()
        audioProgress.innerRingWidth = 3
        audioProgress.maxValue = 100
        return audioProgress
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
        return socialSwitch
    }()
    
    lazy var dividerLine: UIView = {
        let line = UIView()
        line.layer.borderWidth = 0.5
        line.layer.borderColor = UIColor.darkGray.cgColor
        return line
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let color = Color()
        let uiElement = UIElement()
        
        soundTagLabel = uiElement.soundbrewLabel(nil, textColor: .white, font: UIFont(name: "\(uiElement.mainFont)", size: 17)!, numberOfLines: 0)
        
        titleLabel = uiElement.soundbrewLabel(nil, textColor: .white, font: UIFont(name: "\(uiElement.mainFont)-bold", size: 20)!, numberOfLines: 0)
        
        switch reuseIdentifier {
        case "dividerReuse":
            self.addSubview(dividerLine)
            dividerLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            break
            
        case "soundInfoReuse":
            audioProgress.innerRingColor = color.darkGray()
            audioProgress.outerRingColor = color.black()
            self.addSubview(audioProgress)
            audioProgress.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(150)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            soundArtImageButton = uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: .clear, image: UIImage(named: "add_image"), titleFont: nil, titleColor: .white, cornerRadius: 5)
            self.addSubview(soundArtImageButton)
            soundArtImageButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(75)
                make.centerX.centerY.equalTo(audioProgress)
            }
            
            self.addSubview(dividerLine)
            dividerLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(audioProgress.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            inputTitle = uiElement.soundbrewLabel(nil, textColor: .white, font: UIFont(name: "\(uiElement.mainFont)", size: 17)!, numberOfLines: 0)
            self.addSubview(inputTitle)
            inputTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(audioProgress)
                make.left.equalTo(audioProgress.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(dividerLine).offset(uiElement.bottomOffset)
            }
            
            break
            
        case "soundTagReuse":
            self.addSubview(soundTagLabel)
            soundTagLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            chosenSoundTagLabel = uiElement.soundbrewLabel(nil, textColor: .white, font: UIFont(name: "\(uiElement.mainFont)", size: 17)!, numberOfLines: 0)
            self.addSubview(chosenSoundTagLabel)
            chosenSoundTagLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundTagLabel)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            break
            
        case "soundSocialReuse":
            self.addSubview(dividerLine)
            dividerLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            socialSwitch.onTintColor = color.blue()
            self.addSubview(socialSwitch)
            socialSwitch.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(dividerLine.snp.bottom).offset(uiElement.topOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(soundTagLabel)
            soundTagLabel.snp.makeConstraints { (make) -> Void in
                make.centerY.equalTo(socialSwitch)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            break
            
        case "creditReuse":
            //artist profile picture
            artistImage = uiElement.soundbrewImageView(UIImage(named: "profile_icon"), cornerRadius: nil, backgroundColor: nil)
            artistImage.layer.cornerRadius = 35/2
            artistImage.clipsToBounds = true 
            self.addSubview(artistImage)
            artistImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(35)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            //username
            self.addSubview(soundTagLabel)
            soundTagLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistImage).offset(-5)
                make.left.equalTo(artistImage.snp.right).offset(uiElement.elementOffset)
            }
            
            //artist name
            username = uiElement.soundbrewLabel(nil, textColor: .darkGray, font: UIFont(name: uiElement.mainFont, size: 17)!, numberOfLines: 0)
            self.addSubview(username)
            username.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundTagLabel)
                make.left.equalTo(soundTagLabel.snp.right).offset(uiElement.elementOffset)
            }
            
            //credit name
            let localizedArtist = NSLocalizedString("artist", comment: "")
            artistTypeButton = uiElement.soundbrewButton(localizedArtist, shouldShowBorder: false, backgroundColor: .clear, image: nil, titleFont: UIFont(name: "\(uiElement.mainFont)", size: 17)!, titleColor: color.blue(), cornerRadius: nil)
            self.addSubview(artistTypeButton)
            artistTypeButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(20)
                make.top.equalTo(soundTagLabel.snp.bottom)
                make.left.equalTo(soundTagLabel)
            }
            
            //percentage tip
            titleLabel.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
            self.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistTypeButton.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            //percentage chooser
            self.addSubview(percentageSlider)
            percentageSlider.snp.makeConstraints { (make) -> Void in
                make.centerY.equalTo(titleLabel)
                make.left.equalTo(titleLabel.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(dividerLine)
            dividerLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(titleLabel.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self)
            }
            break
            
        case "newCreditReuse":
            titleLabel.text = "Add Credit"
            titleLabel.textColor = .darkGray
            titleLabel.textAlignment = .center
            self.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(50)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(dividerLine)
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

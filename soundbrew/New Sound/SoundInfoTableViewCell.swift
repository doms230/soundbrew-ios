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
       let image = UIButton()
        image.setTitle("Add Art", for: .normal)
        image.titleLabel?.textColor = .black
        image.layer.cornerRadius = 3
        image.clipsToBounds = true
        image.backgroundColor = .lightGray
        image.contentMode = .scaleAspectFill
        return image
    }()
    
    lazy var soundTitle: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Add Title"
        textField.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 20)
        //textField.borderStyle = .roundedRect
        textField.borderStyle = .none
        return textField
    }()
    
    lazy var soundTagLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        label.text = "Tags"
        return label
    }()
    
    lazy var chosenSoundTagLabel: UILabel = {
        let label = UILabel()
        label.text = "Add"
        label.textColor = color.red()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        return label
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = color.black()
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 20)
        return label
    }()
    
   lazy var progressSlider: UISlider = {
        let slider = UISlider()
        slider.value = 0
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.tintColor = color.black()
        slider.isEnabled = false
        slider.setThumbImage(UIImage(), for: .normal)
        return slider
    }()
    
    lazy var socialSwitch: UISwitch = {
       let socialSwitch = UISwitch()
        socialSwitch.onTintColor = color.blue()
        return socialSwitch
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        switch reuseIdentifier {
        case "soundProgressReuse":
            self.addSubview(progressSlider)
            self.addSubview(titleLabel)
            
            titleLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            progressSlider.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(titleLabel.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self)
            }
            
            break
            
        case "soundInfoReuse":
            //self.addSubview(soundArtLabel)
            self.addSubview(soundArt)
            self.addSubview(soundTitle)
            
            soundArt.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(100)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            soundTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundArt).offset(40)
                make.left.equalTo(soundArt.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
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
                //make.bottom.equalTo(soundTagLabel)
            }
            break
            
        case "soundSocialReuse":
            //self.addSubview(titleLabel)
            self.addSubview(soundTagLabel)
            self.addSubview(socialSwitch)
            
            /*titleLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }*/
            
            socialSwitch.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            soundTagLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(socialSwitch)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            break
            
            //case ""
            
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

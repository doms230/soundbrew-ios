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

    lazy var soundArtLabel: UILabel = {
        let label = UILabel()
        label.text = "Sound Art"
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        return label
    }()
    
    lazy var soundArt: UIButton = {
       let image = UIButton()
        image.setTitle("Upload", for: .normal)
        image.titleLabel?.textColor = .black
        image.layer.cornerRadius = 3
        image.clipsToBounds = true
        image.backgroundColor = .lightGray
        image.contentMode = .scaleAspectFill
        return image
    }()
    
    lazy var soundTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Sound Title"
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        return label
    }()
    
    lazy var soundTitle: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Sound Title"
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    /*lazy var soundTagLabel: UILabel = {
        let label = UILabel()
        label.text = "Add Tags. For Ex: tag1 tag2 tag3"
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
       return label
    }()
    
    lazy var soundTags: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Tag1 Tag2 Tag3"
        textField.borderStyle = .roundedRect
        return textField
    }()*/
    
    lazy var soundTagLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        return label
    }()
    
    lazy var chosenSoundTagLabel: UILabel = {
        let label = UILabel()
        label.text = "Add"
        label.textColor = color.blue()
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        return label
    }()
    
    /*lazy var soundTagButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 3
        button.layer.borderWidth = 1
        button.layer.borderColor = color.black().cgColor
        button.setTitleColor(color.black(), for: .normal)
        button.clipsToBounds = true
        return button
    }()
    
    lazy var genreTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 20)
        return label
    }()*/
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        if reuseIdentifier == "soundInfoReuse" {
            self.addSubview(soundArtLabel)
            self.addSubview(soundArt)
            self.addSubview(soundTitleLabel)
            self.addSubview(soundTitle)
            
            soundArtLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            soundArt.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(100)
                make.top.equalTo(self.soundArtLabel.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
             }
            
            soundTitleLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundArtLabel)
                make.left.equalTo(self.soundArt.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            soundTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundTitleLabel.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(soundTitleLabel)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
        } else if reuseIdentifier == "soundTagReuse" {
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
                make.bottom.equalTo(soundTagLabel)
            }
            
        } else {
           /* self.addSubview(genreTitle)
            genreTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }*/
        }
    }
    
    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

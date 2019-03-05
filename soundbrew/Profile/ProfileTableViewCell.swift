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
        label.text = "hey I'm dom and I like all types of music. Mostly hip-hop, electronic, and alt-rock. Hit me up for fyeeeeeee beats!"
        label.numberOfLines = 0
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
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 25)
        label.text = "100"
        label.textAlignment = .center 
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
    
    //EditProfile
    lazy var editProfileImage: UIImageView = {
        let image = UIImageView()
        image.backgroundColor = .lightGray
        image.layer.cornerRadius = 50
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.image = UIImage(named: "profile_icon")
        return image
    }()
    
    lazy var editProfileLabel: UILabel = {
        let label = UILabel()
        label.text = "Change Profile Photo"
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 17)
        label.textAlignment = .center
        label.textColor = color.black()
        return label
    }()
    
    lazy var editNameTitle: UILabel = {
        let label = UILabel()
        label.text = "Name"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = color.black()
        return label
    }()
    lazy var editNameText: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Name"
        textField.borderStyle = .roundedRect
        textField.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        textField.textColor = color.black()
        return textField
    }()
    
    lazy var editUsernameTitle: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = color.black()
        return label
    }()
    lazy var editUsernameText: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Username"
        textField.borderStyle = .roundedRect
        textField.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        textField.textColor = color.black()
        return textField
    }()
    
    lazy var editCityTitle: UILabel = {
        let label = UILabel()
        label.text = "City"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = color.black()
        return label
    }()
    lazy var editCityText: UITextField = {
        let textField = UITextField()
        textField.placeholder = "City"
        textField.borderStyle = .roundedRect
        textField.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        textField.textColor = color.black()
        return textField
    }()
    
    lazy var editBioTitle: UILabel = {
        let label = UILabel()
        label.text = "Bio"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = color.black()
        return label
    }()
    lazy var editBioText: UILabel = {
        let label = UILabel()
        label.text = "Add Bio"
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        label.numberOfLines = 0
        label.textColor = color.black()
        return label
    }()
    
    lazy var editWebsiteTitle: UILabel = {
        let label = UILabel()
        label.text = "Website"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = color.black()
        return label
    }()
    lazy var editWebsiteText: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Website"
        textField.borderStyle = .roundedRect
        textField.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        textField.textColor = color.black()
        return textField
    }()
    
    lazy var privateInformationLabel: UILabel = {
        let label = UILabel()
        label.text = "Private Information"
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        label.textColor = color.black()
        return label
    }()
    
    lazy var editEmailTitle: UILabel = {
        let label = UILabel()
        label.text = "Email"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = color.black()
        return label
    }()
    lazy var editEmailText: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.borderStyle = .roundedRect
        textField.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        textField.textColor = color.black()
        return textField
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let textFieldWidth = self.frame.width - 50
        
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
                //make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            followerCountLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(followerCount).offset(uiElement.elementOffset)
                make.left.equalTo(followerCount.snp.right).offset(uiElement.elementOffset)
                //make.right.equalTo(self)
            }
            
            actionButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(30)
                make.top.equalTo(followerCountLabel.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(followerCount)
                make.left.equalTo(followerCount)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            artistName.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistImage.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(artistImage).offset(uiElement.elementOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            artistCity.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistName.snp.bottom)
                make.left.equalTo(artistName)
                make.right.equalTo(artistName)
            }
            
            artistBio.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistCity.snp.bottom)
                make.left.equalTo(artistName)
                make.right.equalTo(artistName)
            }
            
            artistLink.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistBio.snp.bottom)
                make.left.equalTo(artistName)
                //make.right.equalTo(artistName)
                make.bottom.equalTo(self).offset(-(uiElement.elementOffset))
            }
    
            break
            
        case "editProfileImageReuse":
            self.addSubview(editProfileImage)
            self.addSubview(editProfileLabel)
            editProfileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(100)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self.frame.width / 2)
            }
            
            editProfileLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editProfileImage.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            break
            
        case "editProfileInfoReuse":
            self.addSubview(editNameTitle)
            self.addSubview(editNameText)
            /*self.addSubview(editUsernameTitle)
            self.addSubview(editUsernameText)
            self.addSubview(editCityTitle)
            self.addSubview(editCityText)
            self.addSubview(editWebsiteTitle)
            self.addSubview(editWebsiteText)
            self.addSubview(editBioTitle)
            self.addSubview(editBioText)*/
            
            
            editNameText.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(textFieldWidth)
                make.top.equalTo(self).offset(uiElement.topOffset)
                //make.left.equalTo(editNameTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            editNameTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editNameText)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(editNameText.snp.left).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            
            /*editNameText.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(textFieldWidth)
                make.top.equalTo(self).offset(uiElement.topOffset)
                //make.left.equalTo(editNameTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            editNameTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editNameText)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(editNameText.snp.left).offset(uiElement.rightOffset)
            }*/
            
            /*editUsernameText.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(textFieldWidth)
                make.top.equalTo(editNameText.snp.bottom).offset(uiElement.topOffset)
                //make.left.equalTo(editUsernameTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            editUsernameTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editUsernameText)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(editUsernameText.snp.left).offset(uiElement.rightOffset)
            }
            
            editCityText.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(textFieldWidth)
                make.top.equalTo(editUsernameText.snp.bottom).offset(uiElement.topOffset)
                //make.left.equalTo(editCityTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            editCityTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editCityText)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(editCityText.snp.left).offset(uiElement.rightOffset)
            }
            
            editWebsiteText.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(textFieldWidth)
                make.top.equalTo(editCityText.snp.bottom).offset(uiElement.topOffset)
                //make.left.equalTo(editWebsiteTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            editWebsiteTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editWebsiteText)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(editWebsiteText.snp.left).offset(uiElement.rightOffset)
            }

            editBioText.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(textFieldWidth)
                make.top.equalTo(editWebsiteText.snp.bottom).offset(uiElement.topOffset)
                //make.left.equalTo(editBioTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            editBioTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editBioText)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(editBioText.snp.left).offset(uiElement.rightOffset)
            }*/
            
            break
            
        case "editBioReuse":
            self.addSubview(editBioText)
            self.addSubview(editBioTitle)
            editBioText.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(textFieldWidth)
                make.top.equalTo(self).offset(uiElement.topOffset)
                //make.left.equalTo(editBioTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            editBioTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editBioText)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(editBioText.snp.left).offset(uiElement.rightOffset)
            }
            break
            
        case "editPrivateInfoReuse":
            self.addSubview(privateInformationLabel)
            self.addSubview(editEmailTitle)
            self.addSubview(editEmailText)
            
            privateInformationLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            editEmailText.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(textFieldWidth)
                make.top.equalTo(privateInformationLabel.snp.bottom).offset(uiElement.topOffset)
                //make.left.equalTo(editEmailTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            editEmailTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editEmailText)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(editEmailText.snp.left).offset(uiElement.rightOffset)
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

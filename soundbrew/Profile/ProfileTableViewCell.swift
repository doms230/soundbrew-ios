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
    
    var isSearchActive = false
    
    //profile
    lazy var profileImage: UIImageView = {
        let image = UIImageView()
        image.layer.borderWidth = 1
        image.layer.borderColor = UIColor.black.cgColor
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.image = UIImage(named: "profile_icon")
        image.backgroundColor = .white
        return image
    }()
    
    lazy var displayNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 17)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    lazy var username: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.numberOfLines = 0
        label.textColor = .white
        return label
    }()
    
    lazy var bio: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.numberOfLines = 0
        label.textColor = .white
        return label
    }()
    
    lazy var city: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.textColor = .darkGray
        label.numberOfLines = 0
        return label
    }()
    
    lazy var userCity: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.textColor = .darkGray
        return label
    }()
    
    lazy var website: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.textColor = color.blue()
        return label
    }()
    
    lazy var websiteView: UIButton = {
        let button = UIButton()
        button.setTitleColor(color.blue(), for: .normal)
        return button
    }()
    
    lazy var actionButton: UIButton = {
        let button = UIButton()
        button.setTitle("Loading", for: .normal)
        button.backgroundColor = .lightGray
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 17)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    lazy var newSoundButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .lightGray
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 17)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    lazy var seperatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderColor = UIColor.darkGray.cgColor
        view.layer.borderWidth = 0.5
        view.clipsToBounds = true
        return view
    }()
    
    //EditProfile
    lazy var editProfileLabel: UILabel = {
        let label = UILabel()
        label.text = "Change Profile Photo"
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 17)
        label.textAlignment = .center
        label.textColor = color.blue()
        return label
    }()
    
    lazy var editProfileTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = .lightGray
        return label
    }()
    lazy var editProfileInput: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        textField.textColor = .white
        textField.clearButtonMode = .whileEditing
        textField.tintColor = .white 
        return textField
    }()
    
    lazy var rightArrow: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "dismiss")
        return image
    }()
    
    lazy var editBioTitle: UILabel = {
        let label = UILabel()
        label.text = "Bio"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = .lightGray
        return label
    }()
    lazy var editBioText: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        label.textColor = .white
        return label
    }()
    
    lazy var privateInformationLabel: UILabel = {
        let label = UILabel()
        label.text = "Private Information"
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        label.textColor = .white 
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        switch reuseIdentifier {
        case "profileReuse":
            self.addSubview(profileImage)
            self.addSubview(displayNameLabel)
            self.addSubview(city)
            self.addSubview(bio)
            self.addSubview(websiteView)
            self.websiteView.addSubview(website)
            self.addSubview(actionButton)
            self.addSubview(seperatorLine)
            
            profileImage.layer.cornerRadius = 75/2
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(75)
                make.top.equalTo(self).offset(uiElement.elementOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            actionButton.snp.makeConstraints { (make) -> Void in
                make.centerY.equalTo(profileImage)
                make.left.equalTo(profileImage.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(profileImage.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(profileImage)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            city.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayNameLabel.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(displayNameLabel)
            }
            
            bio.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(city.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(displayNameLabel)
            }
            
            websiteView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(bio.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(displayNameLabel)
            }
            
            website.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(websiteView)
                make.left.equalTo(websiteView)
                make.right.equalTo(websiteView)
                make.bottom.equalTo(websiteView)
            }
            
            seperatorLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(website.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self)
            }
            
            break
            
        case "searchProfileReuse":
            self.addSubview(profileImage)
            self.addSubview(displayNameLabel)
            self.addSubview(city)
            self.addSubview(username)
            
            profileImage.layer.cornerRadius = 25
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(50)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            //username
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(profileImage).offset(uiElement.elementOffset)
                make.left.equalTo(profileImage.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            //city 
            username.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayNameLabel.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(displayNameLabel)
                //make.bottom.equalTo(self).offset(-(uiElement.elementOffset))
            }
            
            break
            
        case "searchTagViewReuse":
            self.addSubview(profileImage)
            self.addSubview(displayNameLabel)
            
            profileImage.layer.cornerRadius = 25
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(50)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            displayNameLabel.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 20)
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.centerY.equalTo(profileImage)
                make.left.equalTo(profileImage.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            break
            
        case "updatesReuse":
            self.addSubview(profileImage)
            self.addSubview(displayNameLabel)
            self.addSubview(username)
            self.addSubview(city)
            
            profileImage.layer.cornerRadius = 25
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(50)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            //person username
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(profileImage.snp.top)
                make.left.equalTo(profileImage.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            //message
            /*username.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayNameLabel)
                make.left.equalTo(displayNameLabel.snp.right)
                //make.right.equalTo(self).offset(uiElement.rightOffset)
            }*/
            
            city.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayNameLabel.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(self).offset(uiElement.rightOffset)
               // make.bottom.equalTo(self)
            }
            
            break
            
        case "settingsReuse":
            //self.addSubview(profileImage)
            self.addSubview(username)
            self.addSubview(displayNameLabel)
            self.addSubview(seperatorLine)
            
            /*profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(100)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }*/
            
            //Followers count, following count, earnings count, funds count
            displayNameLabel.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            // follower label, following label, earnings label, funds labele
            username.font = UIFont(name: "\(uiElement.mainFont)", size: 20)
            username.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayNameLabel.snp.bottom)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
               // make.bottom.equalTo(self).offset(uiE)
            }
            
            seperatorLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(username.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            break
            
        case "settingsTitleReuse":
            self.addSubview(seperatorLine)
            self.addSubview(displayNameLabel)
            displayNameLabel.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            seperatorLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(displayNameLabel.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            break
            
        case "editProfileImageReuse":
            self.addSubview(profileImage)
            self.addSubview(editProfileLabel)
            self.addSubview(seperatorLine)
            profileImage.layer.cornerRadius = 50
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(100)
                make.centerX.equalTo(self)
                make.top.equalTo(self).offset(uiElement.topOffset)
            }
            
            editProfileLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(profileImage.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            seperatorLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(editProfileLabel.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self)
            }
            break
            
        case "editProfileInfoReuse":
            self.addSubview(editProfileTitle)
            self.addSubview(editProfileInput)
            self.addSubview(seperatorLine)
            editProfileTitle.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(100)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                //make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            editProfileInput.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editProfileTitle)
                make.left.equalTo(editProfileTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            seperatorLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(editProfileInput.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(editProfileInput)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self)
            }
            
            break
        //TODO: see if this is still being used ... might need to delete
        case "editProfileCityReuse":
            self.addSubview(editProfileTitle)
            self.addSubview(userCity)
            self.addSubview(seperatorLine)
            editProfileTitle.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(100)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
               // make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            userCity.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editProfileTitle)
                make.left.equalTo(editProfileTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            seperatorLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(userCity.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(userCity)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self)
            }
            
            break
            
        case "editBioReuse":
            self.addSubview(editBioText)
            self.addSubview(editBioTitle)
            self.addSubview(rightArrow)
            self.addSubview(seperatorLine)
            editBioTitle.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(100)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                //make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            rightArrow.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(15)
                make.centerY.equalTo(self)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            editBioText.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editBioTitle)
                make.left.equalTo(editBioTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(rightArrow.snp.left).offset(uiElement.rightOffset)
                //make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            seperatorLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(editBioText.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(editBioText)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self)
            }

            break
            
        case "editPrivateInfoReuse":
            self.addSubview(privateInformationLabel)
            self.addSubview(editProfileTitle)
            self.addSubview(editProfileInput)
            self.addSubview(seperatorLine)
            privateInformationLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            editProfileTitle.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(100)
                make.top.equalTo(privateInformationLabel.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            editProfileInput.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editProfileTitle)
                make.left.equalTo(editProfileTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            seperatorLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(editProfileInput.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(editProfileInput)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self)
            }
            
            break
            
        case "earningsPaymentsReuse":
            self.addSubview(profileImage)
            self.addSubview(displayNameLabel)
            self.addSubview(bio)
            
            profileImage.layer.cornerRadius = 50/2
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(50)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            //artist name
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(profileImage)
                make.left.equalTo(profileImage.snp.right).offset(uiElement.elementOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            //Song Title
            bio.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayNameLabel.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(displayNameLabel)
            }
            break
            
            
        case "spaceReuse":
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

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
    
    lazy var uploadsButton: UIButton = {
        let button = UIButton()
        button.setTitle("Uploads", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 20)
        button.setTitleColor(color.black(), for: .normal)
        return button
    }()
    
    lazy var collectionButton: UIButton = {
        let button = UIButton()
        button.setTitle("Collection", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 20)
        button.setTitleColor(.lightGray, for: .normal)
        return button
    }()
    
    //profile
    lazy var profileImage: UIImageView = {
        let image = UIImageView()
        //image.layer.cornerRadius = 75/2
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.image = UIImage(named: "profile_icon")
        image.backgroundColor = color.darkGray()
        return image
    }()
    
    lazy var displayName: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 17)
        return label
    }()
    
    lazy var username: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.numberOfLines = 0
        return label
    }()
    
    lazy var city: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.textColor = .darkGray 
        return label
    }()
    
    lazy var website: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "website"), for: .normal)
        button.layer.cornerRadius = 25 / 2
        button.clipsToBounds = true
        return button
    }()
    
    lazy var instagramButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "instagram_logo"), for: .normal)
        button.layer.cornerRadius = 25 / 2
        button.clipsToBounds = true
        return button
    }()
    
    lazy var socialScrollview: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
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
    
    //EditProfile
    lazy var editProfileLabel: UILabel = {
        let label = UILabel()
        label.text = "Change Profile Photo"
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 17)
        label.textAlignment = .center
        label.textColor = color.black()
        return label
    }()
    
    lazy var editProfileTitle: UILabel = {
        let label = UILabel()
        label.text = "Name"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = .lightGray
        return label
    }()
    lazy var editProfileInput: UITextField = {
        let textField = UITextField()
        //textField.placeholder = "Name"
        textField.borderStyle = .none
        textField.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        textField.textColor = color.black()
        textField.clearButtonMode = .whileEditing
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
        label.numberOfLines = 0
        label.textColor = color.black()
        return label
    }()
    
    lazy var privateInformationLabel: UILabel = {
        let label = UILabel()
        label.text = "Private Information"
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        label.textColor = color.black()
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        switch reuseIdentifier {
        case "profileReuse":
            self.addSubview(profileImage)
            self.addSubview(displayName)
            self.addSubview(city)
            self.addSubview(username)
            
            profileImage.layer.cornerRadius = 50
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(100)
                make.top.equalTo(self).offset(uiElement.elementOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            displayName.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(profileImage).offset(uiElement.topOffset)
                make.left.equalTo(profileImage.snp.right).offset(uiElement.elementOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            username.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayName.snp.bottom)
                make.left.equalTo(displayName)
                make.right.equalTo(displayName)
                //make.bottom.equalTo(self).offset(-(uiElement.elementOffset))
            }
            
            city.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(username.snp.bottom)
                make.left.equalTo(displayName)
                make.right.equalTo(displayName)
            }
    
            break
            
        case "searchProfileReuse":
            self.addSubview(profileImage)
            self.addSubview(displayName)
            self.addSubview(city)
            self.addSubview(username)
            
            profileImage.layer.cornerRadius = 25
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(50)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            displayName.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(profileImage).offset(uiElement.elementOffset)
                make.left.equalTo(profileImage.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            username.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayName.snp.bottom)
                make.left.equalTo(displayName)
                make.right.equalTo(displayName)
                //make.bottom.equalTo(self).offset(-(uiElement.elementOffset))
            }
            
            break
            
        case "actionProfileReuse":
            self.addSubview(socialScrollview)
            self.addSubview(actionButton)
            actionButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(30)
                make.width.equalTo(100)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                //make.right.equalTo(profileImage.snp.right)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            socialScrollview.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(30)
                make.centerY.equalTo(actionButton)
                make.left.equalTo(actionButton.snp.right)
                make.right.equalTo(self)
            }
            break
            
        case "editProfileImageReuse":
            self.addSubview(profileImage)
            self.addSubview(editProfileLabel)
            
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
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            break
            
        case "editProfileInfoReuse":
            self.addSubview(editProfileTitle)
            self.addSubview(editProfileInput)
            
            editProfileTitle.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(100)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            editProfileInput.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editProfileTitle)
                make.left.equalTo(editProfileTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            break
            
        case "editBioReuse":
            self.addSubview(editBioText)
            self.addSubview(editBioTitle)
            self.addSubview(rightArrow)
            editBioTitle.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(80)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            rightArrow.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(15)
                make.centerY.equalTo(self)
                make.right.equalTo(self).offset(-(uiElement.elementOffset))
            }
            
            editBioText.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editBioTitle)
                make.left.equalTo(editBioTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(rightArrow.snp.left).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }

            break
            
        case "editPrivateInfoReuse":
            self.addSubview(privateInformationLabel)
            self.addSubview(editProfileTitle)
            self.addSubview(editProfileInput)
            
            privateInformationLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            editProfileTitle.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(80)
                make.top.equalTo(privateInformationLabel.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            editProfileInput.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editProfileTitle)
                make.left.equalTo(editProfileTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            break
            
        case "uploadsCollectionsHeaderReuse":
            self.addSubview(uploadsButton)
            self.addSubview(collectionButton)
            
            uploadsButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(35)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self)
            }
            
            collectionButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(35)
                make.top.equalTo(uploadsButton)
                make.left.equalTo(uploadsButton.snp.right).offset(uiElement.leftOffset + 10)
                make.bottom.equalTo(self)
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

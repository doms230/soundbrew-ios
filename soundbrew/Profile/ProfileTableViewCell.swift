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
    
    lazy var homebackgroundView: UIImageView = {
        let image = UIImageView()
        image.backgroundColor = .black
        image.layer.cornerRadius = 5
      //  image.layer.borderColor = color.purpleBlack().cgColor
       // image.layer.borderWidth = 0.5
        image.clipsToBounds = true
        return image
    }()
    
    lazy var shareButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "share"), for: .normal)
        return button
    }()
    
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search People"
        //searchBar.delegate = self
        if #available(iOS 13.0, *) {
            let searchTextField = searchBar.searchTextField
            searchTextField.backgroundColor = color.black()
            searchTextField.textColor = .white
        } else {
            let searchTextField = searchBar.value(forKey: "_searchField") as! UITextField
            searchTextField.backgroundColor = color.black()
            searchTextField.textColor = .white
        }
                
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        return searchBar
    }()
    
    //credits
    lazy var creditPercentage: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 15)
        label.textColor = .darkGray
        return label
    }()
    
    lazy var creditTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 15)
        label.numberOfLines = 0
        label.textColor = .darkGray
        return label
    }()
    
    //profile
    lazy var profileImage: UIImageView = {
        let image = UIImageView()
        image.layer.borderWidth = 1
        image.layer.borderColor = UIColor.darkGray.cgColor
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.image = UIImage(named: "profile_icon")
        image.backgroundColor = .black
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
        label.textColor = .darkGray
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
        let localizedLoading = NSLocalizedString("loading", comment: "")
        let button = UIButton()
        button.setTitle(localizedLoading, for: .normal)
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
        let localizedChangeProfilePhoto = NSLocalizedString("changeProfilePhoto", comment: "")
        let label = UILabel()
        label.text = localizedChangeProfilePhoto
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
        let localizedPrivateInformation = NSLocalizedString("privateInformation", comment: "")
        let label = UILabel()
        label.text = localizedPrivateInformation
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        label.textColor = .white 
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        switch reuseIdentifier {
            
        case "searchReuse":
            self.addSubview(searchBar)
            searchBar.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            break
            
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
            
        case "homeReuse":
           // self.addSubview(homebackgroundView)
            self.addSubview(profileImage)
            self.addSubview(displayNameLabel)
            self.addSubview(city)
            self.addSubview(username)
            self.addSubview(userCity)
            self.addSubview(seperatorLine)
           /* homebackgroundView.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(100)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }*/
            
            let imageHeightWidth = 50
            profileImage.layer.cornerRadius = CGFloat(imageHeightWidth/2)
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(imageHeightWidth)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            displayNameLabel.textColor = .white
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.centerY.equalTo(profileImage).offset(uiElement.bottomOffset)
                make.left.equalTo(profileImage.snp.right).offset(uiElement.elementOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            username.textColor = .darkGray
            username.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayNameLabel.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(displayNameLabel)
            }
            
            //date
            userCity.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
            userCity.textColor = .darkGray
            userCity.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(profileImage.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(username)
            }
            
            //latest update type
            city.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
            city.textColor = .darkGray
            city.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(userCity)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            seperatorLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(city.snp.bottom)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self)
            }
            
            break
            
        case "searchProfileReuse":
            self.addSubview(profileImage)
            self.addSubview(displayNameLabel)
            self.addSubview(username)
            
            profileImage.layer.cornerRadius = 25
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(50)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(profileImage).offset(uiElement.elementOffset)
                make.left.equalTo(profileImage.snp.right).offset(uiElement.elementOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            username.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayNameLabel.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(displayNameLabel)
            }
            
            break
            
        case "creditProfileReuse":
            self.addSubview(profileImage)
            self.addSubview(displayNameLabel)
            self.addSubview(username)
            self.addSubview(creditTitle)
            self.addSubview(creditPercentage)
            
            let profileImageHeightWidth = 75
            profileImage.layer.cornerRadius = CGFloat(profileImageHeightWidth / 2)
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(profileImageHeightWidth)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(profileImage).offset(uiElement.elementOffset)
                make.left.equalTo(profileImage.snp.right).offset(uiElement.elementOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            username.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayNameLabel.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(displayNameLabel)
            }
            
            creditTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(username.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(displayNameLabel)
            }
            
            creditPercentage.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(creditTitle.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(displayNameLabel)
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
            
            city.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayNameLabel.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            break
            
        case "settingsReuse":
            self.addSubview(username)
            self.addSubview(displayNameLabel)
            self.addSubview(seperatorLine)
            
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
            self.addSubview(shareButton)
            
            shareButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(25)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }

            displayNameLabel.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(shareButton.snp.left).offset(uiElement.rightOffset)
            }
            
            seperatorLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(shareButton.snp.bottom).offset(uiElement.topOffset)
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

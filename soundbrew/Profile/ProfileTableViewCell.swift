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
    
    var shareButton: UIButton!
    
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search People"
        searchBar.backgroundColor = color.black()
        searchBar.tintColor = .darkGray
        searchBar.backgroundImage = UIImage()
        //searchBar.delegate = self
        if #available(iOS 13.0, *) {
            let searchTextField = searchBar.searchTextField
            searchTextField.backgroundColor = color.black()
            searchTextField.tintColor = .darkGray
            searchTextField.textColor = .white
        } else {
            let searchTextField = searchBar.value(forKey: "_searchField") as! UITextField
            searchTextField.backgroundColor = color.black()
            searchTextField.tintColor = .darkGray
            searchTextField.textColor = .white
        }
                
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        return searchBar
    }()
    
    //credits
    var creditPercentage: UILabel!
    var creditTitle: UILabel!
    
    //profile
    var profileImage: UIImageView!
    var displayNameLabel: UILabel!
    var username: UILabel!
    var bio: UILabel!
    var city: UILabel!
    var website: UILabel!
    var websiteView: UIButton!
    var actionButton: UIButton!
    var editProfileLabel: UILabel!
    var editProfileTitle: UILabel!
    var rightArrow: UIImageView!
    var editBioTitle: UILabel!
    var editBioText: UILabel!
    var privateInformationLabel: UILabel!
    
    lazy var seperatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderColor = UIColor.darkGray.cgColor
        view.layer.borderWidth = 0.5
        view.clipsToBounds = true
        return view
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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        profileImage = uiElement.soundbrewImageView(UIImage(named: "profile_icon"), cornerRadius: nil, backgroundColor: nil)
        profileImage.layer.borderWidth = 1
        profileImage.layer.borderColor = color.purpleBlack().cgColor
        profileImage.clipsToBounds = true
        profileImage.backgroundColor = .black
        
        displayNameLabel = uiElement.soundbrewLabel(nil, textColor: .white, font: UIFont(name: "\(uiElement.mainFont)-Bold", size: 17)!, numberOfLines: 0)
        
        username = uiElement.soundbrewLabel(nil, textColor: .darkGray, font: UIFont(name: uiElement.mainFont, size: 17)!, numberOfLines: 0)
        
        city = uiElement.soundbrewLabel(nil, textColor: .darkGray, font: UIFont(name: uiElement.mainFont, size: 17)!, numberOfLines: 0)
        
        editProfileTitle = uiElement.soundbrewLabel(nil, textColor: .lightGray, font: UIFont(name: "\(uiElement.mainFont)", size: 17)!, numberOfLines: 0)
        
        switch reuseIdentifier {
            
        case "searchReuse":
            self.addSubview(searchBar)
            searchBar.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self)
            }
            break
            
        case "profileReuse":
            self.addSubview(profileImage)
            profileImage.layer.cornerRadius = 75/2
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(75)
                make.top.equalTo(self).offset(uiElement.elementOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            let localizedLoading = NSLocalizedString("loading", comment: "")
            actionButton = uiElement.soundbrewButton(localizedLoading, shouldShowBorder: false, backgroundColor: .lightGray, image: nil, titleFont: UIFont(name: uiElement.mainFont, size: 17), titleColor: .white, cornerRadius: 3)
            self.addSubview(actionButton)
            actionButton.snp.makeConstraints { (make) -> Void in
                make.centerY.equalTo(profileImage)
                make.left.equalTo(profileImage.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(displayNameLabel)
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(profileImage.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(profileImage)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(city)
            city.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayNameLabel.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(displayNameLabel)
            }
            
            bio = uiElement.soundbrewLabel(nil, textColor: .white, font: UIFont(name: uiElement.mainFont, size: 17)!, numberOfLines: 0)
            self.addSubview(bio)
            bio.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(city.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(displayNameLabel)
            }
            
            websiteView = uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: .clear, image: nil, titleFont: nil, titleColor: color.blue(), cornerRadius: 0)
            self.addSubview(websiteView)
            websiteView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(bio.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(displayNameLabel)
            }
            
            website = uiElement.soundbrewLabel(nil, textColor: color.blue(), font: UIFont(name: uiElement.mainFont, size: 17)!, numberOfLines: 0)
            self.websiteView.addSubview(website)
            website.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(websiteView)
                make.left.equalTo(websiteView)
                make.right.equalTo(websiteView)
                make.bottom.equalTo(websiteView)
            }
            
            self.addSubview(seperatorLine)
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
            profileImage.layer.cornerRadius = 25
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(50)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            self.addSubview(displayNameLabel)
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(profileImage).offset(uiElement.elementOffset)
                make.left.equalTo(profileImage.snp.right).offset(uiElement.elementOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(username)
            username.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayNameLabel.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(displayNameLabel)
            }
            
            break
            
        case "creditProfileReuse":
            let profileImageHeightWidth = 75
            profileImage.layer.cornerRadius = CGFloat(profileImageHeightWidth / 2)
            self.addSubview(profileImage)
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(profileImageHeightWidth)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            self.addSubview(displayNameLabel)
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(profileImage).offset(uiElement.elementOffset)
                make.left.equalTo(profileImage.snp.right).offset(uiElement.elementOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(username)
            username.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayNameLabel.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(displayNameLabel)
            }
            
            creditTitle = uiElement.soundbrewLabel(nil, textColor: .darkGray, font: UIFont(name: uiElement.mainFont, size: 15)!, numberOfLines: 0)
            self.addSubview(creditTitle)
            creditTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(username.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(displayNameLabel)
            }
            
            creditPercentage = uiElement.soundbrewLabel(nil, textColor: .darkGray, font: UIFont(name: uiElement.mainFont, size: 15)!, numberOfLines: 0)
            self.addSubview(creditPercentage)
            creditPercentage.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(creditTitle.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(displayNameLabel)
            }
            break
            
        case "searchTagViewReuse":
            self.addSubview(profileImage)
            profileImage.layer.cornerRadius = 25
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(50)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            self.addSubview(displayNameLabel)
            displayNameLabel.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 20)
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.centerY.equalTo(profileImage)
                make.left.equalTo(profileImage.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            break
            
        case "mentionsReuse":
            self.addSubview(profileImage)
            profileImage.layer.cornerRadius = 25
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(50)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            //person username
             self.addSubview(displayNameLabel)
            displayNameLabel.font = UIFont(name: "\(uiElement.mainFont)", size: 15)
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(profileImage.snp.top)
                make.left.equalTo(profileImage.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(city)
            city.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayNameLabel.snp.bottom)
                make.left.equalTo(displayNameLabel)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            break
            
        case "settingsReuse":
            //Followers count, following count, earnings count, funds count
            self.addSubview(displayNameLabel)
            displayNameLabel.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            // follower label, following label, earnings label, funds labele
            self.addSubview(username)
            username.font = UIFont(name: "\(uiElement.mainFont)", size: 20)
            username.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(displayNameLabel.snp.bottom)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
             self.addSubview(seperatorLine)
            seperatorLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(username.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            break
            
        case "settingsTitleReuse":
            shareButton = uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: .clear, image: UIImage(named: "share"), titleFont: nil, titleColor: .white, cornerRadius: nil)
            self.addSubview(shareButton)
            shareButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(25)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }

            self.addSubview(displayNameLabel)
            displayNameLabel.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
            displayNameLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(shareButton.snp.left).offset(uiElement.rightOffset)
            }
            
            self.addSubview(seperatorLine)
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
            profileImage.layer.cornerRadius = 50
            profileImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(100)
                make.centerX.equalTo(self)
                make.top.equalTo(self).offset(uiElement.topOffset)
            }
            
            let localizedChangeProfilePhoto = NSLocalizedString("changeProfilePhoto", comment: "")
            editProfileLabel = uiElement.soundbrewLabel(localizedChangeProfilePhoto, textColor: color.blue(), font: UIFont(name: "\(uiElement.mainFont)-Bold", size: 17)!, numberOfLines: 0)
            editProfileLabel.textAlignment = .center
            self.addSubview(editProfileLabel)
            editProfileLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(profileImage.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(seperatorLine)
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
            editProfileTitle.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(100)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            self.addSubview(editProfileInput)
            editProfileInput.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editProfileTitle)
                make.left.equalTo(editProfileTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(seperatorLine)
            seperatorLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(editProfileInput.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(editProfileInput)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self)
            }
            
            break
            
        case "editBioReuse":
            editBioTitle = uiElement.soundbrewLabel("Bio", textColor: .lightGray, font: UIFont(name: "\(uiElement.mainFont)", size: 17)!, numberOfLines: 0)
            self.addSubview(editBioTitle)
            editBioTitle.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(100)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            rightArrow = uiElement.soundbrewImageView(UIImage(named: "dismiss"), cornerRadius: nil, backgroundColor: nil)
            self.addSubview(rightArrow)
            rightArrow.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(15)
                make.centerY.equalTo(self)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            editBioText = uiElement.soundbrewLabel(nil, textColor: .white, font: UIFont(name: "\(UIElement().mainFont)", size: 17)!, numberOfLines: 0)
            self.addSubview(editBioText)
            editBioText.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editBioTitle)
                make.left.equalTo(editBioTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(rightArrow.snp.left).offset(uiElement.rightOffset)
            }
            
            self.addSubview(seperatorLine)
            seperatorLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(editBioText.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(editBioText)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self)
            }

            break
            
        case "editPrivateInfoReuse":
            let localizedPrivateInformation = NSLocalizedString("privateInformation", comment: "")
            privateInformationLabel = uiElement.soundbrewLabel(localizedPrivateInformation, textColor: .white, font: UIFont(name: "\(uiElement.mainFont)-bold", size: 17)!, numberOfLines: 0)
            self.addSubview(privateInformationLabel)
            privateInformationLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(editProfileTitle)
            editProfileTitle.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(100)
                make.top.equalTo(privateInformationLabel.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            self.addSubview(editProfileInput)
            editProfileInput.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(editProfileTitle)
                make.left.equalTo(editProfileTitle.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(seperatorLine)
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

//
//  HomeCollectionViewCell.swift
//  soundbrew
//
//  Created by Dominic  Smith on 3/9/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit

class StoryCollectionViewCell: UICollectionViewCell {
    
    let uiElement = UIElement()
    let color = Color()
    
    lazy var view: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .clear
        view.layer.borderWidth = 0.5
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }()
    
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
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 18)
        label.textColor = .white
        label.textAlignment = .center
        //label.numberOfLines = 2
        return label
    }()
    
    lazy var username: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 18)
        label.textColor = .lightGray
        label.textAlignment = .center
        return label
    }()
    
    lazy var storyType: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 16)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    lazy var storyCreatedAt: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 16)
        label.textColor = .lightGray
        label.textAlignment = .center
        return label
    }()
    
    lazy var loadStorySpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .white
        spinner.isHidden = true
        return spinner
    }()
       
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(view)
        view.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self).offset(uiElement.topOffset)
            make.left.equalTo(self).offset(uiElement.leftOffset)
            make.right.equalTo(self).offset(uiElement.rightOffset)
            make.bottom.equalTo(self).offset(uiElement.bottomOffset)
        }
        
        self.view.addSubview(profileImage)
        let profileImageHeightWidth = 100
        profileImage.layer.cornerRadius = CGFloat(profileImageHeightWidth / 2)
        profileImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(profileImageHeightWidth)
            make.top.equalTo(view).offset(uiElement.topOffset)
            make.centerX.equalTo(view)
        }
        
        self.view.addSubview(loadStorySpinner)
        loadStorySpinner.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(profileImageHeightWidth)
            make.centerY.centerX.equalTo(profileImage)
        }
        
        self.view.addSubview(displayNameLabel)
        displayNameLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(profileImage.snp.bottom)
            make.left.equalTo(view).offset(uiElement.leftOffset)
            make.right.equalTo(view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(username)
        username.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(displayNameLabel.snp.bottom)
            make.left.equalTo(view).offset(uiElement.leftOffset)
            make.right.equalTo(view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(storyType)
        storyType.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(username.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(view).offset(uiElement.leftOffset)
            make.right.equalTo(view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(storyCreatedAt)
        storyCreatedAt.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(storyType.snp.bottom)
            make.left.equalTo(view).offset(uiElement.leftOffset)
            make.right.equalTo(view).offset(uiElement.rightOffset)
        }
    }
    
    override func prepareForReuse() {
         super.prepareForReuse()
     }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
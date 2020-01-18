//
//  HomeCollectionViewCell.swift
//  soundbrew
//
//  Created by Dominic Smith on 1/13/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit

class HomeCollectionViewCell: UICollectionViewCell {
    
    let uiElement = UIElement()
    let color = Color()
    
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
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = .white
        label.textAlignment = .center
        //label.numberOfLines = 0
        return label
    }()
    
    lazy var username: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.textColor = .darkGray
        label.textAlignment = .center
        return label
    }()
    
   
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(profileImage)
        let imageHeightWidth = frame.width / 2 + 50
        profileImage.layer.cornerRadius = CGFloat(imageHeightWidth / 2)
        profileImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(imageHeightWidth)
            make.top.equalTo(self).offset(uiElement.topOffset)
            make.centerX.equalTo(self)
        }
        
        self.addSubview(displayNameLabel)
        displayNameLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(profileImage.snp.bottom)
            make.left.equalTo(self).offset(uiElement.leftOffset)
            make.right.equalTo(self).offset(uiElement.rightOffset)
           // make.center.equalTo(self)
        }
        
        self.addSubview(username)
        username.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(displayNameLabel.snp.bottom)
            make.left.equalTo(self).offset(uiElement.leftOffset)
            make.right.equalTo(self).offset(uiElement.rightOffset)
            make.bottom.equalTo(self).offset(uiElement.bottomOffset)
        }
    }
    
    override func prepareForReuse() {
         super.prepareForReuse()
     }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

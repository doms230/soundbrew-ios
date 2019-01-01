//
//  MySoundsTableViewCell.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/11/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit

class MySoundsTableViewCell: UITableViewCell {

    let uiElement = UIElement()
    let color = Color()
    
    lazy var soundArtImage: UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = 3
        image.clipsToBounds = true
        return image
    }()
    
    lazy var soundCreatedAt: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 15)
        return label
    }()
    
    lazy var soundTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        return label
    }()
    
    lazy var soundPlays: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        return label
    }()
    
    lazy var soundTags: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        label.textColor = .darkGray
        return label
    }()
    
    lazy var menuButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "menu"), for: .normal)
        return button 
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.addSubview(menuButton)
        self.addSubview(soundArtImage)
        self.addSubview(soundCreatedAt)
        self.addSubview(soundTitle)
        self.addSubview(soundTags)
        self.addSubview(soundPlays)
        
        menuButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self).offset(uiElement.topOffset)
            make.right.equalTo(self).offset(uiElement.rightOffset)
        }
        
        soundCreatedAt.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(menuButton)
            make.left.equalTo(self).offset(uiElement.leftOffset)
            make.right.equalTo(menuButton.snp.left).offset(uiElement.rightOffset)
        }
        
        soundArtImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(100)
            make.top.equalTo(soundCreatedAt.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(self).offset(uiElement.leftOffset)
            make.bottom.equalTo(self).offset(uiElement.bottomOffset)
        }
        
        soundTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(soundArtImage).offset(uiElement.elementOffset)
            make.left.equalTo(soundArtImage.snp.right).offset(uiElement.elementOffset)
            make.right.equalTo(self).offset(uiElement.rightOffset)
        }
        
        soundPlays.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(soundTitle.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(soundTitle).offset(uiElement.elementOffset)
            make.right.equalTo(self).offset(uiElement.rightOffset)
        }
        
        soundTags.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(soundPlays.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(soundTitle).offset(uiElement.elementOffset)
            make.right.equalTo(self).offset(uiElement.rightOffset)
        }
    }
    
    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

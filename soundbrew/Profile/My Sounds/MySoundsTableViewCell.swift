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
    
    lazy var playFilterScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    lazy var playButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "playIcon"), for: .normal)
        button.setTitle(" Play", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 20)
        button.setTitleColor(color.black(), for: .normal)
        button.backgroundColor = .lightGray
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    lazy var filterLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 20)
        label.text = "Filter"
        return label
    }()
    
    lazy var soundArtImage: UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = 3
        image.clipsToBounds = true
        return image
    }()
    
    lazy var soundTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        return label
    }()
    
    lazy var soundArtist: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        return label
    }()
    
    lazy var soundPlaysImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "playIcon")
        return image
    }()
    
    lazy var soundPlays: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 15)
        return label
    }()
    
    lazy var menuButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "menu"), for: .normal)
        return button 
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        switch reuseIdentifier {
        case "playFilterReuse":
            self.addSubview(playButton)
            self.addSubview(filterLabel)
            
            playButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(40)
                make.width.equalTo(100)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            filterLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(playButton).offset(uiElement.elementOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            break
            
        case "reuse":
            self.addSubview(menuButton)
            self.addSubview(soundArtImage)
            self.addSubview(soundTitle)
            self.addSubview(soundArtist)
            self.addSubview(soundPlaysImage)
            self.addSubview(soundPlays)
            
            soundArtImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(100)
                make.top.equalTo(self).offset(uiElement.elementOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            menuButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(25)
                make.top.equalTo(soundArtImage)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            soundTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundArtImage).offset(uiElement.elementOffset)
                make.left.equalTo(soundArtImage.snp.right).offset(uiElement.elementOffset)
                make.right.equalTo(menuButton.snp.left).offset(-(uiElement.elementOffset))
            }
            
            soundArtist.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundTitle.snp.bottom)
                make.left.equalTo(soundTitle)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            soundPlaysImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(25)
                make.top.equalTo(soundArtist.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(soundTitle)
                //make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            soundPlays.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundPlaysImage).offset(2)
                make.left.equalTo(soundPlaysImage.snp.right)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                //make.bottom.equalTo(self).offset(uiElement.bottomOffset)
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
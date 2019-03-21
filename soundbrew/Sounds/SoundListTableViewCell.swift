//
//  MySoundsTableViewCell.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/11/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit

class SoundListTableViewCell: UITableViewCell {

    let uiElement = UIElement()
    let color = Color()
    
    lazy var dividerLine: UIView = {
        let line = UIView()
        line.layer.borderWidth = 1
        line.layer.borderColor = color.uicolorFromHex(0xcccccc).cgColor
        //profileCell.actionButton.layer.borderWidth = 1
        //profileCell.actionButton.layer.borderColor = color.black().cgColor
        return line
    }()
    
    lazy var headerTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 20)
        return label
    }()
    
    lazy var viewButton: UIButton = {
        let button = UIButton()
        button.setTitle("View All", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)", size: 20)
        button.setTitleColor(color.blue(), for: .normal)
        return button
    }()
    
    lazy var tagsScrollview: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    lazy var uploadsbutton: UIButton = {
        let button = UIButton()
        button.setTitle("Uploads", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 25)
        button.setTitleColor(color.black(), for: .normal)
        return button
    }()
    
    lazy var likesButton: UIButton = {
        let button = UIButton()
        button.setTitle("Likes", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 25)
        button.setTitleColor(.darkGray, for: .normal)
        return button
    }()
    
    lazy var playFilterScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    lazy var soundArtImage: UIImageView = {
        let image = UIImageView()
        return image
    }()
    
    lazy var soundTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        return label
    }()
    
    lazy var soundArtist: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 15)
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
        case "noSoundsReuse":
            self.addSubview(headerTitle)
            headerTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            break
            
        case "profileSoundsReuse":
            self.addSubview(menuButton)
            self.addSubview(soundArtImage)
            self.addSubview(soundTitle)
            self.addSubview(soundArtist)
            self.addSubview(soundPlaysImage)
            self.addSubview(soundPlays)
            self.addSubview(headerTitle)
            self.addSubview(viewButton)
            
            viewButton.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            headerTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(5)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                //make.right.equalTo(self.viewButton.snp.left).offset(-(uiElement.elementOffset))
            }
            
            soundArtImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(100)
                make.top.equalTo(self.headerTitle.snp.bottom).offset(uiElement.topOffset)
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
            
        case "reuse":
            self.addSubview(menuButton)
            self.addSubview(soundArtImage)
            self.addSubview(soundTitle)
            self.addSubview(soundArtist)
            self.addSubview(soundPlaysImage)
            self.addSubview(soundPlays)
            self.addSubview(dividerLine)
            
            soundArtImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(100)
                make.top.equalTo(self)
                make.left.equalTo(self).offset(uiElement.leftOffset)
               // make.bottom.equalTo(self).offset(-(uiElement.elementOffset))
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
            
            dividerLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(1)
                make.top.equalTo(soundArtImage.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(-(uiElement.elementOffset))
            }
            
            break
            
        case "uploadsLikesReuse":
            self.addSubview(uploadsbutton)
            self.addSubview(likesButton)
            
            uploadsbutton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(35)
               // make.width.equalTo(150)
                make.top.equalTo(self).offset(uiElement.elementOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            likesButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(35)
                //make.width.equalTo(150)
                make.top.equalTo(self).offset(uiElement.elementOffset)
                make.left.equalTo(uploadsbutton.snp.right).offset(uiElement.leftOffset + 10)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
        
            break
            
        case "filterTagsReuse":
            self.addSubview(tagsScrollview)
            tagsScrollview.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(40)
                make.top.equalTo(self)
                make.left.equalTo(self)
                make.right.equalTo(self)
                make.bottom.equalTo(self)
            }
            break
            
        case "noFilterTagsReuse":
            self.addSubview(headerTitle)
            headerTitle.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(40)
                make.top.equalTo(self).offset(uiElement.elementOffset)
                make.left.equalTo(self)
                make.right.equalTo(self)
                make.bottom.equalTo(self).offset(-(uiElement.elementOffset))
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

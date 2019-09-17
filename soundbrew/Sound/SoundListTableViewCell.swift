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
    
    //mark: no sounds
    lazy var headerTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 20)
        label.numberOfLines = 0
        label.textColor = .white
        return label
    }()
    
    //filter new/popular
    lazy var newButton: UIButton = {
        let button = UIButton()
        button.setTitle("Recent", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    lazy var popularButton: UIButton = {
        let button = UIButton()
        button.setTitle("Top", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        button.setTitleColor(.darkGray, for: .normal)
        return button
    }()
    
    lazy var tagsScrollview: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    //mark: sounds
    lazy var dividerLine: UIView = {
        let line = UIView()
        line.layer.borderWidth = 1
        line.layer.borderColor = color.black().cgColor
        return line
    }()
    
    lazy var artistButton: UIButton = {
        let button = UIButton()
        return button
    }()
    
    lazy var artistImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "profile_icon")
        image.layer.cornerRadius = 35 / 2
        image.clipsToBounds = true
        return image
    }()
    
    lazy var artistLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 15)
        label.textColor = .white
        return label
    }()
    
    lazy var soundArtImage: UIImageView = {
        let image = UIImageView()
        image.layer.borderWidth = 1
        image.layer.borderColor = UIColor.black.cgColor
        image.layer.cornerRadius = 3
        image.clipsToBounds = true
        image.contentMode = ContentMode.scaleAspectFill
        return image
    }()
    
    lazy var soundTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 16)
        label.textColor = .white
        return label
    }()
    
    lazy var soundDate: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 15)
        label.textColor = color.darkGray()
        return label
    }()
    
    lazy var menuButton: UIButton = {
        let button = UIButton()
        return button 
    }()
    
    lazy var menuImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "more")
        return image
    }()
    
    lazy var collectorsButton: UIButton = {
        let button = UIButton()
        return button
    }()
    
    lazy var collectorsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 15)
        label.textColor = .white
        return label
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
            
        case "soundReuse":
            self.addSubview(artistButton)
            self.artistButton.addSubview(artistImage)
            self.artistButton.addSubview(artistLabel)
            
            self.addSubview(soundArtImage)
            self.addSubview(soundTitle)
            self.addSubview(artistLabel)
            self.addSubview(soundDate)
            self.addSubview(dividerLine)
            
            //adding seperate stuff because doesn't size right as one button.
            self.addSubview(collectorsButton)
            self.collectorsButton.addSubview(collectorsLabel)
            
            soundArtImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(125)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            soundTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundArtImage)
                make.left.equalTo(soundArtImage.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            soundDate.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundTitle.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(soundTitle)
                make.right.equalTo(soundTitle)
            }
            
            artistButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(35)
                make.top.equalTo(soundDate.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(soundTitle)
                make.right.equalTo(soundTitle)
            }
            artistImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(35)
                make.top.equalTo(artistButton)
                make.left.equalTo(artistButton)
            }
            
            artistLabel.snp.makeConstraints { (make) -> Void in
                make.centerY.equalTo(artistImage)
                make.left.equalTo(artistImage.snp.right).offset(uiElement.elementOffset)
                make.right.equalTo(artistButton)
            }
            collectorsButton.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistButton.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(soundTitle)
                make.right.equalTo(soundTitle)
            }
            
            collectorsLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(collectorsButton)
                make.left.equalTo(collectorsButton)
                make.right.equalTo(collectorsButton)
            }
            
            break
            
        case "shareReuse":
            self.addSubview(menuButton)
            self.addSubview(soundArtImage)
            self.addSubview(soundTitle)
            
            soundArtImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(25)
                make.top.equalTo(self)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            menuButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(15)
                make.top.equalTo(soundArtImage)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            soundTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundArtImage).offset(uiElement.elementOffset)
                make.left.equalTo(soundArtImage.snp.right).offset(uiElement.elementOffset)
                make.right.equalTo(menuButton.snp.left).offset(-(uiElement.elementOffset))
            }
            
            break
            
        case "tagsReuse":
            self.addSubview(tagsScrollview)
            tagsScrollview.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(35)
                make.top.equalTo(self)
                make.left.equalTo(self)
                make.right.equalTo(self)
                make.bottom.equalTo(self)
            }
            break
            
        case "filterSoundsReuse":
            self.addSubview(newButton)
            self.addSubview(popularButton)
            
            newButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(35)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            popularButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(35)
                make.top.equalTo(newButton)
                make.left.equalTo(newButton.snp.right).offset(uiElement.leftOffset + 10)
                make.bottom.equalTo(newButton)
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

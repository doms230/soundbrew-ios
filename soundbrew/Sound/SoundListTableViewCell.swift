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
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        label.numberOfLines = 0
        return label
    }()
    
    //filter new/popular
    lazy var newButton: UIButton = {
        let button = UIButton()
        button.setTitle("Recent", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        button.setTitleColor(color.black(), for: .normal)
        return button
    }()
    
    lazy var popularButton: UIButton = {
        let button = UIButton()
        button.setTitle("Top", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        button.setTitleColor(.lightGray, for: .normal)
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
        line.layer.borderColor = color.darkGray().cgColor
        return line
    }()
    
    lazy var soundArtImage: UIImageView = {
        let image = UIImageView()
        image.layer.borderWidth = 1
        image.layer.borderColor = color.darkGray().cgColor
        image.layer.cornerRadius = 3
        image.clipsToBounds = true
        image.contentMode = ContentMode.scaleAspectFill
        return image
    }()
    
    lazy var soundTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 16)
        label.numberOfLines = 2
        return label
    }()
    
    lazy var soundArtist: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 15)
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
            self.addSubview(menuButton)
            self.menuButton.addSubview(menuImage)
            self.addSubview(soundArtImage)
            self.addSubview(soundTitle)
            self.addSubview(soundArtist)
            self.addSubview(soundDate)
            self.addSubview(dividerLine)
            
            soundArtImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(100)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            soundTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundArtImage)
                make.left.equalTo(soundArtImage.snp.right).offset(uiElement.elementOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            soundArtist.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundTitle.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(soundTitle)
                make.right.equalTo(soundTitle)
            }
            
            soundDate.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundArtist.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(soundTitle)
                make.right.equalTo(soundTitle)
            }
            
            dividerLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(1)
                make.top.equalTo(soundArtImage.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self)
            }
            
            menuButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(75)
                make.top.equalTo(soundArtImage.snp.bottom).offset(uiElement.bottomOffset - 10)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            menuImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(15)
                make.top.equalTo(menuButton)
                make.right.equalTo(menuButton)
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

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
    
    //mark: header
    lazy var headerImage: UIImageView = {
        let image = UIImageView()
        return image
    }()
    
    lazy var playButton: UIButton = {
        let localizedPlay = NSLocalizedString("play", comment: "")
        let button = UIButton()
        button.setTitle(localizedPlay, for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 30)
        button.setTitleColor(color.black(), for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        return button
    }()
    
    //mark: no sounds
    lazy var headerTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 20)
        label.numberOfLines = 0
        label.textColor = .white
        return label
    }()
    
    //filter new/popular
    let localizedTags = NSLocalizedString("tags", comment: "")
    lazy var searchTagsButton: UIButton = {
        let button = UIButton()
        button.setTitle(localizedTags, for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    lazy var searchArtistsButton: UIButton = {
        let localizedArtists = NSLocalizedString("artists", comment: "")
        let button = UIButton()
        button.setTitle(localizedArtists, for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        button.setTitleColor(.darkGray, for: .normal)
        return button
    }()
    
    lazy var searchSoundsButton: UIButton = {
        let localizedSounds = NSLocalizedString("sounds", comment: "")
        let button = UIButton()
        button.setTitle(localizedSounds, for: .normal)
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
        line.layer.borderColor = UIColor.darkGray.cgColor
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
        image.backgroundColor = .black 
        return image
    }()
    
    lazy var artistLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 16)
        label.textColor = .white
        return label
    }()
    
    lazy var soundArtImage: UIImageView = {
        let image = UIImageView()
        image.layer.borderWidth = 1
        image.layer.borderColor = UIColor.black.cgColor
        image.layer.cornerRadius = 5
        image.clipsToBounds = true
        image.contentMode = ContentMode.scaleAspectFill
        return image
    }()
    
    lazy var soundTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 18)
        label.textColor = .white
        label.backgroundColor = color.black().withAlphaComponent(0.5)
        label.numberOfLines = 2
        return label
    }()
    
    lazy var soundDate: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        label.textColor = .darkGray
         label.backgroundColor = color.black().withAlphaComponent(0.5)
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
    
    lazy var likesButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "sendTipColored"), for: .normal)
        return button
    }()
    
    lazy var likesCountLabel: UILabel = {
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
            
        case "soundHeaderReuse":
            self.addSubview(headerImage)
            self.addSubview(playButton)
            headerImage.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(150)
                make.top.equalTo(self)
                make.left.equalTo(self)
                make.right.equalTo(self)
                make.bottom.equalTo(self)
            }
            
            playButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(50)
                make.width.equalTo(100)
                make.centerY.centerX.equalTo(headerImage)
            }
            break
            
        case "soundReuse":
            self.addSubview(menuButton)
            self.menuButton.addSubview(menuImage)
            
            self.addSubview(artistButton)
            self.artistButton.addSubview(artistImage)
            self.artistButton.addSubview(artistLabel)
            
            self.addSubview(soundArtImage)
            self.addSubview(soundTitle)
            self.addSubview(artistLabel)
            self.addSubview(soundDate)
            self.addSubview(dividerLine)
            
            //adding seperate stuff because doesn't size right as one button.
            self.addSubview(likesButton)
            self.likesButton.addSubview(likesCountLabel)
            
            soundArtImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(125)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            menuButton.snp.makeConstraints { (make) -> Void in
                make.width.height.equalTo(50)
                make.right.equalTo(self)
            }
            
            menuImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(15)
                make.center.equalTo(menuButton)
            }
            
            artistButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(35)
                make.top.equalTo(soundArtImage)
                make.left.equalTo(soundArtImage.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(menuButton.snp.left).offset(uiElement.leftOffset)
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
            
            menuButton.snp.makeConstraints { (make) -> Void in
                make.width.height.equalTo(50)
                make.centerY.equalTo(artistButton)
            }
            
            dividerLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                //make.top.equalTo(soundDate.snp.bottom)
                make.left.equalTo(soundTitle)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(soundArtImage)
            }
            
            soundDate.snp.makeConstraints { (make) -> Void in
               // make.top.equalTo(soundTitle.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(soundTitle)
                make.right.equalTo(soundTitle)
                make.bottom.equalTo(dividerLine.snp.top)
            }
            
            likesButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(15)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(soundDate)
            }
            
            /*likesCountLabel.snp.makeConstraints { (make) -> Void in
                make.right.equalTo(likesButton)
                make.bottom.equalTo(likesButton)
            }*/
            
            soundTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistButton.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(soundArtImage.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(soundDate.snp.top).offset(uiElement.bottomOffset)
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
            self.addSubview(searchTagsButton)
            self.addSubview(searchArtistsButton)
            self.addSubview(searchSoundsButton)
            searchTagsButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(35)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            searchArtistsButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(35)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(searchTagsButton.snp.right).offset(uiElement.leftOffset + 10)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            searchSoundsButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(35)
                make.top.equalTo(searchArtistsButton)
                make.left.equalTo(searchArtistsButton.snp.right).offset(uiElement.leftOffset + 10)
                make.bottom.equalTo(searchArtistsButton)
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

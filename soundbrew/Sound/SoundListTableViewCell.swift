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
    
    //mark: no sounds
    var headerTitle: UILabel!
    
    //filter new/popular
    var searchTagsButton: UIButton!
    var searchArtistsButton: UIButton!
    var searchSoundsButton: UIButton!
    
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
    
    var artistButton: UIButton!
    var artistImage: UIImageView!
    var artistLabel: UILabel!
    var soundArtImage: UIImageView!
    var soundTitle: UILabel!
    var soundDate: UILabel!
    var menuButton: UIButton!
    var menuImage: UIImageView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let uiElement = UIElement()
        let color = Color()
        
        artistButton = uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: .clear, image: nil, titleFont: nil, titleColor: .white, cornerRadius: nil)
        soundTitle = uiElement.soundbrewLabel(nil, textColor: .white, font: UIFont(name: "\(UIElement().mainFont)-bold", size: 18)!, numberOfLines: 2)
        soundDate = uiElement.soundbrewLabel(nil, textColor: .darkGray, font: UIFont(name: "\(UIElement().mainFont)", size: 17)!, numberOfLines: 2)
        menuButton = uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: .clear, image: nil, titleFont: nil, titleColor: .white, cornerRadius: nil)
        menuImage = uiElement.soundbrewImageView(UIImage(named: "more"), cornerRadius: nil, backgroundColor: .clear)
        soundArtImage = uiElement.soundbrewImageView(nil, cornerRadius: 5, backgroundColor: .clear)
        soundArtImage.layer.borderColor = color.purpleBlack().cgColor
        soundArtImage.layer.borderWidth = 1 
        artistImage = uiElement.soundbrewImageView(UIImage(named: "profile_icon"), cornerRadius: 25 / 2, backgroundColor: .black)
        artistLabel = uiElement.soundbrewLabel(nil, textColor: .white, font: UIFont(name: "\(UIElement().mainFont)", size: 16)!, numberOfLines: 0)
        let localizedTags = NSLocalizedString("tags", comment: "")
        searchTagsButton = uiElement.soundbrewButton(localizedTags, shouldShowBorder: false, backgroundColor: .clear, image: nil, titleFont: UIFont(name: "\(UIElement().mainFont)-bold", size: 17)!, titleColor: .white, cornerRadius: nil)
        let localizedArtists = NSLocalizedString("artists", comment: "")
        searchArtistsButton = uiElement.soundbrewButton(localizedArtists, shouldShowBorder: true, backgroundColor: .clear, image: nil, titleFont: UIFont(name: "\(UIElement().mainFont)-bold", size: 17)!, titleColor: .darkGray, cornerRadius: nil)
        let localizedSounds = NSLocalizedString("sounds", comment: "")
        searchSoundsButton = uiElement.soundbrewButton(localizedSounds, shouldShowBorder: false, backgroundColor: .clear, image: nil, titleFont: UIFont(name: "\(UIElement().mainFont)-bold", size: 17)!, titleColor: .darkGray, cornerRadius: nil)
        
        switch reuseIdentifier {
        case "noSoundsReuse":
            headerTitle = uiElement.soundbrewLabel(nil, textColor: .white, font: UIFont(name: "\(UIElement().mainFont)", size: 20)!, numberOfLines: 0)
            self.addSubview(headerTitle)
            headerTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(artistButton)
            artistButton.setBackgroundImage(UIImage(named: "background"), for: .normal)
            artistButton.setTitleColor(.white, for: .normal)
            artistButton.layer.cornerRadius = 3
            artistButton.clipsToBounds = true
            artistButton.isHidden = true 
            artistButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(uiElement.buttonHeight)
                make.top.equalTo(headerTitle.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
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
                make.height.equalTo(25)
                make.top.equalTo(soundArtImage)
                make.left.equalTo(soundArtImage.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(menuButton.snp.left).offset(uiElement.leftOffset)
            }
            
            artistImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(25)
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
            
            soundTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistButton.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(soundArtImage.snp.right).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            soundDate.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundTitle.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(soundTitle)
                make.right.equalTo(soundTitle)
            }
            
            dividerLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.left.equalTo(soundTitle)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(soundArtImage)
            }
            break
            
        case "filterSoundsReuse":
            self.addSubview(searchTagsButton)
            searchTagsButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(35)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            self.addSubview(searchArtistsButton)
            searchArtistsButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(35)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(searchTagsButton.snp.right).offset(uiElement.leftOffset + 10)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            self.addSubview(searchSoundsButton)
            searchSoundsButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(35)
                make.top.equalTo(searchArtistsButton)
                make.left.equalTo(searchArtistsButton.snp.right).offset(uiElement.leftOffset + 10)
                make.bottom.equalTo(searchArtistsButton)
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

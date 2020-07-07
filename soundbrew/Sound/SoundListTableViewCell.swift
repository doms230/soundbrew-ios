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
        return uiElement.soundbrewLabel(nil, textColor: .white, font: UIFont(name: "\(UIElement().mainFont)", size: 17)!, numberOfLines: 0)
    }()
    
    //filter new/popular
    lazy var searchTagsButton: UIButton = {
        let localizedTags = NSLocalizedString("tags", comment: "")
        return uiElement.soundbrewButton(localizedTags, shouldShowBorder: false, backgroundColor: .clear, image: nil, titleFont: UIFont(name: "\(UIElement().mainFont)-bold", size: 17)!, titleColor: .white, cornerRadius: nil)
    }()
    
    lazy var searchArtistsButton: UIButton = {
        let localizedArtists = NSLocalizedString("artists", comment: "")
        return uiElement.soundbrewButton(localizedArtists, shouldShowBorder: true, backgroundColor: .clear, image: nil, titleFont: UIFont(name: "\(UIElement().mainFont)-bold", size: 17)!, titleColor: .darkGray, cornerRadius: nil)
    }()
    
    lazy var searchSoundsButton: UIButton = {
        let localizedSounds = NSLocalizedString("sounds", comment: "")
        return uiElement.soundbrewButton(localizedSounds, shouldShowBorder: false, backgroundColor: .clear, image: nil, titleFont: UIFont(name: "\(UIElement().mainFont)-bold", size: 17)!, titleColor: .darkGray, cornerRadius: nil)
    }()
    
    lazy var tagsScrollview: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    //mark: sounds
    lazy var exclusiveImage: UIImageView = {
        let image = uiElement.soundbrewImageView(UIImage(named: "diamond"), cornerRadius: 25/2, backgroundColor: .clear)
        image.isHidden = true
        return image
    }()
    
    lazy var artistButton: UIButton = {
        return uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: .clear, image: nil, titleFont: nil, titleColor: .white, cornerRadius: nil)
    }()
        
    lazy var artistImage: UIImageView = {
        return  uiElement.soundbrewImageView(UIImage(named: "profile_icon"), cornerRadius: 25/2, backgroundColor: .black)
    }()
    
    lazy var artistLabel: UILabel = {
        return uiElement.soundbrewLabel(nil, textColor: .white, font: UIFont(name: "\(UIElement().mainFont)", size: 16)!, numberOfLines: 0)
    }()
    
    lazy var soundArtImage: UIImageView = {
        let soundArtImage = uiElement.soundbrewImageView(nil, cornerRadius: 5, backgroundColor: .clear)
        soundArtImage.layer.borderColor = color.purpleBlack().cgColor
        soundArtImage.layer.borderWidth = 1
        soundArtImage.backgroundColor = .darkGray
        return soundArtImage
    }()
    
    lazy var soundTitle: UILabel = {
        return uiElement.soundbrewLabel(nil, textColor: .white, font: UIFont(name: "\(UIElement().mainFont)-bold", size: 18)!, numberOfLines: 1)
    }()
    
    lazy var soundDate: UILabel = {
       return uiElement.soundbrewLabel(nil, textColor: .darkGray, font: UIFont(name: "\(UIElement().mainFont)", size: 17)!, numberOfLines: 1)
    }()
    
    lazy var menuButton: UIButton = {
        return uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: .clear, image: nil, titleFont: nil, titleColor: .white, cornerRadius: nil)
    }()
    
    lazy var menuImage: UIImageView = {
        return uiElement.soundbrewImageView(UIImage(named: "more"), cornerRadius: nil, backgroundColor: .clear)
    }()
    
    lazy var circleImage: UILabel = {
        return uiElement.soundbrewLabel("○", textColor: .darkGray, font: UIFont(name: "\(UIElement().mainFont)-bold", size: 17)!, numberOfLines: 1)
    }()
    
    lazy var dividerLine: UIView = {
        let line = UIView()
        line.layer.borderWidth = 1
        line.layer.borderColor = UIColor.darkGray.cgColor
        return line
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
            
        case "soundReuse", "selectPlaylistSoundsReuse":
            self.addSubview(menuButton)
             self.menuButton.addSubview(menuImage)
             
             self.addSubview(artistButton)
             self.artistButton.addSubview(artistImage)
             self.artistButton.addSubview(artistLabel)
             
             self.addSubview(soundArtImage)
            self.addSubview(exclusiveImage)

             self.addSubview(soundTitle)
             self.addSubview(artistLabel)
             self.addSubview(soundDate)
             self.addSubview(dividerLine)
            
            if reuseIdentifier == "selectPlaylistSoundsReuse" {
                self.addSubview(circleImage)
                circleImage.snp.makeConstraints { (make) -> Void in
                    make.width.equalTo(25)
                    make.left.equalTo(self).offset(uiElement.leftOffset)
                    make.centerY.equalTo(self)
                }
                
                soundArtImage.snp.makeConstraints { (make) -> Void in
                    make.height.width.equalTo(100)
                    make.top.equalTo(self).offset(uiElement.topOffset)
                    make.left.equalTo(circleImage.snp.right).offset(uiElement.leftOffset)
                    make.bottom.equalTo(self).offset(uiElement.bottomOffset)
                }
                
            } else {
                soundArtImage.snp.makeConstraints { (make) -> Void in
                    make.height.width.equalTo(100)
                    make.top.equalTo(self).offset(uiElement.topOffset)
                    make.left.equalTo(self).offset(uiElement.leftOffset)
                    make.bottom.equalTo(self).offset(uiElement.bottomOffset)
                }
            }
            
            exclusiveImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(25)
                make.top.equalTo(soundArtImage).offset(-8)
                make.left.equalTo(soundArtImage).offset(-8)
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
                make.right.equalTo(self).offset(uiElement.rightOffset)
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

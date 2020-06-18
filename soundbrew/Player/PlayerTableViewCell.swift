//
//  PlayerTableViewCell.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/18/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit

class PlayerTableViewCell: UITableViewCell {
    let color = Color()
    let uiElement = UIElement()
    var songArtHeightWidth: Int!
    var frameWidth: Double!
    
    lazy var soundArt: UIImageView = {
        return self.uiElement.soundbrewImageView(nil, cornerRadius: 3, backgroundColor: .black)
    }()
    
    lazy var likeSoundButton: UIButton = {
        return self.uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: .black, image: UIImage(named: "sendTip"), titleFont: nil, titleColor: .black, cornerRadius: nil)
    }()
    
    lazy var shareButton: UIButton = {
        return self.uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: .black, image: UIImage(named: "share"), titleFont: nil, titleColor: .black, cornerRadius: nil)
    }()
    
    lazy var playBackSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.tintColor = .darkGray
        slider.value = 0
        slider.isOpaque = true
        return slider
    }()
    
    lazy var playBackCurrentTime: UILabel = {
        return self.uiElement.soundbrewLabel("0 s", textColor: .white, font: UIFont(name: uiElement.mainFont, size: 10)!, numberOfLines: 1)
    }()
    
    lazy var playBackTotalTime: UILabel = {
        return self.uiElement.soundbrewLabel("0 s", textColor: .white, font: UIFont(name: uiElement.mainFont, size: 10)!, numberOfLines: 1)
    }()
    
    lazy var playBackButton: UIButton = {
        return self.uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: .black, image: UIImage(named: "pause"), titleFont: nil, titleColor: .black, cornerRadius: nil)
    }()
    
    lazy var loadSoundSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .white
        spinner.startAnimating()
        spinner.isHidden = true
        spinner.isOpaque = true
        return spinner
    }()
    
    lazy var skipButton: UIButton = {
        return self.uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: .black, image: UIImage(named: "skip"), titleFont: nil, titleColor: .black, cornerRadius: nil)
    }()
    
    lazy var goBackButton: UIButton = {
        return self.uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: .black, image: UIImage(named: "goBack"), titleFont: nil, titleColor: .black, cornerRadius: nil)
    }()
    
    lazy var playCountButton: UIButton = {
        return self.uiElement.soundbrewButton("0 plays", shouldShowBorder: false, backgroundColor: .black, image: nil, titleFont: UIFont(name: uiElement.mainFont, size: 10)!, titleColor: .darkGray, cornerRadius: nil)
    }()
    
    lazy var likesCountButton: UIButton = {
        return self.uiElement.soundbrewButton("0 likes", shouldShowBorder: false, backgroundColor: .black, image: nil, titleFont: UIFont(name: uiElement.mainFont, size: 10)!, titleColor: .white, cornerRadius: nil)
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(soundArt)
        soundArt.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(songArtHeightWidth)
            make.top.equalTo(self).offset(uiElement.topOffset)
            make.centerX.equalTo(self)
        }
        
        self.addSubview(playBackCurrentTime)
        playBackCurrentTime.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(soundArt.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self).offset(uiElement.leftOffset)
        }
        
        self.addSubview(playBackTotalTime)
        playBackTotalTime.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(playBackCurrentTime)
            make.right.equalTo(self).offset(uiElement.rightOffset)
        }
        
        self.addSubview(playBackSlider)
        playBackSlider.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(playBackTotalTime.snp.bottom)
            make.left.equalTo(self).offset(uiElement.leftOffset)
            make.right.equalTo(self).offset(uiElement.rightOffset)
        }
        
        self.addSubview(playBackButton)
        playBackButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(60)
            make.top.equalTo(playBackSlider.snp.bottom).offset(uiElement.topOffset)
            make.centerX.equalTo(self)
        }
        
        self.addSubview(loadSoundSpinner)
        loadSoundSpinner.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(60)
            make.top.equalTo(playBackButton)
            make.centerX.equalTo(self)
        }
        
        self.addSubview(goBackButton)
        goBackButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(45)
            make.centerY.equalTo(playBackButton)
            make.left.equalTo(self).offset(frameWidth * 0.25)
        }
        
        self.addSubview(skipButton)
        skipButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(45)
            make.centerY.equalTo(playBackButton)
            make.centerX.equalTo(self).offset(-(frameWidth * 0.25))
        }
        
        self.addSubview(likeSoundButton)
        likeSoundButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(30)
            make.centerY.equalTo(self.skipButton)
            make.right.equalTo(self).offset(uiElement.rightOffset)
        }
        
        self.addSubview(shareButton)
        shareButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(30)
            make.centerY.equalTo(self.skipButton)
            make.left.equalTo(self).offset(uiElement.leftOffset)
        }
    }
    
    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

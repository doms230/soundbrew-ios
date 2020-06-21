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
    
    //player reuse
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
    
    lazy var shuffleButton: UIButton = {
        return self.uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: .black, image: UIImage(named: "shuffle"), titleFont: nil, titleColor: .black, cornerRadius: nil)
    }()
    
    lazy var repeatButton: UIButton = {
        return self.uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: .black, image: UIImage(named: "repeat"), titleFont: nil, titleColor: .black, cornerRadius: nil)
    }()
    
    //sound stats reuse
  /*  lazy var playCountButton: UIButton = {
        return self.uiElement.soundbrewButton("0 plays", shouldShowBorder: false, backgroundColor: .black, image: nil, titleFont: UIFont(name: uiElement.mainFont, size: 10)!, titleColor: .darkGray, cornerRadius: nil)
    }()
    
    lazy var likesCountButton: UIButton = {
        return self.uiElement.soundbrewButton("0 likes", shouldShowBorder: false, backgroundColor: .black, image: nil, titleFont: UIFont(name: uiElement.mainFont, size: 10)!, titleColor: .white, cornerRadius: nil)
    }()*/
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        if reuseIdentifier == "playerReuse" {
            self.addSubview(soundArt)
            soundArt.snp.makeConstraints { (make) -> Void in
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
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
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
                make.right.equalTo(playBackButton.snp.left).offset(uiElement.rightOffset)
            }
            
            self.addSubview(skipButton)
            skipButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(45)
                make.centerY.equalTo(playBackButton)
                make.left.equalTo(playBackButton.snp.right).offset(uiElement.leftOffset)
            }
            
            self.addSubview(likeSoundButton)
            likeSoundButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(30)
                make.centerY.equalTo(self.playBackButton)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(shareButton)
            shareButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(30)
                make.centerY.equalTo(self.playBackButton)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            self.addSubview(repeatButton)
            repeatButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(30)
                make.centerY.equalTo(self.playBackButton)
                make.left.equalTo(shareButton.snp.right).offset(uiElement.leftOffset + 5)
                //make.right.equalTo(goBackButton.snp.left).offset(uiElement.rightOffset)
            }
            
            self.addSubview(shuffleButton)
            shuffleButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(30)
                make.centerY.equalTo(self.playBackButton)
                make.right.equalTo(likeSoundButton.snp.left).offset(uiElement.rightOffset - 5)
            }
            
        } else {
           /* self.addSubview(playCountButton)
            playCountButton.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            self.addSubview(likesCountButton)
            likesCountButton.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(playCountButton.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(playCountButton)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }*/
        }
    }
    
    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

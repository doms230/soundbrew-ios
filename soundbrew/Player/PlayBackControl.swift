//
//  PlayBackControl.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/21/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import Foundation
import SnapKit
import GrowingTextView

class PlayBackControl {
    var viewController: UIViewController!
    var isTextViewEditing = false 
    var atTime: Float!
    var textView: GrowingTextView?
    var inputToolBar: UIView!
    
    init(_ viewController: UIViewController, textView: GrowingTextView, inputToolBar: UIView) {
        self.viewController = viewController
        self.textView = textView
        self.inputToolBar = inputToolBar
        attachPlaybackControlsToView()
        setupPlaybackControls()
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSoundUpdate), name: NSNotification.Name(rawValue: "setSound"), object: nil)
    }
    
    @objc func didReceiveSoundUpdate() {
       setupPlaybackControls()
    }
    
    let color = Color()
    let uiElement = UIElement()
    let player = Player.sharedInstance
    //player reuse
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
    
    func setupPlaybackControls() {
        if let sound = player.currentSound {
            if let duration = self.player.player?.duration {
                self.playBackTotalTime.text = self.uiElement.formatTime(Double(duration))
                playBackSlider.maximumValue = Float(duration)
                self.startTimer()
            }
            
            if player.player != nil, player.player!.isPlaying  {
                self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
            } else {
                self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
            }
            
            let like = Like.shared
            like.likeSoundButton = self.likeSoundButton
            like.target = self.viewController
            
            if let likeSound = like.sound {
                if sound.objectId != likeSound.objectId {
                    like.checkIfUserLikedSong(sound)
                    
                } else if likeSound.currentUserTipDate != nil {
                    self.likeSoundButton.isEnabled = false
                    self.likeSoundButton.setImage(UIImage(named: "sendTipColored"), for: .normal)
                } else {
                    self.likeSoundButton.isEnabled = true
                    self.likeSoundButton.setImage(UIImage(named: "sendTip"), for: .normal)
                }
                 
            } else {
                like.checkIfUserLikedSong(sound)
            }
            
            like.sound = sound
        }
    }
    
    func attachPlaybackControlsToView() {
        var bottomOffsetValue: Int!
        switch UIDevice.modelName {
        case "iPhone X", "iPhone XS", "iPhone XR", "iPhone 11", "iPhone 11 Pro", "iPhone 11 Pro Max", "iPhone XS Max", "Simulator iPhone 11 Pro Max":
            bottomOffsetValue = uiElement.bottomOffset * 3
            break
            
        default:
            bottomOffsetValue = uiElement.bottomOffset * 2
            break
        }
        
        playBackButton.addTarget(self, action: #selector(self.didPressPlayBackButton(_:)), for: .touchUpInside)
        self.viewController.view.addSubview(playBackButton)
        playBackButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(50)
            make.centerX.equalTo(self.viewController.view)
            make.bottom.equalTo(self.inputToolBar.snp.top).offset(uiElement.bottomOffset)
        }
        
        self.viewController.view.addSubview(loadSoundSpinner)
        loadSoundSpinner.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(50)
            make.top.equalTo(playBackButton)
            make.centerX.equalTo(self.viewController.view)
        }
        
        goBackButton.addTarget(self, action: #selector(didPressGoBackButton(_:)), for: .touchUpInside)
        self.viewController.view.addSubview(goBackButton)
        goBackButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(35)
            make.centerY.equalTo(playBackButton)
            make.right.equalTo(playBackButton.snp.left).offset(uiElement.rightOffset)
        }
        
        skipButton.addTarget(self, action: #selector(self.didPressSkipButton(_:)), for: .touchUpInside)
        self.viewController.view.addSubview(skipButton)
        skipButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(35)
            make.centerY.equalTo(playBackButton)
            make.left.equalTo(playBackButton.snp.right).offset(uiElement.leftOffset)
        }
        
        likeSoundButton.addTarget(self, action: #selector(self.didPressLikeButton(_:)), for: .touchUpInside)
        self.viewController.view.addSubview(likeSoundButton)
        likeSoundButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.centerY.equalTo(self.playBackButton)
            make.right.equalTo(self.viewController.view).offset(uiElement.rightOffset)
        }
        
        shareButton.addTarget(self, action: #selector(didPressShareButton(_:)), for: .touchUpInside)
        self.viewController.view.addSubview(shareButton)
        shareButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.centerY.equalTo(self.playBackButton)
            make.left.equalTo(self.viewController.view).offset(uiElement.leftOffset)
        }
        
        repeatButton.addTarget(self, action: #selector(self.didPressRepeatButton(_:)), for: .touchUpInside)
        self.viewController.view.addSubview(repeatButton)
        repeatButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(20)
            make.centerY.equalTo(self.playBackButton)
            make.left.equalTo(shareButton.snp.right).offset(uiElement.leftOffset + 20)
        }
        
        shuffleButton.addTarget(self, action: #selector(self.didPressShuffleButton(_:)), for: .touchUpInside)
        self.viewController.view.addSubview(shuffleButton)
        shuffleButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(20)
            make.centerY.equalTo(self.playBackButton)
            make.right.equalTo(likeSoundButton.snp.left).offset(uiElement.rightOffset - 20)
        }
        
        //
        playBackSlider.addTarget(self, action: #selector(sliderValueDidChange(_:)), for: .valueChanged)
        self.viewController.view.addSubview(playBackSlider)
        playBackSlider.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.viewController.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.viewController.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.playBackButton.snp.top).offset(uiElement.bottomOffset)
        }
        
        self.viewController.view.addSubview(playBackCurrentTime)
        playBackCurrentTime.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.viewController.view).offset(uiElement.leftOffset)
            make.bottom.equalTo(playBackSlider.snp.top)
        }
        
        self.viewController.view.addSubview(playBackTotalTime)
        playBackTotalTime.snp.makeConstraints { (make) -> Void in
            make.right.equalTo(self.viewController.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(playBackCurrentTime)
        }
    }
    
    //mark: player view
    var timer = Timer()
    
    @objc func didPressPlayBackButton(_ sender: UIButton) {
        if let soundPlayer = player.player {
            if soundPlayer.isPlaying {
                player.pause()
                timer.invalidate()
                self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
            } else {
                player.play()
                startTimer()
                self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
            }
        }
    }
    
    @objc func didPressGoBackButton(_ sender: UIButton) {
        player.previous()
    }
    
    @objc func didPressSkipButton(_ sender: UIButton) {
        player.next()
    }
    
    @objc func didPressLikeButton(_ sender: UIButton) {
        sender.setImage(UIImage(named: "sendTipColored"), for: .normal)
        sender.isEnabled = false
        let like = Like.shared
        like.target = self.viewController
        like.sound = self.player.currentSound
        like.likeSoundButton = sender
        like.newLike()
    }
    
    @objc func didPressShareButton(_ sender: UIButton) {
        if let sound = self.player.currentSound {
            self.uiElement.showShareOptions(self.viewController, sound: sound)
        }
    }
    
    @objc func sliderValueDidChange(_ sender: UISlider) {
        if let soundPlayer = player.player {
            playBackCurrentTime.text = self.uiElement.formatTime(Double(sender.value))
            soundPlayer.currentTime = TimeInterval(sender.value)
            player.setBackgroundAudioNowPlaying()
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTimer(_:)), userInfo: nil, repeats: true)
    }
    @objc func UpdateTimer(_ timer: Timer) {
        if let currentTime = player.player?.currentTime {
            let floatCurrentTime = Float(currentTime)
            playBackCurrentTime.text = "\(self.uiElement.formatTime(Double(currentTime)))"
            playBackSlider.value = floatCurrentTime
            if !self.isTextViewEditing {
                self.atTime = Float(currentTime)
                let doubleAtTime = self.uiElement.formatTime(Double(currentTime))
                if let textView = self.textView {
                    textView.placeholder = "Add comment at \(doubleAtTime)"
                }
            }
        }
    }
    
    @objc func didPressShuffleButton(_ sender: UIButton) {
        //TODO
    }
    
    
    @objc func didPressRepeatButton(_ sender: UIButton) {
        //TODO
    }
}

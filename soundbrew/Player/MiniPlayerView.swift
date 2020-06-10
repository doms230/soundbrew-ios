//
//  MiniPlayerView.swift
//  soundbrew
//
//  Created by Dominic  Smith on 2/6/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Parse
import AppCenterAnalytics

class MiniPlayerView: UIButton {
    static let sharedInstance = MiniPlayerView()
    
    let color = Color()
    let uiElement = UIElement()
    var shouldSetupConstraints = true
    
    var player = Player.sharedInstance
    var superViewController: UIViewController!
    var playerDelegate: PlayerDelegate?
    var tagDelegate: TagDelegate?
    
    lazy var songTitle: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        return label
    }()
    
    lazy var artistName: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 15)
        return label
    }()
    
    lazy var songArt: UIImageView = {
        let image = UIImageView()
        image.backgroundColor = .clear 
        image.layer.cornerRadius = 3
        image.layer.borderWidth = 1
        image.layer.borderColor = color.purpleBlack().cgColor
        image.clipsToBounds = true
        return image
    }()
    
    lazy var activitySpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .white
        spinner.startAnimating()
        spinner.isHidden = true
        return spinner
    }()
    
    lazy var playBackButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "play"), for: .normal)
        button.addTarget(self, action: #selector(self.didPressPlayBackButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressPlayBackButton(_ sender: UIButton) {
        if let soundPlayer = player.player {
            if soundPlayer.isPlaying {
                player.pause()
                timer.invalidate()
                self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
                MSAnalytics.trackEvent("Mini Player", withProperties: ["Button" : "Pause", "description": "User pressed pause."])
            } else {
                player.play()
                startTimer()
                self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
                MSAnalytics.trackEvent("Mini Player", withProperties: ["Button" : "Play", "description": "User pressed play."])
            }
        }
        
        activitySpinner.isHidden = true
        playBackButton.isHidden = false
    }
    
    lazy var likeSoundButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "sendTip"), for: .normal)
        button.addTarget(self, action: #selector(self.didPressLikeButton(_:)), for: .touchUpInside)
        return button
    }()
    
    @objc func didPressLikeButton(_ sender: UIButton) {
        sender.setImage(UIImage(named: "sendTipColored"), for: .normal)
        sender.isEnabled = false
        let like = Like.shared
        like.target = self.superViewController
        like.sound = player.currentSound
        like.likeSoundButton = sender
        like.newLike()
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "TipButton", "Description": "Current User attempted to tip artist"])
    }
    
    lazy var playBackSlider: UISlider = {
        let slider = UISlider()
        slider.value = 0
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.tintColor = .white
        slider.setThumbImage(UIImage(), for: .normal)
        slider.isEnabled = false
        return slider
     }()
    
    var timer = Timer()
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTimer(_:)), userInfo: nil, repeats: true)
    }
    @objc func UpdateTimer(_ timer: Timer) {
        if let currentTime = player.player?.currentTime {
            playBackSlider.value = Float(currentTime)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = color.black()
        setupNotificationCenter()
        
        let slide = UISwipeGestureRecognizer(target: superViewController, action: #selector(self.miniPlayerWasSwiped))
        slide.direction = .up
        self.addGestureRecognizer(slide)
        self.addTarget(superViewController, action: #selector(self.miniPlayerWasPressed(_:)), for: .touchUpInside)
    }
    
    func showPlayerViewController() {
        if let playerDelegate = self.playerDelegate, let tagDelegate = self.tagDelegate {
            let modal = PlayerViewController()
            modal.playerDelegate = playerDelegate
            modal.tagDelegate = tagDelegate
            superViewController.present(modal, animated: true, completion: nil)
        }
    }
    
    @objc func miniPlayerWasSwiped() {
        showPlayerViewController()
    }
    
    @objc func miniPlayerWasPressed(_ sender: UIButton) {
        showPlayerViewController()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func updateConstraints() {
        if(shouldSetupConstraints) {
            self.addSubview(playBackSlider)
            playBackSlider.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(1)
                make.top.equalTo(self)
                make.left.equalTo(self)
                make.right.equalTo(self)
            }
            
            self.addSubview(likeSoundButton)
            likeSoundButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(30)
                make.centerY.equalTo(self)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(playBackButton)
            playBackButton.snp.makeConstraints { (make) -> Void in
                make.width.height.equalTo(30)
                make.centerY.equalTo(self)
                make.right.equalTo(likeSoundButton.snp.left).offset(uiElement.rightOffset * 2)
            }
            
            self.addSubview(activitySpinner)
            activitySpinner.snp.makeConstraints { (make) -> Void in
                make.width.height.equalTo(30)
                make.center.equalTo(playBackButton)
            }
            activitySpinner.isHidden = true
            
            self.addSubview(songArt)
            songArt.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(50)
                make.centerY.equalTo(self)
                make.left.equalTo(self).offset(uiElement.leftOffset)
            }
            
            self.addSubview(artistName)
            artistName.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(200)
                make.centerY.equalTo(self.songArt).offset(uiElement.topOffset)
                make.left.equalTo(songArt.snp.right).offset(uiElement.elementOffset)
            }
            
            self.addSubview(songTitle)
            songTitle.snp.makeConstraints { (make) -> Void in
                make.left.equalTo(artistName)
                make.right.equalTo(artistName)
                make.bottom.equalTo(artistName.snp.top)
            }
            
            shouldSetupConstraints = false
            setSound()
        }
            
        super.updateConstraints()
    }
    
    func setupNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSoundUpdate), name: NSNotification.Name(rawValue: "setSound"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceivePreparingSoundNotification), name: NSNotification.Name(rawValue: "preparingSound"), object: nil)
    }
    
    @objc func didReceiveSoundUpdate() {
        setSound()
    }
    
    func setSound() {
        if let sound = player.currentSound {
            let like = Like.shared
            like.likeSoundButton = self.likeSoundButton
            like.target = self.superViewController
            
            if let likeSound = like.sound {
                if sound.objectId != likeSound.objectId {
                    like.loadCredits(sound)
                } else if likeSound.currentUserTipDate != nil {
                    self.likeSoundButton.isEnabled = false
                    self.likeSoundButton.setImage(UIImage(named: "sendTipColored"), for: .normal)
                } else {
                    self.likeSoundButton.isEnabled = true
                    self.likeSoundButton.setImage(UIImage(named: "sendTip"), for: .normal)
                }
                
            } else {
                like.loadCredits(sound)
            }
            
            like.sound = sound
            
            setCurrentSoundView(sound)
            self.playBackButton.isEnabled = true
        }
        
        if let duration = self.player.player?.duration {
            playBackSlider.maximumValue = Float(duration)
            self.startTimer()
        }
        
        if let audioPlayer = player.player {
            if audioPlayer.isPlaying {
                self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
            } else {
                self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
            }
            
            activitySpinner.isHidden = true
            playBackButton.isHidden = false
        }
    }
    
    @objc func didReceivePreparingSoundNotification() {
        self.activitySpinner.isHidden = false
        playBackButton.isHidden = true
        playBackSlider.value = 0
    }
    
    func setCurrentSoundView(_ sound: Sound) {
        self.songTitle.text = sound.title
        
        self.songArt.kf.setImage(with: URL(string: sound.artURL ?? ""), placeholder: UIImage(named: "sound"))
        
        if let artistName = sound.artist?.name {
            self.artistName.text = artistName
        } else {
            self.artistName.text = ""
            loadUserInfoFromCloud(sound.artist!.objectId)
        }
    }
    
    func loadUserInfoFromCloud(_ userId: String) {
        let query = PFQuery(className:"_User")
        query.cachePolicy = .networkElseCache
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let user = user {
                let artistName = user["artistName"] as? String
                self.artistName.text = artistName
            }
        }
    }
}

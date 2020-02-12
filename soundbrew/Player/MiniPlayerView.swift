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
    let color = Color()
    let uiElement = UIElement()
    var shouldSetupConstraints = true
    
    var player: Player?
    var sound: Sound?
    
    lazy var songTitle: UILabel = {
        let label = UILabel()
        label.text = "Welcome"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        return label
    }()
    
    lazy var artistName: UILabel = {
        let label = UILabel()
        label.text = "Press Play"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 15)
        return label
    }()
    
    lazy var songArt: UIImageView = {
        let image = UIImageView()
        image.backgroundColor = .clear 
        image.image = UIImage(named: "sound")
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
        return button
    }()
    @objc func didPressPlayBackButton(_ sender: UIButton) {
        if let player = self.player {
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
            
        } else {
            activitySpinner.isHidden = false
            playBackButton.isHidden = true
        }
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
        if let currentTime = player?.player?.currentTime {
            playBackSlider.value = Float(currentTime)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = color.black()
        setupNotificationCenter()
        player = Player.sharedInstance
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
            
            self.addSubview(playBackButton)
            playBackButton.addTarget(self, action: #selector(self.didPressPlayBackButton(_:)), for: .touchUpInside)
            playBackButton.snp.makeConstraints { (make) -> Void in
                make.width.height.equalTo(30)
                make.centerY.equalTo(self)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(activitySpinner)
            activitySpinner.snp.makeConstraints { (make) -> Void in
                make.width.height.equalTo(30)
                make.centerY.equalTo(self)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            activitySpinner.isHidden = true
            
            self.addSubview(songArt)
            songArt.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(40)
                make.top.equalTo(playBackSlider).offset(uiElement.elementOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(-(uiElement.elementOffset))
            }
            
            self.addSubview(artistName)
            artistName.snp.makeConstraints { (make) -> Void in
                make.centerY.equalTo(self.songArt).offset(uiElement.topOffset)
                make.left.equalTo(songArt.snp.right).offset(uiElement.elementOffset)
                make.right.equalTo(playBackButton.snp.left).offset(uiElement.rightOffset)
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
    
    func setupNotificationCenter(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSoundUpdate), name: NSNotification.Name(rawValue: "setSound"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceivePreparingSoundNotification), name: NSNotification.Name(rawValue: "preparingSound"), object: nil)
    }
    
    @objc func didReceiveSoundUpdate() {
        setSound()
    }
    
    func setSound() {
        if let player = self.player {
            if let currentSound = player.currentSound {
            self.sound = currentSound
            setCurrentSoundView(self.sound!)
            self.playBackButton.isEnabled = true
            }
            
            if let duration = self.player?.player?.duration {
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
                self.isEnabled = true
            }
        }
    }
    
    @objc func didReceivePreparingSoundNotification() {
        self.activitySpinner.isHidden = false
        playBackButton.isHidden = true
        self.isEnabled = false
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
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                let artistName = user["artistName"] as? String
                self.artistName.text = artistName
                self.sound!.artist?.name = artistName
            }
        }
    }    
}

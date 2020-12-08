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
import FWPlayerCore

class MiniPlayerView: UIButton {
    static let sharedInstance = MiniPlayerView()
    
    let color = Color()
    let uiElement = UIElement()
    var shouldSetupConstraints = true
    let like = Like.shared
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
        var isPlaying = false
        
        if let soundPlayer = player.player {
            isPlaying = soundPlayer.isPlaying
        } else if let videoPlayerIsPlaying = player.videoPlayer?.currentPlayerManager.isPlaying {
            isPlaying = videoPlayerIsPlaying
        }
        
        if isPlaying {
            player.pause()
            timer.invalidate()
            self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
        } else {
            player.play()
            startTimer()
            self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
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
        if PFUser.current() == nil {
            self.uiElement.signupRequired("Welcome to Soundbrew", message: "Register to like songs and add them to your playlist!", target: superViewController)
        } else {
            sender.setImage(UIImage(named: "sendTipColored"), for: .normal)
            sender.isEnabled = false
            let like = Like.shared
            like.target = self.superViewController
            like.likeSoundButton = sender
            like.newLike()
            
            let alertController = UIAlertController (title: "Sound added to Likes", message: "", preferredStyle: .actionSheet)
            let addPlaylistAction = UIAlertAction(title: "Add to Playlist", style: .default) { (_) -> Void in
                if let sound = self.player.currentSound {
                    let modal = PlaylistViewController()
                    modal.sound = sound
                    self.superViewController.present(modal, animated: true, completion: nil)
                }
            }
            alertController.addAction(addPlaylistAction)
            
            let cancelAction = UIAlertAction(title: "Done", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            self.superViewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    lazy var playBackSlider: UISlider = {
        let slider = UISlider()
        slider.value = 0
        slider.minimumValue = 0
        slider.maximumValue = 1000
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
        var currentTime: TimeInterval?
        
        if let audioCurrentTime = player.player?.currentTime {
            currentTime = audioCurrentTime
        } else if let videoCurrentTime = player.videoPlayer?.currentTime {
            currentTime = videoCurrentTime
        }
        
        if let currentTime = currentTime {
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
    
    @objc func didReceivePreparingSoundNotification() {
        playBackButton.isHidden = true
        self.activitySpinner.isHidden = false
        self.activitySpinner.startAnimating()
        playBackSlider.value = 0
    }
    
    func setSound() {
        like.likeSoundButton = self.likeSoundButton
        like.target = self.superViewController
        if let currentUserDidLikeSong = self.player.currentSound?.currentUserDidLikeSong {
            if currentUserDidLikeSong {
                self.likeSoundButton.isEnabled = false
                self.likeSoundButton.setImage(UIImage(named: "sendTipColored"), for: .normal)
            } else {
                self.likeSoundButton.isEnabled = true
                self.likeSoundButton.setImage(UIImage(named: "sendTip"), for: .normal)
            }
        } else {
            self.likeSoundButton.isEnabled = true
            self.likeSoundButton.setImage(UIImage(named: "sendTip"), for: .normal)
        }
        
        setCurrentSoundView()
        self.playBackButton.isEnabled = true
        
        var duration: TimeInterval?
        
        if let audioDuration = self.player.player?.duration {
            duration = audioDuration
        } else if let videoDuration = self.player.videoPlayer?.totalTime {
            duration = videoDuration
        }
        
        if let duration = duration {
            playBackSlider.maximumValue = Float(duration)
            self.startTimer()
        }
        
        var isPlaying: Bool!
        
        if let audioPlayer = player.player {
            isPlaying = audioPlayer.isPlaying
        } else if let videoPlayer = self.player.videoPlayer?.currentPlayerManager {
            isPlaying = videoPlayer.isPlaying
        }
        
        if let isPlaying = isPlaying, isPlaying {
            self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
        } else {
            self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
        }
        
        activitySpinner.isHidden = true
        playBackButton.isHidden = false
        
    }
    
    func setCurrentSoundView() {
        if let sound = self.player.currentSound {
            self.songTitle.text = sound.title
            
            self.songArt.kf.setImage(with: URL(string: sound.artFile?.url ?? ""), placeholder: UIImage(named: "sound"))
            
            if let videoPlayer = self.player.videoPlayer {
                videoPlayer.allowOrentitaionRotation = false
                videoPlayer.containerView = self.songArt
            }
            
            if let artistName = sound.artist?.name {
                self.artistName.text = artistName
            } else {
                self.artistName.text = ""
                loadUserInfoFromCloud(sound.artist!.objectId)
            }
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

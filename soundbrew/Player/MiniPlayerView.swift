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

class MiniPlayerView: UIButton {
    let color = Color()
    let uiElement = UIElement()
    var shouldSetupConstraints = true
    
    var player: Player?
    var sound: Sound?
    
    lazy var songTitle: UILabel = {
        let label = UILabel()
        //label.text = "Sound Title"
        label.textColor = color.black()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 15)
        label.textAlignment = .center
        return label
    }()
    
    lazy var artistName: UIButton = {
        let button = UIButton()
        //button.setTitle("Artist Name", for: .normal)
        button.setTitleColor(color.black(), for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 10)
        return button
    }()
    
    lazy var playBackButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "play"), for: .normal)
        return button
    }()
    @objc func didPressPlayBackButton(_ sender: UIButton) {
        if let player = self.player?.player {
            if player.isPlaying {
                player.pause()
                self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
                
            } else {
                player.play()
                self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .white
        setupNotificationCenter()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func updateConstraints() {        
        if(shouldSetupConstraints) {
            self.addSubview(playBackButton)
            playBackButton.addTarget(self, action: #selector(self.didPressPlayBackButton(_:)), for: .touchUpInside)
            playBackButton.snp.makeConstraints { (make) -> Void in
                make.width.height.equalTo(40)
                make.top.equalTo(self).offset(uiElement.elementOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                //make.bottom.equalTo(self).offset(-(uiElement.elementOffset))
            }
            
            self.addSubview(songTitle)
            songTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.elementOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(playBackButton.snp.left).offset(uiElement.rightOffset)
            }
            
            self.addSubview(artistName)
            artistName.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.songTitle.snp.bottom)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(songTitle)
            }
            
            shouldSetupConstraints = false
            setSound()
        }
    
        super.updateConstraints()
    }
    
    func setupNotificationCenter(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSound), name: NSNotification.Name(rawValue: "setSound"), object: nil)
    }
    
    @objc func didReceiveSound() {
        setSound()
    }
    
    @objc func playbackWasPaused() {
        self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
    }
    
    func setSound() {
        if let player = self.player {
            if let currentSound = player.currentSound {
            //self.sound = player.sounds[player.currentSoundIndex]
            self.sound = currentSound
            setCurrentSoundView(self.sound!)
            self.playBackButton.isEnabled = true
            }
            
            if let audioPlayer = player.player {
                if audioPlayer.isPlaying {
                    self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
                    
                } else {
                    self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
                }
            }
        }
    }
    
    func setCurrentSoundView(_ sound: Sound) {
        self.songTitle.text = sound.title
        
        if let artistName = sound.artist?.name {
            self.artistName.setTitle(artistName, for: .normal)
            
        } else {
            let placeHolder = ""
            self.artistName.setTitle(placeHolder, for: .normal)
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
                self.artistName.setTitle(artistName, for: .normal)
                self.sound!.artist?.name = artistName
            }
        }
    }
}

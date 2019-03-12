//
//  PlayerV2ViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 2/6/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//
//mark: View, Share

import UIKit
import SCSDKCreativeKit
import ShareInstagram
import Parse
import Kingfisher
import SnapKit
import DeckTransition

class PlayerV2ViewController: UIViewController {

    let color = Color()
    let uiElement = UIElement()
    
    var player: Player?
    var sound: Sound?
    
    var playerDelegate: PlayerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.player != nil {
            self.sound = self.player!.sounds[self.player!.currentSoundIndex]
            setupNotificationCenter()
            setUpView()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let player = self.player?.player {
            if player.isPlaying {
                self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
                
            } else {
                self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
            }
        }
    }
    
    func setupNotificationCenter(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSound), name: NSNotification.Name(rawValue: "setSound"), object: nil)
    }
    
    //mark: sound
    @objc func didReceiveSound(){
        setSound()
    }
    
    func setSound() {
        if let player = self.player {
            self.sound = player.sounds[player.currentSoundIndex]
            setCurrentSoundView(self.sound!)
            self.shouldEnableSoundView(true)
        }
    }
    
    func setCurrentSoundView(_ sound: Sound) {
        self.songTitle.text = sound.title
        
        self.songArt.kf.setImage(with: URL(string: sound.artURL), placeholder: UIImage(named: "appy"))
        
        self.playBackTotalTime.text = formatTime(Double(self.player!.player!.duration))
        
        playBackSlider.maximumValue = Float(self.player!.player!.duration)
        self.startTimer()
        
        if let isLiked = sound.isLiked {
            if isLiked {
                self.likeButton.setImage(UIImage(named: self.likeRedImage), for: .normal)
                
            } else {
                self.likeButton.setImage(UIImage(named: self.likeImage), for: .normal)
            }
            
        } else {
            self.likeButton.setImage(UIImage(named: self.likeImage), for: .normal)
        }
        
        if let artistName = sound.artist?.name {
            self.artistName.setTitle(artistName, for: .normal)
            if let artistVerified = sound.artist?.isVerified {
                if artistVerified {
                    self.verifiedCheck.image = UIImage(named: "check")
                }
                
            } else {
                self.verifiedCheck.image = nil
            }
            
        } else {
            let placeHolder = ""
            self.artistName.setTitle(placeHolder, for: .normal)
            loadUserInfoFromCloud(sound.artist!.objectId)
        }
    }
    
    func shouldEnableSoundView(_ shouldEnable: Bool) {
        self.playBackButton.isEnabled = shouldEnable
        self.skipButton.isEnabled = shouldEnable
        self.goBackButton.isEnabled = shouldEnable
    }
    
    func isSoundLiked() -> Bool {
        if let sound = self.sound {
            if let isLiked = sound.isLiked {
                if isLiked {
                    return true
                }
            }
        }
        
        return false
    }
    
    func manageLikeForCurrentSound() {
        if let currentUser = PFUser.current() {
            if let sound = self.sound {
                if let isLiked = self.sound?.isLiked {
                    if isLiked {
                        unlikeSound(currentUser.objectId!, postId: sound.objectId)
                        
                    } else {
                        newLike(currentUser.objectId!, postId: sound.objectId)
                    }
                    
                } else {
                    newLike(currentUser.objectId!, postId: sound.objectId)
                }
            }
            
        } else {
            //show sign up alert
        }
    }
    
    func newLike(_ userId: String, postId: String) {
        self.likeButton.setImage(UIImage(named: likeRedImage), for: .normal)
        
        let newLike = PFObject(className: "Like")
        newLike["userId"] = userId
        newLike["postId"] = postId
        newLike["isRemoved"] = false 
        newLike.saveEventually {
            (success: Bool, error: Error?) in
            if (success) {
                self.player!.sounds[self.player!.currentSoundIndex].isLiked = true
                self.sound!.isLiked = true
                
            } else if let error = error {
                self.likeButton.setImage(UIImage(named: self.likeImage), for: .normal)
                print(error.localizedDescription)
            }
        }
    }
    
    func unlikeSound(_ userId: String, postId: String) {
        self.likeButton.setImage(UIImage(named: likeImage), for: .normal)
        
        let query = PFQuery(className: "Like")
        query.whereKey("postId", equalTo: postId)
        query.whereKey("userId", equalTo: userId)
        query.whereKey("isRemoved", equalTo: false)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                self.likeButton.setImage(UIImage(named: self.likeRedImage), for: .normal)
                print(error)
                
            } else if let object = object {
                object["isRemoved"] = true
                object.saveEventually()
                self.player!.sounds[self.player!.currentSoundIndex].isLiked = false
                self.sound!.isLiked = false
            }
        }
    }
    
    //mark: View
    lazy var exitButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "dismiss"), for: .normal)
        return button
    }()
    @objc func didPressExitButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    lazy var songArt: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.backgroundColor = .white
        return image
    }()
    
    lazy var songTitle: UILabel = {
        let label = UILabel()
        label.text = "Sound Title"
        label.textColor = color.black()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 25)
        label.textAlignment = .center
        return label
    }()
    
    lazy var artistName: UIButton = {
        let button = UIButton()
        button.setTitle("Artist Name", for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        return button
    }()
    @objc func didPressArtistNameButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: {() in
            if let playerDelegate = self.playerDelegate {
                playerDelegate.selectedArtist(self.sound?.artist)
            }
        })
    }
    
    lazy var verifiedCheck: UIImageView = {
        let image = UIImageView()
        return image
    }()
    
    lazy var tagButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "tag"), for: .normal)
        return button
    }()
    @objc func didpressTagButton(_ sender: UIButton) {
        //TODO: add tag action
    }
    
    lazy var commentButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "comment"), for: .normal)
        return button
    }()
    @objc func didPressCommentButton(_ sender: UIButton) {
        let modal = CommentViewController()
        //modal.player = self.player
        let transitionDelegate = DeckTransitioningDelegate()
        modal.transitioningDelegate = transitionDelegate
        modal.modalPresentationStyle = .custom
        present(modal, animated: true, completion: nil)
    }
    
    let likeRedImage = "like_red"
    let likeImage = "like"
    lazy var likeButton: UIButton = {
        let button = UIButton()
        return button
    }()
    @objc func didPressLikeButton(_ sender: UIButton) {
        manageLikeForCurrentSound()
    }
    
    lazy var shareButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "share"), for: .normal)
        return button
    }()
    @objc func didPressShareButton(_ sender: UIButton) {
        let alertController = UIAlertController (title: "Share this Sound" , message: "To:", preferredStyle: .actionSheet)
        
        let snapchatAction = UIAlertAction(title: "Snapchat", style: .default) { (_) -> Void in
            self.shareToSnapchat()
        }
        alertController.addAction(snapchatAction)
        
        let instagramAction = UIAlertAction(title: "Instagram", style: .default) { (_) -> Void in
            self.shareToInstagram()
        }
        alertController.addAction(instagramAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    lazy var playBackSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.tintColor = .darkGray
        slider.value = 0
        return slider
    }()
    @objc func sliderValueDidChange(_ sender: UISlider) {
        if let player = self.player?.player {
            player.currentTime = TimeInterval(sender.value)
            playBackCurrentTime.text = formatTime(Double(sender.value))
        }
    }
    
    var timer = Timer()
    @objc func UpdateTimer(_ timer: Timer) {
        if let player = self.player?.player {
            playBackCurrentTime.text = "\(formatTime(Double(player.currentTime)))"
            playBackSlider.value = Float(player.currentTime)
        }
    }
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTimer(_:)), userInfo: nil, repeats: true)
    }
    
    lazy var playBackCurrentTime: UILabel = {
        let label = UILabel()
        label.text = "0 s"
        label.textColor = color.black()
        label.font = UIFont(name: uiElement.mainFont, size: 10)
        return label
    }()
    
    lazy var playBackTotalTime: UILabel = {
        let label = UILabel()
        label.text = "0 s"
        label.textColor = color.black()
        label.font = UIFont(name: uiElement.mainFont, size: 10)
        return label
    }()
    
    lazy var playBackButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "pause"), for: .normal)
        button.isEnabled = false
        return button
    }()
    @objc func didPressPlayBackButton(_ sender: UIButton) {
        if let player = self.player?.player {
            if player.isPlaying {
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
    
    lazy var skipButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "skip"), for: .normal)
        button.isEnabled = false
        return button
    }()
    @objc func didPressSkipButton(_ sender: UIButton) {
        if let player = self.player {
            self.shouldEnableSoundView(false)
            self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
            player.next()
        }
    }
    
    lazy var goBackButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "goBack"), for: .normal)
        button.isEnabled = false
        return button
    }()
    @objc func didPressGoBackButton(_ sender: UIButton) {
        if let player = self.player {
            player.previous()
        }
    }
    
    func setUpView() {
        self.view.backgroundColor = .white
        
        //top views
        exitButton.addTarget(self, action: #selector(self.didPressExitButton(_:)), for: .touchUpInside)
        self.view.addSubview(exitButton)
        exitButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self.view).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        //sound views
        self.view.addSubview(songArt)
        songArt.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(self.view.frame.height / 2)
            make.top.equalTo(self.exitButton.snp.bottom).offset(uiElement.topOffset)
            //make.top.equalTo(self.exitButton.snp.bottom).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(exitButton)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(songTitle)
        songTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.songArt.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(exitButton)
            make.right.equalTo(songArt)
        }
        
        self.view.addSubview(artistName)
        artistName.addTarget(self, action: #selector(didPressArtistNameButton(_:)), for: .touchUpInside)
        artistName.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.songTitle.snp.bottom)
            make.left.equalTo(exitButton)
            make.right.equalTo(songArt)
        }
        
        /*self.artistName.addSubview(verifiedCheck)
         verifiedCheck.snp.makeConstraints { (make) -> Void in
         make.height.width.equalTo(15)
         make.top.equalTo(self.artistName).offset(13)
         make.left.equalTo(self.artistName.snp.right).offset(uiElement.elementOffset)
         //make.right.equalTo(self.view).offset(uiElement.rightOffset)
         }*/
        
        //playback views
        self.view.addSubview(playBackSlider)
        playBackSlider.addTarget(self, action: #selector(sliderValueDidChange(_:)), for: .valueChanged)
        playBackSlider.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.artistName.snp.bottom)
            make.left.equalTo(exitButton)
            make.right.equalTo(songArt)
        }
        
        self.view.addSubview(playBackCurrentTime)
        playBackCurrentTime.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(playBackSlider.snp.bottom)
            make.left.equalTo(playBackSlider)
        }
        
        self.view.addSubview(playBackTotalTime)
        playBackTotalTime.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(playBackCurrentTime)
            make.right.equalTo(songArt)
        }
        
        self.view.addSubview(playBackButton)
        self.playBackButton.addTarget(self, action: #selector(self.didPressPlayBackButton(_:)), for: .touchUpInside)
        playBackButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(65)
            make.top.equalTo(self.playBackSlider.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo((self.view.frame.width / 2) - (65 / 2))
        }
        
        self.view.addSubview(goBackButton)
        goBackButton.addTarget(self, action: #selector(didPressGoBackButton(_:)), for: .touchUpInside)
        goBackButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(55)
            make.top.equalTo(playBackButton).offset(3)
            make.right.equalTo(playBackButton.snp.left).offset(uiElement.rightOffset)
        }
        
        shareButton.addTarget(self, action: #selector(didPressShareButton(_:)), for: .touchUpInside)
        self.view.addSubview(shareButton)
        shareButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self.goBackButton).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        /*tagButton.addTarget(self, action: #selector(didpressTagButton(_:)), for: .touchUpInside)
        self.view.addSubview(tagButton)
        tagButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self.goBackButton).offset(uiElement.topOffset)
            make.right.equalTo(self.goBackButton.snp.left).offset(uiElement.rightOffset)
        }*/
        
        self.skipButton.addTarget(self, action: #selector(self.didPressSkipButton(_:)), for: .touchUpInside)
        self.view.addSubview(skipButton)
        skipButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(55)
            make.top.equalTo(playBackButton).offset(3)
            make.left.equalTo(self.playBackButton.snp.right).offset(uiElement.leftOffset)
        }
        
        if isSoundLiked() {
            likeButton.setImage(UIImage(named: likeRedImage), for: .normal)
            
        } else {
            likeButton.setImage(UIImage(named: likeImage), for: .normal)
        }
        likeButton.addTarget(self, action: #selector(didPressLikeButton(_:)), for: .touchUpInside)
        self.view.addSubview(likeButton)
        likeButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self.skipButton).offset(uiElement.topOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        /*commentButton.addTarget(self, action: #selector(didPressCommentButton(_:)), for: .touchUpInside)
        self.view.addSubview(commentButton)
        commentButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self.skipButton).offset(uiElement.topOffset)
            make.left.equalTo(self.skipButton.snp.right).offset(uiElement.leftOffset)
            make.right.equalTo(self.likeButton.snp.left).offset(uiElement.rightOffset)
        }*/
        
        setSound()
    }
    
    //mark: share
    let shareAppURL = "https://www.soundbrew.app/ios"
    
    func shareToSnapchat() {
        if let stickerImage = createShareableSticker() {
            let sticker = SCSDKSnapSticker(stickerImage: stickerImage)
            
            let snap = SCSDKNoSnapContent()
            snap.sticker = sticker
            snap.attachmentUrl = shareAppURL
            let api = SCSDKSnapAPI(content: snap)
            api.startSnapping(completionHandler: { (error: Error?) in
                if let error = error {
                    print("Snapchat error: \(error)")
                }
            })
            
        } else {
            print("didn't work")
        }
    }
    
    func shareToInstagram() {
        if let stickerImage = createShareableSticker() {
            let share = ShareImageInstagram()
            
            share.postToInstagramStories(image: stickerImage, backgroundTopColorHex: "0x393939" , backgroundBottomColorHex: "0x393939", deepLink: shareAppURL)
        }
    }
    
    func createShareableSticker() -> UIImage? {
        // let image: UIImage?
        
        let stickerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        stickerView.backgroundColor = .white
        
        let songArt = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        songArt.image = self.songArt.image!
        songArt.backgroundColor = .white
        
        let songTitle = UILabel(frame: CGRect(x: 55, y: 0, width: 140, height: 20))
        songTitle.text = self.songTitle.text!
        songTitle.textColor = color.black()
        songTitle.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 12)
        
        let artistName = UILabel(frame: CGRect(x: 55, y: 15, width: 140, height: 20))
        artistName.text = self.artistName.titleLabel!.text!
        artistName.textColor = color.black()
        artistName.font = UIFont(name: uiElement.mainFont, size: 11)
        
        let listenOnLabel = UILabel(frame: CGRect(x: 55, y: 30, width: 140, height: 20))
        listenOnLabel.text = "Listening on Soundbrew"
        listenOnLabel.textColor = color.black()
        listenOnLabel.font = UIFont(name: uiElement.mainFont, size: 9)
        
        stickerView.addSubview(songArt)
        stickerView.addSubview(listenOnLabel)
        stickerView.addSubview(songTitle)
        stickerView.addSubview(artistName)
        
        UIGraphicsBeginImageContextWithOptions(stickerView.bounds.size, false, 0.0)
        stickerView.drawHierarchy(in: stickerView.bounds, afterScreenUpdates: true)
        let snapshotImageFromMyView = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        //snapshotImageFromMyView
        return snapshotImageFromMyView
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
                
                self.sound!.artist?.city = user["city"] as? String
                
                if let artistVerified = user["artistVerified"] as? Bool {
                    self.sound!.artist?.isVerified = artistVerified
                    if artistVerified {
                        self.verifiedCheck.image = UIImage(named: "check")
                        
                    } else {
                        self.verifiedCheck.image = nil
                    }
                    
                } else {
                    self.verifiedCheck.image = nil
                }
                
                //Don't want to add blank space to social and streams... that's why we're checking.
                
                /*if let instagramHandle = user["instagramHandle"] as? String {
                 if !instagramHandle.isEmpty {
                 self.sounds[i].instagramHandle = "https://www.instagram.com/\(instagramHandle)"
                 }
                 }
                 
                 if let twitterHandle = user["twitterHandle"] as? String {
                 if !twitterHandle.isEmpty {
                 self.sounds[i].twitterHandle = "https://www.twitter.com/\(twitterHandle)"
                 }
                 }
                 
                 if let soundCloudLink = user["soundCloudLink"] as? String {
                 if !soundCloudLink.isEmpty {
                 self.sounds[i].soundcloudLink = soundCloudLink
                 }
                 }
                 
                 if let appleMusicLink = user["appleMusicLink"] as? String {
                 if !appleMusicLink.isEmpty {
                 self.sounds[i].appleMusicLink = appleMusicLink
                 }
                 }
                 
                 if let spotifyLink = user["spotifyLink"] as? String {
                 if !spotifyLink.isEmpty {
                 self.sounds[i].spotifyLink = spotifyLink
                 }
                 }
                 
                 if let otherLlink = user["otherLink"] as? String {
                 if !otherLlink.isEmpty {
                 self.sounds[i].otherLink = otherLlink
                 }
                 }*/
            }
        }
    }
    
    //mark: mich
    func formatTime(_ durationInSeconds: Double ) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        
        let formattedString = formatter.string(from: durationInSeconds)!
        
        return formattedString
    }
}

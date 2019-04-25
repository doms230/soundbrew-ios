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
import SwiftVideoGenerator
import Photos
import NVActivityIndicatorView
import AppCenterAnalytics
import FirebaseDynamicLinks

class PlayerV2ViewController: UIViewController, NVActivityIndicatorViewable {

    let color = Color()
    let uiElement = UIElement()
    
    var player: Player?
    var sound: Sound?
    
    var playerDelegate: PlayerDelegate?
    var commentDelegate: CommentDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let sound = self.player?.currentSound {
            self.sound = sound 
            setupNotificationCenter()
            setUpView()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let player = self.player {
            self.sound = player.currentSound
            if let currentPlayer = player.player {
                if currentPlayer.isPlaying && player.currentSound != nil {
                    self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
                    
                } else {
                    self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
                }
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
            self.sound = player.currentSound
            setCurrentSoundView(self.sound!)
            self.shouldEnableSoundView(true)
        }
    }
    
    func setCurrentSoundView(_ sound: Sound) {
        self.songTitle.text = sound.title
        
        self.songArt.kf.setImage(with: URL(string: sound.artURL), placeholder: UIImage(named: "appy"))
        
        if let duration = self.player?.player?.duration {
            self.playBackTotalTime.text = self.uiElement.formatTime(Double(duration))
            
            playBackSlider.maximumValue = Float(duration)
            self.startTimer()
        }
        
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
                        MSAnalytics.trackEvent("New Like")
                    }
                    
                } else {
                    newLike(currentUser.objectId!, postId: sound.objectId)
                    MSAnalytics.trackEvent("New Like")
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
                self.incrementLikeCount(sound: self.sound!, incrementLikes: true, decrementLikes: false)
                
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
                object.saveEventually {
                    (success: Bool, error: Error?) in
                    if success && error == nil {
                        self.incrementLikeCount(sound: self.sound!, incrementLikes: false, decrementLikes: true)
                    }
                }
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
        self.dismiss(animated: true, completion: {() in
            if let commentDelegate = self.commentDelegate {
                commentDelegate.selectedComments(self.sound?.objectId, atTime: self.playBackSlider.value)
            }
        })
    }
    
    let likeRedImage = "like_red"
    let likeImage = "like"
    lazy var likeButton: UIButton = {
        let button = UIButton()
        return button
    }()
    @objc func didPressLikeButton(_ sender: UIButton) {
        if PFUser.current() != nil {
            manageLikeForCurrentSound()
        }
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
        
        let musicVideoAction = UIAlertAction(title: "Copy Link", style: .default) { (_) -> Void in
            self.copyLink()
        }
        alertController.addAction(musicVideoAction)
        
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
            playBackCurrentTime.text = self.uiElement.formatTime(Double(sender.value))
        }
    }
    
    var timer = Timer()
    @objc func UpdateTimer(_ timer: Timer) {
        if let player = self.player?.player {
            playBackCurrentTime.text = "\(self.uiElement.formatTime(Double(player.currentTime)))"
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
            make.centerX.equalTo(self.view)
           // make.left.equalTo((self.view.frame.width / 2) - (65 / 2))
        }
        
        self.view.addSubview(goBackButton)
        goBackButton.addTarget(self, action: #selector(didPressGoBackButton(_:)), for: .touchUpInside)
        goBackButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(55)
            //make.top.equalTo(playBackButton).offset(3)
            make.centerY.equalTo(playBackButton)
            make.centerX.equalTo(self.view).offset(-(55 + uiElement.leftOffset))
           // make.right.equalTo(playBackButton.snp.left).offset(uiElement.rightOffset)
        }
        
        shareButton.addTarget(self, action: #selector(didPressShareButton(_:)), for: .touchUpInside)
        self.view.addSubview(shareButton)
        shareButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            //make.top.equalTo(self.goBackButton).offset(uiElement.topOffset)
            make.centerY.equalTo(self.goBackButton)
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
            //make.top.equalTo(playBackButton).offset(3)
            make.centerY.equalTo(playBackButton)
            make.centerX.equalTo(self.view).offset(55 + uiElement.leftOffset)
            //make.left.equalTo(self.playBackButton.snp.right).offset(uiElement.leftOffset)
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
           //make.top.equalTo(self.skipButton).offset(uiElement.topOffset)
            make.centerY.equalTo(self.skipButton)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        commentButton.addTarget(self, action: #selector(didPressCommentButton(_:)), for: .touchUpInside)
        self.view.addSubview(commentButton)
        commentButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self.likeButton)
            //make.left.equalTo(self.skipButton.snp.right).offset(uiElement.leftOffset)
            make.right.equalTo(self.likeButton.snp.left).offset(uiElement.rightOffset)
        }
        
        setSound()
    }
    
    //mark: share
    let shareAppURL = "https://www.soundbrew.app/ios"
    
    func copyLink() {
        guard let link = URL(string: "https://soundbrew.app/\(sound!.objectId!)") else { return }
        let dynamicLinksDomainURIPrefix = "https://soundbrew.page.link"
        let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: dynamicLinksDomainURIPrefix)
        linkBuilder!.iOSParameters = DynamicLinkIOSParameters(bundleID: "com.soundbrew.soundbrew-artists")
        linkBuilder!.iOSParameters!.appStoreID = "1438851832"
        linkBuilder!.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        linkBuilder!.socialMetaTagParameters!.title = "\(self.sound!.title!)"
        linkBuilder!.socialMetaTagParameters!.descriptionText = "Listen to \(self.sound!.title!) by \(self.sound!.artist!.name!) on Soundbrew!"
        linkBuilder!.socialMetaTagParameters!.imageURL = URL(string: self.sound!.artURL)
        linkBuilder!.shorten() { url, warnings, error in
            if let error = error {
                print(error)
                
            } else if let url = url {
                UIPasteboard.general.string = "\(url)"
                self.uiElement.showAlert("Success", message: "Link copied.", target: self)
            }
            
            //guard let url = url, error != nil else { return }

        }
        //guard let longDynamicLink = linkBuilder!.url else { return }
        //print("The long URL is: \(longDynamicLink)")
    }
    
    func imageForSharing() -> UIImage {
        let soundArtImage = SoundArtImage(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        soundArtImage.songArt.image = sound?.artImage
        soundArtImage.updateConstraints()
        return soundArtImage.asImage()
    }
    
    func prepareAudioFileForSharing() {
        self.startAnimating()
        
        do {
            let audioURL = URL(string: sound!.audioURL)
            let audioData = sound!.audioData
            
            let audioFileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("\(audioURL!.lastPathComponent)")
            try audioData?.write(to: audioFileURL, options: .atomic)
            
            generateVideoFromAudioAndArtFile(audioFileURL)
            
        } catch let error {
            self.stopAnimating()
            fatalError("*** Unable to set up the audio session: \(error.localizedDescription) ***")
        }
    }
    
    func generateVideoFromAudioAndArtFile(_ audioFileURL: URL) {
        let musicVideoImage = imageForSharing()
        VideoGenerator.current.fileName = "SingleMovieFileName"
        VideoGenerator.current.shouldOptimiseImageForVideo = true
        VideoGenerator.current.maxVideoLengthInSeconds = 30
        VideoGenerator.current.videoBackgroundColor = .black
        VideoGenerator.current.generate(withImages: [musicVideoImage], andAudios: [audioFileURL], andType: .single, { (progress) in
            print(progress)
            
        }, success: { (url) in
            print(url)
            self.stopAnimating()
            print("absolute String: \(url.absoluteString)")
            self.saveVideoToUserPhotoLibrary(url)
            
        }, failure: { (error) in
            print(error)
            self.stopAnimating()
            self.uiElement.showAlert("Oops", message: "There was an issue creating the music video snippet", target: self)
        })
    }
    
    func saveVideoToUserPhotoLibrary(_ url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            
        }) { saved, error in
            if saved {
                let alertController = UIAlertController(title: "Your video was successfully saved to your photos library.", message: nil, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
                self.stopAnimating()
            }
        }
    }
    
    func checkAccessToPhotoLibrary() {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            self.prepareAudioFileForSharing()
            break
            
        case .denied:
            self.uiElement.permissionDenied("You Denied Access", message: "Soundbrew needs access to your photo library to create a music video snippet. ", target: self)
            break
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                if newStatus == PHAuthorizationStatus.authorized {
                    self.prepareAudioFileForSharing()
                    
                } else {
                    self.uiElement.permissionDenied("You Denied Access", message: "Soundbrew needs access to your photo library to create a music video snippet. ", target: self)
                }
            })
            break
            
        case .restricted:
            break
            
        default:
            break
        }
    }
    
    func shareToSnapchat() {
        let snapchatImage = imageForSharing()
        let snap = SCSDKNoSnapContent()
        snap.sticker = SCSDKSnapSticker(stickerImage: snapchatImage)
        snap.attachmentUrl = shareAppURL
        let api = SCSDKSnapAPI(content: snap)
        api.startSnapping(completionHandler: { (error: Error?) in
            if let error = error {
                print("Snapchat error: \(error)")
            }
        })
    }
    
    func shareToInstagram() {
        let share = ShareImageInstagram()
        let igImage = imageForSharing()
        share.postToInstagramStories(image: igImage, backgroundTopColorHex: "0x393939" , backgroundBottomColorHex: "0x393939", deepLink: shareAppURL)
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
            }
        }
    }
    
    func incrementLikeCount(sound: Sound, incrementLikes: Bool, decrementLikes: Bool) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: sound.objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                if incrementLikes {
                    object.incrementKey("likes")
                    
                } else if decrementLikes {
                    object.incrementKey("likes", byAmount: -1)
                }
                
                object.saveEventually()
            }
        }
    }
}

//
// PlayerViewController.swift
// soundbrew
//
// Created by Dominic Smith on 2/6/19.
// Copyright © 2019 Dominic  Smith. All rights reserved.
//
// mark: View, Share, tips

import UIKit
import SCSDKCreativeKit
import ShareInstagram
import Parse
import Kingfisher
import SnapKit
import Photos
import AppCenterAnalytics
import GoogleMobileAds

class PlayerViewController: UIViewController, PlayerDelegate, TagDelegate, GADBannerViewDelegate {
    
    let color = Color()
    let uiElement = UIElement()
    
    var player = Player.sharedInstance
    var sound: Sound?
    
    var playerDelegate: PlayerDelegate?
    var tagDelegate: TagDelegate?
    
    var skipCount = 0
    var like: Like!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Soundbrew"
        setupNotificationCenter()
        setSound()
   }
        
    override func viewDidAppear(_ animated: Bool) {
        customer = Customer.shared
        if let balance = customer.artist?.balance {
            if balance == 0 {
                setUpBannerView()
            }
        } else {
            setUpBannerView()
        }
    }
    
    func setupNotificationCenter(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSoundUpdate), name: NSNotification.Name(rawValue: "setSound"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector:#selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    //mark: money
    var customer = Customer.shared
    
    func checkIfUserLikedSong(_ sound: Sound) {
        self.currentSoundCredits.removeAll()
        if let userId = PFUser.current()?.objectId {
            self.likeSoundButton.setImage(UIImage(named: "sendTip"), for: .normal)
            self.likeSoundButton.isEnabled = false
            
            let query = PFQuery(className: "Tip")
            query.whereKey("fromUserId", equalTo: userId)
            query.whereKey("soundId", equalTo: sound.objectId!)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                 if let object = object {
                    if let tipAmount = object["amount"] as? Int {
                        self.sound?.tipAmount = tipAmount
                        self.paymentAmountForLike.text = self.uiElement.convertCentsToDollarsAndReturnString(tipAmount, currency: "$")
                    }
                    
                 } else {
                    self.paymentAmountForLike.text = ""
                }
                self.likeSoundButton.isEnabled = true
                self.loadCredits(sound.objectId!)
            }
        }
    }
    
    var currentSoundCredits = [Credit]()
    func loadCredits(_ postId: String) {
        let query = PFQuery(className: "Credit")
        query.whereKey("postId", equalTo: postId)
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                for object in objects {
                    let userId = object["userId"] as? String
                    let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil)
                    
                    let credit = Credit(objectId: object.objectId, artist: artist, title: nil, percentage: 0)
                    if let title = object["title"] as? String {
                        credit.title = title
                    }
                    if let percentage = object["percentage"] as? Int {
                        credit.percentage = percentage
                    }
                    
                    self.currentSoundCredits.append(credit)
                }
            }
            self.like.soundCredits = self.currentSoundCredits
        }
    }
    
    //mark: sound
    @objc func didReceiveSoundUpdate(){
        setSound()
    }
    
    @objc func didBecomeActive() {
        if self.viewIfLoaded?.window != nil {
            player.target = self
        }
    }
    
    func setSound() {
        if let sound = player.currentSound {
            self.like = Like(sound: sound, paymentAmount: 10, soundCredits: self.currentSoundCredits, target: self)
            player.target = self
            self.sound = sound

            checkIfUserLikedSong(sound)
            
            self.songTitle.text = sound.title
            
            self.songArt.kf.setImage(with: URL(string: sound.artURL ?? ""), placeholder: UIImage(named: "sound"))
            
            if let duration = self.player.player?.duration {
                self.playBackTotalTime.text = self.uiElement.formatTime(Double(duration))
                playBackSlider.maximumValue = Float(duration)
                self.startTimer()
            }
            
            if playBackButton.superview == nil {
                showPlayerView()
            } else {
                setCountLabel(self.commentCountLabel, count: sound.commentCount)
                setCountLabel(self.playCountLabel, count: sound.playCount)
                setCountLabel(self.likeCountLabel, count: sound.tipCount)
                var tagCount = 0
                if let tags = sound.tags {
                    tagCount = tags.count
                }
                setCountLabel(self.hashtagCountLabel, count: tagCount)
                //credits should be atleast 1 because of uploading artist where sounds were uplaoded before credits were a thing.
                var creditCount = 1
                if let count = sound.creditCount {
                    creditCount = count
                }
                setCountLabel(self.creditCountLabel, count: creditCount)
                if let artistImage = sound.artist?.image {
                    self.soundArtistImage.kf.setImage(with: URL(string: artistImage))
                } else {
                    self.soundArtistImage.image = UIImage(named: "profile_icon")
                }
            }
            
            updatePlayBackControls()
        }
    }
    
    func resetPlayView() {
        self.playBackButton.isHidden = true
        
        self.loadSoundSpinner.isHidden = false
        
        timer.invalidate()
        self.playBackSlider.value = 0
        self.playBackSlider.isEnabled = false
        
        self.playBackCurrentTime.text = "0s"
        self.playBackTotalTime.text = "0s"
        
        self.soundArtistImage.image = UIImage()
        self.soundArtistImage.backgroundColor = .darkGray

        self.creditCountButton.isEnabled = false
        self.creditCountLabel.text = "0"
        
        self.commentCountButton.isEnabled = false
        self.commentCountLabel.text = "0"
        
        self.playCountButton.isEnabled = false
        self.playCountLabel.text = "0"
        
        self.hashtagCountButton.isEnabled = false
        self.hashtagCountLabel.text = "0"
        
        self.likesCountButton.isEnabled = false
        self.likeCountLabel.text = "0"

        self.likeSoundButton.isEnabled = false
        self.paymentAmountForLike.text = ""
        
        self.shareButton.isEnabled = false
        
        self.songTitle.text = ""
        
        self.songArt.image = UIImage(named: "sound")
    }
    
    func updatePlayBackControls() {
        if let soundPlayer = player.player {
            self.creditCountButton.isEnabled = true
            self.commentCountButton.isEnabled = true
            self.playCountButton.isEnabled = true
            self.hashtagCountButton.isEnabled = true
            self.likesCountButton.isEnabled = true
            self.likeSoundButton.isEnabled = true

            self.loadSoundSpinner.isHidden = true
            self.playBackButton.isHidden = false
            self.playBackButton.isEnabled = true
            
            self.shareButton.isEnabled = true
            self.playBackSlider.isEnabled = true
            
            self.songArt.isHidden = false
            
            if soundPlayer.isPlaying  {
                self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
                
            } else {
                self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
            }
            self.skipButton.setImage(UIImage(named: "skip"), for: .normal)
            self.goBackButton.setImage((UIImage(named: "goBack")), for: .normal)
        } else {
            self.loadSoundSpinner.isHidden = false
            self.playBackButton.isHidden = true
        }
    }
    
    //mark: View
    func handleDismissal(_ artist: Artist?) {
        if let playerDelegate = self.playerDelegate {
            self.dismiss(animated: true, completion: {() in
                playerDelegate.selectedArtist(artist)
            })
        }
    }
    func selectedArtist(_ artist: Artist?) {
        if let artist = artist {
            handleDismissal(artist)
        }
    }
    
    lazy var exitButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "dismiss"), for: .normal)
        button.addTarget(self, action: #selector(self.didPressExitButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressExitButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func soundInfoButton(_ imageName: String, buttonType: String?) -> UIButton {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        self.view.addSubview(button)
        
        let imageView = UIImageView()
        imageView.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        let originalImage = UIImage(named: imageName)
        let tintedImage = originalImage?.withRenderingMode(.alwaysTemplate)
        imageView.image = tintedImage
        button.addSubview(imageView)
        
        let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 15)
        label.textAlignment = .left
        button.addSubview(label)
        label.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(imageView)
            make.top.equalTo(imageView.snp.bottom).offset(uiElement.elementOffset)
        }
        
        if let buttonType = buttonType {
            switch buttonType {
            case "comments":
                imageView.tintColor = .lightGray
                var commentCount = 1
                if let soundCommentCount = self.sound?.commentCount {
                    commentCount = soundCommentCount
                }
                self.setCountLabel(label, count: commentCount)
                self.commentCountLabel = label
                break
                
            case "likes":
                imageView.tintColor = .lightGray
                self.setCountLabel(label, count: self.sound?.tipCount)
                self.likeCountLabel = label
                break
                
            case "credits":
                self.setCountLabel(label, count: self.sound?.creditCount)
                self.creditCountLabel = label
                imageView.layer.cornerRadius = 25 / 2
                imageView.clipsToBounds = true
                self.soundArtistImage = imageView
                break
                
            case "plays":
                imageView.tintColor = .lightGray
                self.setCountLabel(label, count: self.sound?.playCount)
                self.playCountLabel = label
                break
                
            case "tags":
                imageView.tintColor = .lightGray
                var tagCount = 0
                if let tags = self.sound?.tags {
                    tagCount = tags.count
                }
                self.setCountLabel(label, count: tagCount)
                self.hashtagCountLabel = label
                break
                
            default:
                break
            }
            
        } else {
            imageView.tintColor = .white
        }
        
        return button
    }
    
    func setCountLabel(_ label: UILabel, count: Int?) {
        if let count = count {
            label.text = "\(count)"
        } else {
            label.text = "0"
        }
    }
    
    @objc func didPressCommentCountButton(_ sender: UIButton) {
        let commentModal = CommentViewController()
        if let sound = self.sound {
            commentModal.playerDelegate = self
            commentModal.sound = sound
        }
        self.present(commentModal, animated: true, completion: nil)
    }
    
    @objc func didPressLikeCountButton(_ sender: UIButton) {
        setupAndPresentPeopleViewController("likes")
    }
    
    @objc func didPressListenCountButton(_ sender: UIButton) {
        setupAndPresentPeopleViewController("listens")
    }
    
    @objc func didPressCreditCountButton(_ sender: UIButton) {
        if let sound = self.sound {
            if let creditCount = sound.creditCount {
                if creditCount > 1 {
                    setupAndPresentPeopleViewController("credits")
                } else {
                    self.handleDismissal(sound.artist)
                }
                
            } else {
                self.handleDismissal(sound.artist)
            }
        }
    }
    
    @objc func didPressTagCountButton(_ sender: UIButton) {
        if let sound = sound {
            let tagsModal = ChooseTagsViewController()
            tagsModal.tagDelegate = self
            tagsModal.sound = sound
            tagsModal.isViewTagsFromSound = true 
            self.present(tagsModal, animated: true, completion: nil)
        }
    }
    
    func receivedTags(_ chosenTags: Array<Tag>?) {
        if let tags = chosenTags, let tagDelegate = self.tagDelegate {            
            self.dismiss(animated: true, completion: {() in
                tagDelegate.receivedTags(tags)
            })
        }
    }
    
    func setupAndPresentPeopleViewController(_ loadType: String) {
        if let sound = self.sound {
            let modal = PeopleViewController()
            modal.playerDelegate = self
            modal.loadType = loadType
            modal.sound = sound
            self.present(modal, animated: true, completion: nil)
        }
    }
    
    lazy var appTitle: UILabel = {
        let label = UILabel()
        label.text = "Soundbrew"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 15)
        label.textAlignment = .center
        return label
    }()
    
    lazy var songArt: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.backgroundColor = color.black()
        return image
    }()
    
    lazy var songTitle: UILabel = {
        let localizedSoundTitle = NSLocalizedString("soundTitle", comment: "")
        let label = UILabel()
        label.text = localizedSoundTitle
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 25)
        label.textAlignment = .center
        label.numberOfLines = 3
        return label
    }()
    
    lazy var likeSoundButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "sendTip"), for: .normal)
        button.addTarget(self, action: #selector(self.didPressLikeButton(_:)), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    @objc func didPressLikeButton(_ sender: UIButton) {
        self.likeSoundButton.setImage(UIImage(named: "sendTipColored"), for: .normal)
        self.likeSoundButton.isEnabled = false
        self.like.sendPayment()
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "TipButton", "Description": "Current User attempted to tip artist"])
    }
    
    lazy var paymentAmountForLike: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 10)
        label.textAlignment = .center
        return label
    }()
    
    lazy var shareButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "share"), for: .normal)
        button.addTarget(self, action: #selector(didPressShareButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressShareButton(_ sender: UIButton) {
        if let sound = self.sound {
            self.uiElement.showShareOptions(self, sound: sound)
            MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "Share", "Description": "User Pressed Share Button."])
        }
    }
    
    lazy var playBackSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.tintColor = .darkGray
        slider.value = 0
        slider.addTarget(self, action: #selector(sliderValueDidChange(_:)), for: .valueChanged)
        return slider
    }()
    
    @objc func sliderValueDidChange(_ sender: UISlider) {
        if let soundPlayer = player.player {
            player.setBackgroundAudioNowPlaying(soundPlayer, sound: sound!)
            soundPlayer.currentTime = TimeInterval(sender.value)
            playBackCurrentTime.text = self.uiElement.formatTime(Double(sender.value))
        }
        
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "PlayBackSlider", "Description": "User seeked time on song"])
    }
    
    var timer = Timer()
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTimer(_:)), userInfo: nil, repeats: true)
    }
    @objc func UpdateTimer(_ timer: Timer) {
        if let currentTime = player.player?.currentTime {
            playBackCurrentTime.text = "\(self.uiElement.formatTime(Double(currentTime)))"
            playBackSlider.value = Float(currentTime)
        }
    }
    
    lazy var playBackCurrentTime: UILabel = {
        let label = UILabel()
        label.text = "0 s"
        label.textColor = .white
        label.font = UIFont(name: uiElement.mainFont, size: 10)
        return label
    }()
    
    lazy var playBackTotalTime: UILabel = {
        let label = UILabel()
        label.text = "0 s"
        label.textColor = .white
        label.font = UIFont(name: uiElement.mainFont, size: 10)
        return label
    }()
    
    lazy var playBackButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "pause"), for: .normal)
        button.isEnabled = false
        button.addTarget(self, action: #selector(self.didPressPlayBackButton(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var loadingSoundbrewSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .white
        spinner.startAnimating()
        return spinner
    }()
    
    lazy var loadSoundbrewSpinnerTitle: UILabel = {
        let localizedSteepingSoundbrew = NSLocalizedString("steepingSoundbrew", comment: "")
        let label = UILabel()
        label.text = localizedSteepingSoundbrew
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 15)
        label.textAlignment = .center
        return label
    }()
    
    lazy var loadSoundSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .white
        spinner.startAnimating()
        spinner.isHidden = true
        return spinner
    }()
        
    @objc func didPressPlayBackButton(_ sender: UIButton) {
        if let soundPlayer = player.player {
            if soundPlayer.isPlaying {
                player.pause()
                timer.invalidate()
                self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
                MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "Pause", "Description": "User Pressed Pause."])
                
            } else {
                player.play()
                startTimer()
                self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
                MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "Play", "Description": "User Pressed Play."])
            }
        }
    }
    
    lazy var skipButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "skip"), for: .normal)
        button.addTarget(self, action: #selector(self.didPressSkipButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressSkipButton(_ sender: UIButton) {
        self.resetPlayView()
        
        if let balance = customer.artist?.balance {
            if balance > 10 {
                skipCount = 0
            }
        }
        
        if skipCount > 1 {
            player.player = nil
            addBannerViewtoPlayerView(bannerView)
            self.songArt.isHidden = true
            skipCount = 0

        } else {
            skipCount += 1
            bannerView.removeFromSuperview()
            bannerRemoveAdsButton.removeFromSuperview()
            player.next()
        }
        
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "Skip", "Description": "User Skipped Song."])
    }
    
    lazy var goBackButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "goBack"), for: .normal)
        button.addTarget(self, action: #selector(didPressGoBackButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressGoBackButton(_ sender: UIButton) {
        player.previous()
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "Go Back", "Description": "User Pressed Go Back."])
    }
    
    var creditCountButton: UIButton!
    var creditCountLabel: UILabel!
    
    var playCountButton: UIButton!
    var playCountLabel: UILabel!
    
    var commentCountButton: UIButton!
    var commentCountLabel: UILabel!
    
    var hashtagCountButton: UIButton!
    var hashtagCountLabel: UILabel!
    
    var likesCountButton: UIButton!
    var likeCountLabel: UILabel!
    
    var soundArtistImage: UIImageView!
    
    func showPlayerView() {
        self.view.backgroundColor = color.black()
        
        let songArtHeightWidth = (self.view.frame.height / 2) - 100
        
        //top views
        self.view.addSubview(exitButton)
        exitButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self.view).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        /*let menu = soundInfoButton("more", buttonType: nil)
        menu.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(exitButton)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }*/
        
        self.view.addSubview(appTitle)
        appTitle.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(exitButton)
        }
        
        //sound views
        self.view.addSubview(songArt)
        songArt.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(songArtHeightWidth)
            make.top.equalTo(exitButton.snp.bottom).offset(uiElement.topOffset * 3)
            make.centerX.equalTo(self.view)
        }
        
        //sound info
        var bottomOffsetValue: Int!
        switch UIDevice.modelName {
        case "iPhone X", "iPhone XS", "iPhone XR", "iPhone 11", "iPhone 11 Pro", "iPhone 11 Pro Max", "iPhone XS Max", "Simulator iPhone 11 Pro Max":
            bottomOffsetValue = uiElement.bottomOffset * 5
            break
            
        default:
            bottomOffsetValue = uiElement.bottomOffset * 2
            break
        }
        creditCountButton = soundInfoButton("profile_icon_filled", buttonType: "credits")
        creditCountButton.addTarget(self, action: #selector(self.didPressCreditCountButton(_:)), for: .touchUpInside)
        creditCountButton.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.bottom.equalTo(self.view).offset(bottomOffsetValue)
        }
        
        playCountButton = soundInfoButton("play", buttonType: "plays")
        playCountButton.addTarget(self, action: #selector(self.didPressListenCountButton(_:)), for: .touchUpInside)
        playCountButton.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(creditCountButton)
        }

        commentCountButton = soundInfoButton("comment_filled", buttonType: "comments")
        commentCountButton.addTarget(self, action: #selector(self.didPressCommentCountButton(_:)), for: .touchUpInside)
        commentCountButton.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(self.view.frame.width * 0.25)
            make.bottom.equalTo(creditCountButton)
        }
        
        hashtagCountButton = soundInfoButton("hashtag_filled", buttonType: "tags")
        hashtagCountButton.addTarget(self, action: #selector(self.didPressTagCountButton(_:)), for: .touchUpInside)
        hashtagCountButton.snp.makeConstraints { (make) -> Void in
            make.right.equalTo(self.view).offset(-(self.view.frame.width * 0.25))
            make.bottom.equalTo(creditCountButton)
        }
        
        likesCountButton = soundInfoButton("heart_filled", buttonType: "likes")
        likesCountButton.addTarget(self, action: #selector(self.didPressLikeCountButton(_:)), for: .touchUpInside)
        likesCountButton.snp.makeConstraints { (make) -> Void in
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(creditCountButton)
        }
        
        self.view.addSubview(playBackButton)
        playBackButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(60)
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(likesCountButton.snp.top).offset(uiElement.bottomOffset * 5)
        }
        
        self.view.addSubview(loadSoundSpinner)
        loadSoundSpinner.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(60)
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(playBackButton)
        }
        
        self.view.addSubview(goBackButton)
        goBackButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(45)
            make.centerY.equalTo(playBackButton)
            make.centerX.equalTo(commentCountButton)
        }
        
        self.view.addSubview(skipButton)
        skipButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(45)
            make.centerY.equalTo(playBackButton)
            make.centerX.equalTo(hashtagCountButton)
        }
        
        self.view.addSubview(likeSoundButton)
        likeSoundButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(30)
            make.centerY.equalTo(self.skipButton)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        self.view.addSubview(paymentAmountForLike)
        paymentAmountForLike.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(likeSoundButton.snp.bottom)
            make.centerX.equalTo(likeSoundButton)
        }
        
        self.view.addSubview(shareButton)
        shareButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(30)
            make.centerY.equalTo(self.skipButton)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
                
        //playback views
        self.view.addSubview(playBackSlider)
        playBackSlider.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(shareButton.snp.top).offset(uiElement.bottomOffset)
        }
        
        self.view.addSubview(playBackCurrentTime)
        playBackCurrentTime.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.bottom.equalTo(playBackSlider.snp.top).offset(-(uiElement.elementOffset))
        }
        
        self.view.addSubview(playBackTotalTime)
        playBackTotalTime.snp.makeConstraints { (make) -> Void in
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(playBackCurrentTime)
        }
        
        self.view.addSubview(songTitle)
        songTitle.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.playBackTotalTime.snp.top).offset(uiElement.bottomOffset)
        }
                
        //setSound()
    }
    
    //mark: ads
    //mark: Banner Ads
    let liveBannerAdUnitId = "ca-app-pub-9150756002517285~6608111231"
    let testBannerAdUnitId = "ca-app-pub-9150756002517285/6558051480"
    var bannerView = GADBannerView()
    var bannerRemoveAdsButton = UIButton()
    
    func setUpBannerView() {
        bannerView = GADBannerView(adSize: kGADAdSizeLeaderboard)
        bannerView.adUnitID = testBannerAdUnitId
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.load(GADRequest())
    }
    
    /// Tells the delegate an ad request loaded an ad.

    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        bannerView.removeFromSuperview()
        bannerRemoveAdsButton.removeFromSuperview()
        self.skipTimerLabel.removeFromSuperview()
        self.labelAmount = 4
        self.skipButton.isHidden = false
        player.next()
    }
    
    var skipTimerLabel: UILabel!
    var labelAmount = 4
    
    func addBannerViewtoPlayerView(_ bannerView: GADBannerView) {
        let songArtHeightWidth = (self.view.frame.height / 2) - 100
        self.view.addSubview(bannerView)
        bannerView.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(songArtHeightWidth)
            make.top.equalTo(exitButton.snp.bottom).offset(uiElement.topOffset * 3)
            make.centerX.equalTo(self.view)
        }
        
        bannerRemoveAdsButton = UIButton()
        bannerRemoveAdsButton.setTitle("Remove Ads", for: .normal)
        bannerRemoveAdsButton.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        bannerRemoveAdsButton.layer.cornerRadius = 5
        bannerRemoveAdsButton.clipsToBounds = true
        bannerRemoveAdsButton.backgroundColor = color.blue()
        bannerRemoveAdsButton.setTitleColor(.white, for: .normal)
        bannerRemoveAdsButton.addTarget(self, action: #selector(self.didPressRemoveAdsbutton), for: .touchUpInside)
        self.view.addSubview(bannerRemoveAdsButton)
        bannerRemoveAdsButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.width.equalTo(150)
            make.top.equalTo(bannerView.snp.bottom).offset(uiElement.topOffset * 2)
            make.centerX.equalTo(self.view)
        }
        
        self.skipButton.isHidden = true
        skipTimerLabel = UILabel()
        skipTimerLabel.text = ""
        skipTimerLabel.textColor = .white
        skipTimerLabel.font = UIFont(name: "\(uiElement.mainFont)", size: 20)
        skipTimerLabel.layer.cornerRadius = 30 / 2
        skipTimerLabel.layer.borderWidth = 1
        skipTimerLabel.layer.borderColor = UIColor.white.cgColor
        skipTimerLabel.textAlignment = .center
        self.view.addSubview(skipTimerLabel)
        skipTimerLabel.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(30)
            make.centerX.centerY.equalTo(self.skipButton)
        }
        let timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateSkipTimer(_:)), userInfo: nil, repeats: true)
        timer.fire()
    }
    
    @objc func updateSkipTimer(_ timer: Timer) {
        if labelAmount == 0 {
            timer.invalidate()
            self.skipTimerLabel.removeFromSuperview()
            self.labelAmount = 4
            self.skipButton.isHidden = false
        } else {
            labelAmount = labelAmount - 1
            skipTimerLabel.text = "\(labelAmount)"
        }
    }
    
    @objc func didPressRemoveAdsbutton() {
        let artist = Artist(objectId: "addFunds", name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil)
        self.handleDismissal(artist)
        self.player.next()
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Function" : "sendTip", "Description": "User went to Add Funds Page"])
    }
}

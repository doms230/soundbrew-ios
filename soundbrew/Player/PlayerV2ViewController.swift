//
// PlayerV2ViewController.swift
// soundbrew
//
// Created by Dominic  Smith on 2/6/19.
// Copyright © 2019 Dominic  Smith. All rights reserved.
//
// mark: View, Share

import UIKit
import SCSDKCreativeKit
import ShareInstagram
import Parse
import Kingfisher
import SnapKit
import DeckTransition
import Photos
import NVActivityIndicatorView
import FirebaseAnalytics

class PlayerV2ViewController: UIViewController, NVActivityIndicatorViewable, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let color = Color()
    let uiElement = UIElement()
    
    var player: Player?
    var sound: Sound?
    
    var playerDelegate: PlayerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let sound = self.player?.currentSound {
            self.sound = sound 
            setupNotificationCenter()
            setUpView()
            player?.target = self 
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let player = self.player {
            self.sound = player.currentSound
        }
    }
    
    func setupNotificationCenter(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSound), name: NSNotification.Name(rawValue: "setSound"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector:#selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    //mark: money
    let tipAmountInCents = [10, 25, 50, 100]
    var selectedTipAmount = 10
    var customer = Customer.shared
    func showSendMoney() {
        if let sound = self.sound {
            let balanceInDollars = uiElement.convertCentsToDollarsAndReturnString(customer.artist!.balance ?? 0, currency: "$")
            let alertView = UIAlertController(
                title: "Send \(sound.artist!.username!) a Tip",
                message: "Current Balance: \(balanceInDollars) \n\n\n\n\n\n\n\n",
                preferredStyle: .actionSheet)
            
            let pickerView = UIPickerView(frame:
                CGRect(x: 0, y: 45, width: self.view.frame.width, height: 160))
            pickerView.dataSource = self
            pickerView.delegate = self
            alertView.view.addSubview(pickerView)
            
            let sendMoneyActionButton = UIAlertAction(title: "Send Tip", style: .default) { (_) -> Void in
                self.sendTip(sound, tipAmount: self.selectedTipAmount)
            }
            alertView.addAction(sendMoneyActionButton)
            
             let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertView.addAction(cancelAction)
            
            present(alertView, animated: true, completion: nil)
        }
    }
    
    func sendTip(_ sound: Sound, tipAmount: Int) {
        if customer.artist!.balance! >= tipAmount {
            updateArtistPayment(sound, tipAmount: tipAmount)
            newTip(sound, tipAmount: tipAmount)
            customer.updateBalance(-tipAmount)
            
        } else {
            let balance = uiElement.convertCentsToDollarsAndReturnString(customer.artist!.balance ?? 0, currency: "$")
            let tipAmount = uiElement.convertCentsToDollarsAndReturnString(tipAmount, currency: "$")
            
            let alertView = UIAlertController(
                title: "Tip Amount: \(tipAmount) \n Current Balance: \(balance)",
                message: "The selected tip amount exceeds your Soundbrew Balance. You can add funds from your profile.",
                preferredStyle: .alert)
            
            let sendMoneyActionButton = UIAlertAction(title: "Add Funds", style: .default) { (_) -> Void in
                let artist = Artist(objectId: "addFunds", name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, customerId: nil, balance: nil)
                self.handleDismal(artist)
            }
            alertView.addAction(sendMoneyActionButton)
            
            let cancelAction = UIAlertAction(title: "Got It", style: .cancel, handler: nil)
            alertView.addAction(cancelAction)
            
            present(alertView, animated: true, completion: nil)
        }
    }
    
    func updateArtistPayment(_ sound: Sound, tipAmount: Int) {
        if let artistObjectId = sound.artist?.objectId {
            let query = PFQuery(className: "Payment")
            query.whereKey("userId", equalTo: artistObjectId)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if error != nil {
                    self.newArtistPaymentRow(artistObjectId, tipAmount: tipAmount)
                    
                } else if let object = object {
                    object.incrementKey("tipsSinceLastPayout", byAmount: NSNumber(value: tipAmount))
                    object.incrementKey("tips", byAmount: NSNumber(value: tipAmount))
                    object.saveEventually {
                        (success: Bool, error: Error?) in
                        if error != nil {
                            self.customer.updateBalance(tipAmount)
                        }
                    }
                }
            }
        }
    }
    
    func newArtistPaymentRow(_ artistObjectId: String, tipAmount: Int) {
        let newPaymentRow = PFObject(className: "Tip")
        newPaymentRow["userId"] = artistObjectId
        newPaymentRow["tipsSinceLastPayout"] = tipAmount
        newPaymentRow["tips"] = tipAmount
        newPaymentRow.saveEventually {
            (success: Bool, error: Error?) in
            if error != nil {
                self.customer.updateBalance(tipAmount)
            }
        }
    }
    
    func newTip(_ sound: Sound, tipAmount: Int) {
        let newTip = PFObject(className: "Tip")
        newTip["fromUserId"] = PFUser.current()!.objectId!
        newTip["toUserId"] = sound.artist?.objectId
        newTip["amount"] = tipAmount
        newTip["soundId"] = sound.objectId
        newTip.saveEventually()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return tipAmountInCents.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let balanceInDollars = Double(tipAmountInCents[row]) / 100.00
        let doubleStr = String(format: "%.2f", balanceInDollars)
        return "$\(doubleStr)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print(tipAmountInCents[row])
        selectedTipAmount = tipAmountInCents[row]
    }
    
    //mark: sound
    @objc func didReceiveSound(){
        setSound()
    }
    
    @objc func didBecomeActive() {
        if self.viewIfLoaded?.window != nil {
            if let player = player {
                player.target = self
            }
        }
    }
    
    func setSound() {
        if let player = self.player {
            self.sound = player.currentSound
            setCurrentSoundView(self.sound!)
            self.shouldEnableSoundView(true)
            self.checkFollowStatus()
            if let soundPlayer = player.player {
                if soundPlayer.isPlaying  {
                    self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
                    
                } else {
                    self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
                }
            }
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
                        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                            AnalyticsParameterItemID: "id-unlike",
                            AnalyticsParameterItemName: "un like sound",
                            AnalyticsParameterContentType: "cont"
                            ])
                        
                    } else {
                        newLike(currentUser.objectId!, postId: sound.objectId)
                        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                            AnalyticsParameterItemID: "id-new-like",
                            AnalyticsParameterItemName: "new like",
                            AnalyticsParameterContentType: "newlike"
                            ])
                    }
                    
                } else {
                    newLike(currentUser.objectId!, postId: sound.objectId)
                    Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                        AnalyticsParameterItemID: "id-new-like",
                        AnalyticsParameterItemName: "new like",
                        AnalyticsParameterContentType: "unlike"
                        ])
                }
            }
            
        } else {
            self.uiElement.segueToView("Login", withIdentifier: "welcome", target: self)
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
                if let currentUsername = PFUser.current()?.username {
                    self.uiElement.sendAlert("\(currentUsername) added \(self.sound!.title!) to their collection.", toUserId: self.sound!.artist!.objectId)
                }
                
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
    func handleDismal(_ artist: Artist?) {
        self.dismiss(animated: true, completion: {() in
            if let playerDelegate = self.playerDelegate {
                playerDelegate.selectedArtist(artist)
            }
        })
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
        button.addTarget(self, action: #selector(didPressArtistNameButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressArtistNameButton(_ sender: UIButton) {
        self.handleDismal(self.sound?.artist)
    }
    
    lazy var tagButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "tag"), for: .normal)
        return button
    }()
    @objc func didpressTagButton(_ sender: UIButton) {
        //TODO: add tag action
    }
    
    lazy var coinButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "sendTip"), for: .normal)
        button.addTarget(self, action: #selector(self.didPressSendMoneyButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressSendMoneyButton(_ sender: UIButton) {
        showSendMoney()
    }
    
    lazy var userRelationButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "follow"), for: .normal)
        return button
    }()
    @objc func didPressUserRelationButton(_ sender: UIButton) {
        if let currentUser = PFUser.current() {
            if let isFollowedByCurrentUser = self.sound?.artist?.isFollowedByCurrentUser {
                if isFollowedByCurrentUser {
                    unFollowerUser(currentUser)
                    
                } else {
                    followUser(currentUser)
                }
                
            } else {
                followUser(currentUser)
            }
            
        } else {
            self.uiElement.signupRequired("Welcome to Soundbrew!", message: "Following artists will mix in other songs they've uploaded into playlists you create.", target: self)
        }
    }
    
    let likeRedImage = "like_red"
    let likeImage = "like"
    lazy var likeButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didPressLikeButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressLikeButton(_ sender: UIButton) {
        if PFUser.current() != nil {
            manageLikeForCurrentSound()
            
        } else {
            let alertController = UIAlertController (title: "Sign Up or Sign In", message: "Liking songs will add them to your music collection on your profile.", preferredStyle: .alert)
            
            let settingsAction = UIAlertAction(title: "Sign Up", style: .default) { (_) -> Void in
                let artist = Artist(objectId: "signup", name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, customerId: nil, balance: nil)
                self.handleDismal(artist)
            }
            alertController.addAction(settingsAction)
            
            let cancelAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    lazy var shareButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "share"), for: .normal)
        button.addTarget(self, action: #selector(didPressShareButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressShareButton(_ sender: UIButton) {
        if let sound = self.sound {
            self.uiElement.showShareOptions(self, sound: sound)
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
        if let player = self.player {
            if let soundPlayer = player.player {
                player.setBackgroundAudioNowPlaying(soundPlayer, sound: sound!)
                soundPlayer.currentTime = TimeInterval(sender.value)
                playBackCurrentTime.text = self.uiElement.formatTime(Double(sender.value))
            }
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
        button.addTarget(self, action: #selector(self.didPressPlayBackButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressPlayBackButton(_ sender: UIButton) {
        if let player = self.player {
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
    }
    
    lazy var skipButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "skip"), for: .normal)
        button.isEnabled = false
        button.addTarget(self, action: #selector(self.didPressSkipButton(_:)), for: .touchUpInside)
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
        button.addTarget(self, action: #selector(didPressGoBackButton(_:)), for: .touchUpInside)
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
        self.view.addSubview(exitButton)
        exitButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self.view).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        self.view.addSubview(shareButton)
        shareButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self.view).offset(uiElement.topOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        //sound views
        self.view.addSubview(songArt)
        songArt.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(self.view.frame.height / 2)
            make.top.equalTo(self.exitButton.snp.bottom).offset(uiElement.topOffset)
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
        playBackButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(65)
            make.top.equalTo(self.playBackSlider.snp.bottom).offset(uiElement.topOffset)
            make.centerX.equalTo(self.view)
        }
        
        self.view.addSubview(goBackButton)
        goBackButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(55)
            make.centerY.equalTo(playBackButton)
            make.centerX.equalTo(self.view).offset(-(55 + uiElement.leftOffset))
        }
        
        /*tagButton.addTarget(self, action: #selector(didpressTagButton(_:)), for: .touchUpInside)
        self.view.addSubview(tagButton)
        tagButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self.goBackButton).offset(uiElement.topOffset)
            make.right.equalTo(self.goBackButton.snp.left).offset(uiElement.rightOffset)
        }*/
        
        self.view.addSubview(skipButton)
        skipButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(55)
            make.centerY.equalTo(playBackButton)
            make.centerX.equalTo(self.view).offset(55 + uiElement.leftOffset)
        }
        
        if isSoundLiked() {
            likeButton.setImage(UIImage(named: likeRedImage), for: .normal)
            
        } else {
            likeButton.setImage(UIImage(named: likeImage), for: .normal)
        }
        self.view.addSubview(likeButton)
        likeButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(55/2)
            make.centerY.equalTo(self.goBackButton)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        self.view.addSubview(coinButton)
        coinButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(55/2)
            make.centerY.equalTo(self.skipButton)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        /*userRelationButton.addTarget(self, action: #selector(didPressUserRelationButton(_:)), for: .touchUpInside)
        self.view.addSubview(userRelationButton)
        userRelationButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(30)
            make.top.equalTo(likeButton)
            make.right.equalTo(likeButton.snp.left).offset(uiElement.rightOffset)
        }*/
        
        setSound()
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
                    if let likes = object["likes"] as? Int {
                        if likes > 0 {
                            object.incrementKey("likes", byAmount: -1)
                        }
                    }
                }
                object.saveEventually()
            }
        }
    }
    
    func followUser(_ currentUser: PFUser) {
        self.sound!.artist!.isFollowedByCurrentUser = true
        self.userRelationButton.setImage(UIImage(named: "follow_green"), for: .normal)
        let newFollow = PFObject(className: "Follow")
        newFollow["fromUserId"] = currentUser.objectId
        newFollow["toUserId"] = self.sound!.artist!.objectId
        newFollow["isRemoved"] = false
        newFollow.saveEventually {
            (success: Bool, error: Error?) in
            if success && error == nil {
                self.uiElement.sendAlert("\(currentUser.username!) followed you.", toUserId: self.sound!.artist!.objectId)
                
            } else {
                self.sound!.artist!.isFollowedByCurrentUser = false
            }
        }
    }
    
    func unFollowerUser(_ currentUser: PFUser) {
        self.sound!.artist!.isFollowedByCurrentUser = false
        self.userRelationButton.setImage(UIImage(named: "follow"), for: .normal)
        let query = PFQuery(className: "Follow")
        query.whereKey("fromUserId", equalTo: currentUser.objectId!)
        query.whereKey("toUserId", equalTo: self.sound!.artist!.objectId!)
        query.whereKey("isRemoved", equalTo: false)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if error != nil {
                self.sound!.artist!.isFollowedByCurrentUser = true
                self.userRelationButton.setImage(UIImage(named: "follow"), for: .normal)
                
            } else if let object = object {
                object["isRemoved"] = true
                object.saveEventually {
                    (success: Bool, error: Error?) in
                    if success && error == nil {
                    }
                }
            }
        }
    }
    
    func checkFollowStatus() {
        if let currentUser = PFUser.current() {
            if self.sound!.artist?.objectId != currentUser.objectId {
                let query = PFQuery(className: "Follow")
                query.whereKey("fromUserId", equalTo: currentUser.objectId!)
                query.whereKey("toUserId", equalTo: self.sound!.artist!.objectId!)
                query.whereKey("isRemoved", equalTo: false)
                query.getFirstObjectInBackground {
                    (object: PFObject?, error: Error?) -> Void in
                    if object != nil && error == nil {
                        self.sound!.artist!.isFollowedByCurrentUser = true
                        self.userRelationButton.setImage(UIImage(named: "follow_green"), for: .normal)
                        
                    } else {
                        self.sound!.artist!.isFollowedByCurrentUser = false
                        self.userRelationButton.setImage(UIImage(named: "follow"), for: .normal)
                    }
                    self.userRelationButton.isEnabled = true
                }
                
            } else {
                self.userRelationButton.isEnabled = false
                self.userRelationButton.setImage(UIImage(named: "follow"), for: .normal)
            }
            
        } else {
            self.userRelationButton.isEnabled = true
            self.userRelationButton.setImage(UIImage(named: "follow"), for: .normal)
        }
    }
    
}

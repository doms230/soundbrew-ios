//
// PlayerViewController.swift
// soundbrew
//
// Created by Dominic  Smith on 2/6/19.
// Copyright © 2019 Dominic  Smith. All rights reserved.
//
// mark: View, Share, tips

import UIKit
import SCSDKCreativeKit
import ShareInstagram
import Parse
import Kingfisher
import SnapKit
import DeckTransition
import Photos
import NVActivityIndicatorView
import AppCenterAnalytics

class PlayerViewController: UIViewController, NVActivityIndicatorViewable {
    
    let color = Color()
    let uiElement = UIElement()
    
    var player: Player?
    var sound: Sound?
    
    var playerDelegate: PlayerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let sound = self.player?.currentSound {
            self.sound = sound
            player?.target = self
            setupNotificationCenter()
            setUpView()
            
            if let currentUserId = PFUser.current()?.objectId {
                ListenerToArtistTipRelation(sound, tipAmount: nil, currentUserId: currentUserId)
            }
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
    
    //mark: tips
    let selectedTipAmount = 25
    var amountCurrentUserHastipped = 0
    var customer = Customer.shared
    
    func sendTip(_ sound: Sound, tipAmount: Int) {
        if customer.artist!.balance! >= tipAmount {
            //SKStoreReviewController.requestReview()
            self.amountCurrentUserHastipped = tipAmount + self.amountCurrentUserHastipped
            //let amountInDollars = uiElement.convertCentsToDollarsAndReturnString(self.amountCurrentUserHastipped, currency: "$")
           // self.tipAmountButton.setTitle(amountInDollars, for: .normal)
            self.tipButton.setImage(UIImage(named: "sendTipColored"), for: .normal)
            
            customer.updateBalance(-tipAmount)
            updateArtistPayment(sound, tipAmount: tipAmount)
            ListenerToArtistTipRelation(sound, tipAmount: tipAmount, currentUserId: PFUser.current()!.objectId!)
            incrementTipInfo(sound, tipAmount: tipAmount, isIncrementingTipper: false)
            
            let player = Player.sharedInstance
            if player.player != nil {
                let modal = PlayerViewController()
                modal.player = player
                let transitionDelegate = DeckTransitioningDelegate()
                modal.transitioningDelegate = transitionDelegate
                modal.modalPresentationStyle = .custom
                self.present(modal, animated: true, completion: nil)
            }
            
        } else {
            let balance = uiElement.convertCentsToDollarsAndReturnString(customer.artist!.balance ?? 0, currency: "$")
            let tipAmount = uiElement.convertCentsToDollarsAndReturnString(tipAmount, currency: "$")
            
            let alertView = UIAlertController(
                title: "Required Balance: \(tipAmount) \n Current Balance: \(balance)",
                message: "The minimum price to add this song to your collection is $0.25.",
                preferredStyle: .alert)
            
            let sendMoneyActionButton = UIAlertAction(title: "Add Funds", style: .default) { (_) -> Void in
                let artist = Artist(objectId: "addFunds", name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil)
                self.handleDismissal(artist)
            }
            alertView.addAction(sendMoneyActionButton)
            
            let cancelAction = UIAlertAction(title: "Later", style: .cancel, handler: nil)
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
        let newPaymentRow = PFObject(className: "Payment")
        newPaymentRow["userId"] = artistObjectId
        newPaymentRow["tipsSinceLastPayout"] = tipAmount
        newPaymentRow["tips"] = tipAmount
        newPaymentRow.saveEventually {
            (success: Bool, error: Error?) in
            if error != nil {
                self.customer.updateBalance(tipAmount)
                self.tipButton.setImage(UIImage(named: "sendTip"), for: .normal)
            }
        }
    }
    
    func newTipRow(_ sound: Sound, tipAmount: Int) {
        let newTip = PFObject(className: "Tip")
        newTip["fromUserId"] = PFUser.current()!.objectId!
        newTip["toUserId"] = sound.artist?.objectId
        newTip["amount"] = tipAmount
        newTip["soundId"] = sound.objectId
        newTip.saveEventually{
            (success: Bool, error: Error?) in
            if success {
                self.tipButton.setImage(UIImage(named: "sendTip"), for: .normal)
                self.uiElement.sendAlert("\(PFUser.current()!.username!) tipped you for \(sound.title!)!", toUserId: sound.artist!.objectId)
                self.incrementTipInfo(sound, tipAmount: 0, isIncrementingTipper: true)
            }
        }
    }
    
    func ListenerToArtistTipRelation(_ sound: Sound, tipAmount: Int?, currentUserId: String) {
        if let artistObjectId = sound.artist?.objectId {
            let query = PFQuery(className: "Tip")
            query.whereKey("fromUserId", equalTo: currentUserId)
            query.whereKey("toUserId", equalTo: artistObjectId)
            query.whereKey("soundId", equalTo: sound.objectId!)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if let object = object {
                    if let tipAmount = tipAmount {
                        object.incrementKey("amount", byAmount: NSNumber(value: tipAmount))
                        object.saveEventually{
                            (success: Bool, error: Error?) in
                            if success {
                                self.tipButton.setImage(UIImage(named: "sendTip"), for: .normal)
                                self.uiElement.sendAlert("\(PFUser.current()!.username!) tipped you for \(sound.title!)!", toUserId: sound.artist!.objectId)
                            } else if error != nil {
                                self.amountCurrentUserHastipped = self.amountCurrentUserHastipped - tipAmount
                            }
                        }
                    } else {
                        let amountCurrentUserHastipped = object["amount"] as! Int
                        let tipAmountString = self.uiElement.convertCentsToDollarsAndReturnString(amountCurrentUserHastipped, currency: "$")
                        //self.tipAmountButton.setTitle(tipAmountString, for: .normal)
                        self.amountCurrentUserHastipped = amountCurrentUserHastipped
                    }
                } else if let tipAmount = tipAmount {
                    self.newTipRow(sound, tipAmount: tipAmount)
                } else {
                   // self.tipAmountButton.setTitle("$0.00", for: .normal)
                    self.amountCurrentUserHastipped = 0
                }
            }
        }
    }
    
    func incrementTipInfo(_ sound: Sound, tipAmount: Int, isIncrementingTipper: Bool) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: sound.objectId!) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                if isIncrementingTipper {
                    object.incrementKey("tippers")
                } else {
                    object.incrementKey("tips", byAmount: NSNumber(value: tipAmount))
                }
                
                object.saveEventually()
            }
        }
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
        
        if let currentUserId = PFUser.current()?.objectId {
            self.ListenerToArtistTipRelation(sound, tipAmount: nil, currentUserId: currentUserId)
        }
        
        self.songArt.kf.setImage(with: URL(string: sound.artURL ?? ""), placeholder: UIImage(named: "appy"))
        
        if let duration = self.player?.player?.duration {
            self.playBackTotalTime.text = self.uiElement.formatTime(Double(duration))
            playBackSlider.maximumValue = Float(duration)
            self.startTimer()
        }
        
        if let artistName = sound.artist?.name {
            self.artistLabel.text = artistName
            if let artistImage = sound.artist?.image {
                self.artistImage.kf.setImage(with: URL(string: artistImage))
            }
            
        } else {
            self.artistLabel.text = ""
            loadUserInfoFromCloud(sound.artist!.objectId)
        }
    }
    
    func shouldEnableSoundView(_ shouldEnable: Bool) {
        self.playBackButton.isEnabled = shouldEnable
        self.skipButton.isEnabled = shouldEnable
        self.goBackButton.isEnabled = shouldEnable
    }
    
    //mark: View
    func handleDismissal(_ artist: Artist?) {
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
        
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "Exit Button", "Description": "User Exited PlayerViewController."])
    }
    
    lazy var appTitle: UILabel = {
        let label = UILabel()
        label.text = "Soundbrew"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 15)
        label.textAlignment = .center
        return label
    }()
    
    /*lazy var tipAmountButton: UIButton = {
        let button = UIButton()
        button.setTitle("$0.00", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        button.addTarget(self, action: #selector(didPressTipAmountButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressTipAmountButton(_ sender: UIButton) {
        let alertView = UIAlertController(
            title: nil,
            message: "You've tipped \(sound!.artist!.username!) \(sender.titleLabel!.text!) for \(sound!.title!)",
            preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
        alertView.addAction(cancelAction)
        present(alertView, animated: true, completion: nil)
        
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "tipAmountButton", "Description": "How much the current user has tipped the artist for the current song."])
    }*/
    
    lazy var songArt: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.backgroundColor = color.black()
        return image
    }()
    
    lazy var songTitle: UILabel = {
        let label = UILabel()
        label.text = "Sound Title"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 25)
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    lazy var artistButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didPressArtistNameButton(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var artistImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "profile_icon")
        image.layer.cornerRadius = 35 / 2
        image.clipsToBounds = true
        return image
    }()
    
    lazy var artistLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 20)
        label.textColor = .white
        return label
    }()
    
    @objc func didPressArtistNameButton(_ sender: UIButton) {
        self.handleDismissal(self.sound?.artist)
        
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "ArtistName", "Description": "User clicked on artist's name to go to profile."])
    }
    
    lazy var tipButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "sendTip"), for: .normal)
        button.addTarget(self, action: #selector(self.didPressSendMoneyButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressSendMoneyButton(_ sender: UIButton) {
        if let currentUser = PFUser.current() {
            if currentUser.objectId! == sound?.artist?.objectId {
                self.uiElement.showAlert("Love Yourself", message: "But, you can't tip yourself. 🙃", target: self)
            } else {
                //showSendMoney()
                if let sound = self.sound {
                    sendTip(sound, tipAmount: selectedTipAmount)
                }
            }
        }
        
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "TipButton", "Description": "Current User attempted to tip artist"])
        
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
        if let player = self.player {
            if let soundPlayer = player.player {
                player.setBackgroundAudioNowPlaying(soundPlayer, sound: sound!)
                soundPlayer.currentTime = TimeInterval(sender.value)
                playBackCurrentTime.text = self.uiElement.formatTime(Double(sender.value))
            }
        }
        
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "PlayBackSlider", "Description": "User seeked time on song"])
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
    @objc func didPressPlayBackButton(_ sender: UIButton) {
        if let player = self.player {
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
            
            MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "Skip", "Description": "User Skipped Song."])
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
            
            MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "Go Back", "Description": "User Pressed Go Back."])
        }
    }
    
    func setUpView() {
        self.view.backgroundColor = color.black()
        
        //top views
        self.view.addSubview(exitButton)
        exitButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self.view).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        /*self.view.addSubview(tipAmountButton)
        tipAmountButton.snp.makeConstraints { (make) -> Void in
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
            make.height.equalTo(self.view.frame.height / 2)
            make.top.equalTo(self.exitButton.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(exitButton)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(songTitle)
        songTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.songArt.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(songArt)
            make.right.equalTo(songArt)
        }
        
        self.view.addSubview(artistButton)
        artistButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(35)
            make.top.equalTo(songTitle.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(songArt)
            make.right.equalTo(songArt)
        }
        
        self.artistButton.addSubview(artistLabel)
        artistLabel.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(artistButton)
            make.top.equalTo(artistButton)
            //make.right.equalTo(artistButton)
        }
        
        self.artistButton.addSubview(artistImage)
        artistImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(35)
            make.right.equalTo(artistLabel.snp.left).offset(-(uiElement.elementOffset))
            make.centerY.equalTo(artistLabel)
        }
        
        //playback views
        self.view.addSubview(playBackSlider)
        playBackSlider.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.artistButton.snp.bottom)
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
        
        self.view.addSubview(skipButton)
        skipButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(55)
            make.centerY.equalTo(playBackButton)
            make.centerX.equalTo(self.view).offset(55 + uiElement.leftOffset)
        }
        
        self.view.addSubview(tipButton)
        tipButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(45)
            make.centerY.equalTo(self.skipButton)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(shareButton)
        shareButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(45)
            make.centerY.equalTo(self.skipButton)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
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
                self.artistLabel.text = artistName
                self.sound!.artist?.name = artistName
                
                if let artistImage = user["userImage"] as? PFFileObject {
                    self.artistImage.kf.setImage(with: URL(string: artistImage.url!))
                    self.sound!.artist?.image = artistImage.url
                }
                
                self.sound!.artist?.city = user["city"] as? String
            }
        }
    }
}

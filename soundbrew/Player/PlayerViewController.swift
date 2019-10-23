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
import NVActivityIndicatorView
import AppCenterAnalytics

class PlayerViewController: UIViewController, NVActivityIndicatorViewable, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let color = Color()
    let uiElement = UIElement()
    
    let player = Player.sharedInstance
    var sound: Sound?
    
    var playerDelegate: PlayerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayerView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.sound = player.currentSound
        updatePlayBackControls()
    }
    
    func setupNotificationCenter(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSound), name: NSNotification.Name(rawValue: "setSound"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector:#selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    //mark: money
    let tipAmountInCents = [25, 50, 75, 100]
    var selectedTipAmount = 25
    var customer = Customer.shared
    var didAddSongToCollection = false
    func showSendMoney() {
        if let sound = self.sound {
            let balanceInDollars = uiElement.convertCentsToDollarsAndReturnString(customer.artist!.balance ?? 0, currency: "$")
            let alertView = UIAlertController(
                title: "Current Balance: \(balanceInDollars)",
                message: "Pay Artist: \n\n\n\n\n\n\n\n",
                preferredStyle: .actionSheet)
            
            let pickerView = UIPickerView(frame:
                CGRect(x: 0, y: 45, width: self.view.frame.width, height: 160))
            pickerView.dataSource = self
            pickerView.delegate = self
            alertView.view.addSubview(pickerView)
            
            let sendMoneyActionButton = UIAlertAction(title: "Add To Your Collection", style: .default) { (_) -> Void in
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
            self.tipButton.setImage(UIImage(named: "sendTipColored"), for: .normal)
            self.didAddSongToCollection = true
            self.sound?.tips = tipAmount
            
            SKStoreReviewController.requestReview()
            
            customer.updateBalance(-tipAmount)
            updateArtistPayment(sound, tipAmount: tipAmount)
            newTip(sound, tipAmount: tipAmount)
            incrementTipAmount(sound, tipAmount: tipAmount)
            
        } else {
            let balance = uiElement.convertCentsToDollarsAndReturnString(customer.artist!.balance ?? 0, currency: "$")
            let tipAmount = uiElement.convertCentsToDollarsAndReturnString(tipAmount, currency: "$")
            
            let alertView = UIAlertController(
                title: "Tip Amount: \(tipAmount) \n Current Balance: \(balance)",
                message: "The selected tip amount exceeds your Soundbrew Balance.",
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
                self.didAddSongToCollection = false
            }
        }
    }
    
    func newTip(_ sound: Sound, tipAmount: Int) {
        let newTip = PFObject(className: "Tip")
        newTip["fromUserId"] = PFUser.current()!.objectId!
        newTip["toUserId"] = sound.artist?.objectId
        newTip["amount"] = tipAmount
        newTip["soundId"] = sound.objectId
        newTip.saveEventually{
            (success: Bool, error: Error?) in
            if success {
                self.uiElement.sendAlert("\(PFUser.current()!.username!) collected \(sound.title!)!", toUserId: sound.artist!.objectId)
            }
        }
    }
    
    func incrementTipAmount(_ sound: Sound, tipAmount: Int) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: sound.objectId!) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                object.incrementKey("tips", byAmount: NSNumber(value: tipAmount))
                object.incrementKey("tippers")
                object.saveEventually()
            }
        }
    }
    
    func checkIfUserAddedSongToCollection(_ sound: Sound) {
        if PFUser.current() != nil {
            self.tipButton.setImage(UIImage(named: "sendTip"), for: .normal)
            self.tipButton.isEnabled = false
            self.didAddSongToCollection = false
            
            let query = PFQuery(className: "Tip")
            query.whereKey("fromUserId", equalTo: PFUser.current()!.objectId! )
            query.whereKey("soundId", equalTo: sound.objectId!)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                 if let object = object {
                    self.didAddSongToCollection = true
                    self.sound?.tips = (object["amount"] as! Int)
                    self.tipButton.setImage(UIImage(named: "sendTipColored"), for: .normal)
                }
                self.tipButton.isEnabled = true
            }
        } else {
            self.tipButton.isEnabled = true
        }
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
        selectedTipAmount = tipAmountInCents[row]
    }
    
    //mark: sound
    func setupPlayerView() {
        
        setupNotificationCenter()
        if let sound = self.player.currentSound {
            self.sound = sound
           showPlayerView()
            checkIfUserAddedSongToCollection(sound)
            player.target = self
        } else {
            showLoadingSoundbrewSpinner()
        }
        
         /*else {
            self.player = Player.sharedInstance
            self.player!.target = self
            self.player?.sounds = self.sounds
            self.player?.currentSound = sound
            self.player!.fetchAudioData(0, prepareAndPlay: true)
                        
        }*/
        /*setupNotificationCenter()
        setUpView()
        if let player = self.player {
            self.sound = sound
            player.target = self
            checkIfUserAddedSongToCollection(sound)
        } else {
            self.player = Player.sharedInstance
            self.player!.target = self
            self.player?.sounds = self.sounds
            self.player?.currentSound = sound
            self.player!.fetchAudioData(0, prepareAndPlay: true)
                        
        }*/
    }
    @objc func didReceiveSound(){
        setSound()
    }
    
    @objc func didBecomeActive() {
        if self.viewIfLoaded?.window != nil {
            player.target = self
        }
    }
    
    func setSound() {
        if let sound = player.currentSound {
            self.sound = sound
            self.loadingSoundbrewSpinner.removeFromSuperview()

            checkIfUserAddedSongToCollection(sound)
            
            self.songTitle.text = sound.title
            
            self.songArt.kf.setImage(with: URL(string: sound.artURL ?? ""), placeholder: UIImage(named: "sound"))
            
            if let duration = self.player.player?.duration {
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
            
            if playBackButton.superview == nil {
                showPlayerView()
            }
            
            updatePlayBackControls()
        }
    }
    
    func updatePlayBackControls() {
        if let soundPlayer = player.player {
            if soundPlayer.isPlaying  {
                self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
                self.shouldEnablePlaybackControls(true)
                
            } else {
                self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
            }
            
            if soundPlayer.duration >= fiveMinutesInSeconds {
                self.skipButton.setImage(UIImage(named: "skipForward"), for: .normal)
                self.goBackButton.setImage((UIImage(named: "skipBack")), for: .normal)
            } else {
                self.skipButton.setImage(UIImage(named: "skip"), for: .normal)
                self.goBackButton.setImage((UIImage(named: "goBack")), for: .normal)
            }
        }
    }
    
    func shouldEnablePlaybackControls(_ shouldEnable: Bool) {
        if shouldEnable {
            self.loadSoundSpinner.isHidden = true
            self.playBackButton.isHidden = false
        } else {
            self.playBackButton.isHidden = true
            self.loadSoundSpinner.isHidden = false
        }
        self.playBackButton.isEnabled = shouldEnable
    }
    
    //mark: View
    let fiveMinutesInSeconds: Double = 5 * 60
    
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
        button.isEnabled = false
        return button
    }()
    @objc func didPressSendMoneyButton(_ sender: UIButton) {
        if let currentUser = PFUser.current() {
            if currentUser.objectId! == sound?.artist?.objectId {
                self.uiElement.showAlert("🙃", message: "", target: self)
            } else if didAddSongToCollection {
                let amountString = self.uiElement.convertCentsToDollarsAndReturnString(self.sound!.tips!, currency: "$")
                self.uiElement.showAlert("You added \(self.sound!.title!) to your Collection for \(amountString)", message: "", target: self)
            } else {
                showSendMoney()
            }
        } else {
            self.uiElement.signupRequired("Sign up required", message: "Tip artists to add songs to your collection!", target: self)
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
        if let soundPlayer = player.player {
            player.setBackgroundAudioNowPlaying(soundPlayer, sound: sound!)
            soundPlayer.currentTime = TimeInterval(sender.value)
            playBackCurrentTime.text = self.uiElement.formatTime(Double(sender.value))
        }
        
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "PlayBackSlider", "Description": "User seeked time on song"])
    }
    
    var timer = Timer()
    @objc func UpdateTimer(_ timer: Timer) {
        if let currentTime = player.player?.currentTime {
            playBackCurrentTime.text = "\(self.uiElement.formatTime(Double(currentTime)))"
            playBackSlider.value = Float(currentTime)
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
    
    lazy var loadingSoundbrewSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .white
        spinner.startAnimating()
        return spinner
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
        self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
        self.playBackSlider.value = 0
        self.playBackCurrentTime.text = "0s"
        self.playBackTotalTime.text = "0s"
        if let soundPlayer = player.player {
            if soundPlayer.duration >= fiveMinutesInSeconds {
                player.skipForward()
            } else {
                self.shouldEnablePlaybackControls(false)
                player.next()
            }
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
        if let soundPlayer = player.player {
            if soundPlayer.duration >= fiveMinutesInSeconds {
                player.skipBackward()
            } else {
                player.previous()
            }
        }
        
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "Go Back", "Description": "User Pressed Go Back."])
    }
    
    func showLoadingSoundbrewSpinner(){
        self.view.addSubview(loadingSoundbrewSpinner)
        loadingSoundbrewSpinner.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(self.view.frame.width * (2))
            make.centerY.centerX.equalTo(self.view)
        }
    }
    
    func showPlayerView() {
        self.view.backgroundColor = color.black()
        
        //top views
        self.view.addSubview(exitButton)
        exitButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self.view).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
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
        
        self.view.addSubview(loadSoundSpinner)
        loadSoundSpinner.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(200)
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
    
    //MARK: RADIO
    //var sounds = [Sound]()
    
    /*func loadSounds() {
        let query = PFQuery(className: "Post")
        query.whereKey("isRemoved", notEqualTo: true)
        //query.addDescendingOrder("plays")
        query.addDescendingOrder("tips")
        query.limit = 100
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let sound = self.uiElement.newSoundObject(object)
                        self.sounds.append(sound)
                    }
                    self.sounds.shuffle()
                    //self.setupSound(self.sounds[0])
                }
                
            } else {
                print("Error: \(error!)")
            }
        }
    }*/
}

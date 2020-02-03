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
        self.title = "Soundbrew"
        
        setupPlayerView()
    }
        
    override func viewDidAppear(_ animated: Bool) {
        self.setSound()
        customer = Customer.shared
    }
    
    func setupNotificationCenter(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSoundUpdate), name: NSNotification.Name(rawValue: "setSound"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector:#selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    //mark: money
    let tipAmountInCents = [5, 25, 50, 100]
    var selectedTipAmount = 5
    var customer = Customer.shared
    var didAddSongToCollection = false
    func showSendMoney() {
        if let sound = self.sound {
            let localizedCurrentBalance = NSLocalizedString("currentBalance", comment: "")
            let localizedTipArtist = NSLocalizedString("tipArtist", comment: "")
            let balanceInDollars = uiElement.convertCentsToDollarsAndReturnString(customer.artist!.balance ?? 0, currency: "$")
            let alertView = UIAlertController(
                title: "\(localizedCurrentBalance) \(balanceInDollars)",
                message: "\(localizedTipArtist) \n\n\n\n\n\n\n\n",
                preferredStyle: .actionSheet)
            
            let pickerView = UIPickerView(frame:
                CGRect(x: 0, y: 45, width: self.view.frame.width, height: 160))
            pickerView.dataSource = self
            pickerView.delegate = self
            alertView.view.addSubview(pickerView)
            
            let localizedAddToCollection = NSLocalizedString("addToCollection", comment: "")

            let sendMoneyActionButton = UIAlertAction(title: localizedAddToCollection, style: .default) { (_) -> Void in
                self.sendTip(sound, tipAmount: self.selectedTipAmount)
            }
            alertView.addAction(sendMoneyActionButton)
            
            let localizedCancel = NSLocalizedString("cancel", comment: "")
            let cancelAction = UIAlertAction(title: localizedCancel, style: .cancel, handler: nil)
            alertView.addAction(cancelAction)
            
            present(alertView, animated: true, completion: nil)
        }
    }
    
    func sendTip(_ sound: Sound, tipAmount: Int) {
        if customer.artist!.balance! >= tipAmount {
            self.likeSoundButton.setImage(UIImage(named: "sendTipColored"), for: .normal)
            self.didAddSongToCollection = true
            self.sound?.tipAmount = tipAmount
            
            SKStoreReviewController.requestReview()
            
            customer.updateBalance(-tipAmount)
            updateArtistPayment(sound, tipAmount: tipAmount)
            newTip(sound, tipAmount: tipAmount)
            incrementTipAmount(sound, tipAmount: tipAmount)
            
        } else {
            let balance = uiElement.convertCentsToDollarsAndReturnString(customer.artist!.balance ?? 0, currency: "$")
            let tipAmount = uiElement.convertCentsToDollarsAndReturnString(tipAmount, currency: "$")
            let localizedTipAmount = NSLocalizedString("tipAmount", comment: "")
            let localizedCurrentBalance = NSLocalizedString("currentBalance", comment: "")
            let localizedTipAmountExceedsBalance = NSLocalizedString("tipAmountExceedsBalance", comment: "")
            let localizedAddFunds = NSLocalizedString("addFunds", comment: "")
            let localizedLater = NSLocalizedString("later", comment: "")

            let alertView = UIAlertController(
                title: "\(localizedTipAmount) \(tipAmount) \n \(localizedCurrentBalance) \(balance)",
                message: localizedTipAmountExceedsBalance,
                preferredStyle: .alert)
            
            let sendMoneyActionButton = UIAlertAction(title: localizedAddFunds, style: .default) { (_) -> Void in
                let artist = Artist(objectId: "addFunds", name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil)
                self.handleDismissal(artist)
            }
            alertView.addAction(sendMoneyActionButton)
            
            let cancelAction = UIAlertAction(title: localizedLater, style: .cancel, handler: nil)
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
                self.likeSoundButton.setImage(UIImage(named: "sendTip"), for: .normal)
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
            self.likeSoundButton.setImage(UIImage(named: "sendTip"), for: .normal)
            self.likeSoundButton.isEnabled = false
            self.didAddSongToCollection = false
            
            let query = PFQuery(className: "Tip")
            query.whereKey("fromUserId", equalTo: PFUser.current()!.objectId! )
            query.whereKey("soundId", equalTo: sound.objectId!)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                 if let object = object {
                    self.didAddSongToCollection = true
                    self.sound?.tipAmount = (object["amount"] as! Int)
                    self.likeSoundButton.setImage(UIImage(named: "sendTipColored"), for: .normal)
                }
                self.likeSoundButton.isEnabled = true
            }
        } else {
            self.likeSoundButton.isEnabled = true
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
        if let soundId = self.uiElement.getUserDefault("receivedSoundId") as? String {
            UserDefaults.standard.removeObject(forKey: "receivedSoundId")
            loadDynamicLinkSound(soundId, shouldShowShareSoundView: false)
            
        } else if let newSoundId = self.uiElement.getUserDefault("newSoundId") as? String {
            UserDefaults.standard.removeObject(forKey: "newSoundId")
            loadDynamicLinkSound(newSoundId, shouldShowShareSoundView: true)
            
        } else if let sound = self.player.currentSound {
            self.sound = sound
            showPlayerView()
            player.target = self
            
        } else {
            showLoadingSoundbrewSpinner()
        }
    }
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
            self.sound = sound

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
                } else {
                    self.artistImage.image = UIImage(named: "profile_icon")
                }
            }
            
            if playBackButton.superview == nil {
                showPlayerView()
            } else {
                setCountLabel(self.commentCountLabel, count: sound.commentCount)
                setCountLabel(self.playCountLabel, count: sound.playCount)
                setCountLabel(self.likeCountLabel, count: sound.tipCount)
                setCountLabel(self.creditCountLabel, count: sound.creditCount)
                var tagCount = 0
                if let tags = sound.tags {
                    tagCount = tags.count
                }
                setCountLabel(self.hashtagCountLabel, count: tagCount)
            }
            
            updatePlayBackControls()
        }
    }
    
    func resetPlayView() {
        self.playBackButton.isEnabled = false
        self.loadSoundSpinner.isHidden = false
        self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
        timer.invalidate()
        self.playBackSlider.value = 0
        self.playBackCurrentTime.text = "0s"
        self.playBackTotalTime.text = "0s"
        
        let localizedLoading = NSLocalizedString("loading", comment: "")

        self.songTitle.text = localizedLoading
        
        self.songArt.image = UIImage(named: "sound")
        self.artistLabel.text = localizedLoading
        self.artistImage.kf.setImage(with: URL(string: "profile_icon"))
        self.artistLabel.text = ""
        
        if playBackButton.superview == nil {
            showPlayerView()
        }
        let collectorsButton = UIBarButtonItem(title: localizedLoading, style: .plain, target: self, action: #selector(self.didPressCollectorsButton(_:)))
        self.navigationItem.rightBarButtonItem = collectorsButton
    }
    
    @objc func didPressCollectorsButton(_ sender: UIBarButtonItem) {
        if self.navigationController == nil {
            let collectorsArtist = Artist(objectId: "collectors", name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil)
            self.handleDismissal(collectorsArtist)
            
        } else {
            self.performSegue(withIdentifier: "showTippers", sender: self)
        }
    }
    
    func updatePlayBackControls() {
        if let soundPlayer = player.player {
            self.loadSoundSpinner.isHidden = true
            self.playBackButton.isEnabled = true
            if soundPlayer.isPlaying  {
                self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
                
            } else {
                self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
            }
            self.skipButton.setImage(UIImage(named: "skip"), for: .normal)
            self.goBackButton.setImage((UIImage(named: "goBack")), for: .normal)
            /*if soundPlayer.duration >= fiveMinutesInSeconds {
                self.skipButton.setImage(UIImage(named: "skipForward"), for: .normal)
                self.goBackButton.setImage((UIImage(named: "skipBack")), for: .normal)
            } else {
                self.skipButton.setImage(UIImage(named: "skip"), for: .normal)
                self.goBackButton.setImage((UIImage(named: "goBack")), for: .normal)
            }*/
        } else {
            self.loadSoundSpinner.isHidden = false
            self.playBackButton.isEnabled = false
        }
    }
    
    //mark: View
    let fiveMinutesInSeconds: Double = 5 * 60
    let artistImageSize = 30
    
    func handleDismissal(_ artist: Artist?) {
        if let playerDelegate = self.playerDelegate {
                    self.dismiss(animated: true, completion: {() in
                        playerDelegate.selectedArtist(artist)
                    })
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
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "Exit Button", "Description": "User Exited PlayerViewController."])
    }
    
    func soundInfoButton(_ imageName: String, buttonType: String?) -> UIButton {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        self.view.addSubview(button)
        
        let imageView = UIImageView()
        imageView.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        imageView.image = UIImage(named: imageName)
        button.addSubview(imageView)
        
        let label = UILabel()
        label.textColor = .white
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
                self.setCountLabel(label, count: self.sound?.commentCount)
                self.commentCountLabel = label
                break
                
            case "likes":
                self.setCountLabel(label, count: self.sound?.tipCount)
                self.likeCountLabel = label
                break
                
            case "credits":
                self.setCountLabel(label, count: self.sound?.creditCount)
                self.creditCountLabel = label
                break
                
            case "plays":
                self.setCountLabel(label, count: self.sound?.playCount)
                self.playCountLabel = label
                break
                
            case "tags":
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
    
    @objc func didPressCommentButton(_ sender: UIButton) {
        let modal = CommentViewController()
        if let sound = self.sound {
            modal.sound = sound
        }
        
        self.present(modal, animated: true, completion: nil)
    }
    
    lazy var dividerLine: UIView = {
        let line = UIView()
        line.layer.borderWidth = 1
        line.layer.borderColor = UIColor.darkGray.cgColor
        return line
    }()
    
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
    
    lazy var artistButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didPressArtistNameButton(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var artistImage: UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = CGFloat(artistImageSize) / 2
        image.clipsToBounds = true
        image.backgroundColor = .black
        return image
    }()
    
    lazy var artistLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    @objc func didPressArtistNameButton(_ sender: UIButton) {
        if self.navigationController == nil {
            self.handleDismissal(self.sound?.artist)
        } else {
            self.performSegue(withIdentifier: "showProfile", sender: self)
        }
        
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "ArtistName", "Description": "User clicked on artist's name to go to profile."])
    }
    
    lazy var likeSoundButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "sendTip"), for: .normal)
        button.addTarget(self, action: #selector(self.didPressSendMoneyButton(_:)), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    @objc func didPressSendMoneyButton(_ sender: UIButton) {
        if let currentUser = PFUser.current() {
            if currentUser.objectId! == sound?.artist?.objectId {
                let cannottipyourself = NSLocalizedString("cannottipyourself", comment: "")
                self.uiElement.showAlert("🙃", message: cannottipyourself, target: self)
            } else if didAddSongToCollection {
                let amountString = self.uiElement.convertCentsToDollarsAndReturnString(self.sound!.tipAmount!, currency: "$")
                let localizedYouAdded = NSLocalizedString("youAdded", comment: "")
                let localizedToYourCollection = NSLocalizedString("toYourCollection", comment: "")
                self.uiElement.showAlert("\(localizedYouAdded) \(self.sound!.title!) \(localizedToYourCollection) \(amountString)", message: "", target: self)
            } else {
                showSendMoney()
            }
        } else {
            let localizedSignupRequired = NSLocalizedString("signupRequired", comment: "")
            let localizedTipArtistsToAddToCollection = NSLocalizedString("tipArtistsToAddToCollection", comment: "")
            self.uiElement.signupRequired(localizedSignupRequired, message: localizedTipArtistsToAddToCollection, target: self)
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
        player.next()
        /*if let soundPlayer = player.player {
            if soundPlayer.duration >= fiveMinutesInSeconds {
                player.skipForward()
            } else {
                self.shouldEnablePlaybackControls(false)
                player.next()
            }
        }*/
        
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "Skip", "Description": "User Skipped Song."])
    }
    
    lazy var goBackButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "goBack"), for: .normal)
        button.addTarget(self, action: #selector(didPressGoBackButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressGoBackButton(_ sender: UIButton) {
        /*if let soundPlayer = player.player {
            if soundPlayer.duration >= fiveMinutesInSeconds {
                player.skipBackward()
            } else {
                player.previous()
            }
        }*/
        player.previous()
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "Go Back", "Description": "User Pressed Go Back."])
    }
    
    func showLoadingSoundbrewSpinner(){
        self.view.addSubview(loadingSoundbrewSpinner)
        loadingSoundbrewSpinner.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(self.view.frame.width * (2))
            make.centerY.centerX.equalTo(self.view)
        }
        
        self.view.addSubview(loadSoundbrewSpinnerTitle)
        loadSoundbrewSpinnerTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(loadingSoundbrewSpinner.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
    }
    
    func removeShowLoadingSoundbrewSpinner() {
        self.loadingSoundbrewSpinner.removeFromSuperview()
        self.loadSoundbrewSpinnerTitle.removeFromSuperview()
    }
    
    var commentCountLabel: UILabel!
    var playCountLabel: UILabel!
    var likeCountLabel: UILabel!
    var creditCountLabel: UILabel!
    var hashtagCountLabel: UILabel!
    
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
        
        let menu = soundInfoButton("more", buttonType: nil)
        menu.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(exitButton)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(appTitle)
        appTitle.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(exitButton)
        }
        
        self.view.addSubview(dividerLine)
        dividerLine.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(0.5)
            make.top.equalTo(appTitle.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        //sound views
        self.view.addSubview(songArt)
        songArt.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(songArtHeightWidth)
            make.top.equalTo(dividerLine.snp.bottom).offset(uiElement.topOffset * 3)
            make.centerX.equalTo(self.view)
        }
        
        self.view.addSubview(songTitle)
        songTitle.snp.makeConstraints { (make) -> Void in
           make.top.equalTo(self.songArt.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
           // make.bottom.equalTo(self.artistButton.snp.top).offset(uiElement.bottomOffset)
        }
        
        //sound info
        let creditsButton = soundInfoButton("profile_icon_filled", buttonType: "credits")
        creditsButton.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.bottom.equalTo(self.view).offset(uiElement.bottomOffset * 5)
        }
        
        let playsButton = soundInfoButton("play", buttonType: "plays")
        playsButton.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(creditsButton)
        }

        let commentsButton = soundInfoButton("comment_filled", buttonType: "comments")
        commentsButton.addTarget(self, action: #selector(self.didPressCommentButton(_:)), for: .touchUpInside)
        commentsButton.snp.makeConstraints { (make) -> Void in
            //make.right.equalTo(playsButton.snp.left).offset(uiElement.leftOffset * 4)
            make.left.equalTo(self.view).offset(self.view.frame.width * 0.25)
            make.bottom.equalTo(creditsButton)
        }
        
        let tagsButton = soundInfoButton("hashtag_filled", buttonType: "tags")
        tagsButton.snp.makeConstraints { (make) -> Void in
            make.right.equalTo(self.view).offset(-(self.view.frame.width * 0.25))
            make.bottom.equalTo(creditsButton)
        }
        
        let likesButton = soundInfoButton("heart_filled", buttonType: "likes")
        likesButton.snp.makeConstraints { (make) -> Void in
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(creditsButton)
        }
        
        self.view.addSubview(playBackButton)
        playBackButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(60)
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(likesButton.snp.top).offset(uiElement.bottomOffset * 5)
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
            //make.centerX.equalTo(self.view).offset(-(55 + uiElement.leftOffset))
            make.centerX.equalTo(commentsButton)
        }
        
        self.view.addSubview(skipButton)
        skipButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(45)
            make.centerY.equalTo(playBackButton)
            make.centerX.equalTo(tagsButton)
            //make.centerX.equalTo(self.view).offset(55 + uiElement.leftOffset)
        }
        
        self.view.addSubview(likeSoundButton)
        likeSoundButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(30)
            make.centerY.equalTo(self.skipButton)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(shareButton)
        shareButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(30)
            make.centerY.equalTo(self.skipButton)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
                
        //playback views
        self.view.addSubview(playBackCurrentTime)
        playBackCurrentTime.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.bottom.equalTo(shareButton.snp.top).offset(uiElement.bottomOffset)
        }
        
        self.view.addSubview(playBackTotalTime)
        playBackTotalTime.snp.makeConstraints { (make) -> Void in
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(playBackCurrentTime)
        }
        
        self.view.addSubview(playBackSlider)
        playBackSlider.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(playBackCurrentTime)
            make.right.equalTo(playBackTotalTime)
            make.bottom.equalTo(playBackCurrentTime.snp.top)
        }

        self.view.addSubview(artistButton)
        artistButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(artistImageSize + 30)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(playBackSlider.snp.top).offset(uiElement.bottomOffset)
        }
        
        self.artistButton.addSubview(artistLabel)
        artistLabel.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(artistButton)
            make.right.equalTo(artistButton)
            make.bottom.equalTo(artistButton)
        }
        
        self.artistButton.addSubview(artistImage)
        artistImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(artistImageSize)
            make.centerX.equalTo(artistButton)
            make.bottom.equalTo(artistLabel.snp.top).offset(-(uiElement.elementOffset))
        }
                
        setSound()
    }
    
    /*func loadYourSoundbrew(_ shouldSetupPlayer: Bool) {
        let query = PFQuery(className: "Post")
        query.whereKey("isRemoved", notEqualTo: true)
        query.addDescendingOrder("tips")
        query.limit = 100
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    var sounds = [Sound]()
                    
                    for i in 0..<objects.count {
                        let object = objects[i]
                        let sound = UIElement().newSoundObject(object)
                        sounds.append(sound)
                    }

                    sounds.shuffle()
                    if shouldSetupPlayer {
                        self.resetPlayer(sounds: sounds)
                        self.setSound()
                    } else {
                        let player = Player.sharedInstance
                        player.sounds = sounds
                    }
                }
                
            } else {
                print("Error: \(error!)")
            }
        }
    }*/
    
    func loadDynamicLinkSound(_ objectId: String, shouldShowShareSoundView: Bool) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                let sound = self.uiElement.newSoundObject(object)
                if shouldShowShareSoundView {
                    self.uiElement.showShareOptions(self, sound: sound)
                }
               // self.resetPlayer(sounds: [sound])
                self.setSound()
                //self.loadYourSoundbrew(false)
            }
        }
    }
    
    /*func resetPlayer(sounds: [Sound]) {
        let player = Player.sharedInstance
        player.player = nil
        player.sounds = sounds
        player.currentSound = sounds[0]
        player.currentSoundIndex = 0
        player.setUpNextSong(false, at: 0)
        //player.soundsPlayed = 2
    }*/
    
   /* @objc func didPressYourSoundbrewButton(_ sender: UIBarButtonItem) {
        self.resetPlayView()
        loadYourSoundbrew(true)
    }*/
}

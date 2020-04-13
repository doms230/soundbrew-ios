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
import GoogleMobileAds

class PlayerViewController: UIViewController, NVActivityIndicatorViewable, UIPickerViewDelegate, UIPickerViewDataSource, PlayerDelegate, TagDelegate, GADRewardedAdDelegate {
    
    let color = Color()
    let uiElement = UIElement()
    
    let player = Player.sharedInstance
    var sound: Sound?
    
    var playerDelegate: PlayerDelegate?
    var tagDelegate: TagDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Soundbrew"
        setupPlayerView()
    }
        
    override func viewDidAppear(_ animated: Bool) {
        self.setSound()
        customer = Customer.shared
        if let balance = customer.artist?.balance {
            if balance == 0 {
                self.rewardedAd = createAndLoadRewardedAd(testAdUnitId)
            }
        } else {
            self.rewardedAd = createAndLoadRewardedAd(testAdUnitId)
        }
    }
    
    func setupNotificationCenter(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSoundUpdate), name: NSNotification.Name(rawValue: "setSound"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector:#selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    //mark: money
    let tipAmountInCents = [5, 25, 50, 100]
    var selectedTipAmount = 5
    var customer = Customer.shared
    
    func getTipAmountAndLikeSong(){
        if let sound = self.sound {
                if let userSavedTipAmount = self.uiElement.getUserDefault("tipAmount") as? Int {
                    sendTip(sound, tipAmount: userSavedTipAmount)
                    
                } else {
                    let alertView = UIAlertController(
                        title: "1 like = $$$",
                        message: "How much would you like to pay artists when you like a song? \n\n\n\n\n\n\n\n",
                        preferredStyle: .actionSheet)
                    
                    let pickerView = UIPickerView(frame:
                        CGRect(x: 0, y: 45, width: self.view.frame.width, height: 160))
                    pickerView.dataSource = self
                    pickerView.delegate = self
                    alertView.view.addSubview(pickerView)
                    
                    let sendMoneyActionButton = UIAlertAction(title: "Save & Tip", style: .default) { (_) -> Void in
                        self.uiElement.setUserDefault(self.selectedTipAmount, key: "tipAmount")
                        self.sendTip(sound, tipAmount: self.selectedTipAmount)
                    }
                    alertView.addAction(sendMoneyActionButton)
                    
                    let localizedCancel = NSLocalizedString("cancel", comment: "")
                    let cancelAction = UIAlertAction(title: localizedCancel, style: .cancel, handler: nil)
                    alertView.addAction(cancelAction)
                    
                    present(alertView, animated: true, completion: nil)
                }
        }
    }
    
    func tipAction(_ sound: Sound, tipAmount: Int) {
        self.likeSoundButton.setImage(UIImage(named: "sendTipColored"), for: .normal)
        self.likeSoundButton.isEnabled = false
        if PFUser.current()?.objectId != self.uiElement.d_innovatorObjectId {
            SKStoreReviewController.requestReview()
        }
        self.sound?.tipAmount = tipAmount
        updateTip(sound.objectId!, toUserId: sound.artist!.objectId, tipAmount: tipAmount)
    }
    
    func sendTip(_ sound: Sound, tipAmount: Int) {
        //if customer.artist!.balance! >= tipAmount {
        if 0 >= tipAmount {
            tipAction(sound, tipAmount: tipAmount)
            
        } else {
            let soundbrewBalance = uiElement.convertCentsToDollarsAndReturnString(customer.artist!.balance ?? 0, currency: "$")
            let paymentAmount = uiElement.convertCentsToDollarsAndReturnString(tipAmount, currency: "$")

            let localizedAddFunds = NSLocalizedString("addFunds", comment: "")
            
            var artistName = "the artist"
            if let name = self.sound?.artist?.name {
                artistName = name
            } else if let username = self.sound?.artist?.username {
                artistName = username
            }
            
            var soundTitle = "this song"
            if let title = self.sound?.title {
                soundTitle = title
            }

            let alertView = UIAlertController(
                title: "Payment amount of \(paymentAmount) exceeds your Soundbrew balance of \(soundbrewBalance).",
                message: "Liking this song will pay \(artistName) and add \(soundTitle) to your collection of 'likes'.",
                preferredStyle: .actionSheet)
            
            let addFundsActionButton = UIAlertAction(title: localizedAddFunds, style: .default) { (_) -> Void in
                let artist = Artist(objectId: "addFunds", name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil)
                self.handleDismissal(artist)
                
                MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Function" : "sendTip", "Description": "User went to Add Funds Page"])
            }
            alertView.addAction(addFundsActionButton)
            
            let watchAddActionButton = UIAlertAction(title: "Watch Video, Earn Funds", style: .default) { (_) -> Void in
                if let rewardedAd = self.rewardedAd {
                    if rewardedAd.isReady == true {
                       rewardedAd.present(fromRootViewController: self, delegate: self)
                    }
                }
            }
            alertView.addAction(watchAddActionButton)
            
            let cancelAction = UIAlertAction(title: "Don't pay artist", style: .cancel, handler: nil)
            alertView.addAction(cancelAction)
            
            present(alertView, animated: true, completion: nil)
        }
    }
        
    func updateArtistPayment(_ userId: String, tipAmount: Int) {
        let query = PFQuery(className: "Payment")
        query.whereKey("userId", equalTo: userId)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if error != nil {
                self.newArtistPaymentRow(userId, tipAmount: tipAmount)
                
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
    
    func newArtistPaymentRow(_ artistObjectId: String, tipAmount: Int) {
        let newPaymentRow = PFObject(className: "Payment")
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
    
    func newStory(_ postId: String) {
        if let userId = PFUser.current()?.objectId {
            let newStory = PFObject(className: "Story")
            newStory["type"] = "like"
            newStory["userId"] = userId
            newStory["postId"] = postId
            newStory.saveEventually()
        }
    }
    
    func updateTip(_ soundId: String, toUserId: String, tipAmount: Int) {
        if let fromUserId = PFUser.current()?.objectId {
            let query = PFQuery(className: "Tip")
            query.whereKey("fromUserId", equalTo: fromUserId)
            query.whereKey("toUserId", equalTo: toUserId)
            query.whereKey("soundId", equalTo: soundId)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                 if error == nil, let object = object {
                    object.incrementKey("amount", byAmount: NSNumber(value: tipAmount))
                    object.saveEventually {
                        (success: Bool, error: Error?) in
                        self.likeSoundButton.setImage(UIImage(named: "sendTip"), for: .normal)
                        self.likeSoundButton.isEnabled = true
                        
                        var newTipAmount = 0
                        if let savedTipAmount = object["amount"] as? Int {
                            newTipAmount = savedTipAmount
                        }

                        let newTipAmountString = self.uiElement.convertCentsToDollarsAndReturnString(newTipAmount, currency: "$")
                        self.paymentAmountForLike.text = newTipAmountString
                        
                        self.customer.updateBalance(-tipAmount)
                                                
                        if let sound = self.sound {
                            self.incrementSoundTipAmount(sound, tipAmount: tipAmount, shouldIncrementTippers: false)
                            self.getCreditsAndSplit(sound, tipAmount: tipAmount)
                        }
                    }
                    
                 } else {
                    self.newTip(soundId, toUserId: toUserId, tipAmount: tipAmount, fromUserId: fromUserId)
                }
            }
        }
    }
    
    func newTip(_ soundId: String, toUserId: String, tipAmount: Int, fromUserId: String) {
        let newTip = PFObject(className: "Tip")
        newTip["fromUserId"] = fromUserId
        newTip["toUserId"] = toUserId
        newTip["amount"] = tipAmount
        newTip["soundId"] = soundId
        newTip.saveEventually {
            (success: Bool, error: Error?) in
            self.likeSoundButton.setImage(UIImage(named: "sendTip"), for: .normal)
            self.likeSoundButton.isEnabled = true
            let tipAmountString = self.uiElement.convertCentsToDollarsAndReturnString(tipAmount, currency: "$")
            self.paymentAmountForLike.text = tipAmountString
            if success, let sound = self.sound {
                self.customer.updateBalance(-tipAmount)
                self.newMention(sound, toUserId: toUserId)
                self.incrementSoundTipAmount(sound, tipAmount: tipAmount, shouldIncrementTippers: true)
                self.newStory(sound.objectId!)
                self.getCreditsAndSplit(sound, tipAmount: tipAmount)
            }
        }
    }
    
    func getCreditsAndSplit(_ sound: Sound, tipAmount: Int) {
        if currentSoundCredits.isEmpty {
            updateArtistPayment(sound.artist!.objectId, tipAmount: tipAmount)
            
        } else {
            for credit in currentSoundCredits {
                var tipSplit: Float = 0
                if let percentage = credit.percentage {
                    if percentage > 0 {
                        tipSplit = Float(percentage * tipAmount)
                        let tipSplitInCents = tipSplit / 100
                        updateArtistPayment(credit.artist!.objectId, tipAmount: Int(tipSplitInCents))
                    }
                }
            }
        }
    }
    
    func newMention(_ sound: Sound, toUserId: String) {
        let newMention = PFObject(className: "Mention")
        newMention["type"] = "like"
        newMention["fromUserId"] = PFUser.current()!.objectId!
        newMention["toUserId"] = toUserId
        newMention["postId"] = sound.objectId!
        newMention.saveEventually {
            (success: Bool, error: Error?) in
            if success && error == nil {
                self.uiElement.sendAlert("liked \(sound.title!)!", toUserId: toUserId, shouldIncludeName: true)
            }
        }
    }
    
    func incrementSoundTipAmount(_ sound: Sound, tipAmount: Int, shouldIncrementTippers: Bool) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: sound.objectId!) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                object.incrementKey("tips", byAmount: NSNumber(value: tipAmount))
                if shouldIncrementTippers {
                    object.incrementKey("tippers")
                    var newLikeCount = 1
                    if let likes = self.sound?.tipCount {
                        newLikeCount = likes + newLikeCount
                    }
                    self.likeCountLabel.text = "\(newLikeCount)"
                }
                object.saveEventually()
            }
        }
    }
    
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
        
        if playBackButton.superview == nil {
            showPlayerView()
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
                self.gxoBackButton.setImage((UIImage(named: "skipBack")), for: .normal)
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
        if let currentUser = PFUser.current() {
            if currentUser.objectId! == sound?.artist?.objectId {
                let cannottipyourself = NSLocalizedString("cannottipyourself", comment: "")
                self.uiElement.showAlert("🙃", message: cannottipyourself, target: self)
            } else if let sound = self.sound {
                self.sendTip(sound, tipAmount: 10)
            }
            
        } else {
            let localizedSignupRequired = NSLocalizedString("signupRequired", comment: "")
            let localizedTipArtistsToAddToCollection = NSLocalizedString("tipArtistsToAddToCollection", comment: "")
            self.uiElement.signupRequired(localizedSignupRequired, message: localizedTipArtistsToAddToCollection, target: self)
        }
        
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
    var soundArtistImage: UIImageView!
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
        let creditCountButton = soundInfoButton("profile_icon_filled", buttonType: "credits")
        creditCountButton.addTarget(self, action: #selector(self.didPressCreditCountButton(_:)), for: .touchUpInside)
        creditCountButton.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.bottom.equalTo(self.view).offset(bottomOffsetValue)
        }
        
        let playCountButton = soundInfoButton("play", buttonType: "plays")
        playCountButton.addTarget(self, action: #selector(self.didPressListenCountButton(_:)), for: .touchUpInside)
        playCountButton.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(creditCountButton)
        }

        let commentCountButton = soundInfoButton("comment_filled", buttonType: "comments")
        commentCountButton.addTarget(self, action: #selector(self.didPressCommentCountButton(_:)), for: .touchUpInside)
        commentCountButton.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(self.view.frame.width * 0.25)
            make.bottom.equalTo(creditCountButton)
        }
        
        let tagsCountButton = soundInfoButton("hashtag_filled", buttonType: "tags")
        tagsCountButton.addTarget(self, action: #selector(self.didPressTagCountButton(_:)), for: .touchUpInside)
        tagsCountButton.snp.makeConstraints { (make) -> Void in
            make.right.equalTo(self.view).offset(-(self.view.frame.width * 0.25))
            make.bottom.equalTo(creditCountButton)
        }
        
        let likesCountButton = soundInfoButton("heart_filled", buttonType: "likes")
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
            make.centerX.equalTo(tagsCountButton)
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
                
        setSound()
    }
    
    //mark: ads
    let testAdUnitId = "ca-app-pub-3940256099942544/1712485313"
    var rewardedAd: GADRewardedAd?
    func createAndLoadRewardedAd(_ adUnitId: String) -> GADRewardedAd? {
      rewardedAd = GADRewardedAd(adUnitID: adUnitId)
      rewardedAd?.load(GADRequest()) { error in
        if let error = error {
          print("Loading failed: \(error)")
        } else {
          print("Loading Succeeded")
        }
      }
        
      return rewardedAd
    }

    /// Tells the delegate that the user earned a reward.
    func rewardedAd(_ rewardedAd: GADRewardedAd, userDidEarn reward: GADAdReward) {
        print("Reward received with currency: \(reward.type), amount \(reward.amount).")
        let rewardAmount = Int(truncating: reward.amount)
        let currentUser = Customer.shared
        var newBalance = 0
        if let currentBalance = currentUser.artist?.balance {
            newBalance = currentBalance + rewardAmount
            currentUser.artist?.balance = newBalance
        } else {
            currentUser.artist?.balance = rewardAmount
        }
        
        if let sound = self.sound {
            print("tip action")
            self.tipAction(sound, tipAmount: rewardAmount)
        } else {
            print("no tip action")
        }
    }
    
    /// Tells the delegate that the rewarded ad was presented.
    func rewardedAdDidPresent(_ rewardedAd: GADRewardedAd) {
      print("Rewarded ad presented.")
    }
    /// Tells the delegate that the rewarded ad was dismissed.
    func rewardedAdDidDismiss(_ rewardedAd: GADRewardedAd) {
        //self.rewardedAd = createAndLoadRewardedAd(testAdUnitId)
    }
        
    /// Tells the delegate that the rewarded ad failed to present.
    func rewardedAd(_ rewardedAd: GADRewardedAd, didFailToPresentWithError error: Error) {
      print("Rewarded ad failed to present.")
    }
}

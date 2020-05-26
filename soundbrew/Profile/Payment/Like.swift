//
//  Like.swift
//  soundbrew
//
//  Created by Dominic  Smith on 5/6/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import Foundation
import Parse
import GoogleMobileAds

class Like: NSObject, GADRewardedAdDelegate {
    static let shared = Like()
    let customer = Customer.shared
    let uiElement = UIElement()
    var target: UIViewController!
    var sound: Sound?
    var paymentAmount = 100
    var soundCredits = [Credit]()
    var didPressLikeButtonBeforeRewardedAdLoaded = false
    var likeSoundButton: UIButton!
    
    func sendPayment() {
        if let balance = customer.artist?.balance, balance >= self.paymentAmount {
            newPayment(self.paymentAmount)
             
        } else {
            self.askToAdFundsToTheirAccount("")
        }
     }
    
    func newPayment(_ paymentAmount: Int) {
        let newPayment = PFObject(className: "Tip")
        newPayment["fromUserId"] = self.customer.artist?.objectId
        newPayment["toUserId"] = sound!.artist?.objectId
        newPayment["amount"] = paymentAmount
        newPayment["soundId"] = sound!.objectId
        newPayment.saveEventually {
            (success: Bool, error: Error?) in
              if success {
                self.customer.updateBalance(-paymentAmount)
                self.sound?.currentUserTipDate = newPayment.createdAt
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "setSound"), object: nil)
                if let sound = self.sound {
                    self.likeButtonUI(sound)
                }
                self.newMention(self.sound!, toUserId: (self.sound!.artist?.objectId)!)
                self.incrementSoundPaymentAmount(true, paymentAmount: paymentAmount)
                self.getCreditsAndSplit(paymentAmount)
                self.paymentAmount = 100
              }
          }
    }
    
    func incrementSoundPaymentAmount(_ shouldUpdateTippers: Bool, paymentAmount: Int) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: sound!.objectId!) {
            (object: PFObject?, error: Error?) -> Void in
            if let object = object {
                object.incrementKey("tips", byAmount: NSNumber(value: paymentAmount))
                if shouldUpdateTippers {
                    object.incrementKey("tippers")
                }
                object.saveEventually()
            }
        }
    }
    
    func getCreditsAndSplit(_ paymentAmount: Int) {
        if soundCredits.isEmpty {
            updateArtistPayment(sound!.artist!.objectId, paymentAmount: paymentAmount)
            
        } else {
            for credit in soundCredits {
                var paySplit: Float = 0
                if let percentage = credit.percentage {
                    if percentage > 0 {
                        paySplit = Float(percentage * paymentAmount)
                        let paySplitInCents = paySplit / 100
                        updateArtistPayment(credit.artist!.objectId, paymentAmount: Int(paySplitInCents))
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
    
    func updateArtistPayment(_ userId: String, paymentAmount: Int) {
        let query = PFQuery(className: "Payment")
        query.whereKey("userId", equalTo: userId)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if error != nil {
                self.newArtistPaymentRow(userId, paymentAmount: paymentAmount)
                
            } else if let object = object {
                object.incrementKey("tipsSinceLastPayout", byAmount: NSNumber(value: paymentAmount))
                object.incrementKey("tips", byAmount: NSNumber(value: paymentAmount))
                object.saveEventually {
                    (success: Bool, error: Error?) in
                    if error != nil {
                        self.customer.updateBalance(paymentAmount)
                    }
                }
            }
        }
    }
    
    func newArtistPaymentRow(_ artistObjectId: String, paymentAmount: Int) {
        let newPaymentRow = PFObject(className: "Payment")
        newPaymentRow["userId"] = artistObjectId
        newPaymentRow["tipsSinceLastPayout"] = paymentAmount
        newPaymentRow["tips"] = paymentAmount
        newPaymentRow.saveEventually {
            (success: Bool, error: Error?) in
            if error != nil {
                self.customer.updateBalance(paymentAmount)
            }
        }
    }
    
    //mark: rewarded Ads
    let testRewardedAdUnitId = "ca-app-pub-3940256099942544/1712485313"
    let liveRewardedAdUnitId = "ca-app-pub-9150756002517285/9458994684"
    var rewardedAd: GADRewardedAd?
    func createAndLoadRewardedAd(_ adUnitId: String) -> GADRewardedAd? {
      rewardedAd = GADRewardedAd(adUnitID: adUnitId)
      rewardedAd?.load(GADRequest()) { error in
        if let error = error {
          print("Loading failed: \(error)")
        } else if self.didPressLikeButtonBeforeRewardedAdLoaded  {
            self.rewardedAd?.present(fromRootViewController: self.target, delegate: self)
        }
        self.didPressLikeButtonBeforeRewardedAdLoaded = false
      }
        
      return rewardedAd
    }

    /// Tells the delegate that the user earned a reward.
    func setUpPayment() {
        if let balance = customer.artist?.balance, balance < self.paymentAmount {
            self.rewardedAd = createAndLoadRewardedAd(liveRewardedAdUnitId)
            
        } else {
            self.rewardedAd = createAndLoadRewardedAd(liveRewardedAdUnitId)
        }
    }
    
    func rewardedAd(_ rewardedAd: GADRewardedAd, userDidEarn reward: GADAdReward) {
        self.rewardedAd = nil
        let rewardAmount = Int(truncating: reward.amount)
        self.paymentAmount = rewardAmount
        let currentUser = Customer.shared
        var newBalance = 0
        if let currentBalance = currentUser.artist?.balance {
            newBalance = currentBalance + rewardAmount
            currentUser.artist?.balance = newBalance
        } else {
            currentUser.artist?.balance = rewardAmount
        }
        
        newPayment(rewardAmount)
    }
    
    func rewardedAd(_ rewardedAd: GADRewardedAd, didFailToPresentWithError error: Error) {
        self.rewardedAd = nil
        if let sound = self.sound {
            likeButtonUI(sound)
        }
    }
    
    func rewardedAdDidDismiss(_ rewardedAd: GADRewardedAd) {
       // askToAdFundsToTheirAccount("Tired of Ads?")
        self.rewardedAd = nil
        if let sound = self.sound {
            likeButtonUI(sound)
        }
    }
    
    func askToAdFundsToTheirAccount(_ title: String) {
        let paymentAmountString = self.uiElement.convertCentsToDollarsAndReturnString(self.paymentAmount, currency: "$")
        if let sound = self.sound {
            self.likeButtonUI(sound)
        }
        //"Add funds to your Soundbrew wallet to remove ads and pay artists more!"
          let alertView = UIAlertController(
            title: "Your Soundbrew balance is less than the required amount of \(paymentAmountString)",
            message: "'Liking' \(self.sound?.title ?? "this song") will pay \(self.sound?.artist?.name ?? "this arrtist") and add it to your likes on your profile.",
              preferredStyle: .actionSheet)
          
          let addFundsActionButton = UIAlertAction(title: "Add Funds", style: .default) { (_) -> Void in
             let modal = AddFundsViewController()
             modal.shouldShowExitButton = true
             self.target.present(modal, animated: true, completion: nil)
          }
          alertView.addAction(addFundsActionButton)
        
        let watchAddAction = UIAlertAction(title: "Earn Funds ▷", style: .default) { (_) -> Void in
            if let rewardedAd = self.rewardedAd {
                if rewardedAd.isReady == true {
                    rewardedAd.present(fromRootViewController: self.target, delegate: self)
                    
                 } else {
                    self.didPressLikeButtonBeforeRewardedAdLoaded = true
                }
                
            } else {
                self.didPressLikeButtonBeforeRewardedAdLoaded = true
                self.setUpPayment()
            }
        }
        alertView.addAction(watchAddAction)
        
        let laterAction = UIAlertAction(title: "Later", style: .default) { (_) -> Void in
            if let sound = self.sound {
                self.likeButtonUI(sound)
            }
        }
        alertView.addAction(laterAction)
          
         self.target.present(alertView, animated: true, completion: nil)
    }
    
    func loadCredits(_ sound: Sound) {
        let query = PFQuery(className: "Credit")
        query.whereKey("postId", equalTo: sound.objectId!)
        query.cachePolicy = .networkElseCache
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
                    
                    self.soundCredits.append(credit)
                }
            }
            
            self.checkIfUserLikedSong(sound)
        }
    }
    
    func checkIfUserLikedSong(_ sound: Sound) {
        if let userId = PFUser.current()?.objectId {
            let query = PFQuery(className: "Tip")
            query.whereKey("fromUserId", equalTo: userId)
            query.whereKey("soundId", equalTo: sound.objectId!)
            query.cachePolicy = .networkElseCache
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                 if let object = object {
                    self.sound?.currentUserTipDate = object.createdAt
                 }
                self.likeButtonUI(sound)
                Player.sharedInstance.fetchAudioFromNextSound()
            }
        }
    }
    
    func likeButtonUI(_ sound: Sound) {
        var shouldEnableLikeSoundButton = false
        var uiImageName = "sendTip"
        if sound.currentUserTipDate != nil {
            uiImageName = "sendTipColored"
        } else {
            shouldEnableLikeSoundButton = true
            if self.rewardedAd == nil {
                self.setUpPayment()
            }
        }
        
        //make sure this code is run on the main thread
        DispatchQueue.main.async {
            self.likeSoundButton.isEnabled = shouldEnableLikeSoundButton
            self.likeSoundButton.setImage(UIImage(named: uiImageName), for: .normal)
        }
    }
}

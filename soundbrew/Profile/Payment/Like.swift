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
    //var creditsLoaded = false
    var likeSoundButton: UIButton!
    
    func sendPayment() {
        if customer.artist!.balance! >= self.paymentAmount {
            newPaymentRow()
             
         } else if let rewardedAd = self.rewardedAd {
             if rewardedAd.isReady == true {
                print("ad ready and going to present")
                 rewardedAd.present(fromRootViewController: target, delegate: self)
             } else {
                print("did press like button before ad was loaded")
                didPressLikeButtonBeforeRewardedAdLoaded = true
            }
         }
     }
    
    func updatePayment() {
        /*if self.creditsLoaded {
           // if let fromUserId = PFUser.current()?.objectId {
               // newPaymentRow()
               /* let query = PFQuery(className: "Tip")
                query.whereKey("fromUserId", equalTo: fromUserId)
                query.whereKey("toUserId", equalTo: sound!.artist!.objectId!)
                query.whereKey("soundId", equalTo: sound!.objectId!)
                query.getFirstObjectInBackground {
                    (object: PFObject?, error: Error?) -> Void in
                     if error == nil, let object = object {
                        object.incrementKey("amount", byAmount: NSNumber(value: self.paymentAmount))
                        object.saveEventually {
                            (success: Bool, error: Error?) in
                            if success {
                                self.customer.updateBalance(-self.paymentAmount)
                                var currentPaymentAmount = 0
                                if let paymentAmount = self.sound?.tipAmount {
                                    currentPaymentAmount = paymentAmount
                                }
                                self.sound?.tipAmount = currentPaymentAmount + self.paymentAmount
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "setSound"), object: nil)
                                //self.setUpPayment()
                                self.likeButtonUI()
                                self.incrementSoundPaymentAmount(false)
                                self.getCreditsAndSplit()
                            }
                      }
                        
                     } else {
                        self.newPaymentRow()
                    }
                }*/
            //}
        }*/
    }
    
    func newPaymentRow() {
        let newPayment = PFObject(className: "Tip")
        newPayment["fromUserId"] = self.customer.artist?.objectId
        newPayment["toUserId"] = self.sound!.artist?.objectId
        newPayment["amount"] = self.paymentAmount
        newPayment["soundId"] = self.sound!.objectId
        newPayment.saveEventually {
            (success: Bool, error: Error?) in
              if success {
                self.customer.updateBalance(-self.paymentAmount)
                self.sound?.currentUserTipDate = newPayment.createdAt
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "setSound"), object: nil)
                if let sound = self.sound {
                    self.likeButtonUI(sound)
                }
                self.newMention(self.sound!, toUserId: (self.sound!.artist?.objectId)!)
                self.incrementSoundPaymentAmount(true)
                self.getCreditsAndSplit()
              }
          }
    }
    
    func incrementSoundPaymentAmount(_ shouldUpdateTippers: Bool) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: sound!.objectId!) {
            (object: PFObject?, error: Error?) -> Void in
            if let object = object {
                object.incrementKey("tips", byAmount: NSNumber(value: self.paymentAmount))
                if shouldUpdateTippers {
                    object.incrementKey("tippers")
                }
                object.saveEventually()
            }
        }
    }
    
    func getCreditsAndSplit() {
        if soundCredits.isEmpty {
            updateArtistPayment(sound!.artist!.objectId, paymentAmount: self.paymentAmount)
            
        } else {
            for credit in soundCredits {
                var paySplit: Float = 0
                if let percentage = credit.percentage {
                    if percentage > 0 {
                        paySplit = Float(percentage * self.paymentAmount)
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
            print("attempting to present view")
            self.rewardedAd?.present(fromRootViewController: self.target, delegate: self)
        } /*else {
            self.likeButtonUI()
        }*/
        self.didPressLikeButtonBeforeRewardedAdLoaded = false
      }
        
      return rewardedAd
    }

    /// Tells the delegate that the user earned a reward.
    func setUpPayment() {
        if let balance = customer.artist?.balance, balance < self.paymentAmount {
            self.rewardedAd = createAndLoadRewardedAd(testRewardedAdUnitId)
            print("setting up ad")
            /*if balance >= self.paymentAmount {
               // self.likeButtonUI()
            } else {
                self.rewardedAd = createAndLoadRewardedAd(testRewardedAdUnitId)
            }*/
            
        } else {
            print("no balance, loading ad")
            self.rewardedAd = createAndLoadRewardedAd(testRewardedAdUnitId)
        }
    }
    
    func rewardedAd(_ rewardedAd: GADRewardedAd, userDidEarn reward: GADAdReward) {
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
        
        newPaymentRow()
        
        target.dismiss(animated: true, completion: {() in
            var soundArtistName = "this artist"
            if let name = self.sound?.artist?.name {
                soundArtistName = name
            } else if let username = self.sound?.artist?.username {
                soundArtistName = username
            }
            
            let paymentAmountAsString = self.uiElement.convertCentsToDollarsAndReturnString(self.paymentAmount, currency: "$")
            self.askToAdFundsToTheirAccount("You just paid \(soundArtistName) \(paymentAmountAsString)!")
        })
    }
    
    func rewardedAdDidDismiss(_ rewardedAd: GADRewardedAd) {
        print("was dissmissed")
        askToAdFundsToTheirAccount("Tired of Ads?")
    }
    
    func askToAdFundsToTheirAccount(_ title: String) {
        if let sound = self.sound {
            self.likeButtonUI(sound)
        }
         DispatchQueue.main.async {
             let alertView = UIAlertController(
                title: title,
                 message: "Add funds to your Soundbrew wallet to remove ads and pay artists more!",
                 preferredStyle: .actionSheet)
             
             let addFundsActionButton = UIAlertAction(title: "Add Funds", style: .default) { (_) -> Void in
                let modal = AddFundsViewController()
                modal.shouldShowExitButton = true
                self.target.present(modal, animated: true, completion: nil)
             }
             alertView.addAction(addFundsActionButton)
             
             let cancelAction = UIAlertAction(title: "Later", style: .default, handler: nil)
             alertView.addAction(cancelAction)
             
            self.target.present(alertView, animated: true, completion: nil)
        }
    }
    
    func loadCredits(_ sound: Sound) {
        let query = PFQuery(className: "Credit")
        query.whereKey("postId", equalTo: sound.objectId!)
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            //self.creditsLoaded = true
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
                    /*if let tipAmount = object["amount"] as? Int {
                        print("tipAMount: \(tipAmount)")
                        self.sound?.tipAmount = tipAmount
                    }*/
                 }
                self.likeButtonUI(sound)
                //self.setUpPayment()
                Player.sharedInstance.fetchAudioFromNextSound()
            }
        }
    }
    
    func likeButtonUI(_ sound: Sound) {
        DispatchQueue.main.async {
            var uiImageName = "sendTip"
            if sound.currentUserTipDate != nil {
                print("tip exists")
                self.likeSoundButton.isEnabled = false
                uiImageName = "sendTipColored"
            } else {
                print("print exits")
                self.likeSoundButton.isEnabled = true
                self.setUpPayment()
            }
            
            self.likeSoundButton.setImage(UIImage(named: uiImageName), for: .normal)
        }
    }
}

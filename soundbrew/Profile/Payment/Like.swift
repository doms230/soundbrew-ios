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
    let customer = Customer.shared
    let uiElement = UIElement()
    let target: UIViewController!
    var sound: Sound!
    var paymentAmount: Int!
    var soundCredits: [Credit]
    var didPressLikeButtonBeforeRewardedAdLoaded = false
    
    init(sound: Sound, paymentAmount: Int, soundCredits: [Credit], target: UIViewController) {
        self.sound = sound
        self.paymentAmount = paymentAmount
        self.soundCredits = soundCredits
        self.target = target
        
        super.init()
        
        if let balance = customer.artist?.balance {
            if balance == 0 {
                self.rewardedAd = createAndLoadRewardedAd(testRewardedAdUnitId)
            }
        } else {
            self.rewardedAd = createAndLoadRewardedAd(testRewardedAdUnitId)
        }
    }

    func sendPayment() {
        didPressLikeButtonBeforeRewardedAdLoaded = true
        if customer.artist!.balance! >= self.paymentAmount {
            updatePayment()
             
         } else if let rewardedAd = self.rewardedAd {
             if rewardedAd.isReady == true {
                 rewardedAd.present(fromRootViewController: target, delegate: self)
             }
         }
     }
    
    func updatePayment() {
        if let fromUserId = PFUser.current()?.objectId {
            let query = PFQuery(className: "Tip")
            query.whereKey("fromUserId", equalTo: fromUserId)
            query.whereKey("toUserId", equalTo: sound.artist!.objectId!)
            query.whereKey("soundId", equalTo: sound.objectId!)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                 if error == nil, let object = object {
                    object.incrementKey("amount", byAmount: NSNumber(value: self.paymentAmount))
                    object.saveEventually {
                        (success: Bool, error: Error?) in
                        //TODO: completion handler returns true for UI to update
                        if success {
                            self.customer.updateBalance(-self.paymentAmount)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "setSound"), object: nil)
                            self.incrementSoundPaymentAmount(false)
                            self.getCreditsAndSplit()
                        }
                  }
                    
                 } else {
                    let newTip = PFObject(className: "Tip")
                    newTip["fromUserId"] = self.customer.artist?.objectId
                    newTip["toUserId"] = self.sound.artist?.objectId
                    newTip["amount"] = self.paymentAmount
                    newTip["soundId"] = self.sound.objectId
                    newTip.saveEventually {
                        (success: Bool, error: Error?) in
                          if success {
                            self.customer.updateBalance(-self.paymentAmount)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "setSound"), object: nil)
                            self.newMention(self.sound, toUserId: (self.sound.artist?.objectId)!)
                            self.incrementSoundPaymentAmount(true)
                            self.getCreditsAndSplit()
                          }
                      }
                }
            }
        }
    }
    
    func incrementSoundPaymentAmount(_ shouldUpdateTippers: Bool) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: sound.objectId!) {
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
            updateArtistPayment(sound.artist!.objectId, paymentAmount: self.paymentAmount)
            
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
        } else if self.didPressLikeButtonBeforeRewardedAdLoaded {
            self.rewardedAd?.present(fromRootViewController: self.target, delegate: self)
            self.didPressLikeButtonBeforeRewardedAdLoaded = false
        }
      }
        
      return rewardedAd
    }

    /// Tells the delegate that the user earned a reward.
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
        
        updatePayment()
        
        target.dismiss(animated: true, completion: {() in
            self.askToAdFundsToTheirAccount()
        })
    }
    
    func rewardedAdDidDismiss(_ rewardedAd: GADRewardedAd) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "setSound"), object: nil)
        askToAdFundsToTheirAccount()
    }
    
    func askToAdFundsToTheirAccount() {
         let alertView = UIAlertController(
             title: "Tired of Ads?",
             message: "Remove ads by adding funds to your Soundbrew wallet!",
             preferredStyle: .actionSheet)
         
         let addFundsActionButton = UIAlertAction(title: "Add Funds", style: .default) { (_) -> Void in
             /*let artist = Artist(objectId: "addFunds", name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil)
             self.handleDismissal(artist)*/
            let modal = AddFundsViewController()
            self.target.present(modal, animated: true, completion: nil)
            
         }
         alertView.addAction(addFundsActionButton)
         
         let cancelAction = UIAlertAction(title: "Later", style: .default, handler: nil)
         alertView.addAction(cancelAction)
         
        target.present(alertView, animated: true, completion: nil)
    }
    
}

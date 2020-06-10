//
//  Like.swift
//  soundbrew
//
//  Created by Dominic  Smith on 5/6/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import Foundation
import Parse

class Like: NSObject {
    static let shared = Like()
    let customer = Customer.shared
    let uiElement = UIElement()
    var target: UIViewController!
    var sound: Sound?
    var soundCredits = [Credit]()
    var didPressLikeButtonBeforeRewardedAdLoaded = false
    var likeSoundButton: UIButton!
    
    func newLike() {
        let newPayment = PFObject(className: "Tip")
        newPayment["fromUserId"] = self.customer.artist?.objectId
        newPayment["toUserId"] = sound!.artist?.objectId
        newPayment["soundId"] = sound!.objectId
        newPayment.saveEventually {
            (success: Bool, error: Error?) in
              if success {
                self.sound?.currentUserTipDate = newPayment.createdAt
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "setSound"), object: nil)
                if let sound = self.sound {
                    self.likeButtonUI(sound)
                }
                self.newMention(self.sound!, toUserId: (self.sound!.artist?.objectId)!)
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
    
    func loadCredits(_ sound: Sound) {
        let query = PFQuery(className: "Credit")
        query.whereKey("postId", equalTo: sound.objectId!)
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                for object in objects {
                    let userId = object["userId"] as? String
                    let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, accountId: nil, priceId: nil)
                    
                    let credit = Credit(objectId: object.objectId, artist: artist, title: nil)
                    if let title = object["title"] as? String {
                        credit.title = title
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
                    sound.currentUserTipDate = object.createdAt
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
        }
        
        //make sure this code is run on the main thread
        DispatchQueue.main.async {
            self.likeSoundButton.isEnabled = shouldEnableLikeSoundButton
            self.likeSoundButton.setImage(UIImage(named: uiImageName), for: .normal)
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "setSound"), object: nil)
    }
}

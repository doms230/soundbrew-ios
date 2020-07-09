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
    var player = Player.sharedInstance
    var likeSoundButton: UIButton!
    
    func newLike() {
        if let sound = player.currentSound, let toUserId = sound.artist?.objectId, let fromUserId = self.customer.artist?.objectId {
            let newPayment = PFObject(className: "Tip")
            newPayment["fromUserId"] = fromUserId
            newPayment["toUserId"] = toUserId
            newPayment["soundId"] = sound.objectId
            newPayment.saveEventually {
                (success: Bool, error: Error?) in
                  if success {
                    self.player.currentSound?.currentUserDidLikeSong = true
                    self.updateLikeButton()
                    self.newMention(sound, fromUserId: fromUserId, toUserId: toUserId)
                  }
              }
        }
    }
    
    func newMention(_  sound: Sound, fromUserId: String, toUserId: String) {
        if fromUserId != toUserId {
            let newMention = PFObject(className: "Mention")
            newMention["type"] = "like"
            newMention["fromUserId"] = fromUserId
            newMention["toUserId"] = toUserId
            newMention["postId"] = sound.objectId
            newMention.saveEventually {
                (success: Bool, error: Error?) in
                if success && error == nil {
                    self.uiElement.sendAlert("liked \(sound.title ?? "your sound")!", toUserId: toUserId, shouldIncludeName: true)
                }
            }
        }
    }
    
    func checkIfUserLikedSong(_ shouldPlay: Bool) {
        if let soundId = self.player.currentSound?.objectId, let userId = PFUser.current()?.objectId {
            let query = PFQuery(className: "Tip")
            query.whereKey("fromUserId", equalTo: userId)
            query.whereKey("soundId", equalTo: soundId)
            query.cachePolicy = .networkElseCache
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                 if object != nil {
                    self.player.currentSound?.currentUserDidLikeSong = true
                 } else {
                    self.player.currentSound?.currentUserDidLikeSong = false
                }
                self.updateLikeButton()
                if shouldPlay {
                    self.player.play()
                }
                self.player.fetchAudioFromNextSound()
            }
        }
    }
    
    func updateLikeButton() {
        var shouldEnableLikeSoundButton = false
        var uiImageName = "sendTip"
        if let currentUserTipDate = self.player.currentSound?.currentUserDidLikeSong {
            if currentUserTipDate {
                uiImageName = "sendTipColored"
            } else {
                shouldEnableLikeSoundButton = true
            }
        }
        
        //make sure this code is run on the main thread
        DispatchQueue.main.async {
            self.likeSoundButton.isEnabled = shouldEnableLikeSoundButton
            self.likeSoundButton.setImage(UIImage(named: uiImageName), for: .normal)
        }
    }
}

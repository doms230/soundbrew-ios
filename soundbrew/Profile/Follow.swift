//
//  Follow.swift
//  soundbrew
//
//  Created by Dominic  Smith on 3/14/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import Foundation
import Parse

class Follow {
    let uiElement = UIElement()
    let color = Color()
    
    var fromArtist: Artist!
    var toArtist: Artist!
    
    init(fromArtist: Artist!, toArtist: Artist!) {
        self.fromArtist = fromArtist
        self.toArtist = toArtist
    }
    
    func updateFollowStatus(_ shouldFollowArtist: Bool) {
        let query = PFQuery(className: "Follow")
        query.whereKey("fromUserId", equalTo: fromArtist.objectId!)
        query.whereKey("toUserId", equalTo: toArtist.objectId!)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if error != nil {
                if shouldFollowArtist {
                    self.newFollowRow()
                }
                
            } else if let object = object {
                var shouldRemove = true
                if shouldFollowArtist {
                    shouldRemove = false
                }
                object["isRemoved"] = shouldRemove
                object.saveEventually {
                    (success: Bool, error: Error?) in
                    if success && error == nil {
                        self.updateFollowerCount(artist: self.toArtist, incrementFollows: shouldFollowArtist)
                        if shouldFollowArtist {
                            self.newMention(self.toArtist.objectId!)
                        }
                    }
                }
            }
        }
    }
    
    func newFollowRow() {
        let newFollow = PFObject(className: "Follow")
        newFollow["fromUserId"] = fromArtist.objectId!
        newFollow["toUserId"] = toArtist.objectId!
        newFollow["isRemoved"] = false
        newFollow.saveEventually {
            (success: Bool, error: Error?) in
            if success && error == nil {
                self.updateFollowerCount(artist: self.toArtist, incrementFollows: true)
                self.newMention(self.toArtist.objectId!)
            }
        }
    }
    
    func updateFollowerCount(artist: Artist, incrementFollows: Bool) {
        self.updateLocalFriendsList(incrementFollows, userId: artist.objectId!)
        
        let query = PFQuery(className: "Stats")
        query.whereKey("userId", equalTo: artist.objectId!)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if error != nil {
                self.newStatsRow(1, following: 0, userId: artist.objectId)
            } else if let object = object {
                if incrementFollows {
                    object.incrementKey("followers")
                } else {
                    object.incrementKey("followers", byAmount: -1)
                }
                
                object.saveEventually()
            }
        }
        
        if let currentUserID = PFUser.current()?.objectId {
            let query = PFQuery(className: "Stats")
            query.whereKey("userId", equalTo: currentUserID)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if error != nil {
                    self.newStatsRow(0, following: 1, userId: currentUserID)
                    
                } else if let object = object {
                    if incrementFollows {
                        object.incrementKey("following")
                    } else {
                        object.incrementKey("following", byAmount: -1)
                    }
                    
                    object.saveEventually()
                }
            }
        }
    }
    
    func updateLocalFriendsList(_ shouldAddArtist: Bool, userId: String) {
        var friendsList = [String]()
        if let friends = self.uiElement.getUserDefault("friends") as? [String] {
            friendsList = friends
        }
        
        if shouldAddArtist {
            friendsList.append(userId)
            self.uiElement.setUserDefault(friendsList, key: "friends")
        } else {
            for i in 0..<friendsList.count {
                let friend = friendsList[i]
                if friend == userId {
                    friendsList.remove(at: i)
                    self.uiElement.setUserDefault(friendsList, key: "friends")
                    break
                }
            }
        }
    }
    
    func newMention(_ toUserId: String) {
        let newMention = PFObject(className: "Mention")
        newMention["type"] = "follow"
        newMention["fromUserId"] = self.fromArtist.objectId!
        newMention["toUserId"] = toUserId
        newMention["message"] = "@\(Customer.shared.artist?.username ?? "") followed you."
        newMention.saveEventually {
            (success: Bool, error: Error?) in
            if success && error == nil {
                self.uiElement.sendAlert("followed you!", toUserId: self.toArtist.objectId!, shouldIncludeName: true)
            }
        }
    }
    
    func newStatsRow(_ followers: Int, following: Int, userId: String) {
        let newFollow = PFObject(className: "Stats")
        newFollow["followers"] = followers
        newFollow["following"] = following
        newFollow["userId"] = userId
        newFollow.saveEventually()
    }
}

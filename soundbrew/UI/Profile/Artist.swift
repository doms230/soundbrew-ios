//
//  Artist.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 11/12/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//
//email is optional, because won't be able to retreive from database unless it's current usr's email

import Foundation
import Parse

class Artist {
    var objectId: String!
    var name: String?
    var username: String?
    var city: String?
    var image: String?
    var website: String?
    var isVerified: Bool?
    var bio: String?
    var email: String?
    var instagramUsername: String?
    var twitterUsername: String?
    var snapchatUsername: String?
    var isFollowedByCurrentUser: Bool?
    var followerCount: Int?
    
    init(objectId: String!, name: String?, city: String?, image: String?, isVerified: Bool?, username: String?, website: String?, bio: String?, email: String?, instagramUsername: String?, twitterUsername: String?, snapchatUsername: String?, isFollowedByCurrentUser: Bool?, followerCount: Int?) {
        self.objectId = objectId
        self.name = name
        self.username = username
        self.city = city
        self.website = website
        self.image = image
        self.isVerified = isVerified
        self.bio = bio
        self.email = email
        self.instagramUsername = instagramUsername
        self.twitterUsername = twitterUsername
        self.snapchatUsername = snapchatUsername
        self.isFollowedByCurrentUser = isFollowedByCurrentUser
        self.followerCount = followerCount
    }
    
    func cell(_ tableView: UITableView, reuse: String) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuse) as! ProfileTableViewCell
        
        cell.selectionStyle = .gray
        
        if let artistImage = self.image {
            cell.profileImage.kf.setImage(with: URL(string: artistImage))
            
        } else {
            cell.profileImage.image = UIImage(named: "profile_icon")
        }
        
        if let name = self.name {
            cell.displayName.text = name
            
        } else {
            cell.displayName.text = ""
        }
        
        if let username = self.username {
            //email was set as username in prior version of Soundbrew and email is private.
            if username.contains("@") {
                cell.username.text = ""
                
            } else {
                cell.username.text = username
            }
        }
        
        return cell
    }
}

protocol ArtistDelegate {
    func changeBio(_ value: String?)
    
    func newArtistInfo(_ value: Artist?)
}

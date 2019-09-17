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
    var isFollowedByCurrentUser: Bool?
    var followerCount: Int?
    var followingCount: Int?
    var earnings: Int?
    var customerId: String?
    var balance: Int?
    
    init(objectId: String!, name: String?, city: String?, image: String?, isVerified: Bool?, username: String?, website: String?, bio: String?, email: String?, isFollowedByCurrentUser: Bool?, followerCount: Int?, followingCount: Int?, customerId: String?, balance: Int?, earnings: Int?) {
        self.objectId = objectId
        self.name = name
        self.username = username
        self.city = city
        self.website = website
        self.image = image
        self.isVerified = isVerified
        self.bio = bio
        self.email = email
        self.isFollowedByCurrentUser = isFollowedByCurrentUser
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.customerId = customerId
        self.balance = balance
        self.earnings = earnings
    }
    
    func loadUserInfoFromCloud(_ userId: String, target: UIViewController, cell: ProfileTableViewCell?) {
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                let username = user["username"] as? String
                if !username!.contains("@") {
                    self.username = username
                }
                
                if let currentUser = PFUser.current() {
                    if currentUser.objectId! == user.objectId! {
                        self.email = user["email"] as? String
                    }
                }
                
                if let name = user["artistName"] as? String {
                    self.name = name
                    if let cell = cell {
                        cell.displayNameLabel.text = name
                    }
                }
                
                if let city = user["city"] as? String {
                    self.city = city
                    if let cell = cell {
                        cell.city.text = city
                    }
                }
                
                if let userImageFile = user["userImage"] as? PFFileObject {
                    self.image = userImageFile.url!
                    if let cell = cell {
                        cell.profileImage.kf.setImage(with: URL(string: userImageFile.url!))
                    }
                }
                
                if let bio = user["bio"] as? String {
                    self.bio = bio
                }
                
                if let website = user["website"] as? String {
                    self.website = website
                }
            }
        }
    }
    
    func cell(_ tableView: UITableView, reuse: String) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuse) as! ProfileTableViewCell
        
        cell.selectionStyle = .gray
        cell.backgroundColor = Color().black()
        if let artistImage = self.image {
            cell.profileImage.kf.setImage(with: URL(string: artistImage))
            
        } else {
            cell.profileImage.image = UIImage(named: "profile_icon")
        }
        
        if let name = self.username {
            //email was set as username in prior version of Soundbrew and email is private.
            if name.contains("@") {
                cell.username.text = ""
                
            } else {
                cell.username.text = name
            }
            
        } else {
            cell.username.text = ""
        }
        
        if let name = self.name {
            cell.displayNameLabel.text = name
        }
        
        return cell
    }
}

protocol ArtistDelegate {
    func changeBio(_ value: String?)
    
    func newArtistInfo(_ value: Artist?)
}

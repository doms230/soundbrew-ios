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
import Kingfisher
import SwiftyJSON
import Alamofire

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
    var fanCount: Int?
    var earnings: Int?
    var customerId: String?
    var balance: Int?
    var friendObjectIds: [String]?
    var account: Account?
    
    init(objectId: String!, name: String?, city: String?, image: String?, isVerified: Bool?, username: String?, website: String?, bio: String?, email: String?, isFollowedByCurrentUser: Bool?, followerCount: Int?, followingCount: Int?, fanCount: Int?, customerId: String?, balance: Int?, earnings: Int?, friendObjectIds: [String]?, account: Account?) {
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
        self.fanCount = fanCount
        self.customerId = customerId
        self.balance = balance
        self.earnings = earnings
        self.friendObjectIds = friendObjectIds
        self.account = account
    }
    
    func loadUserInfoFromCloud(_ profileCell: ProfileTableViewCell?, soundCell: SoundListTableViewCell?, commentCell: PlayerTableViewCell?, artistUsernameLabel: UILabel?, artistImageButton: UIImageView?) {
        let query = PFQuery(className: "_User")
       query.cachePolicy = .networkElseCache
        query.getObjectInBackground(withId: self.objectId) {
            (user: PFObject?, error: Error?) -> Void in
            if let _ = error {
              
            } else if let user = user {
                let username = user["username"] as? String
                if !username!.contains("@") {
                    self.username = username
                } else {
                    self.username = "username"
                }
                
                if let currentUser = PFUser.current() {
                    if currentUser.objectId! == user.objectId! {
                        self.email = user["email"] as? String
                    }
                }
                
                if let name = user["artistName"] as? String {
                    self.name = name
                }
                
                if let city = user["city"] as? String {
                    self.city = city
                }
                
                if let userImageFile = user["userImage"] as? PFFileObject {
                    self.image = userImageFile.url!
                }
                
                if let bio = user["bio"] as? String {
                    self.bio = bio
                }
                
                if let website = user["website"] as? String {
                    self.website = website
                }
                
                var account: Account?
                
                if let accountId = user["accountId"] as? String, !accountId.isEmpty {
                    account = Account(accountId, productId: nil)
                }
                
                if let productId = user["productId"] as? String, !productId.isEmpty {
                    account?.productId = productId
                }
                
                self.account = account
                
                if let cell = profileCell {
                    if let name = self.name {
                        cell.displayNameLabel.text = name
                    }
                    
                    if let username = self.username {
                        cell.username.text = "@\(username)"
                    }

                    if let image = self.image {
                        cell.profileImage.kf.setImage(with: URL(string: image))
                    } else {
                        cell.profileImage.image = UIImage(named: "profile_icon")
                    }
                    
                } else if let cell = soundCell {
                    cell.artistLabel.text = self.name
                    
                    if let image = self.image {
                        cell.artistImage.kf.setImage(with: URL(string: image), placeholder: UIImage(named: "profile_icon"))
                    } else {
                        cell.artistImage.image = UIImage(named: "profile_icon")
                    }
                    
                } else if let cell = commentCell {
                    if let image = self.image {
                        cell.userImage.kf.setImage(with: URL(string: image), for: .normal)
                    } else {
                        cell.userImage.setImage(UIImage(named: "profile_icon"), for: .normal)
                    }
                    
                    if let username = self.username {
                        cell.username.setTitle(username, for: .normal)
                    }
                    
                } else if let label = artistUsernameLabel, let image = artistImageButton {
                    if let username = self.username {
                        label.text = username
                    } else if let name = self.name {
                        label.text = name
                    } else {
                        label.text = "username"
                    }
                    
                    if let artistImage = self.image {
                        image.kf.setImage(with: URL(string: artistImage), placeholder: UIImage(named: "profile_icon"))
                    } else {
                        image.image = UIImage(named: "profile_icon")

                    }
                    
                } else {
                    let player = Player.sharedInstance
                    if let currentSoundArtistObjectId = player.currentSound?.artist?.objectId {
                        if currentSoundArtistObjectId == self.objectId {
                            player.sendSoundUpdateToUI()
                        }
                    }
                }
            }
        }
    }
    
    func cell(_ tableView: UITableView, reuse: String) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuse) as! ProfileTableViewCell
        
        cell.selectionStyle = .gray
        cell.backgroundColor = Color().black()
        if let image = self.image {
            cell.profileImage.kf.setImage(with: URL(string: image), placeholder: UIImage(named: "profile_icon"))
            
        } else {
            cell.profileImage.image = UIImage(named: "profile_icon")
        }
        
        if let username = self.username {
            cell.username.text = username 
            
        } else {
            cell.username.text = "username n/a"
        }
        
        if let name = self.name {
            cell.displayNameLabel.text = name
        }
        
        return cell
    }
    
    func getAccountPrice(_ priceId: String, priceInput: UILabel) {
        let baseURL = URL(string: "https://www.soundbrew.app/accounts/")
        let url = baseURL!.appendingPathComponent("retrievePrice")
        let parameters: Parameters = [
            "priceId": priceId]
        
        AF.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString))
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    let json = JSON(json)
                    if let amount = json["unit_amount"].int, let _ = json["currency"].string {
                        let amountAsString = UIElement().convertCentsToDollarsAndReturnString(amount)
                        priceInput.text = amountAsString
                    }
                case .failure(let error):
                    print("Get Account PRice- Artist.swift \(error)")
                }
        }
    }
}

protocol ArtistDelegate {
    func changeBio(_ value: String?)
    
    func receivedArtist(_ value: Artist?)
}

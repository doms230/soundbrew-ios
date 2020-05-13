//
//  Customer.swift
//  soundbrew
//
//  Created by Dominic  Smith on 7/3/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import Foundation
import Stripe
import Alamofire
import SnapKit
import UIKit
import Parse
import SwiftyJSON

class Customer: NSObject, STPCustomerEphemeralKeyProvider {
    static let shared = Customer()

    let baseURL = URL(string: "https://www.soundbrew.app/customers/")
    var artist: Artist?
    let uiElement = UIElement()
    var hasUsedReferralCode = false
    var referralCode: String?
    //let baseURL = URL(string: "http://192.168.1.68:3000/customers/")
    
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let url = self.baseURL!.appendingPathComponent("ephemeral_keys")
        AF.request(url, method: .post, parameters: [
            "api_version": apiVersion,
            "customerId": self.artist!.customerId!
            ], encoding: URLEncoding(destination: .queryString))
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    completion(json as? [String: AnyObject], nil)
                    print(json)
                case .failure(let error):
                    completion(nil, error)
                    print(error)
                }
        }
    }
    
    func update() {
        let url = self.baseURL!.appendingPathComponent("update")
        let parameters: Parameters = [
            "email": "\(self.artist!.email!)",
            "name": "\(self.artist!.username!)",
            "customerId": self.artist!.customerId!]
        
        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString))
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    let json = JSON(json)
                    print(json)
                case .failure(let error):
                    print(error)
                }
        }
    }
    
    //reason for urlEncoding:https://stackoverflow.com/questions/43282281/how-to-add-alamofire-url-parameters
    func create(_ objectId: String, email: String, name: String) {
        let url = self.baseURL!.appendingPathComponent("create")
    
        let parameters: Parameters = [
            "objectId": "\(objectId)",
            "email": "\(email)",
            "name": "\(name)" ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString))
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    let json = JSON(json)
                    if let customerId = json["id"].string {
                        self.saveCustomer(objectId, customerId: customerId)
                        self.artist?.customerId = customerId
                        self.artist?.balance = 0
                    }
                case .failure(let error):
                    print(error)
                }
        }
    }
    
    func saveCustomer(_ objectId: String, customerId: String) {
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
             if let object = object {
                object["customerId"] = customerId
                object.saveEventually()
            }
        }
    }
    
    func getCustomer(_ objectId: String) {
        let query = PFQuery(className: "_User")
        query.cachePolicy = .networkElseCache
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
             if let user = object {
                let email = user["email"] as! String
                let username = user["username"] as! String
                
                let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: username, website: nil, bio: nil, email: email, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: 0, earnings: nil, friendObjectIds: nil)
                
                if let customerId = user["customerId"] as? String {
                    if customerId.isEmpty {
                        self.create(user.objectId!, email: email, name: username)
                    } else {
                        artist.customerId = customerId
                    }
                    
                } else {
                    self.create(user.objectId!, email: email, name: username)
                }
                
                artist.name = user["artistName"] as? String
                artist.city = user["city"] as? String
                artist.image = (user["userImage"] as? PFFileObject)?.url
                artist.bio = user["bio"] as? String
                artist.isVerified = user["artistVerification"] as? Bool
                artist.website = user["website"] as? String
                if let balance = user["balance"] as? Int {
                    artist.balance = balance
                }
                self.artist = artist
                if let userId = user.objectId {
                    self.getFriends(userId)
                }
            }
        }
    }
    
    func getFriends(_ userId: String) {
        if let friendObjectIds = self.uiElement.getUserDefault("friends") as? [String], friendObjectIds.count != 0 {
            self.artist?.friendObjectIds = friendObjectIds
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "friendsLoaded"), object: nil)
        } else {
            let query = PFQuery(className: "Follow")
            query.whereKey("fromUserId", equalTo: userId)
            query.whereKey("isRemoved", equalTo: false)
            query.addDescendingOrder("createdAt")
            query.limit = 100
            query.cachePolicy = .networkElseCache
            query.findObjectsInBackground {
                (objects: [PFObject]?, error: Error?) -> Void in
                if let objects = objects {
                    var friendObjectIds = [String]()
                    for object in objects {
                        if let userId = object["toUserId"] as? String {
                            friendObjectIds.append(userId)
                        }
                    }
                    self.artist?.friendObjectIds = friendObjectIds
                    self.uiElement.setUserDefault(friendObjectIds, key: "friends")
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "friendsLoaded"), object: nil)
                }
            }
        }
    }
    
    func updateBalance(_ addSubFunds: Int) {
        let newBalance = addSubFunds + self.artist!.balance!
        self.artist?.balance = newBalance
        
        if let artistObjectId = self.artist?.objectId {
            let query = PFQuery(className: "_User")
                query.getObjectInBackground(withId: artistObjectId) {
                (object: PFObject?, error: Error?) -> Void in
                    if let object = object {
                        object["balance"] = newBalance
                        object.saveEventually()
                    }
                }
        }
    }
    
    func newArtistPaymentRow(_ artistObjectId: String, tipAmount: Int) {
        let newPaymentRow = PFObject(className: "Payment")
        newPaymentRow["userId"] = artistObjectId
        newPaymentRow["tipsSinceLastPayout"] = tipAmount
        newPaymentRow["tips"] = tipAmount
        newPaymentRow.saveEventually()
    }
}

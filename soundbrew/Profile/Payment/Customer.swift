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
    //let uiElement =
    //let baseURL = URL(string: "http://192.168.1.68:3000/customers/")
    
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let url = self.baseURL!.appendingPathComponent("ephemeral_keys")
        Alamofire.request(url, method: .post, parameters: [
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
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString))
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
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString))
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
            if let error = error {
                print(error)
                
            } else if let object = object {
                object["customerId"] = customerId
                object.saveEventually()
            }
        }
    }
    
    func getCustomer(_ objectId: String) {
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = object {
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
                
                //var currentBalance = 0
                /*if let balance = user["balance"] as? Int {
                    currentBalance = balance
                }
                artist.balance = currentBalance*/
                
                if let name = user["artistName"] as? String {
                    artist.name = name
                }
                
                if let username = user["username"] as? String {
                    artist.username = username
                }
                
                if let city = user["city"] as? String {
                    artist.city = city
                }
                
                if let userImageFile = user["userImage"] as? PFFileObject {
                    artist.image = userImageFile.url!
                }
                
                if let bio = user["bio"] as? String {
                    artist.bio = bio
                }
                
                if let artistVerification = user["artistVerification"] as? Bool {
                    artist.isVerified = artistVerification
                }
                
                if let website = user["website"] as? String {
                    artist.website = website
                }
                
                self.artist = artist
                if let userId = user.objectId {
                    self.getFriends(userId)
                    self.getBalance(userId)
                }
            }
        }
    }
    
    func getFriends(_ userId: String) {
        if let friendObjectIds = self.uiElement.getUserDefault("friends") as? [String] {
            self.artist?.friendObjectIds = friendObjectIds
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "friendsLoaded"), object: nil)
        } else {
            let query = PFQuery(className: "Follow")
            query.whereKey("fromUserId", equalTo: userId)
            query.whereKey("isRemoved", equalTo: false)
            query.addDescendingOrder("createdAt")
            query.limit = 100
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
                    self.uiElement.setUserDefault("friends", value: friendObjectIds)
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "friendsLoaded"), object: nil)
                }
            }
        }
    }
    
    func getBalance(_ userId: String) {
        let query = PFQuery(className: "Payment")
        query.whereKey("userId", equalTo: userId)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if let balance = object?["tipsSinceLastPayout"] as? Int {
                self.artist?.balance = balance
            } else {
                self.newArtistPaymentRow(userId, tipAmount: 0)
            }
        }
    }
    
    func updateBalance(_ addSubFunds: Int) {
        let newBalance = addSubFunds + self.artist!.balance!
        self.artist?.balance = newBalance
        
        if let artistObjectId = self.artist?.objectId {
            let query = PFQuery(className: "Payment")
            query.whereKey("userId", equalTo: artistObjectId)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if error != nil {
                    self.newArtistPaymentRow(artistObjectId, tipAmount: newBalance)
                    
                } else if let object = object {
                    object["tipsSinceLastPayout"] = newBalance
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

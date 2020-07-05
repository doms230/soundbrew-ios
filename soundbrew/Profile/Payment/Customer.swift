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
import UIKit
import Parse
import SwiftyJSON

class Customer: NSObject, STPCustomerEphemeralKeyProvider {
    static let shared = Customer()

    let baseURL = URL(string: "https://www.soundbrew.app/customers/")
    //let baseURL = URL(string: "http://192.168.200.8:3000/customers/")
    var artist: Artist?
    let uiElement = UIElement()
    var hasUsedReferralCode = false
    var referralCode: String?
    var currencySymbol: String!
    var currencyCode: String!
    var fanClubs = [String]()
    
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        if let customerId = self.artist?.customerId {
            let url = self.baseURL!.appendingPathComponent("ephemeral_keys")
            AF.request(url, method: .post, parameters: [
                "api_version": apiVersion,
                "customerId": customerId
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
    }
    
    func update() {
        if let email = self.artist?.email, let username = self.artist?.username, let customerId = self.artist?.customerId {
            let url = self.baseURL!.appendingPathComponent("update")
            let parameters: Parameters = [
                "email": "\(email)",
                "name": "\(username)",
                "customerId": customerId]
            
            AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString))
                .validate(statusCode: 200..<300)
                .responseJSON { responseJSON in
                    switch responseJSON.result {
                    case .success(_):
                        break
                    case .failure(let error):
                        print(error)
                    }
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
    
    func getCurrentUserInfo(_ objectId: String) {
        let locale = Locale.current
        if let currencySymbol = locale.currencySymbol, let currencyCode = locale.currencyCode {
            self.currencySymbol = currencySymbol
            self.currencyCode = currencyCode.lowercased()
        } else {
            self.currencySymbol = "$"
            self.currencyCode = "usd"
        }
        
        let query = PFQuery(className: "_User")
        query.cachePolicy = .networkElseCache
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
             if let user = object {
                let artist = self.uiElement.newArtistObject(user)
                if let objectId = artist.objectId, let email = artist.email, let username = artist.username {
                    if let customerId = artist.customerId {
                        if customerId.isEmpty {
                            self.create(user.objectId!, email: email, name: username)
                        } else {
                            artist.customerId = customerId
                            self.getSubscriptions(customerId)
                        }
                        
                    } else {
                        self.create(objectId, email: email, name: username)
                    }
                }
                
                if artist.account != nil {
                    artist.account?.loadEarnings()
                    artist.account?.retreiveAccount()
                }
                
                self.artist = artist
                if let userId = artist.objectId {
                    self.getFriends(userId)
                }
            }
        }
    }
    
    func getSubscriptions(_ customerId: String) {
            let url = self.baseURL!.appendingPathComponent("retrieveSubscriptions")
            let parameters: Parameters = [
                "customer": customerId]
            AF.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString))
                .validate(statusCode: 200..<300)
                .responseJSON { responseJSON in
                    switch responseJSON.result {
                    case .success(let json):
                        let json = JSON(json)
                        if let subs = json["data"].array {
                            for sub in subs {
                                if let product = sub["plan"]["product"].string {
                                    self.fanClubs.append(product)
                                }
                            }
                        }
                    case .failure(let error):
                        print(error)
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
                if let error = error {
                    print("get friends - Customer.swift: \(error)")
                }
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
}

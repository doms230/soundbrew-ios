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

    var customerId: String?
    
    //let baseURL = URL(string: "https://www.soundbrew.app/customers/")
    let baseURL = URL(string: "http://192.168.1.68:3000/customers/")
    
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let url = self.baseURL!.appendingPathComponent("ephemeral_keys")
        Alamofire.request(url, method: .post, parameters: [
            "api_version": apiVersion,
            "customerId": customerId!
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
                        self.customerId = customerId
                        self.saveCustomerId(objectId, customerId: customerId)
                    }
                case .failure(let error):
                    print(error)
                }
        }
    }
    
    func saveCustomerId(_ objectId: String, customerId: String) {
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
    
    func getCustomerId(_ objectId: String) {
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                let email = object["email"] as! String
                let username = object["username"] as! String
                if let customerId = object["customerId"] as? String {
                    if customerId.isEmpty {
                        self.create(object.objectId!, email: email, name: username)
                    } else {
                        self.customerId = customerId
                    }
                    
                } else {
                    self.create(object.objectId!, email: email, name: username)
                }
            }
        }
    }

}

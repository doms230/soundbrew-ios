//
//  Account.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/27/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import Parse

class Account {
    let baseURL = URL(string: "https://www.soundbrew.app/accounts/")
    var id: String?
    var priceId: String?
    var country: String!
    var currency: String!
    var requiresAttentionItems: Int?
    var bankAccountId: String?
    var bankTitle: String?
    var weeklyEarnings: Int!
    
    init(id: String?, priceId: String?) {
        self.id = id
        self.priceId = priceId
    }
    
    func retreiveAccount() {
        let url = self.baseURL!.appendingPathComponent("retrieve")
        let parameters: Parameters = [
            "accountId": self.id ?? "nil"]
        AF.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString))
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    let json = JSON(json)
                    if let currentlyDue = json["requirements"]["currently_due"].arrayObject as? [String], let eventuallyDue = json["requirements"]["eventually_due"].arrayObject as? [String], let pastDue = json["requirements"]["past_due"].arrayObject as? [String] {
                        if !currentlyDue.isEmpty  && !eventuallyDue.isEmpty && !pastDue.isEmpty {
                            self.requiresAttentionItems = currentlyDue.count + eventuallyDue.count + pastDue.count
                            self.shouldSubstractRequiresAttentionNumber(currentlyDue)
                            self.shouldSubstractRequiresAttentionNumber(eventuallyDue)
                            self.shouldSubstractRequiresAttentionNumber(pastDue)
                        } else {
                            self.requiresAttentionItems = 0
                        }
                    }
                    
                    if let bankName = json["external_accounts"]["data"][0]["bank_name"].string, let last4 = json["external_accounts"]["data"][0]["last4"].string {
                        self.bankTitle = "\(bankName) \(last4)"
                    }
                    
                    if let bankAccountId = json["external_accounts"]["data"][0]["id"].string {
                        self.bankAccountId = bankAccountId
                        print("current bank id: \(bankAccountId)")
                    }
                    
                    if let country = json["country"].string {
                        self.country = country
                    }
                    
                    if let currency = json["default_currency"].string {
                        self.currency = currency
                    }
                case .failure(let error):
                    print(error)
                }
        }
    }
    
    func shouldSubstractRequiresAttentionNumber(_ due: [String]) {
        //Don't want user going to Stripe Account Link if they don't have to.
        if due.contains("external_account") {
            self.requiresAttentionItems = self.requiresAttentionItems! - 1
        }
    }
    
    func loadEarnings() {
        let url = baseURL!.appendingPathComponent("retrieveBalance")
        let parameters: Parameters = [
            "account": self.id ?? "nil"]
        AF.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString))
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    let json = JSON(json)
                    if let balance = json["instant_available"][0]["amount"].int {
                        self.weeklyEarnings =  balance
                    } else {
                        self.weeklyEarnings = 0
                    }
                    
                case .failure(let error):
                    self.weeklyEarnings = 0
                    print(error)
                }
        }
    }
    
    //new account
    func createNewAccount(_ countryCode: String, email: String, tableView: UITableView?, target: UIViewController) {
        //self.startAnimating()
        let url = self.baseURL!.appendingPathComponent("create")
        let parameters: Parameters = [
            "country": countryCode,
            "email": email]
        
        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString))
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    let json = JSON(json)
                    self.id = json["id"].stringValue
                    Customer.shared.artist?.account = self
                    if let tableView = tableView {
                        DispatchQueue.main.async {
                            tableView.reloadData()
                        }
                    }
                    self.updateUserInfoWithAccountNumberOrPrice()
                case .failure(let error):
                    UIElement().showAlert("Un-Successful", message: error.errorDescription ?? "", target: target)
                }
        }
    }
    
    func updateUserInfoWithAccountNumberOrPrice() {
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: PFUser.current()!.objectId!) {
            (user: PFObject?, error: Error?) -> Void in
            if let user = user {
                if let accountId = self.id {
                    user["accountId"] = accountId
                }
                user.saveEventually()
            }
        }
    }
}

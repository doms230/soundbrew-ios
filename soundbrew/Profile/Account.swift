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
    var productId: String?
    var country: String!
    var currency: String!
    var requiresAttentionItems: Int?
    var bankAccountId: String?
    var bankTitle: String?
    var weeklyEarnings: Int!
    
    //New Account Info
    var firstName: String?
    var lastName: String?
    var personalIdNumber: String?
    var ssnLastFour: String?
    var birthDay: String?
    var birthMonth: String?
    var birthYear: String?
    var documentFront: String?
    var phoneNumber: String?
    //var documentBack: String?
    //External Account
    var bankAccountNumber: String?
    var routingNumber: String?
    //Address
    var city: String?
    var line1: String?
    var line2: String?
    var postal_code: String?
    var state: String?
    
    init(_ id: String?) {
        self.id = id
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
    func createNewAccount(_ artist: Artist, target: NewAccountViewController) {
        if let customerId = artist.customerId, let userObjectId = artist.objectId, let firstName = self.firstName, let lastName = self.lastName, let idNumber = self.personalIdNumber, let birthDay = self.birthDay, let birthMonth = self.birthMonth, let birthYear = self.birthYear, let username = artist.username, let email = artist.email, let country = self.country, let documentFront = self.documentFront, let currency = self.currency, let routingNumber = self.routingNumber, let bankAccountNumber = self.bankAccountNumber, let city = self.city, let line1 = self.line1, let line2 = self.line2, let postal_code = self.postal_code, let state = self.state, let phoneNumber = self.phoneNumber {
            let url = self.baseURL!.appendingPathComponent("create")
            let parameters: Parameters = [
                "customerId": customerId,
                "userObjectId": userObjectId,
                "username": username,
                "email": email,
                "country": country,
                "currency": currency,
                "first_name": firstName,
                "last_name": lastName,
                "phone": phoneNumber,
                "id_number": idNumber,
                "ssn_last_4": idNumber.suffix(4),
                "birthDay": birthDay,
                "birthMonth": birthMonth,
                "birthYear": birthYear,
                "documentFront": documentFront,
                "routing_number": routingNumber,
                "account_number": bankAccountNumber,
                "city": city,
                "line1": line1,
                "line2": line2,
                "postal_code": postal_code,
                "state": state]
            
            AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString))
                .responseJSON { responseJSON in
                target.uiElement.shouldAnimateActivitySpinner(false, buttonGroup: (target.topView.1, target.topView.3))
                    switch responseJSON.result {
                    case .success(let json):
                        let json = JSON(json)
                        if let statusCode = json["statusCode"].int {
                            if statusCode >= 200 && statusCode < 300 {
                                self.id = json["id"].stringValue
                                self.updateAndMoveForward(target)
                            } else if let code = json["raw"]["code"].string, let message = json["raw"]["message"].string  {
                                target.uiElement.showAlert("Error: \(code)", message: message, target: target)
                            }
                        } else {
                            self.id = json["account"].string
                            self.bankAccountId = json["bank"].string
                            self.bankTitle = json["bankTitle"].string
                            self.productId = json["product"].string
                            self.updateAndMoveForward(target)
                        }

                    case .failure(let error):
                        UIElement().showAlert("Un-Successful", message: error.errorDescription ?? "", target: target)
                    }
            }
            
        } else {
            UIElement().showAlert("Un-Successful", message: "Try Again Later. email support@soundbrew.app or message @sound_brew for more info.", target: target)
        }
    }
    
    func updateAndMoveForward(_ target: NewAccountViewController) {
        target.topView.1.isEnabled = false
        self.bankAccountNumber = nil
        self.routingNumber = nil
        Customer.shared.artist?.account = self
        updateUserInfoWithAccountNumber()
        let menuAlert = UIAlertController(title: "Your Fan Club is Live!", message: "Your fans can join your fan club from the Soundbrew website at soundbrew.app/\(Customer.shared.artist?.username ?? "yourUsername").", preferredStyle: .alert)
        menuAlert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { action in
            target.dismiss(animated: true, completion: nil)
        }))
        target.present(menuAlert, animated: true, completion: nil)
        /*target.isSettingUpNewAccount = true
        target.performSegue(withIdentifier: "showAccountWebView", sender: self)
        self.bankAccountNumber = nil
        self.routingNumber = nil
        Customer.shared.artist?.account = self
        self.updateUserInfoWithAccountNumber()*/
    }
    
    func updateUserInfoWithAccountNumber() {
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: PFUser.current()!.objectId!) {
            (user: PFObject?, error: Error?) -> Void in
            if let user = user {
                if let accountId = self.id, let productId = self.productId {
                    user["accountId"] = accountId
                    user["productId"] = productId
                }
                user.saveEventually()
            }
        }
    }
    
    func createNewFile(_ imageData: Data, spinner: UIActivityIndicatorView, target: NewAccountViewController, documentType: String) {
        spinner.startAnimating()
        spinner.isHidden = false
        let fileName = "\(NSUUID().uuidString).jpeg"
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(imageData, withName: "file", fileName: fileName, mimeType: "image/jpeg")
            multipartFormData.append(("identity_document").data(using: .utf8)!, withName: "purpose")
            }, to: "https://files.stripe.com/v1/files", method: .post, headers: ["Authorization": "Bearer pk_test_0wWjINHvhtgzckFeNxkN7jA400SRMuoO6r"]).responseJSON { responseJSON in
                    spinner.isHidden = true
                spinner.stopAnimating()
                    switch responseJSON.result {
                    case .success(let json):
                        print(json)
                        let json = JSON(json)
                        if let statusCode = json["statusCode"].int {
                            if statusCode >= 200 && statusCode < 300 {
                                self.addFile(json, documentType: documentType)
                            } else if let code = json["raw"]["code"].string, let message = json["raw"]["message"].string  {
                                target.uiElement.showAlert("Error: \(code)", message: message, target: target)
                            }
                        } else {
                            self.addFile(json, documentType: documentType)
                        }

                    case .failure(let error):
                        UIElement().showAlert("Un-Successful", message: error.errorDescription ?? "", target: target)
                    }
            }
    }
    
    func addFile(_ json: JSON, documentType: String) {
        if documentType == "front" {
            self.documentFront = json["id"].stringValue
        }
    }
    
}

protocol AccountDelegate {
    func receivedAccount(_ account: Account?)
}

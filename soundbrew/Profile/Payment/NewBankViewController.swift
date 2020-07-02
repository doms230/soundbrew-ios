//
//  NewBankViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/7/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import NotificationBannerSwift

class NewBankViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let uiElement = UIElement()
    let color = Color()
    
    let baseURL = URL(string: "https://www.soundbrew.app/accounts/")
    
    var accountText: UITextField!
    var routingText: UITextField!
    
    var account: Account?
    var artistDelegate: ArtistDelegate?
    var accountDelegate: AccountDelegate?
    var topView: (UIButton, UIButton, UIView, UIActivityIndicatorView)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        if let account = Customer.shared.artist?.account {
            self.account = account
            topView = self.uiElement.addSubViewControllerTopView(self, action: #selector(self.didPressDoneButton(_:)), doneButtonTitle: "Add", title: "New Bank")
            setUpTableView(topView.2)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func didPressDoneButton(_ sender: UIButton) {
        if sender.tag == 0 {
            self.dismiss(animated: true, completion: nil)
        } else if accountingIsValidated() && routingIsValidated() {
            self.uiElement.shouldAnimateActivitySpinner(true, buttonGroup: (topView.1, topView.3))
            
            if let country = self.account?.country, let currency = self.account?.currency, let bankRoutingNumber = self.routingText.text, let bankAccountNumber = self.accountText.text {
                if let accountId = self.account?.id {
                    createNewBank(accountId, country: country, currency: currency, routing: bankRoutingNumber, accountNumber: bankAccountNumber)
                } else {
                    self.account?.routingNumber = bankRoutingNumber
                    self.account?.bankAccountNumber = bankAccountNumber
                    self.dismiss(animated: true, completion: {() in
                        if let accountDelegate = self.accountDelegate {
                            accountDelegate.receivedAccount(self.account)
                        }
                    })
                }
            }
        }
    }
    
    //MARK: TableView
    let tableView = UITableView()
    let editProfileInfoReuse = "editProfileInfoReuse"
    func setUpTableView(_ dividerLine: UIView) {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editProfileInfoReuse)
        tableView.backgroundColor = color.black()
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(dividerLine.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileInfoReuse) as! ProfileTableViewCell
        let edgeInsets = UIEdgeInsets(top: 0, left: 85 + CGFloat(UIElement().leftOffset), bottom: 0, right: 0)
        cell.backgroundColor = .white
        cell.selectionStyle = .none
        tableView.separatorInset = edgeInsets
        
        if indexPath.row == 0 {
            cell.editProfileTitle.text = "Routing #"
            routingText = cell.editProfileInput
            routingText.becomeFirstResponder()
        } else {
            cell.editProfileTitle.text = "Account #"
            accountText = cell.editProfileInput
        }
        cell.backgroundColor = color.black()
        return cell
    }
    
    func createNewBank(_ accountId: String, country: String, currency: String, routing: String, accountNumber: String) {
        let url = self.baseURL!.appendingPathComponent("newBank")
        let parameters: Parameters = [
            "account": accountId,
            "country": country,
            "currency": currency,
            "routing_number": routing,
            "account_number": accountNumber]
        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString))
            .responseJSON { responseJSON in
                self.uiElement.shouldAnimateActivitySpinner(false, buttonGroup: (self.topView.1, self.topView.3))
                switch responseJSON.result {
                case .success(let json):
                    let json = JSON(json)
                    if let statusCode = json["statusCode"].int {
                        if statusCode >= 200 && statusCode < 300 {
                            self.updateAndDismiss(json)
                        } else if let code = json["raw"]["code"].string, let message = json["raw"]["message"].string  {
                            self.uiElement.showAlert("Error: \(code)", message: message, target: self)
                        }
                    } else {
                        self.updateAndDismiss(json)
                    }
                    
                case .failure(let error):
                    self.uiElement.showAlert("Un-Successful", message: error.errorDescription ?? "", target: self)
                }
        }
    }
    
    func updateAndDismiss(_ json: JSON) {
        if let newBankAccountId = json["external_accounts"]["data"][0]["id"].string {
            Customer.shared.artist?.account?.bankAccountId = newBankAccountId
        }
        
        if let bankName = json["external_accounts"]["data"][0]["bank_name"].string, let last4 = json["external_accounts"]["data"][0]["last4"].string {
             let newBanktitle = "\(bankName) \(last4)"
            Customer.shared.artist?.account?.bankTitle = newBanktitle
         }
        
        let newBankTitle = Customer.shared.artist?.account?.bankTitle
        let banner = StatusBarNotificationBanner(title: "\(newBankTitle ?? "Your Bank") is now your payout bank.", style: .info)
        banner.show()
        
        self.dismiss(animated: true, completion: {() in
            if let artistDelegate = self.artistDelegate {
                artistDelegate.receivedArtist(nil)
            }
        })
    }
    
    func routingIsValidated() -> Bool {
        if routingText.text!.isEmpty {
            self.uiElement.showTextFieldErrorMessage(routingText, text: "Routing # Required")
            return false
        }
       return true
    }
    
    func accountingIsValidated() -> Bool {
        if accountText.text!.isEmpty {
            self.uiElement.showTextFieldErrorMessage(accountText, text: "Account # Required")
            return false
        }
       return true
    }
}

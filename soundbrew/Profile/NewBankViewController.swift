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
import NVActivityIndicatorView

class NewBankViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable {
    let uiElement = UIElement()
    let color = Color()
    
    let baseURL = URL(string: "https://www.soundbrew.app/accounts/")
    
    var accountText: UITextField!
    var routingText: UITextField!
    
    var currentBankAccountId: String?
    var newBankAccountId: String?
    var country: String!
    var currency: String!
    
    var accountId: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        let topView = self.uiElement.addSubViewControllerTopView(self, action: #selector(self.didPressDoneButton(_:)), doneButtonTitle: "Add Bank")
        setUpTableView(topView.2)
    }
    
    @objc func didPressDoneButton(_ sender: UIButton) {
        if sender.tag == 0 {
            self.dismiss(animated: true, completion: nil)
        } else if accountingIsValidated() && routingIsValidated() {
            createNewBank()
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
        //self.view.addSubview(cancelButton)
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
    
    func createNewBank() {
        self.startAnimating()
        let url = self.baseURL!.appendingPathComponent("newBank")
        let parameters: Parameters = [
            "account": accountId!,
            "country": country!,
            "currency": currency!,
            "routing_number": self.routingText.text!,
            "account_number": self.accountText.text!]
        
        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString))
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                self.stopAnimating()
                switch responseJSON.result {
                case .success(let json):
                    let json = JSON(json)
                    if let newBankAccountId = json["external_accounts"]["data"][0]["id"].string {
                        self.newBankAccountId = newBankAccountId
                    }
                    if let currentBankAccountId = self.currentBankAccountId {
                        self.deleteBank(currentBankAccountId)
                    } else {
                        self.dismiss(animated: true, completion: nil)
                        //TODO: update Edit Profile with new bank
                    }
                case .failure(let error):
                    self.uiElement.showAlert("Un-Successful", message: error.errorDescription ?? "", target: self)
                }
        }
    }
    
    func deleteBank(_ bankId: String) {
        print("deleting old bank")
        self.startAnimating()
        let url = self.baseURL!.appendingPathComponent("deleteBank")
        let parameters: Parameters = [
            "account": accountId!,
            "bank": bankId]
        
        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString))
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                self.stopAnimating()
                self.dismiss(animated: true, completion: nil)
        }
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

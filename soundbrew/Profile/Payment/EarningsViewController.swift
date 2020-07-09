//
//  EarningsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/26/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import SnapKit
import Alamofire
import SwiftyJSON

class EarningsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ArtistDelegate {
    
    let uiElement = UIElement()
    let color = Color()
    var earnings = 0
    let artist = Customer.shared.artist
    var lastPayoutDate: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        if let accountId = self.artist?.account?.id {
            setUpTableView()
            loadPayouts(accountId)
        } else {
           self.uiElement.goBackToPreviousViewController(self)
        }
    }
    
    //MARK: Tableview
    let tableView = UITableView()
    let earningsReuse = "earningsReuse"
    let payoutReuse = "payoutReuse"
    let payoutBankReuse = "payoutBankReuse"
    let noSoundsReuse = "noSoundsReuse"
    let titleReuse = "titleReuse"
    func setUpTableView() {
        tableView.backgroundColor = color.black()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(EarningsTableViewCell.self, forCellReuseIdentifier: earningsReuse)
        tableView.register(EarningsTableViewCell.self, forCellReuseIdentifier: payoutReuse)
        tableView.register(EarningsTableViewCell.self, forCellReuseIdentifier: payoutBankReuse)
        tableView.register(EarningsTableViewCell.self, forCellReuseIdentifier: titleReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-165)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3 && payouts.count != 0 {
            return payouts.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: EarningsTableViewCell!
        if indexPath.section == 0 {
            cell = self.tableView.dequeueReusableCell(withIdentifier: earningsReuse) as? EarningsTableViewCell

            let earningsString = self.uiElement.convertCentsToDollarsAndReturnString(self.earnings)
            cell.titleLabel.text = earningsString
            let nextMonday = self.uiElement.formatDateAndReturnString(Date.today().next(.monday))
            cell.dateLabel.text = "Next Payout: \(nextMonday)"
            
            
        } else if indexPath.section == 1 {
            cell = self.tableView.dequeueReusableCell(withIdentifier: payoutBankReuse) as? EarningsTableViewCell
            cell.dateLabel.text = "Payout Bank"
            if let bankTitle = self.artist?.account?.bankTitle {
                cell.titleLabel.text = bankTitle
            } else {
                cell.titleLabel.text = "Add"
                cell.titleLabel.textColor = color.red()
            }
            
        } else if indexPath.section == 2 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: titleReuse) as! EarningsTableViewCell
            cell.backgroundColor = color.black()
            cell.selectionStyle = .none
            return cell
        } else {
            if self.payouts.count == 0 {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
                cell.backgroundColor = color.black()
                cell.selectionStyle = .none
                cell.headerTitle.text = "Your past weekly payouts will show here."
                cell.headerTitle.textColor = .darkGray
                cell.artistButton.isHidden = true
                return cell
            } else {
                cell = self.tableView.dequeueReusableCell(withIdentifier: payoutReuse) as? EarningsTableViewCell
                let payout = self.payouts[indexPath.row]
                let amountString = self.uiElement.convertCentsToDollarsAndReturnString(payout.amount!)
                cell.titleLabel.text = "\(amountString)"
                cell.subTitleLabel.text = "\(payout.bankTitle ?? "Payout Bank Unknown")"
                cell.subTitleLabel.textColor = .darkGray
                let payoutDateString = convertDateFromUnix(payout.arrivalDate!)
                cell.dateLabel.text = "Status: \(payout.status ?? "Unknown") | \(payoutDateString)"
            }
        }
        
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let modal = TransfersViewController()
            modal.lastPayoutDate = self.lastPayoutDate
            self.present(modal, animated: true, completion: nil)
        } else if indexPath.section == 1 {
            showBankAlert()
        }
    }
    
    func convertDateFromUnix(_ unixDate: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unixDate))
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.short //Set time style
        dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        dateFormatter.timeZone = .current
        return dateFormatter.string(from: date)
    }
    
    //MARK: Payouts
    private var payouts = [Payout]()
    
    func loadPayouts(_ accountId: String) {
        let baseURL = URL(string: "https://www.soundbrew.app/accounts/")
        let url = baseURL!.appendingPathComponent("listPayouts")
        let parameters: Parameters = ["destination": accountId]
        AF.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString))
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    let json = JSON(json)
                    if let payoutObjects = json["data"].array {
                        for i in 0..<payoutObjects.count {
                            let payoutObject = payoutObjects[i]
                            
                            let payout = Payout(payoutObject["arrival_date"].int, amount: payoutObject["amount"].int, status: payoutObject["status"].string, bankTitle: nil)
                            
                            var isLastIndex = false
                            if !payoutObjects.indices.contains(i + 1) {
                                isLastIndex = true
                            }
                            
                            self.getBank(accountId, bankId: payoutObject["destination"].stringValue, payout: payout, isLastIndex: isLastIndex)
                        }
                    }
                case .failure(let error):
                    print(error)
                }
        }
    }
    
    private func getBank(_ accountId: String, bankId: String, payout: Payout, isLastIndex: Bool) {
        let baseURL = URL(string: "https://www.soundbrew.app/accounts/")
        let url = baseURL!.appendingPathComponent("retrieveBank")
        let parameters: Parameters = ["accountId": accountId, "bankId": bankId]
        AF.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString))
            .responseJSON { responseJSON in
            switch responseJSON.result {
                case .success(let json):
                    let json = JSON(json)
                    if let bankName = json["bank_name"].string, let last4 = json["last4"].string {
                        payout.bankTitle = "\(bankName) \(last4)"
                    } else {
                        payout.bankTitle = "Payout Bank Unknown"
                    }
                    self.payouts.append(payout)
                case .failure(let error):
                    print(error)
            }
            if isLastIndex {
                self.tableView.reloadData()
            }
        }
    }
    
     func showBankAlert() {
        if let banktitle = self.artist?.account?.bankTitle, self.artist?.account?.bankAccountId != nil {
             let alertController = UIAlertController (title: "Replace Payout Bank?", message: "\(banktitle)", preferredStyle: .actionSheet)
             
             let getStartedAction = UIAlertAction(title: "Yes", style: .default) { (_) -> Void in
                 self.showAddBankView()
             }
             alertController.addAction(getStartedAction)
             
             let cancelAction = UIAlertAction(title: "No", style: .cancel) { (_) -> Void in
             }
             alertController.addAction(cancelAction)
             
             present(alertController, animated: true, completion: nil)
         } else {
             self.showAddBankView()
         }
     }
     
     func showAddBankView() {
        let modal = NewBankViewController()
        modal.artistDelegate = self
        self.present(modal, animated: true, completion: nil)
     }
    
    func receivedArtist(_ value: Artist?) {
        //new artist bank details are attached to Customer.shared so only need to reload tableview
        self.tableView.reloadData()
    }
    
    func changeBio(_ value: String?) {
    }
}

private class Payout {
    var arrivalDate: Int?
    var amount: Int?
    var status: String?
    var bankTitle: String?
    
    init(_ arrivalDate: Int?, amount: Int?, status: String?, bankTitle: String?) {
        self.arrivalDate = arrivalDate
        self.amount = amount
        self.status = status
        self.bankTitle = bankTitle
    }
}

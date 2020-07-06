//
//  TransfersViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/28/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class TransfersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let color = Color()
    let uiElement = UIElement()
    var lastPayoutDate: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        if let accountId = Customer.shared.artist?.account?.id {
            let topView = self.uiElement.addSubViewControllerTopView(self, action: #selector(self.didPressActionButton(_:)), doneButtonTitle: "", title: "Weekly Transfers")
            setUpTableView(topView.2)
            self.loadTransfers(accountId)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func didPressActionButton(_ sender: UIButton) {
        if sender.tag == 0 {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    //MARK: TableView
    let tableView = UITableView()
    let transferReuse = "transferReuse"
    let noSoundsReuse = "noSoundsReuse"
    func setUpTableView(_ dividerLine: UIView) {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(EarningsTableViewCell.self, forCellReuseIdentifier: transferReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
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
        if transfers.count != 0 {
            return transfers.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if transfers.count == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
            cell.backgroundColor = color.black()
            cell.selectionStyle = .none
            cell.headerTitle.text = "Your weekly transfers will show here."
            cell.headerTitle.textColor = .darkGray
            cell.artistButton.isHidden = true
            return cell
        } else {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: transferReuse) as! EarningsTableViewCell
            let transfer = self.transfers[indexPath.row]
            let amountString = self.uiElement.convertCentsToDollarsAndReturnString(transfer.amount!)
            cell.titleLabel.text = "\(amountString)"
            let payoutDateString = convertDateFromUnix(transfer.createdAt!)
            /*if let description = transfer.description {
                cell.subTitleLabel.text = description
            }*/
            
            cell.dateLabel.text = "\(payoutDateString)"
            cell.selectionStyle = .none
            cell.backgroundColor = color.black()
            return cell
        }
    }
    
    func convertDateFromUnix(_ unixDate: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unixDate))
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.medium //Set time style
        dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        dateFormatter.timeZone = .current
        return dateFormatter.string(from: date)
    }

    private var transfers = [Transfer]()
    
    func loadTransfers(_ accountId: String) {
        let baseURL = URL(string: "https://www.soundbrew.app/accounts/")
        let url = baseURL!.appendingPathComponent("listTransfers")
        var parameters: [String : Any]
        let lastPayoutDate = Double(Date.today().previous(.monday).timeIntervalSince1970)
        parameters = ["account": accountId, "gte": lastPayoutDate]
        AF.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString))
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    let json = JSON(json)
                    print(json)
                    if let transfers = json["data"].array {
                        for transfer in transfers {
                            let transfer = Transfer(transfer["created"].int, amount: transfer["amount"].int, description: transfer["description"].string)
                            self.transfers.append(transfer)
                        }
                    }
                    self.tableView.reloadData()
                case .failure(let error):
                    print(error)
                }
        }
    }
    
}

private class Transfer {
    var createdAt: Int?
    var amount: Int?
    var description: String?
    
    init(_ createdAt: Int?, amount: Int?, description: String?) {
        self.createdAt = createdAt
        self.amount = amount
        self.description = description
    }
}

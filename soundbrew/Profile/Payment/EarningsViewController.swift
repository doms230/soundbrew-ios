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

class EarningsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let uiElement = UIElement()
    let color = Color()
    var earnings = 0
    let artist = Customer.shared.artist
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.artist?.account != nil {
            setUpTableView()
        } else {
           self.uiElement.goBackToPreviousViewController(self)
        }
    }
    
    //MARK: Tableview
    let tableView = UITableView()
    let earningsReuse = "earningsReuse"
    let payoutReuse = "payoutReuse"
    let payoutBankReuse = "payoutBankReuse"
    func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(EarningsTableViewCell.self, forCellReuseIdentifier: earningsReuse)
        tableView.register(EarningsTableViewCell.self, forCellReuseIdentifier: payoutReuse)
        tableView.register(EarningsTableViewCell.self, forCellReuseIdentifier: payoutBankReuse)
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
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: EarningsTableViewCell!
        if indexPath.section == 0 {
            cell = self.tableView.dequeueReusableCell(withIdentifier: earningsReuse) as? EarningsTableViewCell

            let earningsString = self.uiElement.convertCentsToDollarsAndReturnString(self.earnings, currency: "$")
            cell.titleLabel.text = earningsString
            cell.dateLabel.text = "Next Payout: Monday, June 29th"
        } else {
            cell = self.tableView.dequeueReusableCell(withIdentifier: payoutBankReuse) as? EarningsTableViewCell
            cell.dateLabel.text = "Payout Bank"
            if let bankTitle = self.artist?.account?.bankTitle {
                cell.titleLabel.text = bankTitle
            } else {
                cell.titleLabel.text = "Add"
                cell.titleLabel.textColor = color.red()
            }
        }
        
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        return cell
    }
    
    func loadPayouts() {
        
    }
    

}

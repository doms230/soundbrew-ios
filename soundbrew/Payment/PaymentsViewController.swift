//
//  PaymentsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 7/2/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse

class PaymentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let uiElement = UIElement()
    let color = Color()
    var paymentType: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPaymentView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let customer = Customer.shared
        if let balance = customer.balance {
            let balanceInDollars = Double(balance) / 100.00
            let doubleStr = String(format: "%.2f", balanceInDollars)
            paymentLabel.text = "$\(doubleStr)"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAddFunds" {
            let backItem = UIBarButtonItem()
            backItem.title = "Add Funds"
            navigationItem.backBarButtonItem = backItem
        }
    }
    
    //MARK: UI
    lazy var paymentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 40)
        label.textAlignment = .center
        label.textColor = color.black()
        return label
    }()
    
    lazy var paymentButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = color.lightGray()
        button.setTitleColor(color.black(), for: .normal)
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 20)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    lazy var paymentsSubLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = color.black()
        label.numberOfLines = 0
        return label
    }()
    
    func setupPaymentView() {
        self.view.addSubview(paymentLabel)
        paymentLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        if paymentType == "payments" {
            paymentButton.setTitle("Add Funds", for: .normal)
            paymentsSubLabel.text = "Add funds to tip artists for their music."
            
        } else {
            paymentButton.setTitle("Add Bank Account", for: .normal)
            paymentsSubLabel.text = "Earnings are deposited to your bank account on a weekly basis."
        }
        
        self.view.addSubview(paymentButton)
        paymentButton.addTarget(target, action: #selector(didPressPaymentButton(_:)), for: .touchUpInside)
        paymentButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.top.equalTo(paymentLabel.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(paymentsSubLabel)
        paymentsSubLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(paymentButton.snp.bottom)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        setUpTableView()
    }
    
    @objc func didPressPaymentButton(_ sender: UIButton) {
        if paymentType == "payments" {
            self.performSegue(withIdentifier: "showAddFunds", sender: self)
        }
    }
    
    //MARK: Tableview
    let tableView = UITableView()
    let settingsTitleReuse = "settingsTitleReuse"
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: settingsTitleReuse)
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = .white
        self.view.addSubview(tableView)
        self.tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.paymentsSubLabel.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 //TODO: return artists they tipped 
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: settingsTitleReuse) as! ProfileTableViewCell
        cell.selectionStyle = .none
        tableView.separatorStyle = .none
        
        if paymentType == "payments" {
            cell.displayNameLabel.text = "Artists You Backed"
            
        } else {
            cell.displayNameLabel.text = "Backers"
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}

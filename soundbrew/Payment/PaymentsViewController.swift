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
        if let balance = customer.artist?.balance {
            let balanceAsDollarString = uiElement.convertCentsToDollarsAndReturnString(balance, currency: "$")
            paymentLabel.text = "\(balanceAsDollarString)"
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
    lazy var paymentView: UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = 5
        image.clipsToBounds = true
        image.image = UIImage(named: "background")
        return image
    }()
    
    lazy var paymentLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 50)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    lazy var addFundsButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = color.blue()
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        return button
    }()
    
    lazy var paymentsSubLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 25)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    func setupPaymentView() {
        self.view.addSubview(paymentView)
        paymentView.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(self.view.frame.height * (1/3) - 10)
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.paymentView.addSubview(paymentLabel)
        paymentLabel.snp.makeConstraints { (make) -> Void in
            //make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.centerY.equalTo(paymentView)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.paymentView.addSubview(paymentsSubLabel)
        paymentsSubLabel.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.paymentLabel.snp.top).offset(uiElement.bottomOffset)
        }
        
        addFundsButton.setTitle("Add Funds", for: .normal)
        paymentsSubLabel.text = "Funds"
        
        self.view.addSubview(addFundsButton)
        addFundsButton.addTarget(target, action: #selector(didPressPaymentButton(_:)), for: .touchUpInside)
        addFundsButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.top.equalTo(paymentView.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        setUpTableView()
    }
    
    @objc func didPressPaymentButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showAddFunds", sender: self)
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
            make.top.equalTo(self.addFundsButton.snp.bottom)
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
        
        cell.displayNameLabel.text = "Artists You Backed"

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}

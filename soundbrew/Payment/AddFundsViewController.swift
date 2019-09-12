//
//  AddFundsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 7/2/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Stripe
import Parse
import AppCenterAnalytics

class AddFundsViewController: UIViewController, STPPaymentContextDelegate {
    
    let color = Color()
    let uiElement = UIElement()
    
    var processingFee: Int!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupPaymentContext()
        updateTotalAndProcessingFee(1)
    }
    
    //mark: payments
    var paymentContext: STPPaymentContext!
    
    func setupPaymentContext() {
        let customer = Customer.shared
        let customerContext = STPCustomerContext(keyProvider: customer)
        paymentContext = STPPaymentContext(customerContext: customerContext)
        self.paymentContext.delegate = self
        self.paymentContext.hostViewController = self
        self.paymentContext.paymentCurrency = "usd"
    }
    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        if paymentContext.selectedPaymentOption == nil {
            self.purchaseButton.isEnabled = false
            self.addCardLabel.text = "Add"
        } else {
            self.purchaseButton.isEnabled = true
            self.addCardLabel.text = "Edit"
        }
        self.purchaseButton.isEnabled = paymentContext.selectedPaymentOption != nil
        self.cardNumberLastFour.text = paymentContext.selectedPaymentOption?.label
        self.cardImage.image = paymentContext.selectedPaymentOption?.image
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPErrorBlock) {
        if let currentUser = PFUser.current() {
            let payment = Payment.shared
            let paymentAmount = paymentContext.paymentAmount
            payment.charge(currentUser.objectId!, email: currentUser.email!, name: currentUser.username!, amount: paymentAmount, currency: paymentContext.paymentCurrency, description: "", source: paymentResult.source.stripeID) { [weak self] (error) in
                
                guard let strongSelf = self else {
                    // View controller was deallocated
                    return
                }
                
                guard error == nil else {
                    // Error while requesting ride
                    completion(error)
                    return
                }
                
                completion(nil)
            }
        }
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        switch status {
        case .error:
            var errorString = ""
            if let reError = error?.localizedDescription {
                errorString = reError
            }
            self.uiElement.showAlert("Payment was Un-Successful", message: errorString, target: self)
            MSAnalytics.trackEvent("Add Funds View Controller", withProperties: ["Button" : "Funds Declined", "description": "User's payment was Un-Successful. \(errorString)"])
            
        case .success:
            let newFunds = paymentContext.paymentAmount - self.processingFee
            let customer = Customer.shared
            customer.updateBalance(newFunds)
            self.uiElement.goBackToPreviousViewController(self)
            
            MSAnalytics.trackEvent("Add Funds View Controller", withProperties: ["Button" : "Funds Added", "description": "User Successfully added funds to their account."])
        case .userCancellation:
            return // Do nothing
        default:
            return
        }
    }
    
    //
    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
        
    }
    
    //mark: UI
    
    lazy var balanceTitle: UILabel = {
        let label = UILabel()
        label.text = "Chosen Funds"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 20)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    lazy var chosenFundAmount: UIButton = {
        let button = UIButton()
        button.setTitleColor(.white, for: .normal)
        button.setTitle("$1.00", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 25)
        button.layer.cornerRadius = 3
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 0.5
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(self.didPressFundAmountButton(_:)), for: .touchUpInside)
        button.tag = 0
        return button
    }()
    
    @objc func didPressFundAmountButton(_ sender: UIButton) {
        let menuAlert = UIAlertController(title: "Funds", message: nil , preferredStyle: .actionSheet)
        menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        menuAlert.addAction(UIAlertAction(title: "$1.00", style: .default, handler: { action in
            sender.setTitle("$1.00", for: .normal)
            self.updateTotalAndProcessingFee(1)
            
        }))
        menuAlert.addAction(UIAlertAction(title: "$5.00", style: .default, handler: { action in
            sender.setTitle("$5.00", for: .normal)
            self.updateTotalAndProcessingFee(5)
            
        }))
        menuAlert.addAction(UIAlertAction(title: "$10.00", style: .default, handler: { action in
            sender.setTitle("$10.00", for: .normal)
            self.updateTotalAndProcessingFee(10)
        }))
        self.present(menuAlert, animated: true, completion: nil)
    }
    
    func changeFundAmountColors(_ selectedButton: UIButton, unSelectedButton: UIButton, unSelectedButton1: UIButton) {
        selectedButton.setTitleColor(.white, for: .normal)
        unSelectedButton.setTitleColor(.lightGray, for: .normal)
        unSelectedButton1.setTitleColor(.lightGray, for: .normal)
    }
    
    func updateTotalAndProcessingFee(_ funds: Double) {
        var processingFee: Double!
        
        processingFee = (funds * 0.029) + 0.30
        processingFee = roundTwoDecimalPlaces(processingFee)
        
        self.paymentProcessingFee.text = "$\(processingFee!)"
        let processingFeeInCents = processingFee * Double(100)
        self.processingFee = Int(processingFeeInCents)
        
        var total = funds + processingFee
        total = roundTwoDecimalPlaces(total)
        self.total.text = "$\(total)"
        
        let totalInCents = total * Double(100)
        self.paymentContext.paymentAmount = Int(totalInCents)
        
        MSAnalytics.trackEvent("Add Funds View Controller", withProperties: ["Button" : "$\(funds)", "description": "User pressed add $\(funds)"])
    }
    
    func roundTwoDecimalPlaces(_ x: Double) -> Double {
        return Double(round(100 * x)/100)
    }
    
    lazy var paymentProcessingFeeTitle: UILabel = {
        let label = UILabel()
        label.text = "Payment Processing Fee"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 20)
        label.textColor = .white 
        label.numberOfLines = 0
        return label
    }()
    lazy var paymentProcessingFee: UILabel = {
        let label = UILabel()
        label.text = "$0.33"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 25)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    lazy var totalTitle: UILabel = {
        let label = UILabel()
        label.text = "Total"
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    lazy var total: UILabel = {
        let label = UILabel()
        label.text = "$1.33"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 25)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    lazy var cardButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(self.didPressAddCardButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressAddCardButton(_ sender: UIButton) {
        self.paymentContext.presentPaymentOptionsViewController()
    }
    
    lazy var cardImage: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.backgroundColor = color.black()
        return image
    }()
    
    lazy var cardNumberLastFour: UILabel = {
        let label = UILabel()
        label.text = "4422"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 20)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    lazy var addCardLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 25)
        label.textColor = color.blue()
        label.numberOfLines = 0
        return label
    }()
    
    lazy var purchaseButton: UIButton = {
        let button = UIButton()
        button.isEnabled = false
        button.backgroundColor = color.blue()
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 30)
        button.setTitle("Purchase", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(didPressPurchaseButton(_:)), for: .touchUpInside)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    @objc func didPressPurchaseButton(_ sender: UIButton) {
        self.paymentContext.requestPayment()
    }
    
    func setupView() {
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        
        self.view.addSubview(chosenFundAmount)
        chosenFundAmount.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(100)
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(balanceTitle)
        balanceTitle.snp.makeConstraints { (make) -> Void in
            ///make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.centerY.equalTo(chosenFundAmount)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        self.view.addSubview(paymentProcessingFeeTitle)
        paymentProcessingFeeTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(chosenFundAmount.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        self.view.addSubview(paymentProcessingFee)
        paymentProcessingFee.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(paymentProcessingFeeTitle)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(totalTitle)
        totalTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(paymentProcessingFee.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        self.view.addSubview(total)
        total.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(totalTitle)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(cardButton)
        cardButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(total.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.cardButton.addSubview(cardImage)
        cardImage.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.cardButton)
            make.left.equalTo(self.cardButton)
        }
        
        self.cardButton.addSubview(cardNumberLastFour)
        cardNumberLastFour.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.cardButton)
            make.left.equalTo(self.cardImage.snp.right)
        }
        
        self.cardButton.addSubview(addCardLabel)
        addCardLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.cardButton)
            make.right.equalTo(self.cardButton)
        }
        
        self.view.addSubview(purchaseButton)
        purchaseButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.top.equalTo(cardButton.snp.bottom).offset(self.uiElement.topOffset)
            make.left.equalTo(self.view).offset(self.uiElement.leftOffset)
            make.right.equalTo(self.view).offset(self.uiElement.rightOffset)
        }
    }
}

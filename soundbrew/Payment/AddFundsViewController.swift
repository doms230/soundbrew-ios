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
import NVActivityIndicatorView

class AddFundsViewController: UIViewController, STPPaymentContextDelegate, NVActivityIndicatorViewable {
    
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
        let localizedAdd = NSLocalizedString("add", comment: "")
        let localizedEdit = NSLocalizedString("edit", comment: "")
        let localizedPurchase = NSLocalizedString("purchase", comment: "")

        if paymentContext.selectedPaymentOption == nil {
            self.purchaseButton.isEnabled = false
            self.addCardLabel.text = localizedAdd
        } else {
            self.purchaseButton.isEnabled = true
            self.addCardLabel.text = localizedEdit
        }
        self.purchaseButton.isEnabled = paymentContext.selectedPaymentOption != nil
        self.purchaseButton.setTitle(localizedPurchase, for: .normal)
        self.cardNumberLastFour.text = paymentContext.selectedPaymentOption?.label
        self.cardImage.image = paymentContext.selectedPaymentOption?.image
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPPaymentStatusBlock) {
        
            if let currentUser = PFUser.current() {
                let payment = Payment.shared
                let paymentAmount = paymentContext.paymentAmount
                payment.createPaymentIntent(currentUser.objectId!, email: currentUser.email!, name: currentUser.username!, amount: paymentAmount, currency: paymentContext.paymentCurrency, description: "") { [weak self] (result) in
                            
                    guard self != nil else {
                        // View controller was deallocated
                        return
                    }
                    
                    switch result {
                        case .success(let clientSecret):
                        // Confirm the PaymentIntent
                            let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                        paymentIntentParams.configure(with: paymentResult)
                        STPPaymentHandler.shared().confirmPayment(withParams: paymentIntentParams, authenticationContext: paymentContext) { status, paymentIntent, error in
                            switch status {
                            case .succeeded:
                                // Our example backend asynchronously fulfills the customer's order via webhook
                                // See https://stripe.com/docs/payments/payment-intents/ios#fulfillment
                                completion(.success, nil)
                            case .failed:
                                completion(.error, error)
                            case .canceled:
                                completion(.userCancellation, nil)
                            @unknown default:
                                completion(.error, nil)
                            }
                        }
                        
                        case .failure(let error):
                            // A real app should retry this request if it was a network error.
                            print("Failed to create a Payment Intent: \(error)")
                            completion(.error, error)
                            break
                    case .none:
                        break
                        
                    }
                }
        }
    }

    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        self.stopAnimating()
        switch status {
        case .error:
            var errorString = ""
            if let reError = error?.localizedDescription {
                errorString = reError
                print(errorString)
            }
            let localizedPaymentDeclined = NSLocalizedString("paymentDeclined", comment: "")
            self.uiElement.showAlert(localizedPaymentDeclined, message: "", target: self)
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
        let localizedChosenFunds = NSLocalizedString("chosenFunds", comment: "")
        let label = UILabel()
        label.text = localizedChosenFunds
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
        let localizedFunds = NSLocalizedString("funds", comment: "")
        let localizedCancel = NSLocalizedString("cancel", comment: "")
        let menuAlert = UIAlertController(title: localizedFunds, message: nil , preferredStyle: .actionSheet)
        menuAlert.addAction(UIAlertAction(title: localizedCancel, style: .cancel, handler: nil))
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
        let localizedPaymentProcessingFee = NSLocalizedString("paymentProcessingFee", comment: "")
        let label = UILabel()
        label.text = localizedPaymentProcessingFee
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
        let localizedTotal = NSLocalizedString("total", comment: "")
        let label = UILabel()
        label.text = localizedTotal
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
        let localizedLoading = NSLocalizedString("loading", comment: "")
        let button = UIButton()
        button.isEnabled = false
        //button.backgroundColor = color.blue()
        button.setBackgroundImage(UIImage(named: "background"), for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        button.setTitle(localizedLoading, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(didPressPurchaseButton(_:)), for: .touchUpInside)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    @objc func didPressPurchaseButton(_ sender: UIButton) {
        self.startAnimating()
        self.paymentContext.requestPayment()
    }
    
    func setupView() {
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
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

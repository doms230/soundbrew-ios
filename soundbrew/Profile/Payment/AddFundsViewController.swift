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
    var isOnboarding = false
    var hasUsedReferralCode = false
    var referrerUserId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupPaymentContext()
    }
    
    //mark: payments
    var paymentContext: STPPaymentContext!
    var fundsToWalletAmount = 999
    func setupPaymentContext() {
        let customer = Customer.shared
        hasUsedReferralCode = customer.hasUsedReferralCode
        let customerContext = STPCustomerContext(keyProvider: customer)
        paymentContext = STPPaymentContext(customerContext: customerContext)
        paymentContext.paymentAmount = 999
        self.paymentContext.delegate = self
        self.paymentContext.hostViewController = self
        self.paymentContext.paymentCurrency = "usd"
    }
    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        let localizedAdd = NSLocalizedString("add", comment: "")
        let localizedEdit = NSLocalizedString("edit", comment: "")

        if paymentContext.selectedPaymentOption == nil {
            self.purchaseButton.isEnabled = false
            self.addCardLabel.text = localizedAdd
        } else {
            self.purchaseButton.isEnabled = true
            self.addCardLabel.text = localizedEdit
        }
        self.purchaseButton.isEnabled = paymentContext.selectedPaymentOption != nil
        let addFundsToWalletAmountString = self.uiElement.convertCentsToDollarsAndReturnString(fundsToWalletAmount, currency: "$")
        self.purchaseButton.setTitle("Add \(addFundsToWalletAmountString) to Wallet", for: .normal)
        self.cardNumberLastFour.text = paymentContext.selectedPaymentOption?.label
        self.cardImage.image = paymentContext.selectedPaymentOption?.image
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        self.uiElement.showAlert("Connectivity Issue", message: "\(error.localizedDescription)", target: self)
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
            
        case .success:
            let customer = Customer.shared
            customer.updateBalance(self.fundsToWalletAmount)
            if self.fundsToWalletAmount == 1099 {
                customer.hasUsedReferralCode = true
                updateUserInfo()
            }
            self.leaveView()
            
        case .userCancellation:
            return
        default:
            return
        }
    }
    
    //
    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
        
    }
    
    //mark: UI
    
    //description
    lazy var addFundsDescription: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        label.textColor = .lightGray
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = "Pay credited artists an amount of your choosing when you 'like' a song."
        return label
    }()
    
    //referral
    lazy var referralCodeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 15)
        label.textColor = .lightGray
        label.numberOfLines = 0
        label.textAlignment = .left
        label.text = "   Enter a referral code, and earn $1."
        return label
    }()
    lazy var referralCodeText: UITextField = {
        let textField = UITextField()
        textField.font = UIFont(name: uiElement.mainFont, size: 17)
        textField.backgroundColor = color.purpleBlack()
        textField.borderStyle = .none
        textField.clearButtonMode = .whileEditing
        textField.keyboardType = .default
        textField.tintColor = color.purpleBlack()
        textField.textColor = .white
        textField.layer.cornerRadius = 3
        textField.clipsToBounds = true
        textField.attributedPlaceholder = NSAttributedString(string: "   Referral Code",
        attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        return textField
    }()
    
    lazy var referralCodeButton: UIButton = {
        let button = UIButton()
        button.setTitle("Add", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = color.purpleBlack()
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 15)
        button.addTarget(self, action: #selector(didPressAddReferralCodeButton), for: .touchUpInside)
        button.layer.cornerRadius = 3
       // button.layer.borderWidth = 0.5
        //button.layer.borderColor = UIColor.lightGray.cgColor
        button.clipsToBounds = true
        return button
    }()
    
    lazy var referralCodeButtonSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .white
        spinner.isHidden = true
        return spinner
    }()
    
    @objc func didPressAddReferralCodeButton(_ sender: UIButton) {
        if hasUsedReferralCode {
            sender.setTitle("x", for: .normal)
            sender.isEnabled = false
            referralCodeText.text = ""
            referralCodeText.attributedPlaceholder = NSAttributedString(string: "   You've already been referred.",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            referralCodeText.isEnabled = false
            self.resignFirstResponder()
            
        } else if !self.referralCodeText.text!.isEmpty {
            sender.setTitle("", for: .normal)
            sender.isEnabled = false
            self.referralCodeButtonSpinner.startAnimating()
            self.referralCodeButtonSpinner.isHidden = false
            let referralCodeCleanedUp = self.uiElement.cleanUpText(referralCodeText.text!, shouldLowercaseText: true)
            let query = PFQuery(className: "_User")
            query.whereKey("referralCode", equalTo: referralCodeCleanedUp)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                self.referralCodeButtonSpinner.stopAnimating()
                self.referralCodeButtonSpinner.isHidden = true
                if object != nil && error == nil {
                    var gotCodePlaceholder: String!
                    self.referrerUserId = object?.objectId
                    if let username = object?["username"] as? String {
                        gotCodePlaceholder = "   @\(username) referred you!"
                    } else {
                        gotCodePlaceholder = "   Got it!"
                    }
                    self.referralCodeText.attributedPlaceholder = NSAttributedString(string: gotCodePlaceholder,
                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
                    self.referralCodeText.text = ""
                    self.referralCodeText.isEnabled = false
                    self.referralCodeText.resignFirstResponder()
                    
                    //
                    sender.setTitle("✔︎", for: .normal)
                    sender.setTitleColor(self.color.green(), for: .normal)
                    //
                    self.fundsToWalletAmount = 1099
                    let addFundsToWalletAmountString = self.uiElement.convertCentsToDollarsAndReturnString(self.fundsToWalletAmount, currency: "$")
                    self.purchaseButton.setTitle("Add \(addFundsToWalletAmountString) to Wallet", for: .normal)
                    
                } else {
                    sender.setTitle("Add", for: .normal)
                    sender.isEnabled = true
                    self.uiElement.showTextFieldErrorMessage(self.referralCodeText, text: "   Invalid Referral Code")
                }
            }
        }
    }
    
    //Funds to add View
    lazy var fundsToAddView: UIView = {
        let view = UIView()
        view.backgroundColor = color.purpleBlack()
        view.layer.cornerRadius = 3
        view.clipsToBounds = true
        return view
    }()
    
    //check out view
    lazy var howMuchToAddDividerLine: UIView = {
        let line = UIView()
        line.layer.borderWidth = 1
        line.layer.borderColor = UIColor.white.cgColor
        return line
    }()
    
    lazy var totalAmountDividerLine: UIView = {
        let line = UIView()
        line.layer.borderWidth = 1
        line.layer.borderColor = UIColor.white.cgColor
        return line
    }()
    
    lazy var totalTitle: UILabel = {
        let localizedTotal = NSLocalizedString("total", comment: "")
        let label = UILabel()
        label.text = localizedTotal
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        label.textColor =  .white
        label.numberOfLines = 0
        return label
    }()
    lazy var total: UILabel = {
        let label = UILabel()
        label.text = "$9.99"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 25)
        label.textColor =  .white
        label.numberOfLines = 0
        return label
    }()
    
    lazy var stripeAddFundsMessage: UIButton = {
        let localizedStripeAddFundsMessage = NSLocalizedString("stripeAddFundsMessage", comment: "")
        let button = UIButton()
        button.setTitle(localizedStripeAddFundsMessage, for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)", size: 15)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: #selector(didPressStripeAddFundsMessage(_:)), for: .touchUpInside)
        return button
    }()
    
    @objc func didPressStripeAddFundsMessage(_ sender: UIButton) {
        let stripeURL = URL(string: "https://stripe.com/payments")
        if UIApplication.shared.canOpenURL(stripeURL!) {
            UIApplication.shared.open(stripeURL!, options: [:], completionHandler: nil)
            MSAnalytics.trackEvent("Add Funds View Controller", withProperties: ["Button" : "stripe", "description": "User selected stripe website"])
        }
    }
    
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
        image.backgroundColor = color.purpleBlack()
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
        //self.startAnimating()
        //self.paymentContext.requestPayment()
        let customer = Customer.shared
        customer.updateBalance(self.fundsToWalletAmount)
        if self.fundsToWalletAmount == 1099 {
            customer.hasUsedReferralCode = true
            updateUserInfo()
            if let userId = self.referrerUserId {
                self.updateReferrerBalance(userId)
            }
        }
        self.leaveView()
    }
    
    func leaveView() {
        if isOnboarding {
            self.uiElement.newRootView("Main", withIdentifier: "tabBar")
        } else {
            self.uiElement.goBackToPreviousViewController(self)
        }
    }
    
    func setupView() {
        self.title = "Add Funds"
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        if isOnboarding {
            let localizedDone = NSLocalizedString("done", comment: "")
            let doneButton = UIBarButtonItem(title: localizedDone, style: .plain, target: self, action: #selector(self.didPressDoneButton(_:)))
            self.navigationItem.rightBarButtonItem = doneButton
        }
        
        self.view.addSubview(addFundsDescription)
        addFundsDescription.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self) * 2)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        //how much would you like to add view
        self.view.addSubview(fundsToAddView)
        fundsToAddView.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(175)
            make.centerY.equalTo(self.view)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.fundsToAddView.addSubview(totalTitle)
        totalTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(fundsToAddView).offset(uiElement.topOffset)
            make.left.equalTo(fundsToAddView).offset(uiElement.leftOffset)
        }
        self.fundsToAddView.addSubview(total)
        total.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(totalTitle)
            make.right.equalTo(fundsToAddView).offset(uiElement.rightOffset)
        }
        
        self.fundsToAddView.addSubview(totalAmountDividerLine)
        totalAmountDividerLine.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(0.5)
            make.top.equalTo(total.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(fundsToAddView).offset(uiElement.leftOffset)
            make.right.equalTo(fundsToAddView).offset(uiElement.rightOffset)
        }
        
        self.fundsToAddView.addSubview(cardButton)
        cardButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.totalAmountDividerLine.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(fundsToAddView).offset(uiElement.leftOffset)
            make.right.equalTo(fundsToAddView).offset(uiElement.rightOffset)
        }
        self.cardButton.addSubview(addCardLabel)
        addCardLabel.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(cardButton)
            make.right.equalTo(self.cardButton)
        }
        self.cardButton.addSubview(cardImage)
        cardImage.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(cardButton)
            make.left.equalTo(self.cardButton)
        }
        self.cardButton.addSubview(cardNumberLastFour)
        cardNumberLastFour.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(cardButton)
            make.left.equalTo(self.cardImage.snp.right)
        }
        
        self.fundsToAddView.addSubview(purchaseButton)
        purchaseButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.top.equalTo(cardButton.snp.bottom).offset(self.uiElement.topOffset * 2)
            make.left.equalTo(fundsToAddView).offset(uiElement.leftOffset)
            make.right.equalTo(fundsToAddView).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(referralCodeButton)
        referralCodeButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(33)
            make.width.equalTo(100)
          //  make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.fundsToAddView.snp.top).offset((uiElement.bottomOffset) * 2)
        }
        
        self.view.addSubview(referralCodeButtonSpinner)
        referralCodeButtonSpinner.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(30)
            make.center.equalTo(referralCodeButton)
        }
        
        //referral code text above add funds
        self.view.addSubview(referralCodeText)
        referralCodeText.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(33)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(referralCodeButton.snp.left).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.fundsToAddView.snp.top).offset((uiElement.bottomOffset) * 2)
        }
        
        self.view.addSubview(referralCodeLabel)
        referralCodeLabel.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.referralCodeText.snp.top).offset(-(uiElement.elementOffset))
        }
        
        //stripe message at bottom
        self.view.addSubview(stripeAddFundsMessage)
        stripeAddFundsMessage.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(self.uiElement.leftOffset)
            make.right.equalTo(self.view).offset(self.uiElement.rightOffset)
            if let tabBarController = self.tabBarController {
                make.bottom.equalTo(self.view).offset(-((tabBarController.tabBar.frame.height)) + CGFloat(uiElement.bottomOffset))
            } else {
                var bottomOffsetValue: Int!
                switch UIDevice.modelName {
                case "iPhone X", "iPhone XS", "iPhone XR", "iPhone 11", "iPhone 11 Pro", "iPhone 11 Pro Max", "iPhone XS Max", "Simulator iPhone 11 Pro Max":
                    bottomOffsetValue = uiElement.bottomOffset * 5
                    break
                    
                default:
                    bottomOffsetValue = uiElement.bottomOffset * 2
                    break
                }
                make.bottom.equalTo(self.view).offset(bottomOffsetValue)
            }
        }
    }
    
    @objc func didPressDoneButton(_ sender: UIBarButtonItem) {
        leaveView()
    }
    
    func updateUserInfo() {
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: PFUser.current()!.objectId!) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                user["hasUsedReferralCode"] = true
                user.saveEventually()
            }
        }
    }
    
    //Referrer
    func updateReferrerBalance(_ userId: String) {
        let query = PFQuery(className: "Payment")
        query.whereKey("userId", equalTo: userId)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if error != nil {
                self.newArtistPaymentRow(userId)
                
            } else if let object = object {
                var currentBalance = 0
                let referrerReward = 50
                if let tipsSinceLastpayout = object["tipsSinceLastPayout"] as? Int {
                    currentBalance = tipsSinceLastpayout
                }
                object["tipsSinceLastPayout"] = currentBalance + referrerReward
                object.saveEventually()
            }
        }
    }
    
    func newArtistPaymentRow(_ userId: String) {
        let newPaymentRow = PFObject(className: "Payment")
        newPaymentRow["userId"] = userId
        newPaymentRow["tipsSinceLastPayout"] = 50
        newPaymentRow["tips"] = 50
        newPaymentRow.saveEventually()
    }
}

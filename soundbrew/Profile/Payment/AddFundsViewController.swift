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
        self.title = "Add Funds"
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

        if paymentContext.selectedPaymentOption == nil {
            self.purchaseButton.isEnabled = false
            self.addCardLabel.text = localizedAdd
        } else {
            self.purchaseButton.isEnabled = true
            self.addCardLabel.text = localizedEdit
        }
        self.purchaseButton.isEnabled = paymentContext.selectedPaymentOption != nil
        self.purchaseButton.setTitle("Add Funds to Wallet", for: .normal)
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
    //current balance view
    lazy var currentBalanceLabel: UILabel = {
        //let curentBalanceLocalized = NSLocalizedString("currentBalance", comment: "")
        let label = UILabel()
        label.text = "Current Balance"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 25)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    lazy var currentBalanceAmount: UILabel = {
        //let curentBalanceLocalized = NSLocalizedString("currentBalance", comment: "")
        var currentBalance = "0"
        if let balance = Customer.shared.artist?.balance {
            let formattedBalance = self.uiElement.convertCentsToDollarsAndReturnString(balance, currency: "$")
            currentBalance = formattedBalance
        }
        let label = UILabel()
        label.text = currentBalance
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 30)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    
    //Funds to add View
    lazy var fundsToAddView: UIView = {
        let view = UIView()
        view.backgroundColor = color.purpleBlack()
        view.layer.cornerRadius = 3
        view.clipsToBounds = true
        return view
    }()
    
    lazy var howMuchWouldYouLikeToAddLabel: UILabel = {
        let label = UILabel()
        label.text = "How much would you like to add?"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    lazy var oneDollarButton: UIButton = {
        let button = UIButton()
        button.setTitle("$1", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setBackgroundImage(UIImage(named: "background"), for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.tag = 0
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)", size: 25)
        button.addTarget(self, action: #selector(self.didPressDollarButton(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var fiveDollarButton: UIButton = {
        let button = UIButton()
        button.setTitle("$5", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.tag = 1
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)", size: 25)
        button.addTarget(self, action: #selector(self.didPressDollarButton(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var tenDollarButton: UIButton = {
        let button = UIButton()
        button.setTitle("$10", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.tag = 2
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)", size: 25)
        button.addTarget(self, action: #selector(self.didPressDollarButton(_:)), for: .touchUpInside)
        return button
    }()
    
    @objc func didPressDollarButton(_ sender: UIButton) {
        var newFundsToAdd: Double!
        switch sender.tag {
        case 0:
            newFundsToAdd = 1
            changeButtonView(fiveDollarButton)
            changeButtonView(tenDollarButton)
            break
            
        case 1:
            newFundsToAdd = 5
            changeButtonView(oneDollarButton)
            changeButtonView(tenDollarButton)
            break
            
        case 2:
            newFundsToAdd = 10
            changeButtonView(oneDollarButton)
            changeButtonView(fiveDollarButton)
            break
            
        default:
            newFundsToAdd = 1
            changeButtonView(fiveDollarButton)
            changeButtonView(tenDollarButton)
            break
        }
        
        sender.setTitleColor(.white, for: .normal)
        sender.setBackgroundImage(UIImage(named: "background"), for: .normal)
        self.updateTotalAndProcessingFee(newFundsToAdd)
    }
    
    func changeButtonView(_ button: UIButton) {
        button.setBackgroundImage(nil, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }
    
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
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor =  .white
        label.numberOfLines = 0
        return label
    }()
    lazy var paymentProcessingFee: UILabel = {
        let label = UILabel()
        label.text = "$0.33"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 25)
        label.textColor =  .white
        label.numberOfLines = 0
        return label
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
        label.text = "$1.33"
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
    
    @objc func didPressAddFundsMessage(_ sender: UIBarButtonItem) {
        let localizedStripeAddFundsMessage = NSLocalizedString("addFundsMessage", comment: "")
        let localizedStripeAddFundsTitle = NSLocalizedString("whyAddFundsTitle", comment: "")
        self.uiElement.showAlert(localizedStripeAddFundsTitle, message: localizedStripeAddFundsMessage, target: self)
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
        self.startAnimating()
        self.paymentContext.requestPayment()
    }
    
    func setupView() {
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        let questionButton = UIBarButtonItem(image: UIImage(named: "questionMark"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.didPressAddFundsMessage(_:)))
        self.navigationItem.rightBarButtonItem = questionButton
        
        //current balance view
        self.view.addSubview(currentBalanceLabel)
        currentBalanceLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.centerX.equalTo(self.view)
        }
        
        self.view.addSubview(currentBalanceAmount)
        currentBalanceAmount.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(currentBalanceLabel.snp.bottom).offset(uiElement.elementOffset)
            make.centerX.equalTo(self.view)
        }
        
        //how much would you like to add view
        self.view.addSubview(fundsToAddView)
        fundsToAddView.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(300)
            make.centerY.equalTo(self.view)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.fundsToAddView.addSubview(howMuchWouldYouLikeToAddLabel)
        howMuchWouldYouLikeToAddLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(fundsToAddView).offset(uiElement.topOffset)
            make.left.equalTo(fundsToAddView).offset(uiElement.leftOffset)
            make.right.equalTo(fundsToAddView).offset(uiElement.rightOffset)
        }
        
        self.fundsToAddView.addSubview(fiveDollarButton)
        fiveDollarButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(self.uiElement.buttonHeight)
            make.width.equalTo(75)
            make.top.equalTo(howMuchWouldYouLikeToAddLabel.snp.bottom).offset(uiElement.topOffset)
            make.centerX.equalTo(fundsToAddView)
        }
        
        self.fundsToAddView.addSubview(oneDollarButton)
        oneDollarButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(self.uiElement.buttonHeight)
            make.width.equalTo(75)
            make.top.equalTo(fiveDollarButton)
            make.left.equalTo(fundsToAddView).offset(uiElement.leftOffset)
        }
        
        self.fundsToAddView.addSubview(tenDollarButton)
        tenDollarButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(self.uiElement.buttonHeight)
            make.width.equalTo(75)
            make.top.equalTo(fiveDollarButton)
            make.right.equalTo(fundsToAddView).offset(uiElement.rightOffset)
        }
            
        self.fundsToAddView.addSubview(howMuchToAddDividerLine)
        howMuchToAddDividerLine.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(0.5)
            make.top.equalTo(tenDollarButton.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(fundsToAddView).offset(uiElement.leftOffset)
            make.right.equalTo(fundsToAddView).offset(uiElement.rightOffset)
        }
        
        self.fundsToAddView.addSubview(paymentProcessingFeeTitle)
        paymentProcessingFeeTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(howMuchToAddDividerLine.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(fundsToAddView).offset(uiElement.leftOffset)
        }
        self.fundsToAddView.addSubview(paymentProcessingFee)
        paymentProcessingFee.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(paymentProcessingFeeTitle)
            make.right.equalTo(fundsToAddView).offset(uiElement.rightOffset)
        }
        
        self.fundsToAddView.addSubview(totalTitle)
        totalTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(paymentProcessingFee.snp.bottom).offset(uiElement.topOffset)
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
            make.top.equalTo(cardButton.snp.bottom).offset(self.uiElement.topOffset)
            make.left.equalTo(fundsToAddView).offset(uiElement.leftOffset)
            make.right.equalTo(fundsToAddView).offset(uiElement.rightOffset)
        }
        
        //stripe message at bottom
        self.view.addSubview(stripeAddFundsMessage)
        stripeAddFundsMessage.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(self.uiElement.leftOffset)
            make.right.equalTo(self.view).offset(self.uiElement.rightOffset)
            make.bottom.equalTo(self.view).offset(-((self.tabBarController?.tabBar.frame.height)!) + CGFloat(uiElement.bottomOffset))
        }
    }
}
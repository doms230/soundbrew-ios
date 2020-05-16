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
    var shouldShowExitButton = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupPaymentContext()
    }
    
    //mark: payments
    var paymentContext: STPPaymentContext!
    func setupPaymentContext() {
        let customer = Customer.shared
        let customerContext = STPCustomerContext(keyProvider: customer)
        paymentContext = STPPaymentContext(customerContext: customerContext)
        paymentContext.paymentAmount = 300
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
        let addFundsToWalletAmountString = self.uiElement.convertCentsToDollarsAndReturnString(paymentContext.paymentAmount, currency: "$")
        self.purchaseButton.setTitle("Add \(addFundsToWalletAmountString) to Wallet", for: .normal)
        self.total.text = addFundsToWalletAmountString
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
            customer.updateBalance(paymentContext.paymentAmount)
           // if PFUser.current()?.objectId != self.uiElement.d_innovatorObjectId {
                SKStoreReviewController.requestReview()
            //}
            
            if shouldShowExitButton {
                self.dismiss(animated: true, completion: nil)
            } else {
               self.uiElement.goBackToPreviousViewController(self)
            }
            
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
    lazy var exitButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "dismiss"), for: .normal)
        button.addTarget(self, action: #selector(self.didPressExitButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressExitButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    lazy var addFundsTitle: UILabel = {
        let label = UILabel()
        label.text = "Add Funds"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 15)
        label.textAlignment = .center
        return label
    }()
    
    //description
    lazy var addFundsDescription: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        label.textColor = .lightGray
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = "1 'Like' = $1"
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
    
    lazy var totalButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(self.didPressChangeAddFundsAmount(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressChangeAddFundsAmount(_ sender: UIBarButtonItem) {
         let alertController = UIAlertController (title: "How much would you like to add?", message: nil, preferredStyle: .actionSheet)
        let threeDollarAction = UIAlertAction(title: "$3", style: .default) { (_) -> Void in
            self.paymentContext.paymentAmount = 300
            self.paymentContextDidChange(self.paymentContext)
            MSAnalytics.trackEvent("Add Funds View Controller", withProperties: ["Button" : "didPressChangeAddFundsAmount", "Amount": "$3.00"])
         }
         alertController.addAction(threeDollarAction)
        
        let tenDollarAction = UIAlertAction(title: "$10", style: .default) { (_) -> Void in
            self.paymentContext.paymentAmount = 1000
            self.paymentContextDidChange(self.paymentContext)
            MSAnalytics.trackEvent("Add Funds View Controller", withProperties: ["Button" : "didPressChangeAddFundsAmount", "Amount": "$10.00"])
        }
        alertController.addAction(tenDollarAction)
        
        let oneHundredDollarAction = UIAlertAction(title: "$100", style: .default) { (_) -> Void in
            self.paymentContext.paymentAmount = 10000
            self.paymentContextDidChange(self.paymentContext)
            MSAnalytics.trackEvent("Add Funds View Controller", withProperties: ["Button" : "didPressChangeAddFundsAmount", "Amount": "$100.00"])
        }
        alertController.addAction(oneHundredDollarAction)
         
         let localizedCancel = NSLocalizedString("cancel", comment: "")
         let cancelAction = UIAlertAction(title: localizedCancel, style: .cancel, handler: nil)
         alertController.addAction(cancelAction)
         
         self.present(alertController, animated: true, completion: nil)
    }
    
    lazy var total: UILabel = {
        let label = UILabel()
        label.text = "$2.99"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 25)
        label.textColor =  .white
        label.numberOfLines = 0
        return label
    }()
    
    lazy var changeTotalAmountImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "dismiss")
        return imageView
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
        }
    }
    
    lazy var cardButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(self.didPressAddCardButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressAddCardButton(_ sender: UIButton) {
        self.paymentContext.presentPaymentOptionsViewController()
        MSAnalytics.trackEvent("Add Funds View Controller", withProperties: ["Button" : "didPressAddCardButton"])
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
        
        MSAnalytics.trackEvent("Add Funds View Controller", withProperties: ["Button" : "didPressPurchaseButton"])
    }
    
    func setupView() {
        self.title = "Add Funds"
        self.view.backgroundColor = color.black()
        
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        var topOffset: CGFloat!
        
        if shouldShowExitButton {
            self.view.addSubview(exitButton)
            exitButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(25)
                make.top.equalTo(self.view).offset(uiElement.topOffset)
                make.left.equalTo(self.view).offset(uiElement.leftOffset)
            }
            
            self.view.addSubview(addFundsTitle)
            addFundsTitle.snp.makeConstraints { (make) -> Void in
                make.centerY.equalTo(exitButton)
                make.centerX.equalTo(self.view)
            }
            
        } else {
            topOffset = uiElement.uiViewTopOffset(self) + 15
            switch UIDevice.modelName {
            case "iPhone X", "iPhone XS", "iPhone XR", "iPhone 11", "iPhone 11 Pro", "iPhone 11 Pro Max", "iPhone XS Max", "Simulator iPhone 11 Pro Max":
                topOffset = uiElement.uiViewTopOffset(self) * 2
                break
                
            default:
                break
            }
        }
        
        self.view.addSubview(addFundsDescription)
        addFundsDescription.snp.makeConstraints { (make) -> Void in
            if shouldShowExitButton {
                make.top.equalTo(addFundsTitle.snp.bottom).offset(uiElement.topOffset)
            } else {
              make.top.equalTo(self.view).offset(topOffset)
            }
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
        
        self.view.addSubview(totalButton)
        totalButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(30)
            make.width.equalTo(100)
            make.centerY.equalTo(totalTitle)
            make.right.equalTo(fundsToAddView).offset(uiElement.rightOffset)
        }
        
        self.totalButton.addSubview(changeTotalAmountImage)
        changeTotalAmountImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(20)
            make.centerY.equalTo(totalTitle)
            make.right.equalTo(totalButton)
        }
        
        self.totalButton.addSubview(total)
        total.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(changeTotalAmountImage)
            make.right.equalTo(changeTotalAmountImage.snp.left).offset(-(uiElement.elementOffset))
        }
        
        self.fundsToAddView.addSubview(totalAmountDividerLine)
        totalAmountDividerLine.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(0.5)
            make.top.equalTo(totalButton.snp.bottom).offset(uiElement.topOffset)
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
}

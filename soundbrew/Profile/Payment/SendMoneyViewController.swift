//
//  SendMoneyViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 7/2/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//
//TODO: refactor to pay artist

import UIKit
import Stripe
import Parse
import AppCenterAnalytics
import NVActivityIndicatorView
import NotificationBannerSwift

class SendMoneyViewController: UIViewController, STPPaymentContextDelegate, NVActivityIndicatorViewable, UIPickerViewDataSource, UIPickerViewDelegate {
    
    let color = Color()
    let uiElement = UIElement()
    var shouldShowExitButton = false
    var artist: Artist?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupPaymentContext()
    }
    
    //description
    lazy var addFundsDescription: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        label.textColor = .lightGray
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = "Support \(self.artist?.name ?? "this artist") by sending them money.\n"
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
        button.addTarget(self, action: #selector(self.didChangeSendAmount(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didChangeSendAmount(_ sender: UIBarButtonItem) {
        let pickerView = UIPickerView(frame: CGRect(x: 10, y: 50, width: 150, height: 150))
        pickerView.delegate = self
        pickerView.dataSource = self

        let ac = UIAlertController(title: "How Much Would You Like Send?", message: "\n\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        ac.view.addSubview(pickerView)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            let amount = self.pickerNumbers[pickerView.selectedRow(inComponent: 1)]
            let amountInCents = amount * 100
            self.paymentContext.paymentAmount = amountInCents
            self.paymentContextDidChange(self.paymentContext)
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(ac, animated: true)
    }
    
    let pickerNumbers = Array(stride(from: 5, to: 999, by: 1))
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 1 {
            return pickerNumbers.count
        }
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return "$"
        } else {
            return "\(pickerNumbers[row])"
        }
    }
    
    lazy var total: UILabel = {
        let label = UILabel()
        label.text = "$5.00"
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
        self.view.backgroundColor = color.black()
        
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        let dividerLine = self.uiElement.addSubViewControllerTopView(self, action: #selector(self.didPressCancelButton(_:)), doneButtonTitle: "")
        
        self.view.addSubview(addFundsDescription)
        addFundsDescription.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(dividerLine.snp.bottom).offset(uiElement.topOffset)
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
    
    @objc func didPressCancelButton(_ sender: UIButton) {
        if sender.tag == 0 {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    //mark: payments
    var paymentContext: STPPaymentContext!
    func setupPaymentContext() {
        let customer = Customer.shared
        let customerContext = STPCustomerContext(keyProvider: customer)
        paymentContext = STPPaymentContext(customerContext: customerContext)
        paymentContext.paymentAmount = 500
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
        let fundsToSend = self.uiElement.convertCentsToDollarsAndReturnString(paymentContext.paymentAmount, currency: "$")
        self.purchaseButton.setTitle("Send \(fundsToSend)", for: .normal)
        self.total.text = fundsToSend
        self.cardNumberLastFour.text = paymentContext.selectedPaymentOption?.label
        self.cardImage.image = paymentContext.selectedPaymentOption?.image
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        self.uiElement.showAlert("Connectivity Issue", message: "\(error.localizedDescription)", target: self)
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPPaymentStatusBlock) {
        if let currentUser = PFUser.current(), let objectId = currentUser.objectId, let email = currentUser.email, let username = self.artist?.username, let accountId = self.artist?.accountId, let customerId = Customer.shared.artist?.customerId {
                let payment = Payment.shared
                let paymentAmount = paymentContext.paymentAmount
            payment.createPaymentIntent(objectId, email: email, name: username, amount: paymentAmount, currency: paymentContext.paymentCurrency, account_id: accountId, customerId: customerId) { [weak self] (result) in
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
            //let localizedPaymentDeclined = NSLocalizedString("paymentDeclined", comment: "")
            //self.uiElement.showAlert(localizedPaymentDeclined, message: "", target: self)
            let banner = StatusBarNotificationBanner(title: "Declined: \(errorString)", style: .danger)
            banner.show()
        case .success:
           // if PFUser.current()?.objectId != self.uiElement.d_innovatorObjectId {
                SKStoreReviewController.requestReview()
            //}
            let banner = StatusBarNotificationBanner(title: "Success", style: .success)
            banner.show()
            self.dismiss(animated: true, completion: nil)
            
        case .userCancellation:
            return
        default:
            return
        }
    }
    
    //
    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
        
    }
}

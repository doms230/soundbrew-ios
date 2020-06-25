//
//  SendMoneyViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 7/2/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Stripe
import Parse
import NVActivityIndicatorView
import NotificationBannerSwift

class SendMoneyViewController: UIViewController, STPPaymentContextDelegate, NVActivityIndicatorViewable, UIPickerViewDataSource, UIPickerViewDelegate, ArtistDelegate, UITextFieldDelegate {
    
    let color = Color()
    let uiElement = UIElement()
    var shouldShowExitButton = false
    var artist: Artist?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        addFundsDescriptionView()
        setupPaymentContext()
    }
    
    var cancelButton: UIButton!
    var sendMoneyButton: UIButton!
    var topViewDividerLine: UIView!
        
    func addFundsDescriptionView() {
        (cancelButton, sendMoneyButton, topViewDividerLine) = self.uiElement.addSubViewControllerTopView(self, action: #selector(self.didPressTopViewButton(_:)), doneButtonTitle: "Send", title: "Gift Money")
        
        self.view.addSubview(addFundsDescription)
        addFundsDescription.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(topViewDividerLine.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
    }
    
    //description
    lazy var addFundsDescription: UILabel = {
        return self.uiElement.soundbrewLabel("Support \(self.artist?.name ?? "this artist") by gifting them money.", textColor: .darkGray, font: UIFont(name: "\(UIElement().mainFont)", size: 17)!, numberOfLines: 1)
    }()
    
    lazy var totalAmountDividerLine: UIView = {
        return self.uiElement.soundbrewDividerLine()
    }()
    
    lazy var totalTitle: UILabel = {
        let localizedTotal = NSLocalizedString("total", comment: "")
        return self.uiElement.soundbrewLabel(localizedTotal, textColor: .white, font: UIFont(name: "\(uiElement.mainFont)", size: 17)!, numberOfLines: 1)
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

        let ac = UIAlertController(title: "How Much Would You Like Gift?", message: "\n\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
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
        label.text = "$10.00"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor =  .white
        label.numberOfLines = 0
        return label
    }()
    
    lazy var changeTotalAmountImage: UIImageView = {
        return self.uiElement.soundbrewImageView(UIImage(named: "dismiss"), cornerRadius: nil, backgroundColor: self.color.black())
    }()
    
    // Payment Method views
    lazy var paymentButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(self.didPressAddCardButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressAddCardButton(_ sender: UIButton) {
        self.paymentContext.presentPaymentOptionsViewController()
    }
    
    lazy var cardImage: UIImageView = {
        return self.uiElement.soundbrewImageView(nil, cornerRadius: nil, backgroundColor: color.purpleBlack())
    }()
    
    lazy var cardNumberLastFour: UILabel = {
        return self.uiElement.soundbrewLabel("4422", textColor: .white, font: UIFont(name: "\(uiElement.mainFont)", size: 17)!, numberOfLines: 1)
    }()
    
    lazy var editCardImage: UIImageView = {
        return self.uiElement.soundbrewImageView(UIImage(named: "dismiss"), cornerRadius: nil, backgroundColor: self.color.black())
    }()
    
    //Message Views
    lazy var messageButton: UIButton = {
        let button = self.uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: color.black(), image: nil, titleFont: nil, titleColor: .white, cornerRadius: 3)
        button.addTarget(self, action: #selector(self.didPressAddMessageButton(_:)), for: .touchUpInside)
        button.titleLabel?.numberOfLines = 0
        return button
    }()
    @objc func didPressAddMessageButton(_ sender: UIButton) {
        let modal = EditBioViewController()
        modal.bioTitle = "Gift Message"
        modal.artistDelegate = self
        self.present(modal, animated: true, completion: nil)
    }
    
    lazy var addMessageDividerLine: UIView = {
        return self.uiElement.soundbrewDividerLine()
    }()
    
    lazy var messageLabel: UILabel = {
        let label =  self.uiElement.soundbrewLabel("Add", textColor: color.blue(), font: UIFont(name: "\(UIElement().mainFont)", size: 17)!, numberOfLines: 0)
        label.textAlignment = .right
        return label
    }()
    
    func changeBio(_ value: String?) {
        if let message = value {
            if message.isEmpty {
                self.messageLabel.text = "Add"
                self.messageLabel.textColor = color.blue()
            } else {
                self.messageLabel.text = message
                self.messageLabel.textColor = .white
            }
        } else {
            self.messageLabel.text = "Add"
            self.messageLabel.textColor = color.blue()
        }
    }
    
    func receivedArtist(_ value: Artist?) {
    }
    
    //Stripe Message Views
    lazy var stripeAddFundsMessage: UIButton = {
        let localizedStripeAddFundsMessage = NSLocalizedString("stripeAddFundsMessage", comment: "")
        let button = UIButton()
        button.setTitle(localizedStripeAddFundsMessage, for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)", size: 15)
        button.setTitleColor(.darkGray, for: .normal)
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
    
    func setupView() {
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
        
        
        //payment view
        self.view.addSubview(paymentButton)
        paymentButton.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.view)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        let paymentTitle = self.uiElement.soundbrewLabel("Payment", textColor: .white, font: UIFont(name: "\(uiElement.mainFont)", size: 17)!, numberOfLines: 1)
        self.paymentButton.addSubview(paymentTitle)
        paymentTitle.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(paymentButton)
            make.left.equalTo(paymentButton)
        }
        self.paymentButton.addSubview(editCardImage)
        editCardImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(20)
            make.centerY.equalTo(paymentButton)
            make.right.equalTo(self.paymentButton)
        }
        
        self.paymentButton.addSubview(cardNumberLastFour)
        cardNumberLastFour.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(editCardImage)
            make.right.equalTo(editCardImage.snp.left).offset(uiElement.rightOffset)
        }
        self.paymentButton.addSubview(cardImage)
        cardImage.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(paymentButton)
            make.right.equalTo(cardNumberLastFour.snp.left)
        }
        
        let paymentDividerLine = self.uiElement.soundbrewDividerLine()
        self.view.addSubview(paymentDividerLine)
        paymentDividerLine.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(0.5)
            make.top.equalTo(paymentButton.snp.bottom).offset(self.uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        //Total View
        self.view.addSubview(totalAmountDividerLine)
        totalAmountDividerLine.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(0.5)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(paymentTitle.snp.top).offset(uiElement.bottomOffset)
        }
        
        self.view.addSubview(totalTitle)
        totalTitle.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.bottom.equalTo(totalAmountDividerLine.snp.bottom).offset(uiElement.bottomOffset)
        }
        
        self.view.addSubview(totalButton)
        totalButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(30)
            make.width.equalTo(100)
            make.centerY.equalTo(totalTitle)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
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
        
        //add message View
        self.view.addSubview(messageButton)
        messageButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(paymentDividerLine.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(stripeAddFundsMessage).offset(uiElement.bottomOffset * 2)
        }
        
        let messageTitle = self.uiElement.soundbrewLabel("Message", textColor: .white, font: UIFont(name: "\(uiElement.mainFont)", size: 17)!, numberOfLines: 1)
        self.messageButton.addSubview(messageTitle)
        messageTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(messageButton)
            make.left.equalTo(messageButton)
        }
        
        self.messageButton.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(messageButton)
            make.left.equalTo(messageTitle.snp.right).offset(uiElement.leftOffset)
            make.right.equalTo(messageButton)
        }
    }
    
    @objc func didPressTopViewButton(_ sender: UIButton) {
        if sender.tag == 0 {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.startAnimating()
            self.paymentContext.requestPayment()
        }
    }
    
    //mark: payments
    var paymentContext: STPPaymentContext!
    func setupPaymentContext() {
        let customer = Customer.shared
        let customerContext = STPCustomerContext(keyProvider: customer)
        paymentContext = STPPaymentContext(customerContext: customerContext)
        paymentContext.paymentAmount = 1000
        self.paymentContext.delegate = self
        self.paymentContext.hostViewController = self
        self.paymentContext.paymentCurrency = "usd"
    }
    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        self.sendMoneyButton.isEnabled = paymentContext.selectedPaymentOption != nil
        let fundsToSend = self.uiElement.convertCentsToDollarsAndReturnString(paymentContext.paymentAmount, currency: "$")
        self.sendMoneyButton.setTitle("Gift \(fundsToSend)", for: .normal)
        self.total.text = fundsToSend
        self.cardNumberLastFour.text = paymentContext.selectedPaymentOption?.label
        self.cardImage.image = paymentContext.selectedPaymentOption?.image
        
        setupView()
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
            let banner = StatusBarNotificationBanner(title: "Declined: \(errorString)", style: .danger)
            banner.show()
        case .success:
            SKStoreReviewController.requestReview()
            if let fromUserId = PFUser.current()?.objectId, let toUserId = self.artist?.objectId {
                self.newMention(fromUserId, toUserId: toUserId)
            }
            let banner = StatusBarNotificationBanner(title: "Success", style: .success)
            banner.show()
            self.dismiss(animated: true, completion: nil)
            return
        case .userCancellation:
            return
        default:
            return
        }
    }
    
    func newMention(_ fromUserId: String, toUserId: String) {
        if fromUserId != toUserId {
            let newMention = PFObject(className: "Mention")
            newMention["type"] = "gift"
            newMention["amount"] = self.paymentContext.paymentAmount
            if let message = self.messageLabel.text, !message.isEmpty {
                newMention["message"] = message
            }
            newMention["fromUserId"] = fromUserId
            newMention["toUserId"] = toUserId
            newMention.saveEventually {
                (success: Bool, error: Error?) in
                if success && error == nil {
                    let amountAsString = self.uiElement.convertCentsToDollarsAndReturnString(self.paymentContext.paymentAmount, currency: "$")
                    var giftMessage = ""
                    if let message = self.messageLabel.text, !message.isEmpty {
                        giftMessage = message
                    }
                    self.uiElement.sendAlert("gifted you\(amountAsString)! '\(giftMessage)'", toUserId: toUserId, shouldIncludeName: true)
                }
            }
        }
    }
    
    //
    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
        
    }
}

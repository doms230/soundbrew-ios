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
            //print(error!.localizedDescription)
            self.uiElement.showAlert("Issue With Charge", message: error!.localizedDescription, target: self)
        case .success:
            let newFunds = paymentContext.paymentAmount - self.processingFee
            let customer = Customer.shared
            customer.updateBalance(newFunds)
            self.uiElement.goBackToPreviousViewController(self)
            print("success")
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
    lazy var oneDollarAmount: UIButton = {
        let button = UIButton()
        button.backgroundColor = color.blue()
        button.setTitleColor(.white, for: .normal)
        button.setTitle("$1", for: .normal)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(self.didPressFundAmountButton(_:)), for: .touchUpInside)
        button.tag = 0
        return button
    }()
    
    lazy var twoDollarAmount: UIButton = {
        let button = UIButton()
        button.backgroundColor = color.lightGray()
        button.setTitleColor(color.black(), for: .normal)
        button.setTitle("$5", for: .normal)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(self.didPressFundAmountButton(_:)), for: .touchUpInside)
        button.tag = 1
        return button
    }()
    
    lazy var threeDollarAmount: UIButton = {
        let button = UIButton()
        button.backgroundColor = color.lightGray()
        button.setTitleColor(color.black(), for: .normal)
        button.setTitle("$10", for: .normal)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(self.didPressFundAmountButton(_:)), for: .touchUpInside)
        button.tag = 2
        return button
    }()
    @objc func didPressFundAmountButton(_ sender: UIButton) {
        var funds: Double!
        
        switch sender.tag {
        case 0:
            funds = 1
            changeFundAmountColors(sender, unSelectedButton: twoDollarAmount, unSelectedButton1: threeDollarAmount)
            break
            
        case 1:
            funds = 5
            changeFundAmountColors(sender, unSelectedButton: oneDollarAmount, unSelectedButton1: threeDollarAmount)
            break
            
        case 2:
            funds = 10
            changeFundAmountColors(sender, unSelectedButton: twoDollarAmount, unSelectedButton1: oneDollarAmount)
            break
            
        default:
            break
        }
        
        updateTotalAndProcessingFee(funds)
    }
    
    func changeFundAmountColors(_ selectedButton: UIButton, unSelectedButton: UIButton, unSelectedButton1: UIButton) {
        selectedButton.backgroundColor = color.blue()
        selectedButton.setTitleColor(.white, for: .normal)
        
        unSelectedButton.backgroundColor = color.lightGray()
        unSelectedButton.setTitleColor(color.black(), for: .normal)
        
        unSelectedButton1.backgroundColor = color.lightGray()
        unSelectedButton1.setTitleColor(color.black(), for: .normal)
    }
    
    lazy var addFundsSegment: UISegmentedControl = {
        let segment = UISegmentedControl(items: ["$1", "$5", "$10"])
        segment.selectedSegmentIndex = 0
        segment.tintColor = color.blue()
        segment.addTarget(self, action: #selector(didPressFundsSegmentButton(_:)), for: .valueChanged)
        return segment
    }()
    @objc func didPressFundsSegmentButton(_ sender: UISegmentedControl) {
        var funds: Double!
        
        switch sender.selectedSegmentIndex {
        case 0:
            funds = 1
            break
            
        case 1:
            funds = 5
            break
            
        case 2:
            funds = 10
            break
            
        default:
            break
        }
        
        updateTotalAndProcessingFee(funds)
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
    }
    
    func roundTwoDecimalPlaces(_ x: Double) -> Double {
        return Double(round(100 * x)/100)
    }
    
    lazy var currentBalanceLabel: UILabel = {
        let label = UILabel()
        label.text = "Current Balance"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 20)
        label.textColor = color.black()
        label.numberOfLines = 0
        return label
    }()
    
    lazy var currentBalanceAmount: UILabel = {
        let label = UILabel()
        label.text = "$1.00"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 25)
        label.textColor = color.black()
        label.numberOfLines = 0
        return label
    }()
    
    lazy var paymentProcessingFeeTitle: UILabel = {
        let label = UILabel()
        label.text = "Payment Processing Fee"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = color.black()
        label.numberOfLines = 0
        return label
    }()
    lazy var paymentProcessingFee: UILabel = {
        let label = UILabel()
        label.text = "$0.33"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = color.black()
        label.numberOfLines = 0
        return label
    }()
    
    lazy var totalTitle: UILabel = {
        let label = UILabel()
        label.text = "Total"
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        label.textColor = color.black()
        label.numberOfLines = 0
        return label
    }()
    lazy var total: UILabel = {
        let label = UILabel()
        label.text = "$1.33"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = color.black()
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
        image.backgroundColor = .white
        return image
    }()
    
    lazy var cardNumberLastFour: UILabel = {
        let label = UILabel()
        label.text = "4422"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = color.black()
        label.numberOfLines = 0
        return label
    }()
    
    lazy var addCardLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 20)
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
        return button
    }()
    
    @objc func didPressPurchaseButton(_ sender: UIButton) {
        self.paymentContext.requestPayment()
    }
    
    func setupView() {
        self.view.addSubview(currentBalanceLabel)
        currentBalanceLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        let customer = Customer.shared
        if let balance = customer.artist?.balance {
            currentBalanceAmount.text = uiElement.convertCentsToDollarsAndReturnString(balance, currency: "$")
        } else {
            currentBalanceAmount.text = "$0.00"
        }
        
        self.view.addSubview(currentBalanceAmount)
        currentBalanceAmount.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(currentBalanceLabel)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(oneDollarAmount)
        oneDollarAmount.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.top.equalTo(currentBalanceLabel.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(twoDollarAmount)
        twoDollarAmount.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.top.equalTo(oneDollarAmount.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(threeDollarAmount)
        threeDollarAmount.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.top.equalTo(twoDollarAmount.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        /*self.view.addSubview(addFundsSegment)
        addFundsSegment.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(currentBalanceAmount.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }*/
        
        self.view.addSubview(paymentProcessingFeeTitle)
        paymentProcessingFeeTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(threeDollarAmount.snp.bottom).offset(uiElement.topOffset)
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
            make.height.equalTo(75)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

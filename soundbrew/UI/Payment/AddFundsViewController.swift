//
//  AddFundsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 7/2/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Stripe

class AddFundsViewController: UIViewController, STPPaymentContextDelegate {
    
    let color = Color()
    let uiElement = UIElement()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupPaymentContext()
    }
    
    //mark: payments
    var paymentContext: STPPaymentContext!
    
    func setupPaymentContext() {
        let customerContext = STPCustomerContext(keyProvider: Payment.shared)
        paymentContext = STPPaymentContext(customerContext: customerContext)
        self.paymentContext.delegate = self
        self.paymentContext.hostViewController = self
        self.paymentContext.paymentAmount = 5000
    }
    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {

    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPErrorBlock) {
        
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        
    }
    
    //mark: UI
    lazy var addFundsSegment: UISegmentedControl = {
        let segment = UISegmentedControl(items: ["$1", "$5", "$10"])
        segment.selectedSegmentIndex = 0
        segment.tintColor = color.blue()
        segment.addTarget(self, action: #selector(didPressFundsSegmentButton(_:)), for: .valueChanged)
        return segment
    }()
    @objc func didPressFundsSegmentButton(_ sender: UISegmentedControl) {
        var funds: Double!
        var processingFee: Double!
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
        
        processingFee = (funds * 0.029) + 0.30
        processingFee = roundTwoDecimalPlaces(processingFee)
        self.paymentProcessingFee.text = "$\(processingFee!)"
        
        var total = funds + processingFee
        total = roundTwoDecimalPlaces(processingFee)
        self.total.text = "$\(total)"
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
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
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
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        label.textColor = color.black()
        label.numberOfLines = 0
        return label
    }()
    
    lazy var cardButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
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
        label.text = "Add Card"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 20)
        label.textColor = color.blue()
        label.numberOfLines = 0
        return label
    }()
    
    lazy var purchaseButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = color.blue()
        button.setTitle("Purchase", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(didPressPurchaseButton(_:)), for: .touchUpInside)
        return button
    }()
    
    @objc func didPressPurchaseButton(_ sender: UIButton) {
        
    }
    
    func setupView() {
        self.view.addSubview(currentBalanceLabel)
        currentBalanceLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        self.view.addSubview(currentBalanceAmount)
        currentBalanceAmount.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(currentBalanceLabel)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(addFundsSegment)
        addFundsSegment.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(currentBalanceAmount.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(paymentProcessingFeeTitle)
        paymentProcessingFeeTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(addFundsSegment.snp.bottom).offset(uiElement.topOffset)
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

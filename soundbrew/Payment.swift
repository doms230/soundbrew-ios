//
//  Payment.swift
//  soundbrew
//
//  Created by Dominic  Smith on 4/2/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import Foundation
import StoreKit

class Payment: NSObject, SKProductsRequestDelegate {
    
    static let shared = Payment()
    
    //var productIdentifier = "premium1"
    
    var product: SKProduct?
    
    func loadSubscriptionOptions() {
        let productID = "premium1"
        let request = SKProductsRequest(productIdentifiers: Set([productID]))
        request.delegate = self
        request.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
       // product = response.products.map { description(product: $0) }
        print("as: \(response.invalidProductIdentifiers)")
        print("a: \(response.products)")
        //product = response.products[0]
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        if request is SKProductsRequest {
            print("Subscription Options Failed Loading: \(error.localizedDescription)")
        }
    }
    
    func canMakePurchases() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    func purchase() {
        if let product = self.product {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        }
    }
    
    

}

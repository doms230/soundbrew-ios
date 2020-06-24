//
//  Payment.swift
//  soundbrew
//
//  Created by Dominic  Smith on 7/1/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import Foundation
import Alamofire
import UIKit
import SwiftyJSON

class Payment: NSObject {
    let uiElement = UIElement()
    static let shared = Payment()

    let baseURL = URL(string: "https://www.soundbrew.app/payments/")
    //let baseURL = URL(string: "http://192.168.200.8:3000/payments/")
    func createPaymentIntent(_ objectId: String, email: String, name: String, amount: Int, currency: String, account_id: String, customerId: String, completion: @escaping (Swift.Result<String, Error>?) -> Void) {
        let url = self.baseURL!.appendingPathComponent("create-payment-intent")
        let parameters: Parameters = [
            "amount": amount,
            "currency": currency,
            "name": name,
            "metadata": objectId,
            "customer": customerId,
            "receipt_email": email,
            "account_id": account_id
        ]
        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString))
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    let json = JSON(json)
                    print(json)
                    if let secret = json["clientSecret"].string {
                        completion(.success(secret))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
        }
    }
}

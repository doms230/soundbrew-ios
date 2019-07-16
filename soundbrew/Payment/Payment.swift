//
//  Payment.swift
//  soundbrew
//
//  Created by Dominic  Smith on 7/1/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import Foundation
import Stripe
import Alamofire
import SnapKit
import UIKit
import SwiftyJSON
class Payment: NSObject {
    let uiElement = UIElement()
    static let shared = Payment()

    let baseURL = URL(string: "https://www.soundbrew.app/payments/")
    //let baseURL = URL(string: "http://192.168.1.68:3000/payments/")
    
    func charge(_ objectId: String, email: String, name: String, amount: Int, currency: String, description: String, source: String, completion: @escaping (Error?) -> Void) {
        let url = self.baseURL!.appendingPathComponent("charge")
        let customer = Customer.shared
        let parameters: Parameters = [
            "amount": amount,
            "currency": currency,
            "description": description,
            "source": source,
            "metadata": objectId,
            "customer": "\(customer.artist!.customerId!)",
            "receipt_email": email
        ]
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString))
            //.validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    let json = JSON(json)
                    print(json)
                    if let status = json["status"].string {
                        if status == "succeeded" {
                            completion(nil)
                        }
                    }
                case .failure(let error):
                    completion(error)
                }
        }
    }
}

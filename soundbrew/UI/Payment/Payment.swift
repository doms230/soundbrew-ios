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

class Payment: NSObject, STPCustomerEphemeralKeyProvider {
    let uiElement = UIElement()
    static let shared = Payment()

    let baseURL = URL(string: "https://www.soundbrew.app")
    
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let url = self.baseURL!.appendingPathComponent("ephemeral_keys")
        Alamofire.request(url, method: .post, parameters: [
            "api_version": apiVersion
            ])
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    completion(json as? [String: AnyObject], nil)
                case .failure(let error):
                    completion(nil, error)
                }
        }
    }
    
    
}

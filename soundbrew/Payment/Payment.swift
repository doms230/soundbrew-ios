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

class Payment: NSObject {
    let uiElement = UIElement()
    static let shared = Payment()

    let baseURL = URL(string: "https://www.soundbrew.app/payments/")
    

}

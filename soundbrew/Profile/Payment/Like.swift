//
//  Like.swift
//  soundbrew
//
//  Created by Dominic  Smith on 5/6/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import Foundation

class Like {
    let customer = Customer.shared
    init() {
        
    }
    

    func sendPayment(_ sound: Sound, tipAmount: Int) {
         if customer.artist!.balance! >= tipAmount {
             tipAction(sound, tipAmount: tipAmount)
             
         } /*else if let rewardedAd = self.rewardedAd {
             if rewardedAd.isReady == true {
                 rewardedAd.present(fromRootViewController: self, delegate: self)
             }
         }*/
     }
}

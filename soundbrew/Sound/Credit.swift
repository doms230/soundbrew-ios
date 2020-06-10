//
//  Credit.swift
//  soundbrew
//
//  Created by Dominic Smith on 1/5/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import Foundation
import Parse
import Alamofire

class Credit {
    var objectId: String?
    var artist: Artist?
    var title: String?

    init(objectId: String?, artist: Artist?, title: String?) {
        self.objectId = objectId
        self.artist = artist
        self.title = title
    }
}

protocol CreditDelegate {
    func receivedCredits(_ chosenCredits: Array<Credit>?)
}

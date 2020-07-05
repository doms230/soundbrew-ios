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
    var username: String?
    var title: String?
    var artist: Artist?

    init(objectId: String?, username: String?, title: String?, artist: Artist?) {
        self.objectId = objectId
        self.username = username
        self.title = title
        self.artist = artist
    }
}

protocol CreditDelegate {
    func receivedCredits(_ chosenCredits: Array<Credit>?)
}

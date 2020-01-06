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
    var percentage: Int?

    init(objectId: String?, artist: Artist?, title: String?, percentage: Int?) {
        self.objectId = objectId
        self.artist = artist
        self.title = title
        self.percentage = percentage
    }
}

protocol CreditDelegate {
    func receivedCredits(_ chosenTags: Array<Credit>?)
}

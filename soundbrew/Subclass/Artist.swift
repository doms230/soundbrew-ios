//
//  Artist.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 11/12/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import Foundation
import Parse

class Artist {
    var objectId: String!
    var name: String?
    var city: String?
    var image: String?
    
    init(objectId: String!, name: String?, city: String?, image: String?) {
        self.objectId = objectId
        self.name = name
        self.city = city
        self.image = image
    }
}

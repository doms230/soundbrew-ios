//
//  Tag.swift
//  soundbrew
//
//  Created by Dominic  Smith on 10/15/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import Foundation

class Tag {
    var objectId: String!
    var name: String!
    var count: Int!
    
    init(objectId: String!, name: String!, count: Int!) {
        self.objectId = objectId
        self.name = name
        self.count = count 
    }
}

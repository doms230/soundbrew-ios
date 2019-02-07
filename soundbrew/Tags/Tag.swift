//
//  Tag.swift
//  soundbrew
//
//  Created by Dominic  Smith on 10/15/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import Foundation
import UIKit

class Tag {
    var objectId: String!
    var name: String!
    var count: Int!
    var tagType: String?
    var isSelected: Bool!
    
    
    init(objectId: String?, name: String!, count: Int!, isSelected: Bool!, tagType: String?) {
        self.objectId = objectId
        self.name = name
        self.count = count
        self.isSelected = isSelected
        self.tagType = tagType
    }
}

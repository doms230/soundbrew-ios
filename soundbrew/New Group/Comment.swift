//
//  Comment.swift
//  soundbrew
//
//  Created by Dominic  Smith on 4/17/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import Foundation
import UIKit

class Comment {
    var objectId: String?
    var artist: Artist!
    var text: String!
    var atTime: Float!
    
    init(objectId: String?, artist: Artist!, text: String!, atTime: Float!) {
        self.objectId = objectId
        self.artist = artist
        self.text = text
        self.atTime = atTime
    }
}

protocol CommentDelegate {
    func selectedComments(_ postId: String?, atTime: Float?)    
}

//
//  Post.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/26/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import Foundation
import Parse

class Song {
    var objectId: String!
    var title: String!
    var audioFile: PFFile!
    var art: String?
    var userId: String!
    var description: String?
    var tags: Array<String>!
    
    init(objectId: String!, title: String!, audioFile: PFFile!, art: String?, userId: String!, description: String?, tags: Array<String>!) {
        self.objectId = objectId
        self.title = title
        self.audioFile = audioFile
        self.art = art
        self.userId = userId
        self.description = description
        self.tags = tags
    }
}

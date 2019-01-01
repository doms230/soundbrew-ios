//
//  Song.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/8/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import Foundation
import Parse

class Song {
    var objectId: String!
    var userId: String!
    var title: String!
    var audio: PFFileObject!
    var art: String!
    var tags: Array<String>!
    var plays: Int?
    var createdAt: Date!
    
    init(objectId: String!, title: String!, audio: PFFileObject!, art: String!, userId: String!, tags: Array<String>!, createdAt: Date!, plays: Int?) {
        self.objectId = objectId
        self.userId = userId
        self.title = title
        self.audio = audio
        self.art = art
        self.tags = tags
        self.createdAt = createdAt
        self.plays = plays
    }
}

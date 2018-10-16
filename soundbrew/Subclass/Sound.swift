//
//  Sound.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/26/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import Foundation
import Parse

class Sound {
    var objectId: String!
    var userId: String!
    var title: String!
    var audio: PFFile!
    var audioData: Data?
    var art: String!
    var tags: Array<String>!
    var plays: Int?
    var createdAt: Date!
    var relevancyScore: Int!
    
    init(objectId: String!, title: String!, art: String!, userId: String!, tags: Array<String>!, createdAt: Date!, plays: Int?, audio: PFFile!, relevancyScore: Int!, audioData: Data?) {
        self.objectId = objectId
        self.userId = userId
        self.title = title
        self.audio = audio
        self.art = art
        self.tags = tags
        self.createdAt = createdAt
        self.plays = plays
        self.relevancyScore = relevancyScore
        self.audioData = audioData
    }
}

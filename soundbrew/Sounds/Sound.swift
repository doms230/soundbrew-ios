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
    var title: String!
    var audio: PFFileObject!
    var audioURL: String!
    var audioData: Data?
    var artURL: String!
    var artFile: PFFileObject!
    var artImage: UIImage?
    var tags: Array<String>!
    var plays: Int?
    var createdAt: Date!
    var relevancyScore: Int!
    var artist: Artist?
    
    init(objectId: String!, title: String!, artURL: String!, artImage: UIImage?, artFile: PFFileObject!, tags: Array<String>!, createdAt: Date!, plays: Int?, audio: PFFileObject!, audioURL: String, relevancyScore: Int!, audioData: Data?, artist: Artist?) {
        self.objectId = objectId
        self.title = title
        self.audio = audio
        self.audioURL = audioURL
        self.artURL = artURL
        self.artImage = artImage
        self.artFile = artFile
        self.tags = tags
        self.createdAt = createdAt
        self.plays = plays
        self.relevancyScore = relevancyScore
        self.audioData = audioData
        self.artist = artist 
    }
}

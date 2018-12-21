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
    var audio: PFFileObject!
    var audioURL: String!
    var audioData: Data?
    var artURL: String!
    var artImage: UIImage?
    var tags: Array<String>!
    var plays: Int?
    var createdAt: Date!
    var relevancyScore: Int!
    var artistName: String?
    var artistCity: String?
    var instagramHandle: String?
    var twitterHandle: String?
    var spotifyLink: String?
    var soundcloudLink: String?
    var appleMusicLink: String?
    var otherLink: String?
    var artistVerified: Bool?
    
    init(objectId: String!, title: String!, artURL: String!,artImage: UIImage?, userId: String!, tags: Array<String>!, createdAt: Date!, plays: Int?, audio: PFFileObject!, audioURL: String, relevancyScore: Int!, audioData: Data?, artistName: String?, artistCity: String?, instagramHandle: String?, twitterHandle: String?, spotifyLink: String?, soundcloudLink: String?, appleMusicLink: String?, otherLink: String?, artistVerified: Bool?) {
        self.objectId = objectId
        self.userId = userId
        self.title = title
        self.audio = audio
        self.audioURL = audioURL
        self.artURL = artURL
        self.artImage = artImage
        self.tags = tags
        self.createdAt = createdAt
        self.plays = plays
        self.relevancyScore = relevancyScore
        self.audioData = audioData
        self.artistName = artistName
        self.artistCity = artistCity
        self.instagramHandle = instagramHandle
        self.twitterHandle = twitterHandle
        self.spotifyLink = spotifyLink
        self.soundcloudLink = soundcloudLink
        self.appleMusicLink = appleMusicLink
        self.otherLink = otherLink
        self.artistVerified = artistVerified
    }
}

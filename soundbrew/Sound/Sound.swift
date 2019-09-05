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
    var objectId: String?
    var title: String?
    var audio: PFFileObject?
    var audioURL: String?
    var audioData: Data?
    var artURL: String?
    var artFile: PFFileObject?
    var artImage: UIImage?
    var tags: Array<String>?
    var plays: Int?
    var createdAt: Date?
    var relevancyScore: Int!
    var artist: Artist?
    var tmpFile: TemporaryFile?
    var tips: Int?
    var isDraft: Bool?
    
    init(objectId: String?, title: String?, artURL: String?, artImage: UIImage?, artFile: PFFileObject?, tags: Array<String>?, createdAt: Date?, plays: Int?, audio: PFFileObject?, audioURL: String?, relevancyScore: Int!, audioData: Data?, artist: Artist?, tmpFile: TemporaryFile?, tips: Int?, isDraft: Bool?) {
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
        self.tmpFile = tmpFile
        self.tips = tips
        self.isDraft = isDraft
    }
}

func newSoundObject(_ object: PFObject, tagsForFiltering: Array<Tag>?) -> Sound {
    let title = object["title"] as! String
    let art = object["songArt"] as! PFFileObject
    let audio = object["audioFile"] as! PFFileObject
    
    var tags: Array<String>?
    var relevancyScore = 0
    if let retreivedTags = object["tags"] as? Array<String> {
        tags = retreivedTags
        if let tagsForFiltering = tagsForFiltering {
            for tag in retreivedTags {
                let selectedTagNames = tagsForFiltering.map {$0.name!}
                if selectedTagNames.contains(tag) {
                    relevancyScore += 1
                }
            }
        }
    }
    
    var plays: Int?
    if let soundPlays = object["plays"] as? Int {
        plays = soundPlays
    }
    
    var tips: Int?
    if let soundTips = object["tips"] as? Int {
        tips = soundTips
    }
    
    let userId = object["userId"] as! String
    let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: "", website: "", bio: "", email: "", isFollowedByCurrentUser: nil, followerCount: nil, customerId: nil, balance: nil)
    
    let sound = Sound(objectId: object.objectId, title: title, artURL: art.url!, artImage: nil, artFile: art, tags: tags, createdAt: object.createdAt!, plays: plays, audio: audio, audioURL: audio.url!, relevancyScore: relevancyScore, audioData: nil, artist: artist, tmpFile: nil, tips: tips, isDraft: false)
    
    return sound
}

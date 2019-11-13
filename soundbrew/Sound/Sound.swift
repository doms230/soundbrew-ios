//
//  Sound.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/26/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import Foundation
import Parse
import Alamofire

class Sound {
    var objectId: String?
    var title: String?
    var audio: PFFileObject?
    var audioURL: String?
    var audioData: Data?
    var isNextUpToPlay: Bool!
    var artURL: String?
    var artFile: PFFileObject?
    var artImage: UIImage?
    var tags: Array<String>?
    var plays: Int?
    var createdAt: Date?
   // var relevancyScore: Int!
    var artist: Artist?
    var tmpFile: TemporaryFile?
    var tips: Int?
    var tippers: Int?
    var isDraft: Bool?

    init(objectId: String?, title: String?, artURL: String?, artImage: UIImage?, artFile: PFFileObject?, tags: Array<String>?, createdAt: Date?, plays: Int?, audio: PFFileObject?, audioURL: String?, audioData: Data?, artist: Artist?, tmpFile: TemporaryFile?, tips: Int?, tippers: Int?, isDraft: Bool?, isNextUpToPlay: Bool! ) {
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
        //self.relevancyScore = relevancyScore
        self.audioData = audioData
        self.artist = artist
        self.tmpFile = tmpFile
        self.tips = tips
        self.tippers = tippers
        self.isDraft = isDraft
        self.isNextUpToPlay = isNextUpToPlay
    }
    
    func fetchAudioData() {
        if self.audioData == nil, let audio = self.audio {            
            audio.getDataInBackground {
                (audioData: Data?, error: Error?) -> Void in
                if let error = error?.localizedDescription {
                    print(error)
                    
                } else if let audioData = audioData {
                    print("fetched \(self.title!)")
                    self.audioData = audioData
                    if self.isNextUpToPlay {
                        print("up nex to play")
                        self.isNextUpToPlay = false 
                        let player = Player.sharedInstance
                        if player.player == nil {
                            player.prepareAndPlay(audioData)
                        }
                    }
                }
            }
        }
    }
}


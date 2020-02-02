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
    var playCount: Int?
    var commentCount: Int?
    var creditCount: Int?
    var createdAt: Date?
    var artist: Artist?
    var tmpFile: TemporaryFile?
    var tipAmount: Int?
    var currentUserTipDate: Date?
    var tipCount: Int?
    var isDraft: Bool?

    init(objectId: String?, title: String?, artURL: String?, artImage: UIImage?, artFile: PFFileObject?, tags: Array<String>?, createdAt: Date?, playCount: Int?, audio: PFFileObject?, audioURL: String?, audioData: Data?, artist: Artist?, tmpFile: TemporaryFile?, tipAmount: Int?, tipCount: Int?, currentUserTipDate: Date?, isDraft: Bool?, isNextUpToPlay: Bool!, creditCount: Int?, commentCount: Int?) {
        self.objectId = objectId
        self.title = title
        self.audio = audio
        self.audioURL = audioURL
        self.artURL = artURL
        self.artImage = artImage
        self.artFile = artFile
        self.tags = tags
        self.createdAt = createdAt
        self.playCount = playCount
        self.audioData = audioData
        self.artist = artist
        self.tmpFile = tmpFile
        self.tipAmount = tipAmount
        self.tipCount = tipCount
        self.currentUserTipDate = currentUserTipDate
        self.isDraft = isDraft
        self.isNextUpToPlay = isNextUpToPlay
        self.creditCount = creditCount
        self.commentCount = commentCount
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
                        self.isNextUpToPlay = false
                        let player = Player.sharedInstance
                        if player.player == nil {
                            player.prepareAndPlay(audioData)
                        }
                    }
                    
                    if self.artist?.image == nil {
                        self.artist?.loadUserInfoFromCloud(nil, soundCell: nil, commentCell: nil)
                    }
                }
            }
        }        
    }
}


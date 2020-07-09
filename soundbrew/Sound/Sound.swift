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
    var artFile: PFFileObject?
    var artImage: UIImage?
    var tags: Array<String>?
    var playCount: Int?
    var commentCount: Int?
    var creditCount: Int?
    var createdAt: Date?
    var artist: Artist?
    var tmpFile: TemporaryFile?
   // var currentUserTipDate: Date?
    var currentUserDidLikeSong: Bool?
    var tipCount: Int?
    var isDraft: Bool?
    var isFeatured: Bool?
    var isExclusive: Bool?
    var productId: String?
    
    init(objectId: String?, title: String?, artImage: UIImage?, artFile: PFFileObject?, tags: Array<String>?, createdAt: Date?, playCount: Int?, audio: PFFileObject?, audioURL: String?, audioData: Data?, artist: Artist?, tmpFile: TemporaryFile?, tipCount: Int?, currentUserDidLikeSong: Bool?, isDraft: Bool?, isNextUpToPlay: Bool!, creditCount: Int?, commentCount: Int?, isFeatured: Bool?, isExclusive: Bool?, productId: String?) {
        self.objectId = objectId
        self.title = title
        self.audio = audio
        self.audioURL = audioURL
        self.artImage = artImage
        self.artFile = artFile
        self.tags = tags
        self.createdAt = createdAt
        self.playCount = playCount
        self.audioData = audioData
        self.artist = artist
        self.tmpFile = tmpFile
        self.tipCount = tipCount
        self.currentUserDidLikeSong = currentUserDidLikeSong
        self.isDraft = isDraft
        self.isNextUpToPlay = isNextUpToPlay
        self.creditCount = creditCount
        self.commentCount = commentCount
        self.isFeatured = isFeatured
        self.isExclusive = isExclusive
        self.productId = productId
    }
    
    func fetchAudioData(_ shouldPlay: Bool) {
        if self.audioData == nil, let audio = self.audio {            
            audio.getDataInBackground {
                (audioData: Data?, error: Error?) -> Void in
                 if let audioData = audioData {
                    self.audioData = audioData
                    if self.isNextUpToPlay {
                        self.isNextUpToPlay = false
                        let player = Player.sharedInstance
                        if player.player == nil {
                            player.prepareAudio(audioData, shouldPlay: shouldPlay)
                        }
                    }
                    
                    if self.artist?.image == nil {
                        self.artist?.loadUserInfoFromCloud(nil, soundCell: nil, commentCell: nil, artistUsernameLabel: nil, artistImageButton: nil)
                    }
                }
            }
        }        
    }
}


//
//  Playlist.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/10/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import Foundation
import Parse
import Alamofire

class Playlist {
    var objectId: String?
    var artist: Artist?
    var title: String?
    var image: PFFileObject?
    var type: String?
    var count: Int?
    
    init(objectId: String?, artist: Artist?, title: String?, image: PFFileObject?, type: String?, count: Int?) {
        self.objectId = objectId
        self.artist = artist
        self.title = title
        self.image = image
        self.type = type
        self.count = count
    }
    
    func loadPlaylist() {
        if let objectId = self.objectId {
            let query = PFQuery(className: "Playlist")
            query.getObjectInBackground(withId: objectId) {
                (object: PFObject?, error: Error?) -> Void in
                if let object = object {
                    object["isRemoved"] = true
                    object.saveEventually {
                        (success: Bool, error: Error?) in
                        if success && error == nil {
                            self.title = object["title"] as? String
                            self.image = object["image"] as? PFFileObject
                            self.type = object["type"] as? String
                            self.count = object["count"] as? Int 
                        }
                    }
                }
            }
        }
    }
}

protocol PlaylistDelegate {
    func receivedPlaylist(_ playlist: Playlist?)
}

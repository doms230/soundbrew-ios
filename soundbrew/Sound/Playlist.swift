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
    var userId: String?
    var title: String?
    var type: String?
    
    init(objectId: String?, userId: String?, title: String?, type: String?) {
        self.objectId = objectId
        self.userId = userId
        self.title = title
        self.type = type
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
                            self.type = object["type"] as? String 
                        }
                    }
                }
            }
        }
    }
}

protocol PlaylistDelegate {
    func receivedPlaylist(_ chosenPlaylist: Playlist?)
}

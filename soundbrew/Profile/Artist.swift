//
//  Artist.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 11/12/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//
//email is optional, because won't be able to retreive from database unless it's current usr's email

import Foundation
import Parse

class Artist {
    var objectId: String!
    var name: String?
    var username: String!
    var city: String?
    var image: String?
    var website: String?
    var isVerified: Bool?
    var bio: String?
    var email: String?
    
    init(objectId: String!, name: String?, city: String?, image: String?, isVerified: Bool?, username: String!, website: String?, bio: String?, email: String?) {
        self.objectId = objectId
        self.name = name
        self.username = username
        self.city = city
        self.website = website
        self.image = image
        self.isVerified = isVerified
        self.bio = bio
        self.email = email 
    }
}

protocol ArtistDelegate {
    func changeBio(_ value: String?)
    
    func newArtistInfo(_ value: Artist?)
}

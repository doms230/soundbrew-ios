//
//  Artist.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 11/12/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import Foundation
import Parse

class Artist {
    var objectId: String!
    var name: String!
    var city: String!
    var image: String!
    var instagramHandle: String?
    var instagramClicks: Int?
    var twitterHandle: String?
    var twitterClicks: Int?
    var soundcloud: String?
    var soundcloudClicks: Int?
    var spotify: String?
    var spotifyClicks: Int?
    var appleMusic: String?
    var appleMusicClicks: Int?
    var otherLink: String?
    var otherLinkClicks: Int?
    var plays: Int?
    var createdAt: Date!
    
    init(objectId: String!, name: String!, city: String!, image: String!, instagramHandle: String?, instagramClicks: Int?, twitterHandle: String?, twitterClicks: Int?, soundcloud: String?, soundcloudClicks: Int?, spotify: String?, spotifyClicks: Int?, appleMusic: String?, appleMusicClicks: Int?, otherLink: String?, otherLinkClicks: Int? ) {
        self.objectId = objectId
        self.name = name
        self.city = city
        self.image = image
        self.instagramHandle = instagramHandle
        self.instagramClicks = instagramClicks
        self.twitterHandle = twitterHandle
        self.twitterClicks = twitterClicks
        self.soundcloud = soundcloud
        self.soundcloudClicks = soundcloudClicks
        self.spotify = spotify
        self.spotifyClicks = spotifyClicks
        self.appleMusic = appleMusic
        self.appleMusicClicks = appleMusicClicks
        self.otherLink = otherLink
        self.otherLinkClicks = otherLinkClicks
    }
}

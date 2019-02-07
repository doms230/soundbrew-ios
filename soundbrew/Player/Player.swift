//
//  Player.swift
//  soundbrew
//
//  Created by Dominic  Smith on 2/6/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//
//mark: Data,

import Foundation
import AVFoundation
import Parse
import MediaPlayer
import Kingfisher

class Player: NSObject, AVAudioPlayerDelegate {
    var player: AVAudioPlayer?
    var currentSoundIndex = -1
    var sounds = [Sound]()
    var tags = [String]()
    
    override init() {
        super.init()
        if let tagArray = UserDefaults.standard.stringArray(forKey: "tags") {
            tags = tagArray
            loadSounds()
            setupRemoteTransportControls()
        }
    }
    
    func play() {
        if let player = self.player {
            if !player.isPlaying {
                player.play()
            }
        }
    }
    
    func pause() {
        if let player = self.player {
            if player.isPlaying {
                player.pause()
            }
        }
    }
    
    func skip() {
        self.setUpNextSong(false)
    }
    
    func goBack() {
        if let player = self.player {
            if Int(player.currentTime) > 5 || currentSoundIndex == 0 {
                player.currentTime = 0.0
                
            } else {
                self.setUpNextSong(true)
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
           setUpNextSong(false)
        }
    }
    
    func setUpNextSong(_ didPressGoBackButton: Bool) {
        //stop soundplayer audio from playing over each other
        if player != nil {
            player?.pause()
            player = nil
        }
        
        var sound: Sound
        
        if didPressGoBackButton {
            sound = decrementPlaylistPositionAndReturnSound()
            
        } else {
            sound = incrementPlaylistPositionAndReturnSound()
        }
        
        if let audioData = sound.audioData {
            self.prepareAndPlay(audioData)
            
        } else {
            fetchAudioData(currentSoundIndex, prepareAndPlay: true)
        }
        
        let nextSoundIndex = currentSoundIndex + 1
        if sounds.indices.contains(nextSoundIndex) && sounds[nextSoundIndex].audioData == nil {
            fetchAudioData(nextSoundIndex, prepareAndPlay: false)
        }
    }
    
    func incrementPlaylistPositionAndReturnSound() -> Sound {
        self.currentSoundIndex = self.currentSoundIndex + 1
        
        if self.currentSoundIndex == sounds.count {
            //no sounds left, go back to zero.
            self.currentSoundIndex = 0
        }
        
        let sound = sounds[self.currentSoundIndex]
        
        return sound
    }
    
    func decrementPlaylistPositionAndReturnSound() -> Sound {
        self.currentSoundIndex = self.currentSoundIndex - 1
        
        if self.currentSoundIndex < 0 {
            self.currentSoundIndex = 0
        }
        
        let sound = sounds[self.currentSoundIndex]
        
        return sound
    }
    
    func fetchAudioData(_ position: Int, prepareAndPlay: Bool) {
        self.sounds[position].audio.getDataInBackground {
            (audioData: Data?, error: Error?) -> Void in
            if let error = error?.localizedDescription {
                print(error)
                
            } else if let audioData = audioData {
                print(audioData)
                if prepareAndPlay {
                    self.prepareAndPlay(audioData)
                }
                self.sounds[position].audioData = audioData
            }
        }
    }
    
    func prepareAndPlay(_ audioData: Data) {
        var soundPlayable = true
        
        //need audio url so can see what type of file audio is... helps get audio duration
        let audioURL = URL(string: sounds[currentSoundIndex].audioURL)
        
        //convert Data to URL on disk.. AVAudioPlayer won't play sound otherwise.
        let audioFileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("\(audioURL!.lastPathComponent)")
        
        // Set up the session.
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(AVAudioSession.Category.playback,
                                    mode: .default,
                                    policy: .longForm,
                                    options: [])
            
        } catch let error {
            soundPlayable = false
            fatalError("*** Unable to set up the audio session: \(error.localizedDescription) ***")
        }
        
        // Set up the player.
        do {
            self.player = try AVAudioPlayer(contentsOf: audioFileURL)
            player?.delegate = self
            
        } catch let error {
            print("*** Unable to set up the audio player: \(error.localizedDescription) ***")
            soundPlayable = false
        }
        
        // Activate and request the route.
        do {
            try session.setActive(true)
            
        } catch let error {
            print("Unable to activate audio session:  \(error.localizedDescription)")
            soundPlayable = false
        }
        
        if soundPlayable {
            player?.play()
            let sound = sounds[currentSoundIndex]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "setSound"), object: nil)
            setBackgroundAudioViews()
            incrementPlayCount(sound: sound)
            
        } else {
            setUpNextSong(false)
        }
    }
    
    func incrementPlayCount(sound: Sound) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: sound.objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                /*if let plays = object["plays"] as? Double {
                 //We want to notify artists every time their song hits a milestone like 10, 20, 100, 110, etc. Best way to determine if "plays" equally divids by 10
                 let incrementedPlays = plays + 1.0
                 if incrementedPlays.truncatingRemainder(dividingBy: 10) == 0 {
                 self.sendAlert("Congrats \(sound.artistName!), \(sound.title!) just hit \(incrementedPlays) plays!", toUserId: sound.userId)
                 }
                 }*/
                object.incrementKey("plays")
                object.saveEventually()
            }
        }
    }
    
    //mark: background controls
    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            if !self.player!.isPlaying {
                self.player!.play()
                return .success
            }
            
            return .commandFailed
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.player!.isPlaying {
                self.player!.pause()
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            self.setUpNextSong(false)
            return .success
        }
    }
    
    func setBackgroundAudioNowPlaying(_ player: AVAudioPlayer, sound: Sound) {
        var nowPlayingInfo = [String : Any]()
        
        // Define Now Playing Info
        nowPlayingInfo[MPMediaItemPropertyTitle] = sound.title
        
        nowPlayingInfo[MPMediaItemPropertyArtist] = sound.artist?.name
        
        if let image = sound.artImage {
            nowPlayingInfo[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: image.size) { size in
                    return image
            }
        }
        
        let cmTime = CMTime(seconds: player.currentTime, preferredTimescale: 1000000)
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(cmTime)
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func setBackgroundAudioViews() {
        self.sounds[currentSoundIndex].artFile.getDataInBackground { (imageData: Data?, error: Error?) in
            if let error = error {
                print(error.localizedDescription)
                
            } else if let imageData = imageData {
                let image = UIImage(data:imageData)
                self.sounds[self.currentSoundIndex].artImage = image
                
                if (self.sounds[self.currentSoundIndex].artist?.name) != nil {
                    self.setBackgroundAudioNowPlaying(self.player!, sound: self.sounds[self.currentSoundIndex])
                    
                } else {
                    self.loadUserInfoFromCloud(self.sounds[self.currentSoundIndex].artist!.objectId, i: self.currentSoundIndex)
                }
            }
        }
    }
    
    //mark: data
    func loadSounds() {
        let query = PFQuery(className: "Post")
        query.whereKey("tags", containedIn: tags)
        query.addDescendingOrder("createdAt")
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let title = object["title"] as! String
                        let audioFile = object["audioFile"] as! PFFileObject
                        let artFile = object["songArt"] as! PFFileObject
                        let artURL = artFile.url!
                        let userId = object["userId"] as! String
                        let tags = object["tags"] as! Array<String>
                        var playCount = 0
                        if let plays = object["plays"] as? Int {
                            playCount = plays
                        }
                        
                        var relevancyScore = 0
                        for tag in self.tags {
                            if tags.contains(tag) {
                                relevancyScore = relevancyScore + 1
                            }
                        }
                        
                        let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil)
                        
                        let newSound = Sound(objectId: object.objectId, title: title, artURL: artURL, artImage: nil, artFile: artFile, tags: tags, createdAt: object.createdAt, plays: playCount, audio: audioFile, audioURL: audioFile.url!, relevancyScore: relevancyScore, audioData: nil, artist: artist)
                        
                        self.sounds.append(newSound)
                    }
                    
                    self.sounds.sort(by: { $0.relevancyScore > $1.relevancyScore })
                    
                    if objects.count > 0 {
                        self.setUpNextSong(false)
                    }
                }
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func loadUserInfoFromCloud(_ userId: String, i: Int) {
        let query = PFQuery(className:"_User")
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                let artistName = user["artistName"] as? String
                self.sounds[i].artist?.name = artistName
                self.setBackgroundAudioNowPlaying(self.player!, sound: self.sounds[self.currentSoundIndex])
                self.sounds[i].artist?.city = user["city"] as? String
            }
        }
    }
}

//
//  Player.swift
//  soundbrew
//
//  Created by Dominic  Smith on 2/6/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//
//mark: Data

import Foundation
import AVFoundation
import Parse
import MediaPlayer
import Kingfisher
import Alamofire

class Player: NSObject, AVAudioPlayerDelegate {
    
    static let sharedInstance = Player()
    
    var player: AVAudioPlayer?
    var currentSoundIndex = 0
    var sounds: Array<Sound>!
    var currentSound: Sound?
    var tableView: UITableView?
    var target: UIViewController!
    var secondsPlayed = 0.0
    var secondsPlayedTimer = Timer()
    var didRecordStream = false
    var didRecordPlay = false
    
    override init() {
        super.init()
        setupRemoteTransportControls()
    }
    
    func prepareAudio(_ audioData: Data, shouldPlay: Bool) {
        var soundPlayable = true
        
        //need audio url so can see what type of file audio is... helps get audio duration
        let sound = sounds[currentSoundIndex]
        var audioURL: URL?
        var soundObjectId: String?
        if let getAudioURL = URL(string: sound.audioURL ?? "") {
            audioURL = getAudioURL
        }
        
        if let getSoundObject = sound.objectId {
            soundObjectId = getSoundObject
        }
        
        // Set up the session.
        let session = AVAudioSession.sharedInstance()
        
        do {
            //convert Data to URL on disk.. AVAudioPlayer won't play sound otherwise. .documentDirectory
            if audioURL != nil && soundObjectId != nil {
                let tempAudioFile = try TemporaryFile(creatingTempDirectoryForFilename: "\(audioURL!.lastPathComponent)")
                
                self.sounds[currentSoundIndex].tmpFile = tempAudioFile
                //AVAudioPlayer(
                try audioData.write(to: tempAudioFile.fileURL, options: .atomic)
                
                try session.setCategory(AVAudioSession.Category.playback,
                                        mode: .default,
                                        policy: .longForm,
                                        options: [])
                // Set up the player.
                self.player = try AVAudioPlayer(contentsOf: tempAudioFile.fileURL, fileTypeHint: "\(audioURL!.lastPathComponent)")
                player?.delegate = self
                
                // Activate and request the route.
                try session.setActive(true)
                
            } else {
                soundPlayable = false
            }
            
        } catch let error {
            print("prepare Audio- Player.swift \(error)")

            soundPlayable = false
        }
        
        if soundPlayable {
            resetStream()
            if sound.artImage == nil {
                loadArtfileImageData(sound)
            }
            
            if sound.artist?.image == nil {
                sound.artist?.loadUserInfoFromCloud(nil, soundCell: nil, commentCell: nil, artistUsernameLabel: nil, artistImageButton: nil)
            }
            
            if shouldPlay {
               self.play()
            } else {
                let miniPlayerView = MiniPlayerView.sharedInstance
                miniPlayerView.isEnabled = true
            }
            
        } else {
            setUpNextSong(false, at: nil, shouldPlay: false)
        }
    }
    
    func sendSoundUpdateToUI() {
        self.setBackgroundAudioNowPlaying()
        if let tableView = self.tableView {
            tableView.reloadData()
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "setSound"), object: nil)
        let miniPlayer = MiniPlayerView.sharedInstance
        miniPlayer.setSound()
    }
    
    func play() {
        shouldEnableCommandCenter(true)
        if let player = self.player {
            if !player.isPlaying {
                player.play()
                sendSoundUpdateToUI()
                startTimer()
            }
        }
    }
    
    func pause() {
        if let player = self.player {
            if player.isPlaying {
                player.pause()
                sendSoundUpdateToUI()
                secondsPlayedTimer.invalidate()
            }
        }
    }
    
    func next() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "preparingSound"), object: nil)
        self.setUpNextSong(false, at: nil, shouldPlay: true)
    }
    
    func previous() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "preparingSound"), object: nil)
        if let player = self.player, let sound = self.currentSound {
            if Int(player.currentTime) > 5 || currentSoundIndex == 0 {
                player.currentTime = 0.0
                setBackgroundAudioNowPlaying()
                incrementPlayCount(sound)
                recordListener(sound)
            } else {
                self.setUpNextSong(true, at: nil, shouldPlay: true)
            }
        }
    }
    
    func didSelectSoundAt(_ i: Int) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "preparingSound"), object: nil)
        self.setUpNextSong(false, at: i, shouldPlay: true)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            setUpNextSong(false, at: nil, shouldPlay: true)
        }
    }
    
    func setUpNextSong(_ didPressGoBackButton: Bool, at: Int?, shouldPlay: Bool) {
        //stop soundplayer audio from playing over each other
        if player != nil {
            player = nil
        } else if let sound = self.currentSound {
            if sound.audioData == nil {
                //don't want audio to continue downloading while attempting to fetch next song...
                //holds up everything.
                sound.audio?.cancel()
            }
        }
                
        if let sound = determineSoundToPlay(didPressGoBackButton, at: at) {
            currentSound = sound
            self.sendSoundUpdateToUI()
            prepareToPlaySound(sound, shouldPlay: shouldPlay)
        }
    }
    
    func fetchAudioFromNextSound() {
        let nextIndex = self.currentSoundIndex + 1
        if self.sounds.indices.contains(nextIndex) {
            self.sounds[nextIndex].fetchAudioData(false)
            self.sounds[nextIndex].isNextUpToPlay = false
        }
    }
    
    func determineSoundToPlay(_ didPressGoBackButton: Bool, at: Int?) -> Sound? {
        var sound: Sound?
        
        if let at = at {
            currentSoundIndex = at
            if sounds.indices.contains(at) {
                sound = sounds[at]
            }
            
        } else if didPressGoBackButton {
            sound = decrementPlaylistPositionAndReturnSound()
            
        } else {
            sound = incrementPlaylistPositionAndReturnSound()
        }
        
        return sound
    }
    
    func prepareToPlaySound(_ sound: Sound, shouldPlay: Bool) {
        if let audioData = sound.audioData {
            self.prepareAudio(audioData, shouldPlay: shouldPlay)
        } else {
            self.sounds[currentSoundIndex].isNextUpToPlay = true
            self.sounds[currentSoundIndex].fetchAudioData(shouldPlay)
        }
    }
    
    func incrementPlaylistPositionAndReturnSound() -> Sound {
        self.currentSoundIndex = self.currentSoundIndex + 1
        if !self.sounds.indices.contains(self.currentSoundIndex) {
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
    
    func incrementStreamCount(_ sound: Sound) {
        if let artistObjectId = sound.artist?.objectId {
            let query = PFQuery(className: "Payment")
            query.whereKey("userId", equalTo: artistObjectId)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if error != nil {
                    self.newArtistPaymentRow(artistObjectId)
                    
                } else if let object = object {
                    object.incrementKey("streamsSinceLastPayout")
                    object.incrementKey("streams")
                    object.saveEventually {
                        (success: Bool, error: Error?) in
                        if error != nil {
                            self.didRecordStream = false
                        }
                    }
                }
            }
        }
    }
    
    func newArtistPaymentRow(_ artistObjectId: String) {
        let newPaymentRow = PFObject(className: "Payment")
        newPaymentRow["userId"] = artistObjectId
        newPaymentRow["user"] = PFUser.current()
        newPaymentRow["streamsSinceLastPayout"] = 1
        newPaymentRow["streams"] = 1
        newPaymentRow.saveEventually{
            (success: Bool, error: Error?) in
            if error != nil {
                self.didRecordStream = false
            }
        }
    }
    
    func resetStream() {
        didRecordPlay = false
        didRecordStream = false
        secondsPlayedTimer.invalidate()
        secondsPlayed = 0.0
    }
    
    @objc func UpdateTimer(_ timer: Timer) {
        secondsPlayed = secondsPlayed + timer.timeInterval
        
        if secondsPlayed >= 1 && !didRecordPlay {
            didRecordPlay = true
            if let currentSound = currentSound {
                incrementPlayCount(currentSound)
                recordListener(currentSound)
            }
        }
        
        if secondsPlayed >= 30 && !didRecordStream {
            didRecordStream = true
            if let currentSound = currentSound {
                incrementStreamCount(currentSound)
            }
        }
    }
    func startTimer() {
        secondsPlayedTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTimer(_:)), userInfo: nil, repeats: true)
    }
    
    func incrementPlayCount(_ sound: Sound) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: sound.objectId!) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print("incrementPlayCount- Player.swift \(error)")
            } else if let object = object {
                if let plays = object["plays"] as? Double {
                    //We want to notify artists every time their song hits a milestone like 10, 20, 100, 110, etc. Best way to determine if "plays" equally divids by 10
                    let incrementedPlays = plays + 1.0
                    switch incrementedPlays {
                    case 10, 50, 100, 1000, 10000, 100000, 1000000:
                        UIElement().sendAlert("Congrats, \(sound.title!) just hit \(Int(incrementedPlays)) plays!", toUserId: sound.artist!.objectId, shouldIncludeName: false)
                        break
                        
                        default:
                        break
                    }
                }
                object.incrementKey("plays")
                object.saveEventually()
            }
        }
    }
    
    func recordListener(_ sound: Sound) {
        if let userId = Customer.shared.artist?.objectId, let postId = sound.objectId {
            let query = PFQuery(className: "Listen")
            query.whereKey("userId", equalTo: userId)
            query.whereKey("postId", equalTo: postId)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if let object = object {
                    object.incrementKey("count")
                    object.saveEventually()
                } else {
                    let newListenRow = PFObject(className: "Listen")
                    newListenRow["userId"] = userId
                    newListenRow["postId"] = postId
                    newListenRow["count"] = 1
                    newListenRow.saveEventually()
                }
            }
        }
    }
    
    //mark: background controls
    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
                
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [weak self] event in
            if let playSelf = self {
                playSelf.play()
                return .success
            }
            
            return .commandFailed
        }
                
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [weak self] event in
            if let pauseSelf = self {
                pauseSelf.pause()
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            if let nextSelf = self {
                nextSelf.next()
                return .success
            }

            return .commandFailed
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            if let previousSelf = self {
                previousSelf.previous()
                return .success
            }

            return .commandFailed
        }
    }
    
    func shouldEnableCommandCenter(_ shouldEnable: Bool ) {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = shouldEnable
        commandCenter.pauseCommand.isEnabled = shouldEnable
        commandCenter.nextTrackCommand.isEnabled = shouldEnable
        commandCenter.previousTrackCommand.isEnabled = shouldEnable
    }
    
    func setBackgroundAudioNowPlaying() {
        if let sound = self.currentSound {
            DispatchQueue.main.async {
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
                
                if let player = self.player {
                    let cmTime = CMTime(seconds: player.currentTime, preferredTimescale: 1000000)
                    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(cmTime)
                    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration
                    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
                }
                
                // Set the metadata
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        }
    }
    
    func loadArtfileImageData(_ sound: Sound) {
        if let artFile = sound.artFile {
            artFile.getDataInBackground { (imageData: Data?, error: Error?) in
                if let error = error {
                    print("loadArtFileImageData-Player.swift: \(error.localizedDescription)")
                } else if let imageData = imageData {
                    let image = UIImage(data:imageData)
                    sound.artImage = image
                    
                    self.setBackgroundAudioNowPlaying()
                }
            }
        }
    }
    
    //mark: data
    func loadUserInfoFromCloud(_ userId: String, i: Int) {
        let query = PFQuery(className:"_User")
        query.cachePolicy = .networkElseCache
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print("load user info from cloud - Player.swift: \(error)")
            }
            if let user = user {
                self.sounds[i].artist = UIElement().newArtistObject(user)
                self.setBackgroundAudioNowPlaying()
            }
        }
    }
}

protocol PlayerDelegate {
    func selectedArtist(_ artist: Artist?)
}



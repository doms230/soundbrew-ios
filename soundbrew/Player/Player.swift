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
import FirebaseAnalytics

class Player: NSObject, AVAudioPlayerDelegate {
    
    static let sharedInstance = Player()
    
    var player: AVAudioPlayer?
    var currentSoundIndex = 0
    var sounds: Array<Sound>!
    var currentSound: Sound?
    var tags = [String]()
    var tableView: UITableView?
    var miniPlayerView: MiniPlayerView!
    var target: UIViewController!
    var ad: Ad!
    var secondsPlayed = 0.0
    var secondsPlayedTimer = Timer()
    var didRecordStream = false
    var didRecordPlay = false
    
    override init() {
        super.init()
        setupRemoteTransportControls()
        ad = Ad(player: self)
    }
    
    func prepareAndPlay(_ audioData: Data) {
        var soundPlayable = true
        
        //need audio url so can see what type of file audio is... helps get audio duration
        let sound = sounds[currentSoundIndex]
        var audioURL: URL?
        var soundObjectId: String?
        if let getAudioURL = URL(string: sound.audioURL) {
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
                
                try audioData.write(to: tempAudioFile.fileURL, options: .atomic)
                
                try session.setCategory(AVAudioSession.Category.playback,
                                        mode: .default,
                                        policy: .longForm,
                                        options: [])
                // Set up the player.
                self.player = try AVAudioPlayer(contentsOf: tempAudioFile.fileURL)
                player?.delegate = self
                
                // Activate and request the route.
                try session.setActive(true)
                
            } else {
                soundPlayable = false
            }
            
        } catch let error {
            print(error)
            soundPlayable = false
        }
        
        if soundPlayable {
            resetStream()
            self.play()
            
        } else {
            setUpNextSong(false, at: nil)
        }
    }
    
    func sendSoundUpdateToUI() {
        self.setBackgroundAudioNowPlaying(self.player, sound: currentSound!)
        
        if let tableView = self.tableView {
            tableView.reloadData()
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "setSound"), object: nil)
    }
    
    func play() {
        let applicationState = UIApplication.shared.applicationState
        
        if ad.secondsPlayedSinceLastAd < ad.fifteenMinutesInSeconds {
            shouldEnableCommandCenter(true)
            if let player = self.player {
                if !player.isPlaying {
                    player.play()
                    sendSoundUpdateToUI()
                    startTimer()
                    Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                        AnalyticsParameterItemID: "id-play",
                        AnalyticsParameterItemName: "play",
                        AnalyticsParameterContentType: "cont"
                        ])
                }
            }
            
            //currenty, ads can only be shown when app is active and view is shown.
        } else if ad.secondsPlayedSinceLastAd > ad.fifteenMinutesInSeconds && applicationState == .active {
            print("is active")
            ad.showAd(target)
            
        } else if ad.secondsPlayedSinceLastAd > ad.fifteenMinutesInSeconds &&
            applicationState == .background {
            print("is not active")
            shouldEnableCommandCenter(false)
        }
    }
    
    func pause() {
        if let player = self.player {
            if player.isPlaying {
                player.pause()
                secondsPlayedTimer.invalidate()
            }
        }
    }
    
    func next() {
        self.setUpNextSong(false, at: nil)
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterItemID: "id-skip",
            AnalyticsParameterItemName: "skip",
            AnalyticsParameterContentType: "cont"
            ])
    }
    
    func previous() {
        if let player = self.player {
            if Int(player.currentTime) > 5 || currentSoundIndex == 0 {
                player.currentTime = 0.0
                setBackgroundAudioNowPlaying(player, sound: self.currentSound!)
                incrementPlayCount(self.currentSound!)
                Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                    AnalyticsParameterItemID: "id-goback",
                    AnalyticsParameterItemName: "go back",
                    AnalyticsParameterContentType: "cont"
                    ])
                
            } else {
                self.setUpNextSong(true, at: nil)
            }
        }
    }
    
    func didSelectSoundAt(_ i: Int, soundList: SoundList) {
        self.sounds = soundList.sounds
        self.setUpNextSong(false, at: i)
        if let tableView = self.tableView {
            tableView.reloadData()
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            setUpNextSong(false, at: nil)
        }
    }
    
    func setUpNextSong(_ didPressGoBackButton: Bool, at: Int?) {
        //stop soundplayer audio from playing over each other
        if player != nil {
            player?.pause()
            player = nil
        }
        
        DispatchQueue.main.async {
            if let temporaryFile =  self.sounds[self.currentSoundIndex].tmpFile {
                do {
                    try temporaryFile.deleteDirectory()
                    
                } catch let error {
                    print("error deleting temp file: \(error)")
                }
            }
        }
        
        if let sound = determineSoundToPlay(didPressGoBackButton, at: at) {
            updateUI(sound)
            prepareToPlaySound(sound)
            setUpAudioForNextSound()
        }
    }
    
    func setUpAudioForNextSound() {
        let nextSoundIndex = currentSoundIndex + 1
        if sounds.indices.contains(nextSoundIndex) && sounds[nextSoundIndex].audioData == nil {
            fetchAudioData(nextSoundIndex, prepareAndPlay: false)
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
    
    func prepareToPlaySound(_ sound: Sound) {
        if let audioData = sound.audioData {
            self.prepareAndPlay(audioData)
            
        } else {
            fetchAudioData(currentSoundIndex, prepareAndPlay: true)
        }
    }
    
    func updateUI(_ sound: Sound) {
        currentSound = sound
        setBackgroundAudioViews(sound)
        if let currentUser = PFUser.current() {
            self.loadLikeInfo(sound.objectId, userId: currentUser.objectId!, i: currentSoundIndex)
            
        } else {
            self.sendSoundUpdateToUI()
        }
    }
    
    func incrementPlaylistPositionAndReturnSound() -> Sound {
        self.currentSoundIndex = self.currentSoundIndex + 1
        
        if self.currentSoundIndex == sounds.count || !self.sounds.indices.contains(self.currentSoundIndex) {
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
                if prepareAndPlay {
                    self.prepareAndPlay(audioData)
                }
                self.sounds[position].audioData = audioData
            }
        }
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
        ad.secondsPlayedSinceLastAd = ad.secondsPlayedSinceLastAd + Int(player!.duration)
        UIElement().setUserDefault("secondsPlayedSinceLastAd", value: ad.secondsPlayedSinceLastAd)
    }
    
    @objc func UpdateTimer(_ timer: Timer) {
        secondsPlayed = secondsPlayed + timer.timeInterval
        
        if secondsPlayed >= 5 && !didRecordPlay {
            didRecordPlay = true
            if let currentSound = currentSound {
                incrementPlayCount(currentSound)
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
        query.getObjectInBackground(withId: sound.objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                if let plays = object["plays"] as? Double {
                    //We want to notify artists every time their song hits a milestone like 10, 20, 100, 110, etc. Best way to determine if "plays" equally divids by 10
                    let incrementedPlays = plays + 1.0
                    switch incrementedPlays {
                    case 10, 50, 100, 1000, 10000, 100000, 1000000:
                    UIElement().sendAlert("Congrats, \(sound.title!) just hit \(Int(incrementedPlays)) plays!", toUserId: sound.artist!.objectId)
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
    
    func setBackgroundAudioNowPlaying(_ player: AVAudioPlayer?, sound: Sound) {
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
        
        if let player = player {
            let cmTime = CMTime(seconds: player.currentTime, preferredTimescale: 1000000)
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(cmTime)
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        }
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func setBackgroundAudioViews(_ sound: Sound) {
        sound.artFile.getDataInBackground { (imageData: Data?, error: Error?) in
            if let error = error {
                print(error.localizedDescription)
                
            } else if let imageData = imageData {
                let image = UIImage(data:imageData)
                sound.artImage = image
                
                if (sound.artist?.name) != nil {
                    self.setBackgroundAudioNowPlaying(self.player, sound: sound)
                    
                } else {
                    self.loadUserInfoFromCloud(sound.artist!.objectId, i: self.currentSoundIndex)
                }
            }
        }
    }
    
    //mark: data
    func loadDynamicLinkSound(_ objectId: String) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                let sound = [UIElement().newSoundObject(object)]
                self.sounds = sound
                self.setUpNextSong(false, at: 0)
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
                self.setBackgroundAudioNowPlaying(self.player, sound: self.sounds[self.currentSoundIndex])
                self.sounds[i].artist?.city = user["city"] as? String
            }
        }
    }
    
    func loadLikeInfo(_ postId: String, userId: String, i: Int) {
        let query = PFQuery(className: "Like")
        query.whereKey("postId", equalTo: postId)
        query.whereKey("userId", equalTo: userId)
        query.whereKey("isRemoved", equalTo: false)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                self.sounds[i].isLiked = false
                
            } else if object != nil {
                self.sounds[i].isLiked = true
            }
            self.sendSoundUpdateToUI()
        }
    }
}

protocol PlayerDelegate {
    func selectedArtist(_ artist: Artist?)
}



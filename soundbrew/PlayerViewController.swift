//
//  PlayerViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/26/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//
//MARK: Player, View, Ads, Data

import UIKit
import SnapKit
import Parse
import Kingfisher
import AVFoundation
import MediaPlayer
import Alamofire
import SCSDKCreativeKit
import ShareInstagram
import Firebase

class PlayerViewController: UIViewController, AVAudioPlayerDelegate {

    let uiElement = UIElement()
    let color = Color()
    
    var tags = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let tagArray = UserDefaults.standard.stringArray(forKey: "tags") {
            tags = tagArray
            
            setupRemoteTransportControls()
            setUpView()
            loadSounds()
        }
    }
    
    //mark: Player
    var soundPlayer: AVAudioPlayer!
    var isSoundPlaying = false
    var playlistPosition: Int?
    
    func prepareAndPlay(_ audioData: Data) {
        var audioAsset: AVURLAsset!
        
        var soundPlayable = true

        //need audio url so can see what type of file audio is... helps get audio duration
        let audioURL = URL(string: sounds[playlistPosition!].audioURL)
        
        //convert Data to URL on disk.. AVAudioPlayer won't play sound otherwise.
        let audioFileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("\(audioURL!.lastPathComponent)")
        
        do {
            try audioData.write(to: audioFileURL, options: .atomic)
            audioAsset = AVURLAsset.init(url: audioFileURL, options: nil)
            let duration = audioAsset.duration.seconds
            self.playBackTotalTime.text = self.formatTime(duration)
            self.playBackSlider.maximumValue = Float(duration)
            
        } catch {
            print(error)
            soundPlayable = false
            isSoundPlaying = false
        }
        
        // Set up the session.
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(AVAudioSession.Category.playback,
                                    mode: .default,
                                    policy: .longForm,
                                    options: [])
            
        } catch let error {
            soundPlayable = false
            isSoundPlaying = false
            fatalError("*** Unable to set up the audio session: \(error.localizedDescription) ***")
        }
        
        // Set up the player.
        do {
            self.soundPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
            soundPlayer.delegate = self

        } catch let error {
            print("*** Unable to set up the audio player: \(error.localizedDescription) ***")
            soundPlayable = false
            isSoundPlaying = false
            //return
        }
        
        // Activate and request the route.
        do {
            try session.setActive(true)
            
        } catch let error {
            print("Unable to activate audio session:  \(error.localizedDescription)")
            soundPlayable = false
            isSoundPlaying = false
        }
            
        if !soundPlayable {
            setUpNextSong()
            
        } else {
            playNextSong()
        }
    }
    
    func playNextSong() {
        soundPlayer.play()
        isSoundPlaying = true
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTimer), userInfo: nil, repeats: true)
        
        playBackButton.setImage(UIImage(named: "pause"), for: .normal)
        self.shouldEnableSoundView(true)
        
        let sound = sounds[playlistPosition!]
        self.setCurrentSoundView(sound, i: playlistPosition!)
        
        incrementPlayCount(sound: sound)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        setUpNextSong()
    }
    
    func setUpNextSong() {
        //stop soundplayer audio from playing over each other
        if soundPlayer != nil {
            soundPlayer.pause()
            soundPlayer = nil
        }
        
        //put playback time back to zero
        timer.invalidate()
        counter = 0
        playBackSlider.value = 0
        
        let sound = incrementPlaylistPositionAndReturnSound()
        
        if let audioData = sound.audioData {
            self.prepareAndPlay(audioData)
            
        } else {
            fetchAudioData(playlistPosition!, prepareAndPlay: true)
        }
        
        let nextPlaylistPosition = playlistPosition! + 1
        if sounds.indices.contains(nextPlaylistPosition) && sounds[nextPlaylistPosition].audioData == nil {
            fetchAudioData(nextPlaylistPosition, prepareAndPlay: false)
        }
    }
    
    func incrementPlaylistPositionAndReturnSound() -> Sound {
        if let playlistPostion = self.playlistPosition {
            self.playlistPosition = playlistPostion + 1
            
        } else {
            playlistPosition = 0
        }
        
        if playlistPosition == sounds.count {
            //no sounds left, go back to zero.
            playlistPosition = 0
        }
        
        let sound = sounds[playlistPosition!]
        
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
    
    //var nowPlayingInfo = [String : Any]()
    var commandCenter = MPRemoteCommandCenter.shared()
    
    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        //let commandCenter = MPRemoteCommandCenter.shared()
        
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            if !self.isSoundPlaying {
                self.playOrPause()
                return .success
            }
            
            return .commandFailed
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.isSoundPlaying {
                self.playOrPause()
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            self.setUpNextSong()
            return .success
        }
    }
    
    func shouldEnableBackgroundAudioButtons(_ shouldEnable: Bool) {
        skipButton.isEnabled = shouldEnable
        
        commandCenter.nextTrackCommand.isEnabled = shouldEnable
        commandCenter.playCommand.isEnabled = shouldEnable
        commandCenter.pauseCommand.isEnabled = shouldEnable
    }
    
    func setBackgroundAudioNowPlaying(_ player: AVAudioPlayer, sound: Sound) {
        var nowPlayingInfo = [String : Any]()
        
        // Define Now Playing Info
        nowPlayingInfo[MPMediaItemPropertyTitle] = sound.title
        
        nowPlayingInfo[MPMediaItemPropertyArtist] = sound.artistName
        
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
    
    /*func setBackgoundAudioArtistName(_ artistName: String) {
        self.nowPlayingInfo[MPMediaItemPropertyArtist] = artistName
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }*/
    
    func playOrPause() {
        if self.isSoundPlaying {
            self.soundPlayer.pause()
            isSoundPlaying = false
            timer.invalidate()
            self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
            
        } else {
            self.soundPlayer.play()
            isSoundPlaying = true
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTimer), userInfo: nil, repeats: true)
            self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
        }
    }
    
    //mark: View
    lazy var exitButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "exit"), for: .normal)
        return button
    }()
    
    lazy var chosenTags: UILabel = {
        let label = UILabel()
        label.text = "Tags"
        label.textColor = color.black()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 15)
        return label
    }()
    
    lazy var artistName: UIButton = {
        let button = UIButton()
        button.setTitle("Artist Name", for: .normal)
        button.setTitleColor(color.black(), for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        return button
    }()
    
    lazy var verifiedCheck: UIImageView = {
        let image = UIImageView()
        return image
    }()
    
    lazy var shareButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "share"), for: .normal)
        return button
    }()
    
    lazy var songArt: UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = 3
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.backgroundColor = .white
        return image
    }()
    
    lazy var songTitle: UILabel = {
        let label = UILabel()
        label.text = "Sound Title"
        label.textColor = color.black()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 25)
       // label.textAlignment = .center
        return label
    }()
    
    lazy var songTags: UILabel = {
        let label = UILabel()
        label.text = "Tags"
        label.textColor = color.black()
       //label.textAlignment = .center
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        //label.numberOfLines = 0
        return label
    }()
    
    lazy var playbackView: UIView = {
        let view = UIView()
        view.backgroundColor = color.black()
        return view
    }()
    
    lazy var playBackSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.tintColor = .darkGray
        slider.value = 0
        slider.isEnabled = false
        return slider
    }()
    
    var counter = 00.00
    var timer = Timer()
    lazy var playBackCurrentTime: UILabel = {
        let label = UILabel()
        label.text = "0 s"
        label.textColor = color.black()
        label.font = UIFont(name: uiElement.mainFont, size: 10)
        return label
    }()
    
    lazy var playBackTotalTime: UILabel = {
        let label = UILabel()
        label.text = "0 s"
        label.textColor = color.black()
        label.font = UIFont(name: uiElement.mainFont, size: 10)
        return label
    }()
    
    lazy var playBackButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "pause"), for: .normal)
        button.isEnabled = false
        return button
    }()
    
    lazy var skipButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "skip"), for: .normal)
        button.isEnabled = false 
        return button
    }()
    
    lazy var goBackButton: UIButton = {
        let button = UIButton()
        //button.setImage(UIImage(named: "goBack"), for: .normal)
        button.setTitle("<Back", for: .normal)
        return button
    }()
    
    func setUpView() {
        self.view.backgroundColor = .white
        
        //top views
        let tagsAsString = convertArrayToString(tags)
        exitButton.setTitle(tagsAsString, for: .normal)
        exitButton.addTarget(self, action: #selector(self.didPressExitButton(_:)), for: .touchUpInside)
        self.view.addSubview(exitButton)
        exitButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self.view).offset(uiElement.topOffset + 20)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        shareButton.addTarget(self, action: #selector(didPressShareButton(_:)), for: .touchUpInside)
        self.view.addSubview(shareButton)
        shareButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self.exitButton)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        chosenTags.text = convertArrayToString(tags)
        self.view.addSubview(chosenTags)
        chosenTags.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(exitButton).offset(2)
            make.left.equalTo(self.exitButton.snp.right).offset(uiElement.elementOffset)
            make.right.equalTo(self.shareButton.snp.left).offset(-(uiElement.elementOffset))
        }
        
        //playback views
        self.view.addSubview(playbackView)
        playbackView.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(60)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
        
        self.playbackView.addSubview(playBackButton)
        self.playBackButton.addTarget(self, action: #selector(self.didPressPlayBackButton(_:)), for: .touchUpInside)
        self.view.addSubview(playBackButton)
        playBackButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(50)
            make.top.equalTo(playbackView).offset(uiElement.elementOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        self.skipButton.addTarget(self, action: #selector(self.didPressSkipButton(_:)), for: .touchUpInside)
        self.playbackView.addSubview(skipButton)
        skipButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(45)
            make.top.equalTo(playBackButton).offset(3)
            make.left.equalTo(self.playBackButton.snp.right).offset(uiElement.leftOffset)
        }
        
        self.playbackView.addSubview(playBackSlider)
        playBackSlider.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.skipButton).offset(7)
            make.left.equalTo(self.skipButton.snp.right).offset(uiElement.elementOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        //sound views
        self.view.addSubview(songArt)
        songArt.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(self.view.frame.height / 2)
            make.top.equalTo(self.exitButton.snp.bottom).offset(uiElement.topOffset)
            //make.top.equalTo(self.exitButton.snp.bottom).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(songTitle)
        songTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.songArt.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(artistName)
        artistName.addTarget(self, action: #selector(didPressArtistNameButton(_:)), for: .touchUpInside)
        artistName.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.songTitle.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            //make.right.equalTo(self.moreButton.snp.left).offset(-(uiElement.elementOffset))
        }
        
        self.view.addSubview(verifiedCheck)
        verifiedCheck.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(15)
            make.top.equalTo(self.artistName).offset(13)
            make.left.equalTo(self.artistName.snp.right).offset(uiElement.elementOffset)
            //make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(songTags)
        songTags.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.artistName.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
    }
    
    func setCurrentSoundView(_ sound: Sound, i: Int) {
        self.songTitle.text = sound.title
        self.songTags.text = convertArrayToString(sound.tags)
        
        if let artistName = sound.artistName {
            self.artistName.setTitle(artistName, for: .normal)
            self.setCurrentSoundViewImageAndbackgroundAudio(sound)
            if let artistVerified = sound.artistVerified {
                if artistVerified {
                    self.verifiedCheck.image = UIImage(named: "check")
                }
                
            } else {
                self.verifiedCheck.image = nil
            }
            
        } else {
            let placeHolder = ""
            self.artistName.setTitle(placeHolder, for: .normal)
            loadUserInfoFromCloud(sound.userId, i: i)
        }
    }
    
    func setCurrentSoundViewImageAndbackgroundAudio(_ sound: Sound) {
        self.songArt.kf.setImage(with: URL(string: sound.artURL), placeholder: UIImage(named: "appy"), options: nil, progressBlock: nil, completionHandler: {(image, error, cacheType, imageURL) in
            if error == nil {
                self.sounds[self.playlistPosition!].artImage = image
                sound.artImage = image
                self.setBackgroundAudioNowPlaying(self.soundPlayer, sound: sound)
            }
        })
    }
    
    func shouldEnableSoundView(_ shouldEnable: Bool) {
        self.playBackButton.isEnabled = shouldEnable
        self.skipButton.isEnabled = shouldEnable
    }
    
    @objc func didPressArtistNameButton(_ sender: UIButton) {
        self.showArtistSocialsAndStreams(sound: self.sounds[playlistPosition!])
    }
    
    @objc func didPressShareButton(_ sender: UIButton) {
        let alertController = UIAlertController (title: "Share this Sound" , message: "To:", preferredStyle: .actionSheet)

        let snapchatAction = UIAlertAction(title: "Snapchat", style: .default) { (_) -> Void in
            self.shareToSnapchat()
        }
        alertController.addAction(snapchatAction)
        
        let instagramAction = UIAlertAction(title: "Instagram", style: .default) { (_) -> Void in
            self.shareToInstagram()
        }
        alertController.addAction(instagramAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func didPressExitButton(_ sender: UIButton) {
        if self.soundPlayer != nil {
            self.soundPlayer.pause()
        }
        
        self.uiElement.segueToView("Main", withIdentifier: "main", target: self)
    }
    
    @objc func didPressPlayBackButton(_ sender: UIButton) {
        /*if secondsPlayedSinceLastAd > thirtyMinutesInSeconds && !isSoundPlaying {
            self.showAd()
            
        } else {
            playOrPause()
        }*/
        
        playOrPause()
    }
    
    @objc func didPressSkipButton(_ sender: UIButton) {
        self.shouldEnableSoundView(false)
        self.setUpNextSong()
    }
    
    @objc func UpdateTimer() {
        counter = counter + 0.1
        playBackCurrentTime.text = formatTime(counter)
        playBackSlider.value = Float(counter)
    }
    
    //mark: share
    let shareAppURL = "https://www.soundbrew.app/ios"
    
    func shareToSnapchat() {
        if let stickerImage = createShareableSticker() {
            let sticker = SCSDKSnapSticker(stickerImage: stickerImage)
            
            let snap = SCSDKNoSnapContent()
            snap.sticker = sticker
            snap.attachmentUrl = shareAppURL
            let api = SCSDKSnapAPI(content: snap)
            api.startSnapping(completionHandler: { (error: Error?) in
                if let error = error {
                    print("Snapchat error: \(error)")
                    
                } else {
                    self.logExternalShareEvent("Snapchat")
                }
            })
            
        } else {
            print("didn't work")
        }
    }
    
    func shareToInstagram() {
        if let stickerImage = createShareableSticker() {
            let share = ShareImageInstagram()
            
            share.postToInstagramStories(image: stickerImage, backgroundTopColorHex: "0x393939" , backgroundBottomColorHex: "0x393939", deepLink: shareAppURL)
            self.logExternalShareEvent("Instagram")
        }
    }
    
    func logExternalShareEvent(_ title: String) {
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterItemID: "id-\(title)",
            AnalyticsParameterItemName: title,
            AnalyticsParameterContentType: "cont"
            ])
    }
    
    func createShareableSticker() -> UIImage? {
       // let image: UIImage?
        
        let stickerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        stickerView.backgroundColor = .white        
        
        let songArt = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        songArt.image = self.songArt.image!
        songArt.backgroundColor = .white
        
        let songTitle = UILabel(frame: CGRect(x: 55, y: 0, width: 140, height: 20))
        songTitle.text = self.songTitle.text!
        songTitle.textColor = color.black()
        songTitle.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 12)
        
        let artistName = UILabel(frame: CGRect(x: 55, y: 15, width: 140, height: 20))
        artistName.text = self.artistName.titleLabel!.text!
        artistName.textColor = color.black()
        artistName.font = UIFont(name: uiElement.mainFont, size: 11)
        
        let listenOnLabel = UILabel(frame: CGRect(x: 55, y: 30, width: 140, height: 20))
        listenOnLabel.text = "Listening on Soundbrew"
        listenOnLabel.textColor = color.black()
        listenOnLabel.font = UIFont(name: uiElement.mainFont, size: 9)
        
        stickerView.addSubview(songArt)
        stickerView.addSubview(listenOnLabel)
        stickerView.addSubview(songTitle)
        stickerView.addSubview(artistName)
        
        UIGraphicsBeginImageContextWithOptions(stickerView.bounds.size, false, 0.0)
        stickerView.drawHierarchy(in: stickerView.bounds, afterScreenUpdates: true)
        let snapshotImageFromMyView = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        //snapshotImageFromMyView
        return snapshotImageFromMyView
    }
    
    //mark: data
    var sounds = [Sound]()
    
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
                        let songArt = (object["songArt"] as! PFFileObject).url!
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
                        
                        let newSound = Sound(objectId: object.objectId, title: title, artURL: songArt, artImage: nil, userId: userId, tags: tags, createdAt: object.createdAt, plays: playCount, audio: audioFile, audioURL: audioFile.url!, relevancyScore: relevancyScore, audioData: nil, artistName: nil, artistCity: nil, instagramHandle: nil, twitterHandle: nil, spotifyLink: nil, soundcloudLink: nil, appleMusicLink: nil, otherLink: nil, artistVerified: nil)
                        self.sounds.append(newSound)
                    }
                    
                    self.sounds.sort(by: { $0.relevancyScore > $1.relevancyScore })
                    
                    if objects.count > 0 {
                        self.setUpNextSong()
                        
                    } else {
                        self.uiElement.segueToView("Main", withIdentifier: "main", target: self)
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
                self.artistName.setTitle(artistName, for: .normal)
                self.sounds[i].artistName = artistName
                
                self.setCurrentSoundViewImageAndbackgroundAudio(self.sounds[i])
                
                self.sounds[i].artistCity = user["city"] as? String
                
                //Don't want to add blank space to social and streams... that's why we're checking.
                
                if let instagramHandle = user["instagramHandle"] as? String {
                    if !instagramHandle.isEmpty {
                        self.sounds[i].instagramHandle = "https://www.instagram.com/\(instagramHandle)"
                    }
                }
                
                if let twitterHandle = user["twitterHandle"] as? String {
                    if !twitterHandle.isEmpty {
                        self.sounds[i].twitterHandle = "https://www.twitter.com/\(twitterHandle)"
                    }
                }
                
                if let soundCloudLink = user["soundCloudLink"] as? String {
                    if !soundCloudLink.isEmpty {
                        self.sounds[i].soundcloudLink = soundCloudLink
                    }
                }
                
                if let appleMusicLink = user["appleMusicLink"] as? String {
                    if !appleMusicLink.isEmpty {
                        self.sounds[i].appleMusicLink = appleMusicLink
                    }
                }
                
                if let spotifyLink = user["spotifyLink"] as? String {
                    if !spotifyLink.isEmpty {
                        self.sounds[i].spotifyLink = spotifyLink
                    }
                }
                
                if let otherLlink = user["otherLink"] as? String {
                    if !otherLlink.isEmpty {
                        self.sounds[i].otherLink = otherLlink
                    }
                }
                
                if let artistVerified = user["artistVerified"] as? Bool {
                    self.sounds[i].artistVerified = artistVerified
                    if artistVerified {
                        self.verifiedCheck.image = UIImage(named: "check")
                        
                    } else {
                        self.verifiedCheck.image = nil
                    }
                    
                } else {
                    self.verifiedCheck.image = nil
                }
            }
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
    
    func incrementSocialAndStreamClicks(sound: Sound, socialAndStreamClick: String) {
        let query = PFQuery(className: "Click")
        query.whereKey("userId", equalTo: sound.userId)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                //can't get error code from "Error", so converting to "NSError".. Can't do "NSError" above because Parse requires "Error" be used. 
                let nsError = error as NSError
                if nsError.code == 101 {
                    //Click row for artist hasn't been created yet. create one.
                    let newClickRow = PFObject(className: "Click")
                    newClickRow["userId"] = sound.userId
                    newClickRow[socialAndStreamClick] = 1
                    newClickRow.saveEventually()
                }
                
            } else if let object = object {
                object.incrementKey(socialAndStreamClick)
                object.saveEventually()
            }
        }
    }
    
    //MARK: mich
    func convertArrayToString(_ array: Array<String>) -> String{
        var text = ""
        for i in 0..<array.count {
            if i == 0 {
                text = array[i]
                
            } else {
                text = "\(text), \(array[i])"
            }
        }
        
        return text
    }
    
    func formatTime(_ durationInSeconds: Double ) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        
        let formattedString = formatter.string(from: durationInSeconds)!
        
        return formattedString
    }
    
    func showArtistSocialsAndStreams(sound: Sound) {
        let alertController = UIAlertController (title: sound.artistName , message: sound.artistCity, preferredStyle: .actionSheet)
        
        var socialsAndStreams = [String]()
        if let igHandle = sound.instagramHandle {
            socialsAndStreams.append(igHandle)
        }
        
        if let twitterHandle = sound.twitterHandle {
            socialsAndStreams.append(twitterHandle)
        }
        
        if let soundcloudLink = sound.soundcloudLink {
            socialsAndStreams.append(soundcloudLink)
        }
        
        if let spotifyLink = sound.spotifyLink {
            socialsAndStreams.append(spotifyLink)
        }
        
        if let appleMusicLink = sound.appleMusicLink {
            socialsAndStreams.append(appleMusicLink)
        }
        
        if let otherLink = sound.otherLink {
            socialsAndStreams.append(otherLink)
        }
        
        for socialAndStream in socialsAndStreams {
            let settingsAction = UIAlertAction(title: socialAndStream, style: .default) { (_) -> Void in
                guard let socialAndStreamURL = URL(string: socialAndStream) else {
                    return
                }
                
                if UIApplication.shared.canOpenURL(socialAndStreamURL) {
                    UIApplication.shared.open(socialAndStreamURL, completionHandler: { (success) in
                        if success {
                            var socialAndStreamToIncrement: String!
                            if let host = socialAndStreamURL.host {
                                switch host {
                                case "www.instagram.com", "instagram.com":
                                    socialAndStreamToIncrement = "instagramClicks"
                                    break
                                    
                                case "www.twitter.com", "twitter.com":
                                    socialAndStreamToIncrement = "twitterClicks"
                                    break
                                    
                                case "open.spotify.com", "www.spotify.com", "spotify.com":
                                    socialAndStreamToIncrement = "spotifyClicks"
                                    break
                                    
                                case "applemusic.com", "itunes.apple.com", "www.applemusic.com":
                                    socialAndStreamToIncrement = "appleMusicClicks"
                                    break
                                    
                                case "soundcloud.com", "www.soundcloud.com", "m.soundcloud.com":
                                    socialAndStreamToIncrement = "soundcloudClicks"
                                    break
                                    
                                default:
                                    socialAndStreamToIncrement = "otherLinkClicks"
                                    break
                                }
                            }
                            
                            self.incrementSocialAndStreamClicks(sound: sound, socialAndStreamClick: socialAndStreamToIncrement)
                        }
                    })
                }
            }
            
            alertController.addAction(settingsAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func sendAlert(_ message: String, toUserId: String) {
        Alamofire.request("https://soundbrew.herokuapp.com/notifications/alertUser", method: .post, parameters: ["message": message, "userId": toUserId], encoding: JSONEncoding.default).validate().response{response in
        }
    }
}

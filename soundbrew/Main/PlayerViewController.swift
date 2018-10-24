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
import GoogleMobileAds

class PlayerViewController: UIViewController, AVAudioPlayerDelegate, GADInterstitialDelegate {

    let uiElement = UIElement()
    let color = Color()
    
    var tags = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let tagArray = UserDefaults.standard.stringArray(forKey: "tags") {
            tags = tagArray
            self.title = convertArrayToString(tags)
            
            self.secondsPlayed = UserDefaults.standard.integer(forKey: "secondsPlayed")
            
            setUpView()
            loadSounds()
            setUpAds()
            setupRemoteTransportControls()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UserDefaults.standard.set(secondsPlayed, forKey: "secondsPlayed")
    }
    
    //mark: Player
    var soundPlayer: AVAudioPlayer!
    var audioAsset: AVURLAsset!
    var secondsPlayed = 0
    var thirtyMinutesInSeconds = 1800
    var isSoundPlaying = false
    var playlistPosition: Int?
    
    func prepareAndPlay(_ audioData: Data) {
        var soundPlayable = true
        
        //convert Data to URL on disk.. AVAudioPlayer won't play sound otherwise.
        let audioFileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("audio.mp3")
        
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
            
        } else if soundPlayable && secondsPlayed < thirtyMinutesInSeconds {
            playNextSong()
            
        } else if soundPlayable && secondsPlayed > thirtyMinutesInSeconds {
            self.soundPlayer.pause()
            shouldEnableButtons(false)
            playBackButton.setImage(UIImage(named: "play"), for: .normal)
        }
    }
    
    func playNextSong() {
        soundPlayer.play()
        isSoundPlaying = true
        
        secondsPlayed = secondsPlayed + Int(audioAsset.duration.seconds)
        print(secondsPlayed)
        timer.invalidate()
        counter = 0
        playBackSlider.value = 0
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTimer), userInfo: nil, repeats: true)
        
        playBackButton.setImage(UIImage(named: "pause"), for: .normal)
        
        setupBackgroundAudioNowPlaying(audioAsset, player: soundPlayer)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        setUpNextSong()
    }
    
    func setUpNextSong() {
        let sound = incrementPlaylistPositionAndReturnSound()

        self.setCurrentSoundView(sound, i: playlistPosition!)
        
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
                if prepareAndPlay {
                    self.prepareAndPlay(audioData)
                }
                self.sounds[position].audioData = audioData
            }
        }
    }
    
    var nowPlayingInfo = [String : Any]()
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
    
    func shouldEnableButtons(_ shouldEnable: Bool) {
        skipButton.isEnabled = shouldEnable
        
        commandCenter.nextTrackCommand.isEnabled = shouldEnable
        commandCenter.playCommand.isEnabled = shouldEnable
        commandCenter.pauseCommand.isEnabled = shouldEnable
    }
    
    func setupBackgroundAudioNowPlaying(_ playerItem: AVURLAsset, player: AVAudioPlayer) {
        // Define Now Playing Info
        nowPlayingInfo[MPMediaItemPropertyTitle] = songtitle.text!
        
        let cmTime = CMTime(seconds: player.currentTime, preferredTimescale: 1000000)
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(cmTime)
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = playerItem.duration.seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func setBackgoundAudioArtistName(_ artistName: String) {
        self.nowPlayingInfo[MPMediaItemPropertyArtist] = artistName
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
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
    
    //mark: Ads
    var interstitial: GADInterstitial!
    var productionKey = "ca-app-pub-9150756002517285/6848154898"
    var testKey = "ca-app-pub-3940256099942544/4411468910"
    
    func setUpAds() {
        interstitial = createAndLoadInterstitial()
    }
    
    func createAndLoadInterstitial() -> GADInterstitial {
        let interstitial = GADInterstitial(adUnitID: testKey)
        interstitial.delegate = self
        let request = GADRequest()
        request.testDevices = ["da8e23242ac0690b867b0fe94ba2f2a7"]
        interstitial.load(request)
        return interstitial
    }
    
    func showAd() {
        if interstitial.isReady {
            DispatchQueue.main.async {
                self.interstitial.present(fromRootViewController: self)
            }
            
        //add wasn't ready, so give ad time to load.
        } else if sounds.count == 0 {
            loadSounds()
                
        } else {
            playNextSong()
            self.shouldEnableButtons(true)
        }
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        interstitial = createAndLoadInterstitial()
    }
    
    /// Tells the delegate an ad request succeeded.
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
    }
    
    /// Tells the delegate an ad request failed.
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
    }
    
    /// Tells the delegate that an interstitial will be presented.
    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        self.soundPlayer.pause()
    }
    
    /// Tells the delegate the interstitial is to be animated off the screen.
    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
        secondsPlayed = 0
        playNextSong()
        shouldEnableButtons(true)
    }
    
    /// Tells the delegate that a user click will open another app
    /// (such as the App Store), backgrounding the current app.
    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
    }
    
    //mark: View
    lazy var exitButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "exit_white"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()
    
    lazy var chosenTags: UILabel = {
        let label = UILabel()
        label.text = "Tags"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 15)
        return label
    }()
    
    lazy var artistName: UIButton = {
        let button = UIButton()
        button.setTitle("Artist Name", for: .normal)
        button.setTitleColor(color.primary(), for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        return button
    }()
    
    lazy var songArt: UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = 3
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.backgroundColor = .black
        return image
    }()
    
    lazy var songtitle: UILabel = {
        let label = UILabel()
        label.text = "Sound Title"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 20)
        label.textAlignment = .center
        return label
    }()
    
    lazy var songTags: UILabel = {
        let label = UILabel()
        label.text = "Tags"
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 15)
        return label
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
        label.textColor = .white
        label.font = UIFont(name: uiElement.mainFont, size: 10)
        return label
    }()
    
    lazy var playBackTotalTime: UILabel = {
        let label = UILabel()
        label.text = "0 s"
        label.textColor = .white
        label.font = UIFont(name: uiElement.mainFont, size: 10)
        return label
    }()
    
    lazy var playBackButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "pause"), for: .normal)
        return button
    }()
    
    lazy var skipButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "skip"), for: .normal)
        return button
    }()
    
    lazy var goBackButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "goBack"), for: .normal)
        return button
    }()
    
    func setUpView() {
        self.view.backgroundColor = color.black()
        
        exitButton.addTarget(self, action: #selector(self.didPressExitButton(_:)), for: .touchUpInside)
        self.view.addSubview(exitButton)
        exitButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self.view).offset(uiElement.topOffset + 10)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        chosenTags.text = convertArrayToString(tags)
        self.view.addSubview(chosenTags)
        chosenTags.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(exitButton).offset(2)
            make.left.equalTo(self.exitButton.snp.right).offset(uiElement.elementOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(songArt)
        songArt.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(self.view.frame.height / 2)
            make.top.equalTo(self.exitButton.snp.bottom).offset(uiElement.topOffset)
            //make.top.equalTo(self.exitButton.snp.bottom).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(songtitle)
        songtitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.songArt.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        artistName.addTarget(self, action: #selector(self.didPressArtistNameButton(_:)), for: .touchUpInside)
        self.view.addSubview(artistName)
        artistName.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.songtitle.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(songTags)
        songTags.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.artistName.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(playBackSlider)
        playBackSlider.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.songTags.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(playBackCurrentTime)
        playBackCurrentTime.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.playBackSlider.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        self.view.addSubview(playBackTotalTime)
        playBackTotalTime.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(playBackCurrentTime)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.playBackButton.addTarget(self, action: #selector(self.didPressPlayBackButton(_:)), for: .touchUpInside)
        self.view.addSubview(playBackButton)
        playBackButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(65)
            make.top.equalTo(playBackTotalTime.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(self.view).offset((self.view.frame.width / 2) - CGFloat(35))
        }
        
        self.skipButton.addTarget(self, action: #selector(self.didPressSkipButton(_:)), for: .touchUpInside)
        self.view.addSubview(skipButton)
        skipButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(40)
            make.top.equalTo(playBackButton).offset(10)
            make.left.equalTo(self.playBackButton.snp.right).offset(uiElement.leftOffset)
        }        
    }
    
    func setCurrentSoundView(_ sound: Sound, i: Int) {
        self.songtitle.text = sound.title
        
        self.songTags.text = convertArrayToString(sound.tags)
        if let artistName = sound.artistName {
            self.artistName.setTitle(artistName, for: .normal)
            self.setBackgoundAudioArtistName(artistName)
            
        } else {
            let placeHolder = ""
            self.artistName.setTitle(placeHolder, for: .normal)
            self.setBackgoundAudioArtistName(placeHolder)
            loadUserInfoFromCloud(sound.userId, i: i)
        }
        
        self.songArt.kf.setImage(with: URL(string: sound.art), placeholder: UIImage(named: "appy"), options: nil, progressBlock: nil, completionHandler: {(image, error, cacheType, imageURL) in
            if error == nil {
                if let backgroundAudioArtwork = image {
                    self.nowPlayingInfo[MPMediaItemPropertyArtwork] =
                        MPMediaItemArtwork(boundsSize: backgroundAudioArtwork.size) { size in
                            return backgroundAudioArtwork
                    }
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
                }
            }
            })
    }
    
    @objc func didPressArtistNameButton(_ sender: UIButton) {
        self.showArtistSocialsAndStreams(sound: self.sounds[playlistPosition!])
    }
    
    @objc func didPressExitButton(_ sender: UIButton) {
        self.soundPlayer.pause()
        self.uiElement.segueToView("Main", withIdentifier: "main", target: self)
    }
    
    @objc func didPressPlayBackButton(_ sender: UIButton) {
        if secondsPlayed > thirtyMinutesInSeconds && !isSoundPlaying {
            self.showAd()
            
        } else {
            playOrPause()
        }
    }
    
    @objc func didPressSkipButton(_ sender: UIButton) {
        self.setUpNextSong()
    }
    
    @objc func UpdateTimer() {
        counter = counter + 0.1
        playBackCurrentTime.text = formatTime(counter)
        playBackSlider.value = Float(counter)
    }
    
    //mark: data
    var sounds = [Sound]()
    
    func loadSounds() {
        let query = PFQuery(className: "Post")
        query.whereKey("tags", containedIn: tags)
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let title = object["title"] as! String
                        let audioFile = object["audioFile"] as! PFFile
                        let songArt = (object["songArt"] as! PFFile).url!
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
                        
                        let newSound = Sound(objectId: object.objectId, title: title, art: songArt, userId: userId, tags: tags, createdAt: object.createdAt, plays: playCount, audio: audioFile, relevancyScore: relevancyScore, audioData: nil, artistName: nil, artistCity: nil, instagramHandle: nil, twitterHandle: nil, spotifyLink: nil, soundcloudLink: nil, appleMusicLink: nil, otherLink: nil)
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
                self.setBackgoundAudioArtistName(artistName ?? "Artist")
                self.sounds[i].artistName = artistName

                self.sounds[i].artistCity = user["city"] as? String
                
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
                    UIApplication.shared.open(socialAndStreamURL, completionHandler: nil)
                }
            }
            alertController.addAction(settingsAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}

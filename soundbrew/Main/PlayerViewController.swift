//
//  PlayerViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/26/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit
import Parse
import Kingfisher
import AVFoundation

class PlayerViewController: UIViewController, AVAudioPlayerDelegate {

    let uiElement = UIElement()
    let color = Color()
    
    var tags = [String]()
    
    var sounds = [Sound]()
    var soundPlayer: AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = convertArrayToString(tags)
        setUpView()
        loadSounds()
    }
    
    //mark: Player
    var isAudioPlaying = false
    var playlistPosition: Int?
    
    func prepareAndPlay(_ audioData: Data) {
        var soundPlayable = true
        
        //convert Data to URL on disk.. AVAudioPlayer won't play sound otherwise.
        let audioFileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("audio.mp3")
        
        do {
            try audioData.write(to: audioFileURL, options: .atomic)
            
        } catch {
            print(error)
            self.isAudioPlaying = false
            soundPlayable = false
        }
        
        // Set up the session.
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(AVAudioSession.Category.playback,
                                    mode: .default,
                                    policy: .longForm,
                                    options: [])
            
        } catch let error {
            self.isAudioPlaying = false
            soundPlayable = false
            fatalError("*** Unable to set up the audio session: \(error.localizedDescription) ***")
        }
        
        // Set up the player.
        do {
            self.soundPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
            
        } catch let error {
            print("*** Unable to set up the audio player: \(error.localizedDescription) ***")
            self.isAudioPlaying = false
            soundPlayable = false
            //return
        }
        
        // Activate and request the route.
        do {
            try session.setActive(true)
            
        } catch let error {
            print("Unable to activate audio session:  \(error.localizedDescription)")
            self.isAudioPlaying = false
            soundPlayable = false
        }
            
        // Play the audio file.
        if soundPlayable {
            self.soundPlayer.play()
            
        } else {
            self.setUpNextSong()
        }
    }
    
    func setUpNextSong() {
        let sound = incrementPlaylistPositionAndReturnSound()
        let tagString = self.convertArrayToString(sound.tags)
        
        self.setCurrentSoundView(sound.title, soundArt: sound.art, soundTags: tagString, userId: sound.userId)
        
        if let audioData = sound.audioData {
            self.prepareAndPlay(audioData)
            
        } else {
            sound.audio.getDataInBackground {
                (audioData: Data?, error: Error?) -> Void in
                if let error = error?.localizedDescription {
                    print(error)
                    
                } else if let audioData = audioData {
                    self.prepareAndPlay(audioData)
                }
            }
        }
        
        if sounds.indices.contains(playlistPosition! + 1) {
            fetchNextSoundAudioData(playlistPosition! + 1)
        }
        
        self.isAudioPlaying = true
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
    
    func fetchNextSoundAudioData(_ position: Int) {
        self.sounds[position].audio.getDataInBackground {
            (audioData: Data?, error: Error?) -> Void in
            if let error = error?.localizedDescription {
                print(error)
                
            } else if let audioData = audioData {
                self.sounds[position].audioData = audioData
            }
        }
    }
    
    //mark: View
    lazy var artistName: UILabel = {
        let label = UILabel()
        label.text = "Artist Name"
        label.textColor = .white
        //label.textAlignment = .center
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        return label
    }()
    
    lazy var songArt: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "musicNote")
        image.layer.cornerRadius = 3
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        return image
    }()
    
    lazy var songtitle: UILabel = {
        let label = UILabel()
        label.text = "Dallas Strong"
        label.textColor = .white
        //label.textAlignment = .center
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        return label
    }()
    
    lazy var songTags: UILabel = {
        let label = UILabel()
        label.text = "Dallas, LoFi, Trap, Henny"
        label.textColor = color.primary()
        label.textAlignment = .center
        label.font = UIFont(name: uiElement.mainFont, size: 15)
        return label
    }()
    
    lazy var playBackSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.tintColor = .darkGray
        slider.value = 33
       //
        //slider.isEnabled = false
        return slider
    }()
    
    lazy var playBackCurrentTime: UILabel = {
        let label = UILabel()
        label.text = "1.20"
        label.textColor = .white
        label.font = UIFont(name: uiElement.mainFont, size: 10)
        return label
    }()
    
    lazy var playBackTotalTime: UILabel = {
        let label = UILabel()
        label.text = "3.58"
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
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        self.view.addSubview(songArt)
        songArt.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(350)
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(songtitle)
        songtitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.songArt.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
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
            make.top.equalTo(self.songTags.snp.bottom).offset(uiElement.topOffset)
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
        
        self.view.addSubview(goBackButton)
        goBackButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(50)
            make.top.equalTo(playBackTotalTime.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset + 50)
        }
        
        self.playBackButton.addTarget(self, action: #selector(self.didPressPlayBackButton(_:)), for: .touchUpInside)
        self.view.addSubview(playBackButton)
        playBackButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(75)
            make.top.equalTo(goBackButton).offset(-10)
            make.left.equalTo(self.goBackButton.snp.right).offset(uiElement.leftOffset + 20)
        }
        
        self.skipButton.addTarget(self, action: #selector(self.didPressSkipButton(_:)), for: .touchUpInside)
        self.view.addSubview(skipButton)
        skipButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(50)
            make.top.equalTo(goBackButton)
            make.right.equalTo(self.view).offset(uiElement.rightOffset - 50)
        }        
    }
    
    func setCurrentSoundView(_ title: String, soundArt: String, soundTags: String, userId: String ) {
        self.songtitle.text = title
        self.songArt.kf.setImage(with: URL(string: soundArt))
        self.songTags.text = soundTags
        loadUserInfoFromCloud(userId)
    }
    
    @objc func didPressBackButton(_ sender: UIButton) {
        
    }
    
    @objc func didPressPlayBackButton(_ sender: UIButton) {
        if isAudioPlaying {
            self.soundPlayer.pause()
            self.isAudioPlaying = false
            self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
            
        } else {
            self.soundPlayer.play()
            self.isAudioPlaying = true
            self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
        }
    }
    
    @objc func didPressSkipButton(_ sender: UIButton) {
        self.setUpNextSong()
    }
    
    //mark: data
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
                        
                        let newSound = Sound(objectId: object.objectId, title: title, art: songArt, userId: userId, tags: tags, createdAt: object.createdAt, plays: playCount, audio: audioFile, relevancyScore: relevancyScore, audioData: nil)
                        self.sounds.append(newSound)
                    }
                    
                    self.sounds.sort(by: { $0.relevancyScore > $1.relevancyScore })
                    
                    if !self.isAudioPlaying {
                        self.setUpNextSong()
                        self.isAudioPlaying = true
                    }
                }
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func loadUserInfoFromCloud(_ userId: String) {
        let query = PFQuery(className:"_User")
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                self.artistName.text = user["artistName"] as? String
                //self.artistCity.text = user["city"] as? String
                /*if let userImageFile = user["userImage"] as? PFFile {
                 
                 }*/
                
                /*if let instagramHandle = user["instagramHandle"] as? String {
                 if !instagramHandle.isEmpty {
                 self.socialsAndStreams.append("https://www.instagram.com/\(instagramHandle)")
                 self.socialsAndStreamImages.append("ig_logo")
                 }
                 }
                 
                 if let twitterHandle = user["twitterHandle"] as? String {
                 if !twitterHandle.isEmpty {
                 self.socialsAndStreams.append("https://www.twitter.com/\(twitterHandle)")
                 self.socialsAndStreamImages.append("twitter_logo")
                 }
                 }
                 
                 if let soundCloudLink = user["soundCloudLink"] as? String {
                 if !soundCloudLink.isEmpty {
                 self.socialsAndStreams.append(soundCloudLink)
                 self.socialsAndStreamImages.append("soundcloud_logo")
                 }
                 }
                 
                 if let appleMusicLink = user["appleMusicLink"] as? String {
                 if !appleMusicLink.isEmpty {
                 self.socialsAndStreams.append(appleMusicLink)
                 self.socialsAndStreamImages.append("appleMusic_logo")
                 }
                 }
                 
                 if let spotifyLink = user["spotifyLink"] as? String {
                 if !spotifyLink.isEmpty {
                 self.socialsAndStreams.append(spotifyLink)
                 self.socialsAndStreamImages.append("spotify_logo")
                 }
                 }
                 
                 if let otherLlink = user["otherLink"] as? String {
                 if !otherLlink.isEmpty {
                 self.socialsAndStreams.append(otherLlink)
                 self.socialsAndStreamImages.append("link_logo")
                 }
                 }*/
                
                //self.tableView.reloadData()
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

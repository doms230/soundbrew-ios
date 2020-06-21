//
//  PlayerV2ViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/18/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import Kingfisher
import Parse
import AppCenter

class PlayerV2ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let uiElement = UIElement()
    let color = Color()
    
    var playerDelegate: PlayerDelegate?
    var tagDelegate: TagDelegate?
    
    var player = Player.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        setupNotificationCenter()
        setupTopView()
        setUpTableView()
    }
    
    func setupNotificationCenter(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSoundUpdate), name: NSNotification.Name(rawValue: "setSound"), object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    lazy var dismissButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "dismiss"), for: .normal)
        button.addTarget(self, action: #selector(self.didPressDismissbutton(_:)), for: .touchUpInside)
        button.isOpaque = true
        return button
    }()
    @objc func didPressDismissbutton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    lazy var appTitle: UILabel = {
        let label = UILabel()
        label.text = "Soundbrew"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 15)
        label.textAlignment = .center
        label.isOpaque = true
        return label
    }()
    
    func setupTopView() {
        self.view.addSubview(self.dismissButton)
        self.dismissButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        self.view.addSubview(self.appTitle)
        self.appTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(dismissButton)
            make.centerX.equalTo(self.view)
        }
    }
    
    //MARK: Tableview
    var tableView: UITableView!
    let playerReuse = "playerReuse"
    let soundStatsReuse = "soundStatsReuse"
    let commentReuse = "commentReuse"
    let noSoundsReuse = "noSoundsReuse"
    let searchProfileReuse = "searchProfileReuse"
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        self.tableView.register(PlayerTableViewCell.self, forCellReuseIdentifier: self.playerReuse)
        self.tableView.register(PlayerTableViewCell.self, forCellReuseIdentifier: self.soundStatsReuse)
        tableView.separatorStyle = .none
        tableView.backgroundColor = color.black()
        tableView.frame = self.view.bounds
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.dismissButton.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
        
        let player = Player.sharedInstance
        player.tableView = tableView
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        //section 0: player view
        //section 1: like count and play count
        //section 2: comments
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return playerCell()
      /*  if indexPath.section == 0 {
            return playerCell()
        } else {
           // return soundStatsCell()
        }*/
        /*switch indexPath.section {
        case 0:
            return playerCell()
            
        case 1:
            return soundStatsCell()
            
        case 2:
            break
            
        default:
            break
        }*/
    }
        
    //mark: sound
    @objc func didReceiveSoundUpdate(){
        self.tableView.reloadData()
    }
    
    @objc func didBecomeActive() {
        if self.viewIfLoaded?.window != nil {
            player.target = self
        }
    }
    
    //mark: player view
    var playBackCurrentTime: UILabel!
    var playBackTotalTime: UILabel!
    var playBackSlider: UISlider!
    var playBackButton: UIButton!
    var likeSoundButton: UIButton!
    var shareSoundButton: UIButton!
    var timer = Timer()

    func playerCell() -> PlayerTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: playerReuse) as! PlayerTableViewCell
        cell.backgroundColor = .black
        cell.selectionStyle = .none
        
        if let sound = player.currentSound {
            player.target = self
            
            cell.soundArt.kf.setImage(with: URL(string: sound.artFile?.url  ?? ""), placeholder: UIImage(named: "sound"))
            //making constraints here to get view frame
            cell.soundArt.snp.makeConstraints { (make) -> Void in
                make.width.height.equalTo((self.view.frame.height / 2) - 100)
            }
                    
            playBackCurrentTime = cell.playBackCurrentTime
            playBackTotalTime = cell.playBackTotalTime
            cell.playBackSlider.addTarget(self, action: #selector(sliderValueDidChange(_:)), for: .valueChanged)
            playBackSlider = cell.playBackSlider
            if let duration = self.player.player?.duration {
                self.playBackTotalTime.text = self.uiElement.formatTime(Double(duration))
                playBackSlider.maximumValue = Float(duration)
                self.startTimer()
            }
            
            playBackButton = cell.playBackButton
            playBackButton.addTarget(self, action: #selector(self.didPressPlayBackButton(_:)), for: .touchUpInside)
            if player.player != nil, player.player!.isPlaying  {
                self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
            } else {
                self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
            }
            
            cell.goBackButton.addTarget(self, action: #selector(didPressGoBackButton(_:)), for: .touchUpInside)
            //making constraints here to get view frame
            cell.goBackButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(45)
                make.centerY.equalTo(cell.playBackButton)
                make.left.equalTo(cell).offset(self.view.frame.width * 0.25)
            }
            
            cell.skipButton.addTarget(self, action: #selector(self.didPressSkipButton(_:)), for: .touchUpInside)
            //making constraints here to get view frame
            cell.skipButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(45)
                make.centerY.equalTo(cell.playBackButton)
                make.right.equalTo(cell).offset(-self.view.frame.width * 0.25)
            }
            cell.likeSoundButton.addTarget(self, action: #selector(self.didPressLikeButton(_:)), for: .touchUpInside)
            self.likeSoundButton = cell.likeSoundButton
            
            let like = Like.shared
            like.likeSoundButton = self.likeSoundButton
            like.target = self
            
            if let likeSound = like.sound {
                if sound.objectId != likeSound.objectId {
                    like.checkIfUserLikedSong(sound)
                    
                } else if likeSound.currentUserTipDate != nil {
                    self.likeSoundButton.isEnabled = false
                    self.likeSoundButton.setImage(UIImage(named: "sendTipColored"), for: .normal)
                } else {
                    self.likeSoundButton.isEnabled = true
                    self.likeSoundButton.setImage(UIImage(named: "sendTip"), for: .normal)
                }
                 
            } else {
                like.checkIfUserLikedSong(sound)
            }
            
            like.sound = sound
            
            
            cell.shareButton.addTarget(self, action: #selector(didPressShareButton(_:)), for: .touchUpInside)
            self.shareSoundButton = cell.shareButton
        }
        
        return cell
    }
    
    @objc func didPressPlayBackButton(_ sender: UIButton) {
        if let soundPlayer = player.player {
            if soundPlayer.isPlaying {
                player.pause()
                timer.invalidate()
                self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
            } else {
                player.play()
                startTimer()
                self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
            }
        }
    }
    
    @objc func didPressGoBackButton(_ sender: UIButton) {
        player.previous()
    }
    
    @objc func didPressSkipButton(_ sender: UIButton) {
        player.next()
    }
    
    @objc func didPressLikeButton(_ sender: UIButton) {
        sender.setImage(UIImage(named: "sendTipColored"), for: .normal)
        sender.isEnabled = false
        let like = Like.shared
        like.target = self
        like.sound = self.player.currentSound
        like.likeSoundButton = sender
        like.newLike()
    }
    
    @objc func didPressShareButton(_ sender: UIButton) {
        if let sound = self.player.currentSound {
            self.uiElement.showShareOptions(self, sound: sound)
        }
    }
    
    @objc func sliderValueDidChange(_ sender: UISlider) {
        if let soundPlayer = player.player {
            playBackCurrentTime.text = self.uiElement.formatTime(Double(sender.value))
            soundPlayer.currentTime = TimeInterval(sender.value)
            player.setBackgroundAudioNowPlaying()
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTimer(_:)), userInfo: nil, repeats: true)
    }
    @objc func UpdateTimer(_ timer: Timer) {
        if let currentTime = player.player?.currentTime {
            playBackCurrentTime.text = "\(self.uiElement.formatTime(Double(currentTime)))"
            playBackSlider.value = Float(currentTime)
        }
    }
    
    //Sound Stats
    /*func soundStatsCell() -> PlayerTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: soundStatsReuse) as! PlayerTableViewCell
        cell.backgroundColor = .black
        cell.selectionStyle = .none
        if let sound = player.currentSound {
            cell.likesCountButton.setTitle("\(sound.tipCount ?? 0) likes", for: .normal)
            cell.playCountButton.setTitle("\(sound.playCount ?? 0) plays", for: .normal)
        }
        
        return cell
    }*/
}

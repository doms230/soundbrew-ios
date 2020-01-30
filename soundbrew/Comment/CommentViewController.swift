//
//  CommentViewController.swift
//  soundbrew
//
//  Created by Dominic Smith on 1/28/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import MessageViewController
import Parse
import Kingfisher
import AppCenterAnalytics
import SnapKit

class CommentViewController: MessageViewController, UITableViewDataSource, UITableViewDelegate {
    
    var comments = [Comment?]()
    let uiElement = UIElement()
    let color = Color()
    
    var sound: Sound?
    var atTime: Float?
    let player = Player.sharedInstance
    var selectedArtist: Artist?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
         setupNav()
        setUpTableView()
        if let soundId = sound?.objectId {
            loadComments(soundId)
        }
    }
    
    lazy var dividerLine: UIView = {
        let line = UIView()
        line.layer.borderWidth = 1
        line.layer.borderColor = UIColor.darkGray.cgColor
        return line
    }()
    
    lazy var appTitle: UILabel = {
        let label = UILabel()
        label.text = "Soundbrew"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 15)
        label.textAlignment = .center
        return label
    }()
    
    lazy var exitButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "dismiss"), for: .normal)
        button.addTarget(self, action: #selector(self.didPressExitButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressExitButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "Exit Button", "Description": "User Exited PlayerViewController."])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showProfile":
            let viewController = segue.destination as! ProfileViewController
            viewController.profileArtist = selectedArtist
            
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
            break
                        
        default:
            break
        }
    }
    
    func setupNotificationCenter(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSoundUpdate), name: NSNotification.Name(rawValue: "setSound"), object: nil)
    }
    
    @objc func didReceiveSoundUpdate() {
        if let sound = self.player.currentSound {
            self.sound = sound
            self.playBackSlider = nil
            if let objectId = sound.objectId {
                loadComments(objectId)
            }
        }
    }
    
    func setPlaybackSliderValue() {
        if let duration = self.player.player?.duration {
            if let playBackSlider = self.playBackSlider {
                playBackSlider.maximumValue = Float(duration)
                self.startTimer()
            }
        }
    }
    
    //mark: topview
    func setupNav() {
        self.view.addSubview(exitButton)
        exitButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self.view).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        self.view.addSubview(appTitle)
        appTitle.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(exitButton)
        }
        
        self.view.addSubview(dividerLine)
        dividerLine.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(0.5)
            make.top.equalTo(appTitle.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
    }
    
    //mark: MessageView
    func setUpMessageView() {
        borderColor = .lightGray
        messageView.inset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        messageView.font = UIFont(name: uiElement.mainFont, size: 17)
        var placeHolderText = "Add comment"
        if let atTime = self.atTime {
            placeHolderText = "Add comment at \(self.uiElement.formatTime(Double(atTime)))"
        }
        
        messageView.textView.placeholderText = placeHolderText
        messageView.textView.placeholderTextColor = .darkGray
        
        messageView.setButton(title: "Send", for: .normal, position: .right)
        messageView.addButton(target: self, action: #selector(didPressRightButton(_:)), position: .right)
        messageView.rightButtonTint = color.blue()
        
        messageAutocompleteController.tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: commentReuse)
        messageAutocompleteController.tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        messageAutocompleteController.tableView.dataSource = self
        messageAutocompleteController.tableView.delegate = self
        setup(scrollView: tableView)
    }
    
    @objc func didPressRightButton(_ sender: UIButton) {
        if let artist = Customer.shared.artist, let objectId = self.sound?.objectId, let atTime = self.atTime {
            addNewComment(messageView.text, atTime: Double(atTime), postId: objectId)
            let comment = Comment(objectId: nil, artist: artist, text: messageView.text, atTime: Float(atTime), createdAt: Date())
            self.comments.append(comment)
            messageView.text = ""
            messageView.textView.resignFirstResponder()
            self.tableView.reloadData()
            tableView.scrollToRow(
                at: IndexPath(row: comments.count - 1, section: 0),
                at: .bottom,
                animated: true
            )
        }
    }
    
    //mark: Tableview
    let tableView = UITableView()
    let commentReuse = "commentReuse"
    let noSoundsReuse = "noSoundsReuse"
    let miniPlayerReuse = "miniPlayerReuse"
    func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: commentReuse)
        tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: miniPlayerReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        tableView.backgroundColor = color.black()
        self.tableView.separatorStyle = .none
        self.view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        
        if comments.count == 0 {
            return 1
        }
        
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return miniPlayerCell()
        } else {
            if self.comments.count == 0 {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
                cell.backgroundColor = color.black()
                cell.headerTitle.text = "No comments yet. Be the first, and comment below. 😎"
                return cell
                
            } else {
                return commentCell(indexPath)
            }
        }
    }
    
    func miniPlayerCell() -> CommentTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: miniPlayerReuse) as!
        CommentTableViewCell
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        if let sound = self.sound {
            if let player = player.player {
               /* self.playBackSlider = cell.playBackSlider
                self.setPlaybackSliderValue()*/
                
                cell.playBackButton.addTarget(self, action: #selector(self.didPressPlayBackButton(_:)), for: .touchUpInside)
                if player.isPlaying {
                    cell.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
                    
                } else {
                    cell.playBackButton.setImage(UIImage(named: "play"), for: .normal)
                }
            }
            
            if let image = sound.artURL {
                cell.songArt.kf.setImage(with: URL(string: image))
            } else {
                cell.songArt.image = UIImage(named: "sound")
            }
            
            if let title = sound.title {
                cell.songTitle.text = title
            } else {
                cell.songTitle.text = "Sound Title"
            }
            
            
            if let name = sound.artist?.name {
                cell.artistName.text = name
                
            } else {
                cell.artistName.text = "Artist Name"
            }
        }
        
        return cell
    }
    
    @objc func didPressPlayBackButton(_ sender: UIButton) {
        if let soundPlayer = player.player {
            if soundPlayer.isPlaying {
                player.pause()
                timer.invalidate()
                sender.setImage(UIImage(named: "play"), for: .normal)
                
            } else {
                player.play()
                startTimer()
                sender.setImage(UIImage(named: "pause"), for: .normal)
            }
        }
    }
    
    var timer = Timer()
    var playBackSlider: UISlider?
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTimer(_:)), userInfo: nil, repeats: true)
    }
    @objc func UpdateTimer(_ timer: Timer) {
        if let currentTime = player.player?.currentTime {
            if let playBackSlider = playBackSlider {
                playBackSlider.value = Float(currentTime)
                print(playBackSlider.value)
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            }
        }
    }
    
    func commentCell(_ indexPath: IndexPath) -> CommentTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: commentReuse) as! CommentTableViewCell
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        if let comment = comments[indexPath.row] {
            let artist = comment.artist
            cell.userImage.addTarget(self, action: #selector(didPressProfileButton(_:)), for: .touchUpInside)
            cell.userImage.tag = indexPath.row
            if let image = comment.artist.image {
                cell.userImage.kf.setImage(with: URL(string: image), for: .normal)
            } else {
                cell.userImage.setImage(UIImage(named: "profile_icon"), for: .normal)
                artist?.loadUserInfoFromCloud(nil, soundCell: nil, commentCell: cell)
            }
            
            cell.username.addTarget(self, action: #selector(didPressProfileButton(_:)), for: .touchUpInside)
            cell.username.tag = indexPath.row
            if let username = comment.artist.username {
                cell.username.setTitle(username, for: .normal)
            } else {
                cell.username.setTitle("username", for: .normal)
            }
            
            cell.comment.text = comment.text
            
            let atTime = self.uiElement.formatTime(Double(comment.atTime))
            cell.atTime.setTitle("At \(atTime)", for: .normal)
            cell.atTime.addTarget(self, action: #selector(self.didPressAtTimeButton(_:)), for: .touchUpInside)
            cell.atTime.tag = indexPath.row
            
            let formattedDate = self.uiElement.formatDateAndReturnString(comment.createdAt)
            cell.date.text = formattedDate
        }
        

        
        return cell
    }
    
    @objc func didPressAtTimeButton(_ sender: UIButton) {
        if let player = self.player.player {
            if let comment = self.comments[sender.tag] {
                player.currentTime = TimeInterval(comment.atTime)
                self.atTime = comment.atTime
                messageView.textView.placeholderText = "Add comment at \(self.uiElement.formatTime(Double(atTime!)))"
                if !player.isPlaying {
                    self.player.play()
                }
            }
        }
    }
    
    @objc func didPressProfileButton(_ sender: UIButton) {
        if let artist = self.comments[sender.tag]?.artist {
            selectedArtist = artist
            self.performSegue(withIdentifier: "showProfile", sender: self)
        }
    }
    
    //mark: Data
    func addNewComment(_ text: String, atTime: Double, postId: String) {
        let newComment = PFObject(className: "Comment")
        newComment["postId"] = postId
        newComment["userId"] = PFUser.current()!.objectId
        newComment["text"] = text
        newComment["atTime"] = atTime
        newComment["isRemoved"] = false
        newComment.saveEventually {
            (success: Bool, error: Error?) in
            if success && error == nil {
                self.comments[self.comments.count - 1]?.objectId = newComment.objectId
                MSAnalytics.trackEvent("comment added")
                
            } else {
                self.comments.removeLast()
                self.tableView.reloadData()
            }
        }
    }
    
    func loadComments(_ postId: String) {
        self.comments.removeAll()
        let query = PFQuery(className: "Comment")
        query.whereKey("postId", equalTo: postId)
        query.whereKey("isRemoved", equalTo: false)
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let text = object["text"] as! String
                        let atTime = object["atTime"] as! Double
                        let userId = object["userId"] as! String
                        
                        let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil)
                        let comment = Comment(objectId: object.objectId!, artist: artist, text: text, atTime: Float(atTime), createdAt: object.createdAt!)
                        
                        self.comments.append(comment)
                    }
                }
                
            } else {
                print("Error: \(error!)")
            }
            
            self.tableView.reloadData()
            self.setUpMessageView()
        }
    }
}

class Comment {
    var objectId: String?
    var artist: Artist!
    var text: String!
    var atTime: Float!
    var createdAt: Date!
    
    init(objectId: String?, artist: Artist!, text: String!, atTime: Float!, createdAt: Date!) {
        self.objectId = objectId
        self.artist = artist
        self.text = text
        self.atTime = atTime
        self.createdAt = createdAt
    }
}

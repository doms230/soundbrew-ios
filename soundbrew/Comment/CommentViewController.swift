//
//  CommentViewController.swift
//  soundbrew
//
//  Created by Dominic Smith on 1/28/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import Kingfisher
import AppCenterAnalytics
import SnapKit
import GrowingTextView
class CommentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, GrowingTextViewDelegate {
    
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
        if let soundId = sound?.objectId {
            setupNotificationCenter()
            setupPlayerView()
            setupGrowingTextView(soundId)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
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
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSoundUpdate), name: NSNotification.Name(rawValue: "setSound"), object: nil)
    }
    @objc func didReceiveSoundUpdate() {
        if let sound = self.player.currentSound {
            self.setupPlayerView()
            if sound.objectId != self.sound?.objectId {
                self.sound = sound
                if let objectId = sound.objectId {
                    loadComments(objectId)
                }
            }
        }
    }
    
    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        if let endFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            var keyboardHeight = UIScreen.main.bounds.height - endFrame.origin.y
            if #available(iOS 11, *) {
                if keyboardHeight > 0 {
                    keyboardHeight = keyboardHeight - view.safeAreaInsets.bottom
                }
            }
            textViewBottomConstraint.constant = -keyboardHeight - 8
            view.layoutIfNeeded()
        }
    }
    
    //growing textview
    private var inputToolbar: UIView!
    private var textView: GrowingTextView!
    private var textViewBottomConstraint: NSLayoutConstraint!
    
    func setupGrowingTextView(_ soundId: String) {
        var placeHolderText = "Add comment"
        if let atTime = self.atTime {
            placeHolderText = "Add comment at \(self.uiElement.formatTime(Double(atTime)))"
        }
        
        // *** Create GrowingTextView ***
        textView = GrowingTextView()
        textView.delegate = self
        textView.layer.cornerRadius = 4.0
        textView.maxLength = 200
        textView.maxHeight = 70
        textView.trimWhiteSpaceWhenEndEditing = true
        textView.placeholder = placeHolderText
        textView.placeholderColor = UIColor(white: 0.8, alpha: 1.0)
        textView.font = UIFont(name: self.uiElement.mainFont, size: 17)
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        inputToolbar = UIView()
        inputToolbar.backgroundColor = color.black()
        inputToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputToolbar)
        inputToolbar.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
        
        
        inputToolbar.addSubview(textView)
        
        // *** Autolayout ***
        let topConstraint = textView.topAnchor.constraint(equalTo: inputToolbar.topAnchor, constant: 8)
        topConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            inputToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputToolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            topConstraint
        ])

        if #available(iOS 11, *) {
            textViewBottomConstraint = textView.bottomAnchor.constraint(equalTo: inputToolbar.safeAreaLayoutGuide.bottomAnchor, constant: -8)
            NSLayoutConstraint.activate([
                textView.leadingAnchor.constraint(equalTo: inputToolbar.safeAreaLayoutGuide.leadingAnchor, constant: 8),
                textView.trailingAnchor.constraint(equalTo: inputToolbar.safeAreaLayoutGuide.trailingAnchor, constant: -8),
                textViewBottomConstraint
                ])
        } else {
            textViewBottomConstraint = textView.bottomAnchor.constraint(equalTo: inputToolbar.bottomAnchor, constant: -8)
            NSLayoutConstraint.activate([
                textView.leadingAnchor.constraint(equalTo: inputToolbar.leadingAnchor, constant: 8),
                textView.trailingAnchor.constraint(equalTo: inputToolbar.trailingAnchor, constant: -8),
                textViewBottomConstraint
                ])
        }
        
        loadComments(soundId)
    }
    
    func textViewDidChangeHeight(_ textView: GrowingTextView, height: CGFloat) {
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: [.curveLinear], animations: { () -> Void in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    //player view
    lazy var playerViewButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(self.didPressExitButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressExitButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
        
    lazy var songTitle: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        if let title = self.sound?.title {
            label.text = title
        }
        return label
    }()
    
    lazy var artistName: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 15)
        if let name = self.sound?.artist?.name {
            label.text = name
        }
        return label
    }()
    
    lazy var songArt: UIImageView = {
        let image = UIImageView()
        image.backgroundColor = .clear
        image.image = UIImage(named: "sound")
        return image
    }()
    
    lazy var activitySpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .white
        spinner.startAnimating()
        spinner.isHidden = true
        return spinner
    }()
    
    lazy var playBackButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "play"), for: .normal)
        return button
    }()
    
    lazy var playBackSlider: UISlider = {
        let slider = UISlider()
        slider.value = 0
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.tintColor = .white
        slider.setThumbImage(UIImage(), for: .normal)
        slider.isEnabled = false
        return slider
     }()
    
    func setPlaybackSliderValue() {
        if let player = self.player.player {
            playBackSlider.maximumValue = Float(player.duration)
            playBackSlider.value = Float(player.currentTime)
            if player.isPlaying {
                self.startTimer()
            } else {
                self.timer.invalidate()
            }
        }
    }
    
    lazy var commentTitle: UILabel = {
        let label = UILabel()
        label.text = "Comments"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        return label
    }()
    
    func setupPlayerView() {
        print("set up player view")
        playBackButton.addTarget(self, action: #selector(didPressPlayBackButton(_:)), for: .touchUpInside)
        if let player = self.player.player {
            if player.isPlaying {
                self.playBackButton.setImage(UIImage(named: "pause"), for: .normal)
            } else {
                self.playBackButton.setImage(UIImage(named: "play"), for: .normal)
            }
        }
        self.view.addSubview(playBackButton)
        playBackButton.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(50)
            make.top.equalTo(self.view).offset(uiElement.topOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(playerViewButton)
        playerViewButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(50)
            make.top.equalTo(playBackButton)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.playBackButton.snp.left).offset(uiElement.leftOffset)
        }
        
        if let image = self.sound?.artURL {
            songArt.kf.setImage(with: URL(string: image))
        }
        self.playerViewButton.addSubview(songArt)
        songArt.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(50)
            make.top.equalTo(playerViewButton)
            make.left.equalTo(playerViewButton)
        }
        
        self.playerViewButton.addSubview(activitySpinner)
        activitySpinner.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(30)
            make.centerY.equalTo(songArt)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        activitySpinner.isHidden = true
        
        self.playerViewButton.addSubview(artistName)
        artistName.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.songArt).offset(uiElement.topOffset)
            make.left.equalTo(songArt.snp.right).offset(uiElement.elementOffset)
            make.right.equalTo(playBackButton.snp.left).offset(uiElement.rightOffset)
        }
        
        self.playerViewButton.addSubview(songTitle)
        songTitle.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(artistName)
            make.right.equalTo(artistName)
            make.bottom.equalTo(artistName.snp.top).offset(-(uiElement.elementOffset))
        }
        
        setPlaybackSliderValue()
        self.view.addSubview(playBackSlider)
        playBackSlider.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(1)
            make.top.equalTo(songArt.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(commentTitle)
        commentTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(playBackSlider.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
    }
        
    //mark: Tableview
    var tableView: UITableView!
    let commentReuse = "commentReuse"
    let noSoundsReuse = "noSoundsReuse"
    func setUpTableView() {
        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: commentReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        tableView.backgroundColor = color.black()
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            //for some reason, attachinxg to the bottom of playerdividerline makes the tableview stretch all the way to the bottom of screen
            make.top.equalTo(self.view).offset(100 + self.uiElement.topOffset)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.inputToolbar.snp.top)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if comments.count == 0 {
            return 1
        }
        
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.comments.count == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
            cell.backgroundColor = color.black()
            cell.headerTitle.text = "No comments yet. Be the first, and comment below. 😎"
            return cell
            
        } else {
            return commentCell(indexPath)
        }
    }
    
    @objc func didPressPlayBackButton(_ sender: UIButton) {
        if let soundPlayer = player.player {
            if soundPlayer.isPlaying {
                player.pause()
            } else {
                player.play()
            }
        }
    }
    
    var timer = Timer()
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(UpdateTimer(_:)), userInfo: nil, repeats: true)
    }
    @objc func UpdateTimer(_ timer: Timer) {
        if let currentTime = player.player?.currentTime {
            playBackSlider.value = Float(currentTime)
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
               // messageView.textView.placeholderText = "Add comment at \(self.uiElement.formatTime(Double(atTime!)))"
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
    
    //mark: MessageView
    
    @objc func didPressRightButton(_ sender: UIButton) {
        /*if let artist = Customer.shared.artist, let objectId = self.sound?.objectId, let atTime = self.atTime {
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
        }*/
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
            }
            
            if self.tableView == nil {
                self.setUpTableView()
            } else {
               self.tableView.reloadData()
            }
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

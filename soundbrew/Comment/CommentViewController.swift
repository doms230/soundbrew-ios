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
import NVActivityIndicatorView
class CommentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, GrowingTextViewDelegate, NVActivityIndicatorViewable {
    
    var comments = [Comment?]()
    let uiElement = UIElement()
    let color = Color()
    
    var sound: Sound?
    var atTime: Float = 0
    let player = Player.sharedInstance
    var selectedArtist: Artist?
    var selectedCommentFromMentions: String? 
    var mentionedRowToScrollTo = 0
    var playerDelegate: PlayerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        if let sound = self.sound {
            setupNotificationCenter()
            setupPlayerView()
            setupGrowingTextView(sound)
        } else {
            self.dismiss(animated: true, completion: nil)
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
                loadComments(sound)
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
    
    //mark: textview
    var isSearchingForUserToMention = false
    var searchUsers = [Artist]()
    private var inputToolbar: UIView!
    private var textView: GrowingTextView!
    var isTextViewEditing = false
    private var textViewBottomConstraint: NSLayoutConstraint!
    private var sendButtomBottomConstraint: NSLayoutConstraint!
    private var sendButton: UIButton!
    var mentions = [String]()
    func setupGrowingTextView(_ sound: Sound) {
        if let currentTime = player.player?.currentTime {
            self.atTime = Float(currentTime)
        }
        let formattedCurrentTime = self.uiElement.formatTime(Double(self.atTime))

        inputToolbar = UIView()
        inputToolbar.backgroundColor = color.black()
        inputToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputToolbar)
        
        textView = GrowingTextView()
        textView.backgroundColor = color.black()
        textView.delegate = self
        textView.layer.cornerRadius = 4.0
        textView.maxLength = 200
        textView.maxHeight = 70
        textView.trimWhiteSpaceWhenEndEditing = true
        textView.placeholder = "Add comment at \(formattedCurrentTime)"
        textView.placeholderColor = .darkGray
        textView.font = UIFont(name: self.uiElement.mainFont, size: 17)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.keyboardType = .twitter
        textView.textColor = .white
        inputToolbar.addSubview(textView)

        let buttonWidthHeight = 35
        sendButton = UIButton(frame: CGRect(x: Int(view.frame.width) + uiElement.rightOffset - buttonWidthHeight, y: uiElement.topOffset, width: buttonWidthHeight, height: buttonWidthHeight))
        sendButton.addTarget(self, action: #selector(self.didPressSendButton(_:)), for: .touchUpInside)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.setImage(UIImage(named: "send"), for: .normal)
        sendButton.isHidden = true
        sendButton.isEnabled = false
        inputToolbar.addSubview(sendButton)
        
        let imageHeightWidth = 35
        let userImageView = UIImageView(frame: CGRect(x: uiElement.leftOffset, y: uiElement.topOffset, width: imageHeightWidth, height: imageHeightWidth))
        userImageView.layer.cornerRadius = CGFloat(imageHeightWidth / 2)
        userImageView.clipsToBounds = true
        if let artistImage = Customer.shared.artist?.image {
            userImageView.kf.setImage(with: URL(string: artistImage))
        } else {
            userImageView.image = UIImage(named: "profile_icon")
        }
        inputToolbar.addSubview(userImageView)
        
        // *** Autolayout ***/
        let topConstraint = textView.topAnchor.constraint(equalTo: inputToolbar.topAnchor, constant: 8)
        topConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            inputToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputToolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            topConstraint
        ])
        
        textViewBottomConstraint = textView.bottomAnchor.constraint(equalTo: inputToolbar.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: userImageView.safeAreaLayoutGuide.trailingAnchor, constant: 15),
            textView.trailingAnchor.constraint(equalTo: sendButton.safeAreaLayoutGuide.leadingAnchor, constant: -15),
            textViewBottomConstraint
            ])
        
        loadComments(sound)
    }
    
    func textViewDidChangeHeight(_ textView: GrowingTextView, height: CGFloat) {
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: [.curveLinear], animations: { () -> Void in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty {
            sendButton.isHidden = true
            sendButton.isEnabled = false
            self.commentTitle.text = "Comments"
            self.isSearchingForUserToMention = false
            self.tableView.isHidden = false
            self.tableView.reloadData()
            
        } else {
            sendButton.isHidden = false
            sendButton.isEnabled = true
            
            let textViewArray = textView.text.split{$0 == " "}.map(String.init)
            if textViewArray.count != 0 {
                let textToSearchWith = textViewArray[textViewArray.count - 1]
                if textToSearchWith.starts(with: "@") {
                    self.commentTitle.text = "Search Accounts"
                    self.isSearchingForUserToMention = true
                    let textToSearch = getTextWithoutAtSign(textToSearchWith)
                    self.tableView.isHidden = true
                    searchUsers(textToSearch)
                } else {
                    self.commentTitle.text = "Comments"
                    self.isSearchingForUserToMention = false
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func getTextWithoutAtSign(_ text: String) -> String {
        let charactersArray = Array(text)
        var textWithoutAt = ""
        for i in 0..<charactersArray.count {
            let c = charactersArray[i]
            if i != 0 {
                textWithoutAt = "\(textWithoutAt)\(c)"
            }
        }
        
        return textWithoutAt
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.isTextViewEditing = false
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.isTextViewEditing = true
    }
        
    @objc func didPressSendButton(_ sender: UIButton) {
        if let artist = Customer.shared.artist, let objectId = self.sound?.objectId {
            addNewComment(textView.text, atTime: Double(atTime), postId: objectId)
            let comment = Comment(objectId: nil, artist: artist, text: textView.text, atTime: Float(atTime), createdAt: Date())
            self.comments.append(comment)
            self.comments.sort(by: {$0!.atTime < $1!.atTime})
            textView.text = ""
            textView.resignFirstResponder()
            sendButton.isHidden = true
            sendButton.isEnabled = false
            self.tableView.reloadData()
            tableView.scrollToRow(
                at: IndexPath(row: comments.count - 1, section: 0),
                at: .bottom,
                animated: true
            )
        }
    }

    //player view
    lazy var songArtButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(self.didPressExitButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressExitButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    lazy var dismissImage: UIImageView = {
       let image = UIImageView()
        image.image = UIImage(named: "dismiss")
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
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 15)
        label.textAlignment = .center
        return label
    }()
    
    func setupPlayerView() {
       /* if let currentSound = self.player.currentSound, currentSound.objectId != self.sound?.objectId {
            setupCurrentSoundPlayer()
        } else {
            setupCurrentSoundPlayer()
        }*/
        
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
            make.width.height.equalTo(25)
            make.top.equalTo(self.view).offset(uiElement.topOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(commentTitle)
        commentTitle.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.playBackButton)
        }
        
        if let image = self.sound?.artURL {
            songArtButton.kf.setImage(with: URL(string: image), for: .normal)
        }
        
        self.view.addSubview(songArtButton)
        songArtButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(playBackButton)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        self.songArtButton.addSubview(dismissImage)
        dismissImage.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(20)
            make.center.equalTo(songArtButton)
        }
        
        self.songArtButton.addSubview(activitySpinner)
        activitySpinner.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(25)
            make.centerY.equalTo(songArtButton)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        activitySpinner.isHidden = true
        
        setPlaybackSliderValue()
        self.view.addSubview(playBackSlider)
        playBackSlider.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(1)
            make.top.equalTo(songArtButton.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
    }
    
    func setupCurrentSoundPlayer() {
        if let sound = self.sound {
            var sounds = [Sound]()
            sounds.append(sound)
            let player = Player.sharedInstance
            player.player = nil
            player.sounds = sounds
            player.currentSound = sounds[0]
            player.currentSoundIndex = 0
            player.setUpNextSong(false, at: 0)
        }
    }
        
    //mark: Tableview
    var tableView: UITableView!
    let commentReuse = "commentReuse"
    let noSoundsReuse = "noSoundsReuse"
    let searchProfileReuse = "searchProfileReuse"
    func setUpTableView() {
        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: commentReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchProfileReuse)
        tableView.backgroundColor = color.black()
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            //for some reason, attachinxg to the bottom of playerdividerline makes the tableview stretch all the way to the bottom of screen
            make.top.equalTo(self.view).offset(45 + self.uiElement.topOffset)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.inputToolbar.snp.top)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearchingForUserToMention {
            if searchUsers.count == 0 {
                return 1
            }
            return searchUsers.count
            
        } else {
            if comments.count == 0 {
                return 1
            }
            return comments.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSearchingForUserToMention {
            if searchUsers.count == 0 {
                return noResultsCell("No accounts found.")
            }
             return searchUsers[indexPath.row].cell(tableView, reuse: searchProfileReuse)
            
        } else {
            if self.comments.count == 0 {
                return noResultsCell("No comments yet. Be the first, and comment below. 😎")
                
            } else {
                return commentCell(indexPath)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSearchingForUserToMention, let selectedUsername = self.searchUsers[indexPath.row].username {
            let textViewArray = textView.text.split{$0 == " "}.map(String.init)
            var newTextView: String!
            for i in 0..<textViewArray.count {
                if i == textViewArray.count - 1 {
                    if i == 0 {
                        self.textView.text = "\(selectedUsername) "
                    } else {
                       self.textView.text = "\(newTextView!) \(selectedUsername) "
                    }
                    self.commentTitle.text = "Comments"
                    self.isSearchingForUserToMention = false
                    self.tableView.reloadData()
                } else if i == 0 {
                    newTextView = "\(textViewArray[i])"
                } else {
                    newTextView = "\(newTextView!) \(textViewArray[i])"
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row != 0 && comments.indices.contains(indexPath.row), let commentId = comments[indexPath.row]?.artist?.objectId,
            let currentUserId = PFUser.current()?.objectId, let soundId = self.sound?.artist?.objectId {
            if currentUserId == soundId {
                return true
            }
            
            if currentUserId == commentId {
                return true
            }
        }

        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let commentId = comments[indexPath.row]?.objectId {
                self.comments.remove(at: indexPath.row)
                self.tableView.reloadSections([0], with: .automatic)
                removeComment(objectId: commentId)
            }
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
            let floatCurrentTime = Float(currentTime)
            playBackSlider.value = floatCurrentTime
            if !self.isTextViewEditing {
                self.atTime = Float(currentTime)
                let doubleAtTime = self.uiElement.formatTime(Double(currentTime))
                textView.placeholder = "Add comment at \(doubleAtTime)"
            }
        }
    }
    
    func noResultsCell(_ title: String) -> SoundListTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
        cell.backgroundColor = color.black()
        cell.headerTitle.text = title
        return cell
    }
    
    func commentCell(_ indexPath: IndexPath) -> CommentTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: commentReuse) as! CommentTableViewCell
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        if let comment = comments[indexPath.row] {
            let artist = comment.artist
            cell.userImage.addTarget(self, action: #selector(didPressProfileButton(_:)), for: .touchUpInside)
            cell.userImage.tag = indexPath.row
            if let image = comment.artist?.image {
                cell.userImage.kf.setImage(with: URL(string: image), for: .normal)
            } else {
                cell.userImage.setImage(UIImage(named: "profile_icon"), for: .normal)
                artist?.loadUserInfoFromCloud(nil, soundCell: nil, commentCell: cell)
            }
            
            cell.username.tag = indexPath.row
            cell.username.addTarget(self, action: #selector(didPressProfileButton(_:)), for: .touchUpInside)
            
            if let username = comment.artist?.username {
                cell.username.setTitle(username, for: .normal)
            } else {
                cell.username.setTitle("username", for: .normal)
            }
            
            cell.comment.text = comment.text
            cell.comment.handleMentionTap {userHandle in
                self.loadArtistFromUsername(userHandle, commentId: nil)
            }
            
            let atTime = self.uiElement.formatTime(Double(comment.atTime))
            cell.atTime.setTitle("\(atTime)", for: .normal)
            cell.atTime.tag = indexPath.row
            cell.atTime.addTarget(self, action: #selector(self.didPressAtTimeButton(_:)), for: .touchUpInside)
            
            cell.replyButton.tag = indexPath.row
            cell.replyButton.addTarget(self, action: #selector(self.didPressReplyButton(_:)), for: .touchUpInside)
            
            let formattedDate = self.uiElement.formatDateAndReturnString(comment.createdAt!)
            cell.date.text = formattedDate
           
            if let selectedCommentFromMentions = self.selectedCommentFromMentions {
                if selectedCommentFromMentions == comment.objectId {
                    cell.backgroundColor = .lightGray
                }
            }
        }
                
        return cell
    }
    
    func handleDismissal(_ artist: Artist) {
        if let playerDelegate = self.playerDelegate {
            print(playerDelegate)
            self.dismiss(animated: false, completion: {() in
                playerDelegate.selectedArtist(artist)
            })
        }
    }
    
    @objc func didPressAtTimeButton(_ sender: UIButton) {
        if let player = self.player.player {
            if let comment = self.comments[sender.tag] {
                player.currentTime = TimeInterval(comment.atTime)
                self.atTime = comment.atTime
                if !player.isPlaying {
                    self.player.play()
                }
            }
        }
    }
    
    @objc func didPressProfileButton(_ sender: UIButton) {
        if let artist = self.comments[sender.tag]?.artist {
            handleDismissal(artist)
        }
    }
    
    @objc func didPressReplyButton(_ sender: UIButton) {
        if let username = self.comments[sender.tag]?.artist?.username {
            if let atTime = self.comments[sender.tag]?.atTime {
                self.isTextViewEditing = true
                self.atTime = atTime
            }
            textView.text = "@\(username) "
            textView.becomeFirstResponder()
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
                self.updateCommentCount(postId, byAmount: 1)
                self.newMention(self.sound!.artist!.objectId, commentId: newComment.objectId!)
                self.checkForMentions(text, commentId: newComment.objectId!)
                MSAnalytics.trackEvent("comment added")
                
            } else {
                self.comments.removeLast()
                self.tableView.reloadData()
            }
        }
    }
    
    func updateCommentCount(_ objectId: String, byAmount: NSNumber) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let object = object {
                object.incrementKey("comments", byAmount: byAmount)
                object.saveEventually()
            }
        }
    }
    
    func removeComment(objectId: String) {
        let query = PFQuery(className: "Comment")
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let object = object {
                object["isRemoved"] = true
                object.saveEventually {
                    (success: Bool, error: Error?) in
                    if success && error == nil {
                        if let objectId = self.sound?.objectId {
                            self.updateCommentCount(objectId, byAmount: -1)
                        }
                    }
                }
            }
        }
    }
    
    func checkForMentions(_ text: String, commentId: String) {
        let textArray = text.split{$0 == " "}.map(String.init)
        for text in textArray {
            if text.starts(with: "@") {
                let textWithoutAt = self.getTextWithoutAtSign(text)
                loadArtistFromUsername(textWithoutAt, commentId: commentId)
            }
        }
    }
    
    func loadArtistFromUsername(_ username: String, commentId: String?) {
        if commentId == nil {
            self.startAnimating()
        }
        let query = PFQuery(className: "_User")
        query.whereKey("username", equalTo: username)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            self.stopAnimating()
            if let object = object {
                if let commentId = commentId, username != self.sound?.artist?.username {
                    self.newMention(object.objectId!, commentId: commentId)
                } else {
                    let artist = self.uiElement.newArtistObject(object)
                    self.handleDismissal(artist)
                }

            } else if commentId == nil {
                self.uiElement.showAlert("User doesn't exist.", message: "", target: self)
            }
        }
    }
    
    func newMention(_ userId: String, commentId: String) {
        let newMention = PFObject(className: "Mention")
        //newMention["postId"] = self.sound?.objectId
        newMention["type"] = "comment"
        newMention["commentId"] = commentId
        newMention["fromUserId"] = PFUser.current()!.objectId
        newMention["toUserId"] = userId
        newMention.saveEventually {
            (success: Bool, error: Error?) in
            if success && error == nil {
                self.uiElement.sendAlert("mentioned you in a comment", toUserId: userId)
            }
        }
    }
    
    func loadComments(_ sound: Sound) {
        self.comments.removeAll()
        
        if let soundArtist = sound.artist{
            let comment = Comment(objectId: nil, artist: soundArtist, text: sound.title, atTime: 0, createdAt: sound.createdAt)
            self.comments.insert(comment, at: 0)
        }
        
        let query = PFQuery(className: "Comment")
        query.whereKey("postId", equalTo: sound.objectId!)
        query.whereKey("isRemoved", equalTo: false)
        query.addAscendingOrder("atTime")
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                for object in objects {
                    let text = object["text"] as! String
                    let atTime = object["atTime"] as! Double
                    let userId = object["userId"] as! String
                    
                    let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil)
                    let comment = Comment(objectId: object.objectId!, artist: artist, text: text, atTime: Float(atTime), createdAt: object.createdAt!)
                    
                    self.comments.append(comment)
                    
                    if let selectedCommentFromMentions = self.selectedCommentFromMentions {
                        if selectedCommentFromMentions != comment.objectId {
                            self.mentionedRowToScrollTo = self.mentionedRowToScrollTo + 1
                        }
                    }
                }
            }
            
            if self.tableView == nil {
                self.setUpTableView()
            } else {
               self.tableView.reloadData()
            }
            
            if self.selectedCommentFromMentions != nil {
                let indexPath = IndexPath(row: self.mentionedRowToScrollTo, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        }
    }
    
    func searchUsers(_ text: String) {
        self.searchUsers.removeAll()
        let nameQuery = PFQuery(className: "_User")
        nameQuery.whereKey("artistName", matchesRegex: text.lowercased())
        nameQuery.whereKey("artistName", matchesRegex: text)
        
        let usernameQuery = PFQuery(className: "_User")
        usernameQuery.whereKey("username", matchesRegex: text.lowercased())
        let query = PFQuery.orQuery(withSubqueries: [nameQuery, usernameQuery])
        query.limit = 25
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for user in objects {
                        let artist = self.uiElement.newArtistObject(user)
                        if artist.username != nil {
                            self.searchUsers.append(artist)
                        }
                    }
                }
                
                self.tableView.reloadData()
                self.tableView.isHidden = false
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
}

class Comment {
    var objectId: String?
    var artist: Artist?
    var text: String!
    var atTime: Float!
    var createdAt: Date?
    
    init(objectId: String?, artist: Artist?, text: String!, atTime: Float!, createdAt: Date?) {
        self.objectId = objectId
        self.artist = artist
        self.text = text
        self.atTime = atTime
        self.createdAt = createdAt
    }
}

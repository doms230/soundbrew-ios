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
import AVFoundation

class CommentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, GrowingTextViewDelegate, NVActivityIndicatorViewable {
    
    var comments = [Comment?]()
    let uiElement = UIElement()
    let color = Color()
    
    var atTime: Float = 0
    let player = Player.sharedInstance
    var selectedArtist: Artist?
    var selectedCommentFromMentions: String? 
    var mentionedRowToScrollTo = 0
    var playerDelegate: PlayerDelegate?    
    var tagDelegate: TagDelegate?
    var playBackControl: PlayBackControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        if player.currentSound != nil {
            playBackControl = PlayBackControl(self, textView: textView)
            setupTopView()
            setupNotificationCenter()
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
        
    func setupNotificationCenter(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSoundUpdate), name: NSNotification.Name(rawValue: "setSound"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector:#selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    @objc func didReceiveSoundUpdate() {
        self.tableView.reloadData()
        loadComments()
        
        if let player = self.player.player, let atTime = self.didPressAtTime {
            self.didPressAtTime = nil
            jumpToTime(player, atTime: atTime)
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
            textViewBottomConstraint.constant = -keyboardHeight - 20
            view.layoutIfNeeded()
        } else {
            print("dismissed")
        }
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
            make.height.width.equalTo(25)
            make.top.equalTo(self.view).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        self.view.addSubview(self.appTitle)
        self.appTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(dismissButton)
            make.centerX.equalTo(self.view)
        }
        
        setupGrowingTextView()
    }
    
    //mark: textview
    var isSearchingForUserToMention = false
    var searchUsers = [Artist]()
    private var inputToolbar: UIView!
    private var textView = GrowingTextView()
    var isTextViewEditing = false
    private var textViewBottomConstraint: NSLayoutConstraint!
    private var sendButton: UIButton!
    private var userImageView: UIImageView!
    var mentions = [String]()
    func setupGrowingTextView() {
        if let currentTime = player.player?.currentTime {
            self.atTime = Float(currentTime)
        }
        let formattedCurrentTime = self.uiElement.formatTime(Double(self.atTime))

        inputToolbar = UIView()
        inputToolbar.backgroundColor = color.black()
        inputToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputToolbar)
        
        textView.backgroundColor = color.black()
        textView.delegate = self
        textView.layer.cornerRadius = 15
        textView.layer.borderColor = UIColor.darkGray.cgColor
        textView.layer.borderWidth = 1
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
        sendButton.layer.cornerRadius = CGFloat(buttonWidthHeight / 2)
        sendButton.clipsToBounds = true 
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
            inputToolbar.bottomAnchor.constraint(equalTo: playBackControl!.playBackButton.topAnchor),
            topConstraint
        ])
        
        textViewBottomConstraint = textView.bottomAnchor.constraint(equalTo: inputToolbar.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: userImageView.safeAreaLayoutGuide.trailingAnchor, constant: 15),
            textView.trailingAnchor.constraint(equalTo: sendButton.safeAreaLayoutGuide.leadingAnchor, constant: -15),
            textViewBottomConstraint
            ])
        
        setUpTableView()
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
                    self.isSearchingForUserToMention = true
                    let textToSearch = getTextWithoutAtSign(textToSearchWith)
                    self.tableView.isHidden = true
                    searchUsers(textToSearch)
                } else {
                    self.isSearchingForUserToMention = false
                    if self.tableView != nil {
                        self.tableView.reloadData()
                    }
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
        self.playBackControl?.isTextViewEditing = false
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.playBackControl?.isTextViewEditing = true
    }
        
    @objc func didPressSendButton(_ sender: UIButton) {
        if let artist = Customer.shared.artist, let objectId = self.player.currentSound?.objectId, let atTime = self.playBackControl?.atTime {
            addNewComment(textView.text, atTime: Double(atTime), postId: objectId)
            let comment = Comment(objectId: nil, artist: artist, text: textView.text, atTime: Float(atTime), createdAt: Date())
            self.comments.append(comment)
            self.comments.sort(by: {$0!.atTime < $1!.atTime})
            textView.text = ""
            textView.resignFirstResponder()
            sendButton.isHidden = true
            sendButton.isEnabled = false
            self.tableView.reloadData()
        }
        
        MSAnalytics.trackEvent("Comment View Controller", withProperties: ["Button" : "didPressSendButton"])
    }
    
    //mark: sound
    @objc func didBecomeActive() {
        if self.viewIfLoaded?.window != nil {
            player.target = self
        }
    }
        
    //mark: Tableview
    var tableView: UITableView!
    let commentReuse = "commentReuse"
    let noSoundsReuse = "noSoundsReuse"
    let searchProfileReuse = "searchProfileReuse"
    let playerReuse = "playerReuse"
    func setUpTableView() {
        DispatchQueue.main.async {
            self.tableView = UITableView()
            self.tableView.dataSource = self
            self.tableView.delegate = self
            //player view
            self.tableView.register(PlayerTableViewCell.self, forCellReuseIdentifier: self.playerReuse)
            //comment view
            self.tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: self.commentReuse)
            self.tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: self.noSoundsReuse)
            self.tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: self.searchProfileReuse)
            self.tableView.backgroundColor = self.color.black()
            self.tableView.keyboardDismissMode = .onDrag
            self.tableView.separatorStyle = .none
            self.view.addSubview(self.tableView)
            self.tableView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.dismissButton.snp.bottom)
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
                make.bottom.equalTo(self.inputToolbar.snp.top)
            }
        }
        loadComments()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if isSearchingForUserToMention {
            return 1
        }
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearchingForUserToMention {
            if searchUsers.count == 0 {
                return 1
            }
            return searchUsers.count
            
        } else {
            if section == 0 || comments.count == 0 {
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
            if indexPath.section == 0 {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: playerReuse) as! PlayerTableViewCell
                cell.backgroundColor = .black
                cell.selectionStyle = .none
                
                if let sound = player.currentSound {
                    player.target = self
                    cell.soundArt.kf.setImage(with: URL(string: sound.artFile?.url  ?? ""), placeholder: UIImage(named: "sound"))
                    //making constraints here to get view frame
                }
                return cell
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
                        self.textView.text = "@\(selectedUsername) "
                    } else {
                       self.textView.text = "\(newTextView!) @\(selectedUsername) "
                    }
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
            let currentUserId = PFUser.current()?.objectId, let soundId = self.player.currentSound?.artist?.objectId {
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
              //  self.tableView.reloadData()
                removeComment(objectId: commentId)
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
        if comments.indices.contains(indexPath.row), let comment = comments[indexPath.row] {
            let artist = comment.artist
            cell.userImage.addTarget(self, action: #selector(didPressProfileButton(_:)), for: .touchUpInside)
            cell.userImage.tag = indexPath.row
            if let image = comment.artist?.image {
                cell.userImage.kf.setImage(with: URL(string: image), for: .normal)
            } else {
                cell.userImage.setImage(UIImage(named: "profile_icon"), for: .normal)
                artist?.loadUserInfoFromCloud(nil, soundCell: nil, commentCell: cell, artistUsernameLabel: nil, artistImageButton: nil)
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
                    cell.backgroundColor = color.purpleBlack()
                }
            }
        }
                
        return cell
    }
    
    func handleDismissal(_ artist: Artist) {
        if let playerDelegate = self.playerDelegate {
            self.dismiss(animated: false, completion: {() in
                playerDelegate.selectedArtist(artist)
            })
        }
    }
    
    //didPressAtTime for people who are coming in from mentions page
    var didPressAtTime: Float?
    @objc func didPressAtTimeButton(_ sender: UIButton) {
        if let comment = self.comments[sender.tag] {
            if let player = self.player.player, let playerSound = self.player.currentSound, let commentSound = self.player.currentSound, playerSound.objectId == commentSound.objectId {
                jumpToTime(player, atTime: comment.atTime)
            } else {
                didPressAtTime = comment.atTime
            }
        }
        
        MSAnalytics.trackEvent("Comment View Controller", withProperties: ["Button" : "didPressAtTimeButton"])
    }
    func jumpToTime(_ player: AVAudioPlayer, atTime: Float) {
        player.currentTime = TimeInterval(atTime)
        self.atTime = atTime
        if !player.isPlaying {
            self.player.play()
        }
    }
    
    @objc func didPressProfileButton(_ sender: UIButton) {
        if let artist = self.comments[sender.tag]?.artist {
            handleDismissal(artist)
        }
        
        MSAnalytics.trackEvent("Comment View Controller", withProperties: ["Button" : "didPressProfileButton"])
    }
    
    @objc func didPressReplyButton(_ sender: UIButton) {
        if let username = self.comments[sender.tag]?.artist?.username {
            if let atTime = self.comments[sender.tag]?.atTime {
                self.playBackControl?.isTextViewEditing = true
                self.atTime = atTime
            }
            textView.text = "@\(username) "
            textView.becomeFirstResponder()
        }
        
        MSAnalytics.trackEvent("Comment View Controller", withProperties: ["Button" : "didPressReplyButton"])
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
                self.newMention(self.player.currentSound!.artist!.objectId, commentId: newComment.objectId!)
                self.checkForMentions(text, commentId: newComment.objectId!)
                MSAnalytics.trackEvent("comment added")
                
            } else {
                self.comments.removeLast()
                DispatchQueue.main.async {self.tableView.reloadData()}
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
                        if let objectId = self.player.currentSound?.objectId {
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
        query.cachePolicy = .networkElseCache
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            self.stopAnimating()
            if let object = object {
                if let commentId = commentId {
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
        newMention["type"] = "comment"
        newMention["commentId"] = commentId
        newMention["fromUserId"] = PFUser.current()!.objectId
        newMention["toUserId"] = userId
        newMention.saveEventually {
            (success: Bool, error: Error?) in
            if success && error == nil {
                self.uiElement.sendAlert("mentioned you in a comment", toUserId: userId, shouldIncludeName: true)
            }
        }
    }
    
    var didLoadComments = false
    func loadComments() {
        if let sound = player.currentSound {
            self.comments.removeAll()
            
            if let soundArtist = sound.artist {
                var hashtagsAsString = ""
                if let hashtags = sound.tags {
                    for hashtag in hashtags {
                        if hashtagsAsString.isEmpty {
                            hashtagsAsString = "#\(hashtag)"
                        } else {
                            hashtagsAsString = "\(hashtagsAsString) #\(hashtag)"
                        }
                    }
                }
                
                let features = "@d_innovator (producer)"

                let text = "\(sound.title ?? "")\n\nfeaturing \(features)\n\n\(hashtagsAsString)"
                let comment = Comment(objectId: nil, artist: soundArtist, text: text, atTime: 0, createdAt: sound.createdAt)
                self.comments.append(comment)
            }

            let query = PFQuery(className: "Comment")
            query.cachePolicy = .networkElseCache
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
                        
                        let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, accountId: nil, priceId: nil)
                        let comment = Comment(objectId: object.objectId!, artist: artist, text: text, atTime: Float(atTime), createdAt: object.createdAt!)
                        
                        self.comments.append(comment)
                        
                        if let selectedCommentFromMentions = self.selectedCommentFromMentions {
                            if selectedCommentFromMentions != comment.objectId {
                                self.mentionedRowToScrollTo = self.mentionedRowToScrollTo + 1
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {self.tableView.reloadData()}

                if self.selectedCommentFromMentions != nil && !self.didLoadComments {
                     DispatchQueue.main.async {
                        self.tableView.reloadData()
                        let indexPath = IndexPath(row: self.mentionedRowToScrollTo, section: 0)
                        self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                        self.didLoadComments = true
                    }
                }
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
        query.cachePolicy = .networkElseCache
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
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.tableView.isHidden = false
                }
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

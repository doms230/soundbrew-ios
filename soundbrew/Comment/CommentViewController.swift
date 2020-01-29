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

class CommentViewController: MessageViewController, UITableViewDataSource, UITableViewDelegate {
    
    var comments = [Comment]()
    let uiElement = UIElement()
    let color = Color()
    
    var sound: Sound?
    var atTime: Float?
    var player = Player.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        if let soundId = sound?.objectId {
            loadComments(soundId)
        }
    }
    
    //mark: MessageView
    func setUpMessageView() {
        borderColor = .lightGray
        //messageView.inset = UIEdgeInsets(top: 0, left: CGFloat(uiElement.leftOffset), bottom: 0, right: CGFloat(uiElement.rightOffset))
        //messageView.backgroundColor = color.black()
        messageView.inset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        messageView.font = UIFont(name: uiElement.mainFont, size: 17)
        var placeHolderText = "Add comment"
        if let atTime = self.atTime {
            placeHolderText = "Add comment at \(self.uiElement.formatTime(Double(atTime)))"
        }
       // messageView.textView.textColor = .white
        
        messageView.textView.placeholderText = placeHolderText
        messageView.textView.placeholderTextColor = .darkGray
        //messageView.textView.layer.cornerRadius = 10
        //messageView.textView.layer.borderWidth = 1
        //messageView.textView.layer.borderColor = color.darkGray().cgColor
       // messageView.textView.backgroundColor = color.black()
        
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
    var tableView = UITableView()
    let commentReuse = "commentReuse"
    let noSoundsReuse = "noSoundsReuse"
    
    func setUpTableView() {
        tableView.dataSource = self
        tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: commentReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        tableView.backgroundColor = color.black()
        self.tableView.separatorStyle = .none
        self.view.addSubview(tableView)
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
            let cell = self.tableView.dequeueReusableCell(withIdentifier: commentReuse) as! CommentTableViewCell
            cell.backgroundColor = color.black()
            let comment = comments[indexPath.row]
            
            let artist = comment.artist
            
            if let image = comment.artist.image {
                cell.userImage.kf.setImage(with: URL(string: image))
            } else {
                cell.userImage.image = UIImage(named: "profile_icon")
                artist?.loadUserInfoFromCloud(nil, soundCell: nil, commentCell: cell)
            }
            
            if let username = comment.artist.username {
                cell.username.setTitle(username, for: .normal)
            } else {
                cell.username.setTitle("username", for: .normal)
            }
            
            cell.comment.text = comment.text
            
            let atTime = self.uiElement.formatTime(Double(comment.atTime))
            cell.atTime.setTitle("At \(atTime)", for: .normal)
            cell.atTime.addTarget(self, action: #selector(self.didPressAtTime(_:)), for: .touchUpInside)
            cell.atTime.tag = indexPath.row
            
            let formattedDate = self.uiElement.formatDateAndReturnString(comment.createdAt)
            cell.date.text = formattedDate
            
            return cell
        }
    }
    
    @objc func didPressAtTime(_ sender: UIButton) {
        if let player = self.player.player {
            player.currentTime = TimeInterval(self.comments[sender.tag].atTime)
            self.atTime = self.comments[sender.tag].atTime
            messageView.textView.placeholderText = "Add comment at \(self.uiElement.formatTime(Double(atTime!)))"
            if !player.isPlaying {
                self.player.play()
            }
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
                self.comments[self.comments.count - 1].objectId = newComment.objectId
                MSAnalytics.trackEvent("comment added")
                
            } else {
                self.comments.removeLast()
                self.tableView.reloadData()
            }
        }
    }
    
    func loadComments(_ postId: String) {
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
            
            self.setUpTableView()
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

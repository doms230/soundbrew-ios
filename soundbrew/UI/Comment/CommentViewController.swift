//
//  CommentViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 2/28/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//
//Mark: MessageView, TableView, Data

import UIKit
import MessageViewController
import Parse
import Kingfisher

class CommentViewController: MessageViewController, UITableViewDataSource, UITableViewDelegate {
    
    var comments = [Comment]()
    let uiElement = UIElement()
    let color = Color()
    
    var postId: String?
    var atTime: Float?
    var player = Player.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(postId ?? "nil")
        if let postId = self.postId {
            loadComments(postId)
        }
    }
    
    //mark: MessageView
    func setUpMessageView() {
        borderColor = .lightGray
        //messageView.inset = UIEdgeInsets(top: 0, left: CGFloat(uiElement.leftOffset), bottom: 0, right: CGFloat(uiElement.rightOffset))
        messageView.inset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        messageView.font = UIFont(name: uiElement.mainFont, size: 17)
        messageView.textView.placeholderText = "Add Comment at \(self.uiElement.formatTime(Double(atTime!)))"
        messageView.textView.placeholderTextColor = .lightGray
        
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
        addNewComment(messageView.text, atTime: Double(atTime!), postId: postId!)
        
        let artist = Artist(objectId: PFUser.current()!.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, instagramUsername: nil, twitterUsername: nil, snapchatUsername: nil, isFollowedByCurrentUser: nil, followerCount: nil)
        let comment = Comment(objectId: nil, artist: artist, text: messageView.text, atTime: Float(atTime!))
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
    
    //mark: Tableview
    var tableView = UITableView()
    let commentReuse = "commentReuse"
    let noSoundsReuse = "noSoundsReuse"
    
    func setUpTableView() {
        tableView.dataSource = self
        tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: commentReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
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
            cell.headerTitle.text = "No Comments Yet. Be the first, and comment below. 😎"
            return cell
            
        } else {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: commentReuse) as! CommentTableViewCell
            let comment = comments[indexPath.row]
                        
            if let userImage =  comment.artist.image {
                cell.userImage.kf.setImage(with: URL(string: userImage))
                cell.username.text = comment.artist.username!
                
            } else {
                loadArtist(cell, userId: comment.artist.objectId, row: indexPath.row)
            }
            
            cell.comment.text = comment.text
            
            let atTime = self.uiElement.formatTime(Double(comment.atTime))
            cell.atTime.setTitle("\(atTime)", for: .normal)
            cell.atTime.addTarget(self, action: #selector(self.didPressAtTime(_:)), for: .touchUpInside)
            cell.atTime.tag = indexPath.row 
            return cell
        }
    }
    
    @objc func didPressAtTime(_ sender: UIButton) {
        if let player = self.player.player {
            player.currentTime = TimeInterval(self.comments[sender.tag].atTime)
            self.atTime = self.comments[sender.tag].atTime
            messageView.textView.placeholderText = "Comment at \(self.uiElement.formatTime(Double(atTime!)))"
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
                        
                        let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, instagramUsername: nil, twitterUsername: nil, snapchatUsername: nil, isFollowedByCurrentUser: nil, followerCount: nil)
                        
                        let comment = Comment(objectId: object.objectId!, artist: artist, text: text, atTime: Float(atTime))
                        
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
    
    func loadArtist(_ cell: CommentTableViewCell, userId: String, row: Int) {
        let query = PFQuery(className:"_User")
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                let username = user["username"] as? String
                cell.username.text = username
                
                let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: username, website: nil, bio: nil, email: nil, instagramUsername: nil, twitterUsername: nil, snapchatUsername: nil, isFollowedByCurrentUser: nil, followerCount: nil)
                
                if let name = user["artistName"] as? String {
                    //cell.soundArtist.text = name
                    artist.name = name
                }
                
                if let verified = user["artistVerified"] as? Bool {
                    artist.isVerified = verified
                }
                
                if let count = user["followerCount"] as? Int {
                    artist.followerCount = count
                }
                
                if let city = user["city"] as? String {
                    artist.city = city
                }
                
                if let image = user["userImage"] as? PFFileObject {
                    artist.image = image.url
                    cell.userImage.kf.setImage(with: URL(string: image.url!))
                }
                
                self.comments[row].artist = artist
            }
        }
    }
}

//
//  HomeViewController.swift
//  soundbrew
//
//  Created by Dominic Smith on 1/13/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import Kingfisher

class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PlayerDelegate {
    
    let uiElement = UIElement()
    let color = Color()
    var soundList: SoundList!
    var selectedIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotificationCenter()
        if let currentUserId = PFUser.current()?.objectId {
            loadFollowing(currentUserId)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let player = Player.sharedInstance
        if player.player != nil {
            setUpMiniPlayer()
        } else {
            setupCollectionView(nil)
        }
    }
    
    func setupNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSoundUpdate), name: NSNotification.Name(rawValue: "setSound"), object: nil)
    }
    @objc func didReceiveSoundUpdate(){
        if self.view.window != nil {
            let player = Player.sharedInstance
            if player.player != nil {
                self.setUpMiniPlayer()
            } else {
                setupCollectionView(nil)
            }
        }
    }
    
    var collectionView: UICollectionView!
    
    func setupCollectionView(_ miniPlayer: MiniPlayerView?) {
        collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.register(HomeCollectionViewCell.self, forCellWithReuseIdentifier: "reuse")
        self.collectionView.alwaysBounceVertical = true
        //self.view.addSubview(self.collectionView)
        if let miniPlayer = miniPlayer {
            self.view.addSubview(self.collectionView)
            self.collectionView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.view)
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
                make.bottom.equalTo(miniPlayer.snp.top)
            }
            
        } else {
            self.collectionView.frame = view.bounds
            self.view.addSubview(collectionView)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return friendPosts.count
    }
    
    var cell: HomeCollectionViewCell!
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "reuse", for: indexPath) as! HomeCollectionViewCell
        
            let artist = friendPosts[indexPath.row].artist!
            
            if let image = artist.image {
                cell.profileImage.kf.setImage(with: URL(string: image))
            } else {
                cell.profileImage.image = UIImage(named: "profile_icon")
            }
        
            if let selectedIndex = selectedIndex {
                if selectedIndex == indexPath.row {
                    cell.profileImage.layer.borderColor = color.blue().cgColor
                    cell.profileImage.layer.borderWidth = 5
                } else {
                    cell.profileImage.layer.borderColor = UIColor.darkGray.cgColor
                    cell.profileImage.layer.borderWidth = 1
                }
            }
            
            if let name = artist.name {
                cell.displayNameLabel.text = name
            } else {
                cell.displayNameLabel.text = "name"
            }
        
            if let username = artist.username {
                cell.username.text = "@\(username)"
            } else {
                cell.username.text = "@username"
            }
            
        self.cell = cell
            return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let selectedUserId = self.friendPosts[indexPath.row].artist?.objectId {
            self.selectedIndex = indexPath.row
            self.collectionView.reloadData()
            self.loadCollection(selectedUserId)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 130)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) //.zero
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    //
    var friendPosts = [Sound]()
    
    func loadFollowing(_ userId: String) {
        var friends = [Artist]()
        let query = PFQuery(className: "Follow")
        query.whereKey("fromUserId", equalTo: userId)
        query.whereKey("isRemoved", equalTo: false)
        query.addDescendingOrder("createdAt")
        query.limit = 100
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let userId = object["toUserId"] as! String
                        let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil)
                        artist.loadUserInfoFromCloud(nil, soundCell: nil)
                        friends.append(artist)
                    }
                    //print("friends \(friends.count)")
                    self.loadFriendsLatestSounds(friends)
                }
                
            } else {
               // print("Error: \(error!)")
            }
        }
    }
    
    func loadFriendsLatestSounds(_ friends: Array<Artist>) {
        for i in 0..<friends.count {
            let friendId = friends[i].objectId
            let query = PFQuery(className: "Post")
            query.whereKey("userId", equalTo: friendId!)
            query.whereKey("isDraft", notEqualTo: true)
            query.whereKey("isRemoved", notEqualTo: true)
            query.addDescendingOrder("createdAt")
              query.getFirstObjectInBackground {
                  (object: PFObject?, error: Error?) -> Void in
                    var post: Sound!
                    if let object = object {
                        post = self.uiElement.newSoundObject(object)
                        post!.artist = friends[i]
                    } else {
                        let sound = Sound(objectId: nil, title: nil, artURL: nil, artImage: nil, artFile: nil, tags: nil, createdAt: nil, plays: nil, audio: nil, audioURL: nil, audioData: nil, artist: friends[i], tmpFile: nil, tips: nil, tippers: nil, isDraft: nil, isNextUpToPlay: false)
                        post = sound
                    }
                                    
                    let isLastIndex = friends.indices.contains(i + 1)
                    self.loadLatestCollectedItem(friendId!, latestPost: post, isLastIndex: isLastIndex)
              }
        }
    }
    
    func loadLatestCollectedItem(_ friendId: String, latestPost: Sound, isLastIndex: Bool) {
        let query = PFQuery(className: "Tip")
        query.whereKey("fromUserId", equalTo: friendId)
        query.addDescendingOrder("createdAt")
          query.getFirstObjectInBackground {
              (object: PFObject?, error: Error?) -> Void in
                var collectionCreatedAt: Date?
                    if let object = object {
                        collectionCreatedAt = object.createdAt!
                    }
                                
                //if the last thing the user did was collect audio, want that to be tracked when sorting story
                if let collectionCreatedAt = collectionCreatedAt {
                    if let latestPostCreatedAt = latestPost.createdAt {
                        if collectionCreatedAt > latestPostCreatedAt {
                            latestPost.createdAt = collectionCreatedAt
                        }
                    } else {
                        latestPost.createdAt = collectionCreatedAt
                    }
                }

                if latestPost.createdAt != nil {
                    self.friendPosts.append(latestPost)
                }
                
                if isLastIndex {
                    self.friendPosts.sort(by: {$0.createdAt! > $1.createdAt!})
                    self.setupCollectionView(nil)
                }
          }
    }
    
    //mark: miniPlayer
    var miniPlayerView: MiniPlayerView?
    func setUpMiniPlayer() {
        miniPlayerView = MiniPlayerView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        self.view.addSubview(miniPlayerView!)
        let slide = UISwipeGestureRecognizer(target: self, action: #selector(self.miniPlayerWasSwiped))
        slide.direction = .up
        miniPlayerView!.addGestureRecognizer(slide)
        miniPlayerView!.addTarget(self, action: #selector(self.miniPlayerWasPressed(_:)), for: .touchUpInside)
        miniPlayerView!.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-((self.tabBarController?.tabBar.frame.height)!))
        }
        
        setupCollectionView(self.miniPlayerView)
    }
    
    @objc func miniPlayerWasSwiped() {
        showPlayerViewController()
    }
    
    @objc func miniPlayerWasPressed(_ sender: UIButton) {
        showPlayerViewController()
    }
    
    func showPlayerViewController() {
        let player = Player.sharedInstance
        if player.player != nil {
            let modal = PlayerViewController()
            modal.playerDelegate = self
            self.present(modal, animated: true, completion: nil)
        }
    }
    
    func selectedArtist(_ artist: Artist?) {
        if let artist = artist {
            if artist.objectId == "addFunds" {
                self.performSegue(withIdentifier: "showAddFunds", sender: self)
            } else if artist.objectId == "signup" {
                self.performSegue(withIdentifier: "showWelcome", sender: self)
            } else if artist.objectId == "collectors" {
                if let currentSound = Player.sharedInstance.currentSound {
                    soundList.selectedSound = currentSound
                }
                self.performSegue(withIdentifier: "showTippers", sender: self)
            } else {
                soundList.selectedArtist(artist)
            }
        }
    }
    
    func loadCollection(_ userId: String) {
        var collectionSoundIds = [String]()
        let query = PFQuery(className: "Tip")
        query.whereKey("fromUserId", equalTo: userId)
        query.addDescendingOrder("createdAt")
        query.limit = 25
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        collectionSoundIds.append(object["soundId"] as! String)
                    }
                }
                self.loadSounds(userId, collectionSoundIds: collectionSoundIds)
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func loadSounds(_ userId: String, collectionSoundIds: Array<String>) {
        let uploadedQuery = PFQuery(className: "Post")
        uploadedQuery.whereKey("isRemoved", notEqualTo: true)
        uploadedQuery.whereKey("isDraft", notEqualTo: true)
        uploadedQuery.whereKey("userId", equalTo: userId)
        
        let collectionQuery = PFQuery(className: "Post")
        collectionQuery.whereKey("isRemoved", notEqualTo:true)
        collectionQuery.whereKey("isDraft", notEqualTo: true)
        collectionQuery.whereKey("objectId", containedIn: collectionSoundIds)
        
        let query = PFQuery.orQuery(withSubqueries: [uploadedQuery, collectionQuery])
        query.limit = 50
        query.addDescendingOrder("createdAt")
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    var sounds = [Sound]()
                    for object in objects {
                        let newSoundObject = self.uiElement.newSoundObject(object)
                        print(newSoundObject.title!)
                        sounds.append(newSoundObject)
                    }
                    
                    let player = Player.sharedInstance
                    player.player = nil
                    player.sounds = sounds
                    player.currentSound = sounds[0]
                    player.currentSoundIndex = 0
                    player.setUpNextSong(false, at: 0)
                }
            } else {
                print("Error: \(error!)")
            }
        }
    }
}

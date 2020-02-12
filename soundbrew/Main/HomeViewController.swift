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

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, PlayerDelegate, TagDelegate {
    
    let uiElement = UIElement()
    let color = Color()
    var soundList: SoundList!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Stories"
        setupNotificationCenter()
        loadFriendStories()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let player = Player.sharedInstance
        if player.player != nil {
            setUpMiniPlayer()
        } else {
            setUpTableView(nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showProfile":
            soundList.prepareToShowSelectedArtist(segue)
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
            break
            
        case "showSounds":
            let viewController = segue.destination as! SoundsViewController
            viewController.selectedTagForFiltering = self.selectedTagFromPlayerView
            viewController.soundType = "discover"
            
            let backItem = UIBarButtonItem()
            backItem.title = self.selectedTagFromPlayerView.name
            navigationItem.backBarButtonItem = backItem
            break
            
        default:
            break
        }
    }
    
    func setupNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSoundUpdate), name: NSNotification.Name(rawValue: "setSound"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveFriendsLoaded), name: NSNotification.Name(rawValue: "friendsLoaded"), object: nil)
    }
    @objc func didReceiveSoundUpdate(){
        if self.view.window != nil {
            let player = Player.sharedInstance
            if player.player != nil {
                self.setUpMiniPlayer()
            } else {
                setUpTableView(nil)
            }
        }
    }
    @objc func didReceiveFriendsLoaded() {
        if !didGetInitialFriendsList {
            loadFriendStories()
        }
    }
    
    //MARK: Tableview
    var tableView: UITableView!
    let homeReuse = "homeReuse"
    var selectedIndexPath: IndexPath?
    
    func setUpTableView(_ miniPlayer: UIView?) {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: homeReuse)
        tableView.separatorStyle = .none
        tableView.backgroundColor = color.black()
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl
        if let miniPlayer = miniPlayer {
            self.view.addSubview(tableView)
            self.tableView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.view)
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
                make.bottom.equalTo(miniPlayer.snp.top)
            }
            
        } else {
            self.tableView.frame = view.bounds
            self.view.addSubview(tableView)
        }
    }
    
    @objc func refresh(_ sender: UIRefreshControl) {
        loadFriendStories()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendsStories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: homeReuse) as! ProfileTableViewCell
       
        let artist = friendsStories[indexPath.row].artist!
        
        if let username = artist.username {
            cell.username.text = "@\(username)"
        } else {
            print("load artist")
            cell.username.text = "@username"
            artist.loadUserInfoFromCloud(cell, soundCell: nil, commentCell: nil)
        }
       
        if let image = artist.image {
            cell.profileImage.kf.setImage(with: URL(string: image))
        } else {
            cell.profileImage.image = UIImage(named: "profile_icon")
        }
           
        if let name = artist.name {
            cell.displayNameLabel.text = name
        } else {
            cell.displayNameLabel.text = "name"
        }
        
         if let dateCreated = friendsStories[indexPath.row].lastUpdated {
            cell.city.text = "\(self.uiElement.formatDateAndReturnString(dateCreated))"
         }
         
             /*if let didCurrentUserListenToStory = friendsStories[indexPath.row].didListenToLatest {
                 if didCurrentUserListenToStory {
                     cell.city.text = "Listened"
                 } else {
                     cell.city.text = "Un-Listened"
                 }
             } else {
                 cell.city.text = ""
             }*/
        
            if let selectedIndexPath = self.selectedIndexPath {
                if selectedIndexPath == indexPath {
                    cell.homebackgroundView.image = UIImage(named: "background")
                   // cell.profileImage.layer.borderColor = color.blue().cgColor
                   // cell.profileImage.layer.borderWidth = 5
                } else {
                    cell.homebackgroundView.image = UIImage()
                    //cell.profileImage.layer.borderColor = UIColor.darkGray.cgColor
                   // cell.profileImage.layer.borderWidth = 1
                }
            }
           
           return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            if let selectedUserId = friendsStories[indexPath.row].artist?.objectId {
                self.selectedIndexPath = indexPath
                tableView.reloadData()
                soundList = SoundList(target: self, tableView: nil, soundType: "story", userId: selectedUserId, tags: nil, searchText: nil, descendingOrder: "createdAt", linkObjectId: nil)
            }
    }
    
    //
    var friendsStories = [Story]()
    var didGetInitialFriendsList = false
    func loadFriendStories() {
        if let friendUserIds = self.uiElement.getUserDefault("friends") as? [String] {
            didGetInitialFriendsList = true
            self.friendsStories.removeAll()
            for friendUserId in friendUserIds {
                print(friendUserId)
                let query = PFQuery(className: "Story")
                query.whereKey("userId", equalTo: friendUserId)
                query.addDescendingOrder("createdAt")
                query.getFirstObjectInBackground {
                      (object: PFObject?, error: Error?) -> Void in
                        if let object = object {
                            let friend = Artist(objectId: friendUserId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil)
                            //friend.loadUserInfoFromCloud(nil, soundCell: nil, commentCell: nil)
                            let story = Story(friend, lastUpdated: object.createdAt, didListenToLatest: false)
                            let postId = object["postId"] as! String
                            self.determineIfUserListened(postId, story: story)
                        }
                  }
            }
        }
    }
    
    func determineIfUserListened(_ postId: String, story: Story) {
        let query = PFQuery(className: "Listen")
        query.whereKey("userId", equalTo: story.artist.objectId!)
        query.whereKey("postId", equalTo: postId)
        query.getFirstObjectInBackground {
              (object: PFObject?, error: Error?) -> Void in
            if object != nil {
                story.didListenToLatest = true
                story.lastUpdated = object?.createdAt
            }
            self.friendsStories.append(story)
            
            self.friendsStories.sort(by: {$0.lastUpdated! > $1.lastUpdated!})
            if self.tableView != nil {
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            } else {
                self.setUpTableView(nil)
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
        
        self.setUpTableView(self.miniPlayerView)
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
    
    //mark: tags
    var selectedTagFromPlayerView: Tag!
    func receivedTags(_ chosenTags: Array<Tag>?) {
        if let tags = chosenTags {
            self.selectedTagFromPlayerView = tags[0]
            self.performSegue(withIdentifier: "showSounds", sender: self)
        }
    }
    
}

class Story {
    var artist: Artist!
    var lastUpdated: Date?
    var didListenToLatest: Bool?
    
    init(_ artist: Artist, lastUpdated: Date?, didListenToLatest: Bool?) {
        self.artist = artist
        self.lastUpdated = lastUpdated
        self.didListenToLatest = didListenToLatest
    }
}

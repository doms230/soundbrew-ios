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

class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PlayerDelegate, TagDelegate {
    
    let uiElement = UIElement()
    let color = Color()
    var soundList: SoundList!
    var storiesAreLoading = true
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        self.navigationItem.title = "Soundbrew"
        setupNotificationCenter()
        loadFriendStories()
        if let soundId = self.uiElement.getUserDefault("receivedSoundId") as? String {
            UserDefaults.standard.removeObject(forKey: "receivedSoundId")
            loadDynamicLinkSound(soundId, shouldShowShareSoundView: false)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showProfile":
            let viewController = segue.destination as! ProfileViewController
            viewController.profileArtist = selectedArtist
            
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
            
        case "showTags":
            let viewController = segue.destination as! SoundsViewController
            viewController.selectedTagForFiltering = self.selectedTagFromPlayerView
            viewController.soundType = "discover"
            
            let backItem = UIBarButtonItem()
            backItem.title = self.selectedTagFromPlayerView.name
            navigationItem.backBarButtonItem = backItem
            break
            
        default:
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
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
                setupCollectionView(nil)
            }
        }
    }
    @objc func didReceiveFriendsLoaded() {
        if !didGetInitialFriendsList {
            loadFriendStories()
        }
    }
    
    var collectionView: UICollectionView!
    var selectedIndexPath: IndexPath?
    var cell: HomeCollectionViewCell!
    
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
        return unListenedStories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return storyCell(indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let selectedUserId = unListenedStories[indexPath.row].artist.objectId {
            self.selectedIndexPath = indexPath
            collectionView.reloadData()
            soundList = SoundList(target: self, tableView: nil, soundType: "story", userId: selectedUserId, tags: nil, searchText: nil, descendingOrder: "createdAt", linkObjectId: nil)
        }

        /*if indexPath.section == 0 {
            self.selectedIndexPath = indexPath
            collectionView.reloadData()
            soundList = SoundList(target: self, tableView: nil, soundType: "yourSoundbrew", userId: nil, tags: nil, searchText: nil, descendingOrder: "createdAt", linkObjectId: nil)
            
        } else if let selectedUserId = unListenedStories[indexPath.row].artist.objectId {
            self.selectedIndexPath = indexPath
            collectionView.reloadData()
            soundList = SoundList(target: self, tableView: nil, soundType: "story", userId: selectedUserId, tags: nil, searchText: nil, descendingOrder: "createdAt", linkObjectId: nil)
        }*/
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let collectionViewSize = collectionView.frame.size.width
        return CGSize(width: collectionViewSize/2, height: collectionViewSize/2)
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
 
    
    func storyCell(_ indexPath: IndexPath) -> HomeCollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "reuse", for: indexPath) as! HomeCollectionViewCell
        
        let story = unListenedStories[indexPath.row]
        let artist = unListenedStories[indexPath.row].artist!
        
        if let image = artist.image {
            cell.profileImage.kf.setImage(with: URL(string: image))
        } else {
            cell.profileImage.image = UIImage(named: "profile_icon")
        }
        
        if let selectedIndexPath = self.selectedIndexPath {
            if selectedIndexPath.row == indexPath.row {
                cell.view.image = UIImage(named: "background")
                //cell.profileImage.layer.borderColor = color.blue().cgColor
                //cell.profileImage.layer.borderWidth = 5
            } else {
                cell.view.image = UIImage()
                //cell.profileImage.layer.borderColor = UIColor.darkGray.cgColor
                //cell.profileImage.layer.borderWidth = 1
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
            artist.loadUserInfoFromCloud(nil, soundCell: nil, commentCell: nil, HomeCollectionCell: cell)
        }
        
        if let storyType = story.type {
            cell.storyType.text = "New \(storyType.capitalized)"
        }
            
        self.cell = cell
        return cell
    }
    
    func changeArtistStoryColor(_ cell: ProfileTableViewCell, color: UIColor) {
        cell.username.textColor = color
        cell.displayNameLabel.textColor = color
        if color == .white {
            cell.userCity.textColor = .darkGray
            cell.city.textColor = .darkGray
        } else {
            cell.userCity.textColor = color
            cell.city.textColor = color
        }
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /*if indexPath.section == 0 {
            self.selectedIndexPath = indexPath
            tableView.reloadData()
            soundList = SoundList(target: self, tableView: nil, soundType: "yourSoundbrew", userId: nil, tags: nil, searchText: nil, descendingOrder: "createdAt", linkObjectId: nil)
            
        } else if let selectedUserId = unListenedStories[indexPath.row].artist.objectId {
            self.selectedIndexPath = indexPath
            tableView.reloadData()
            soundList = SoundList(target: self, tableView: nil, soundType: "story", userId: selectedUserId, tags: nil, searchText: nil, descendingOrder: "createdAt", linkObjectId: nil)
        }*/
    }
    
    func removeUnlistenedStoryAndAddToListenedStories(_ row: Int, story: Story) {
        self.unListenedStories.remove(at: row)
        listenedStories.append(story)
        self.listenedStories.sort(by: {$0.lastUpdated! > $1.lastUpdated!})
      //  self.tableView.reloadData()
    }
    
    //
    var unListenedStories = [Story]()
    var listenedStories = [Story]()
    var didGetInitialFriendsList = false
    func loadFriendStories() {
        self.storiesAreLoading = true
        if let friendUserIds = self.uiElement.getUserDefault("friends") as? [String] {
            didGetInitialFriendsList = true
            self.unListenedStories.removeAll()
            self.listenedStories.removeAll()
            for i in 0..<friendUserIds.count {
                let friendUserId = friendUserIds[i]
                let query = PFQuery(className: "Story")
                query.whereKey("userId", equalTo: friendUserId)
                query.addDescendingOrder("createdAt")
                query.getFirstObjectInBackground {
                      (object: PFObject?, error: Error?) -> Void in
                    if let object = object {
                        let friend = Artist(objectId: friendUserId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil)
                        let story = Story(friend, lastUpdated: object.createdAt, type: nil)
                        if let type = object["type"] as? String {
                            story.type = type
                        }
                        self.unListenedStories.append(story)
                        self.unListenedStories.sort(by: {$0.lastUpdated! > $1.lastUpdated!})
                        self.setUpOrReloadTableView()
                    }
                }
            }
        }
    }
    
    func determineIfUserListened(_ postId: String, story: Story) {
        let query = PFQuery(className: "Listen")
        query.whereKey("userId", equalTo: PFUser.current()!.objectId!)
        query.whereKey("postId", equalTo: postId)
        query.getFirstObjectInBackground {
              (object: PFObject?, error: Error?) -> Void in
            if object != nil {
                print(object!["postId"] as! String)
                self.listenedStories.append(story)
                self.listenedStories.sort(by: {$0.lastUpdated! > $1.lastUpdated!})
            } else {
                self.unListenedStories.append(story)
                self.unListenedStories.sort(by: {$0.lastUpdated! > $1.lastUpdated!})
            }
            
            self.setUpOrReloadTableView()
          }
    }
    
    func setUpOrReloadTableView() {
        self.storiesAreLoading = false
        if self.collectionView != nil {
           // self.tableView.refreshControl?.endRefreshing()
           // self.tableView.reloadData()
            self.collectionView.reloadData()
        } else {
            self.setupCollectionView(nil)
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
        
        self.setupCollectionView(self.miniPlayerView)
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
            modal.tagDelegate = self 
            self.present(modal, animated: true, completion: nil)
        }
    }
    
    var selectedArtist: Artist?
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
                self.selectedArtist = artist
                self.performSegue(withIdentifier: "showProfile", sender: self)
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
    
    func loadDynamicLinkSound(_ objectId: String, shouldShowShareSoundView: Bool) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                let sound = self.uiElement.newSoundObject(object)
                if shouldShowShareSoundView {
                    self.uiElement.showShareOptions(self, sound: sound)
                }
                self.resetPlayer(sounds: [sound])
            }
        }
    }
    
    func resetPlayer(sounds: [Sound]) {
        let player = Player.sharedInstance
        player.player = nil
        player.sounds = sounds
        player.currentSound = sounds[0]
        player.currentSoundIndex = 0
        player.setUpNextSong(false, at: 0)
    }
}

class Story {
    var artist: Artist!
    var lastUpdated: Date?
    var type: String?
    init(_ artist: Artist, lastUpdated: Date?, type: String?) {
        self.artist = artist
        self.lastUpdated = lastUpdated
        self.type = type
    }
}

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

/*class StoryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PlayerDelegate, TagDelegate {
    
    let uiElement = UIElement()
    let color = Color()
    var soundList: SoundList!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        self.navigationItem.title = "Updates"
        setupNotificationCenter()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let player = Player.sharedInstance
        if player.player != nil {
            setUpMiniPlayer()
        } else {
            setupCollectionView()
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
                setupCollectionView()
            }
        }
    }
    @objc func didReceiveFriendsLoaded() {
        if !didGetInitialFriendsList {
            loadFriendStories()
        }
    }
    
    //mark: collectionview
    var collectionView: UICollectionView!
    var selectedIndexPath: IndexPath?
    var cell: StoryColl!
    
    func setupCollectionView() {
        collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.register(HomeCollectionViewCell.self, forCellWithReuseIdentifier: "reuse")
        self.collectionView.alwaysBounceVertical = true
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        collectionView.refreshControl = refreshControl
        if let miniPlayerView = self.miniPlayerView {
            self.view.addSubview(self.collectionView)
            self.collectionView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.view)
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
                make.bottom.equalTo(miniPlayerView.snp.top)
            }
            
        } else {
            self.collectionView.frame = view.bounds
            self.view.addSubview(collectionView)
        }
    }
    
    @objc func refresh(_ sender: UIRefreshControl) {
       loadFriendStories()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if stories.count == 0 {
            return 1
        }
        
        return stories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return storyCell(indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if stories.indices.contains(indexPath.row), let selectedUserId = stories[indexPath.row].artist.objectId {
             self.selectedIndexPath = indexPath
            self.collectionView.reloadData()
             soundList = SoundList(target: self, tableView: nil, soundType: "story", userId: selectedUserId, tags: nil, searchText: nil, descendingOrder: "createdAt", linkObjectId: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let collectionViewSize = collectionView.frame.size.width
        if stories.count == 0 {
            return CGSize(width: collectionViewSize, height: (collectionViewSize - 30) / 2)
        } else {
            return CGSize(width: collectionViewSize/2, height: (collectionViewSize + 35) / 2)
        }
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
        
        if stories.count == 0 {
            cell.profileImage.image = UIImage()
            cell.profileImage.isHidden = true
            cell.displayNameLabel.text = ""
            cell.username.text = "Follow your friends and favorite artists to keep up with their latest uploads, likes, and credits!"
            cell.username.numberOfLines = 0
            cell.storyType.text = ""
            cell.storyCreatedAt.text = ""
        } else {
            let story = stories[indexPath.row]
            let artist = story.artist!
            
            cell.profileImage.isHidden = false 
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
            
            if let username = artist.username {
                cell.username.text = "@\(username)"
            } else {
                cell.username.text = "@username"
                artist.loadUserInfoFromCloud(nil, soundCell: nil, commentCell: nil, HomeCollectionCell: cell, artistUsernameLabel: nil, artistImageButton: nil)
            }
            cell.username.numberOfLines = 1
            
            if let storyType = story.type {
                cell.storyType.isHidden = false
                cell.storyType.text = "New \(storyType.capitalized)"
            }
            
            cell.storyCreatedAt.text = self.uiElement.formatDateAndReturnString(story.lastUpdated!)
            cell.storyCreatedAt.isHidden = false
                        
            self.cell = cell
        }
        
        if let selectedIndexPath = self.selectedIndexPath {
            if selectedIndexPath.row == indexPath.row, selectedIndexPath.section == indexPath.section {
                cell.view.image = UIImage(named: "background")
            } else {
                cell.view.image = UIImage()
            }
        }
        
        return cell
    }
    
    var stories = [Story]()
    var didGetInitialFriendsList = false
    func loadFriendStories() {
        if let friendUserIds = self.uiElement.getUserDefault("friends") as? [String] {
            didGetInitialFriendsList = true
            let storyObjectIds = self.stories.map {$0.objectId}
            if friendUserIds.count == 0 {
                self.setUpOrReloadTableView()
            } else {
                for i in 0..<friendUserIds.count {
                    let friendUserId = friendUserIds[i]
                    let query = PFQuery(className: "Story")
                    query.whereKey("userId", equalTo: friendUserId)
                    query.addDescendingOrder("createdAt")
                    query.getFirstObjectInBackground {
                          (object: PFObject?, error: Error?) -> Void in
                        if let object = object, !storyObjectIds.contains(object.objectId) {
                            let friend = Artist(objectId: friendUserId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil)
                             let story = Story(friend, lastUpdated: object.createdAt, type: nil, objectId: object.objectId!)
                             if let type = object["type"] as? String {
                                 story.type = type
                             }
                            self.stories.append(story)
                        }
                        
                        //is last index
                        if i == friendUserIds.count - 1 {
                            self.stories.sort(by: {$0.lastUpdated! > $1.lastUpdated!})
                            self.setUpOrReloadTableView()
                        }
                    }
                }
            }
        } else {
            self.setUpOrReloadTableView()
        }
    }
    
    func setUpOrReloadTableView() {
        let player = Player.sharedInstance
        if player.player != nil {
            self.setUpMiniPlayer()
        } else if self.collectionView != nil {
            self.collectionView.refreshControl?.endRefreshing()
            self.collectionView.reloadData()
        } else {
            self.setupCollectionView()
        }
    }
    
    //mark: miniPlayer
    var miniPlayerView: MiniPlayerView?
    func setUpMiniPlayer() {
        DispatchQueue.main.async {
            self.miniPlayerView = MiniPlayerView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            self.view.addSubview(self.miniPlayerView!)
            let slide = UISwipeGestureRecognizer(target: self, action: #selector(self.miniPlayerWasSwiped))
            slide.direction = .up
            self.miniPlayerView!.addGestureRecognizer(slide)
            self.miniPlayerView!.addTarget(self, action: #selector(self.miniPlayerWasPressed(_:)), for: .touchUpInside)
            self.miniPlayerView!.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(50)
                make.right.equalTo(self.view)
                make.left.equalTo(self.view)
                make.bottom.equalTo(self.view).offset(-((self.tabBarController?.tabBar.frame.height)!))
            }
            
            self.setupCollectionView()
        }
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
}*/

class Story {
    var artist: Artist!
    var lastUpdated: Date?
    var type: String?
    var objectId: String!
    init(_ artist: Artist, lastUpdated: Date?, type: String?, objectId: String!) {
        self.artist = artist
        self.lastUpdated = lastUpdated
        self.type = type
        self.objectId = objectId
    }
}

//
//  CollectionViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 8/6/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import Kingfisher
import SnapKit
import AppCenterAnalytics

class UpdatesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, PlayerDelegate {
    
    let uiElement = UIElement()
    let color = Color()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if PFUser.current() != nil {
            let player = Player.sharedInstance
            if player.player != nil {
                setUpMiniPlayer()
            } else if PFUser.current() != nil {
                setUpTableView(nil)
            }
            
            loadNewFollows()
        } else {
            let localizedRegisterForUpdatesMessage = NSLocalizedString("registerForUpdatesMessage", comment: "")
            self.uiElement.welcomeAlert(localizedRegisterForUpdatesMessage, target: self)
        }
        
        let installation = PFInstallation.current()
        installation?.badge = 0
        installation?.saveEventually()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfile" {
            let viewController = segue.destination as! ProfileViewController
            viewController.profileArtist = selectedArtist
            
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
        } else if segue.identifier == "showTippers" {
            if let currentSound = Player.sharedInstance.currentSound {
                let viewController = segue.destination as! PeopleViewController
                viewController.sound = currentSound
            }
            
            let localizedCollectors = NSLocalizedString("collectors", comment: "")
            let backItem = UIBarButtonItem()
            backItem.title = localizedCollectors
            navigationItem.backBarButtonItem = backItem
        }
    }
    
    //mark: tableview
    var tableView = UITableView()
    let updatesReuse = "updatesReuse"
    let noSoundsReuse = "noSoundsReuse"
    func setUpTableView(_ miniPlayer: UIView?) {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: updatesReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = color.black()
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if updates.count == 0 {
            return 1
        }
        return updates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if updates.count == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
            cell.backgroundColor = color.black()
            let localizedNewCollectorsAndFollowersMessage = NSLocalizedString("NewCollectorsAndFollowersMessage", comment: "")
            cell.headerTitle.text = localizedNewCollectorsAndFollowersMessage
            return cell
        } else {
           return updatesCell(indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        selectedArtist = updates[indexPath.row].artist
        self.performSegue(withIdentifier: "showProfile", sender: self)
        MSAnalytics.trackEvent("Updates View Controller", withProperties: ["Button" : "Did Select Person"])
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
        
        setUpTableView(miniPlayerView!)
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
            //modal.player = player
            modal.playerDelegate = self
            self.present(modal, animated: true, completion: nil)
        }
    }
    
    //mark: selectedArtist
    var selectedArtist: Artist!
    
    func selectedArtist(_ artist: Artist?) {
        if let artist = artist {
            if artist.objectId == "addFunds" {
                self.performSegue(withIdentifier: "showAddFunds", sender: self)
            } else if artist.objectId == "signup" {
                self.performSegue(withIdentifier: "showWelcome", sender: self)
            } else if artist.objectId == "collectors" {
                self.performSegue(withIdentifier: "showTippers", sender: self)
            } else {
                selectedArtist = artist
                self.performSegue(withIdentifier: "showProfile", sender: self)
            }
        }
    }
    
    //Updates 
    var updates = [Update]()
    let localizedFollowedYou = NSLocalizedString("followedYou", comment: "")
    let localizedCollected = NSLocalizedString("collected", comment: "")
    let localizedFor = NSLocalizedString("for", comment: "")
    
    func updatesCell(_ indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: updatesReuse) as! ProfileTableViewCell
        cell.backgroundColor = color.black()
        let update = self.updates[indexPath.row]
        
        if let image = update.artist.image {
            cell.profileImage.kf.setImage(with: URL(string: image))
            let name = self.getName(update.artist)
            if update.soundId != nil {
                let tipAmountInDollarString = self.uiElement.convertCentsToDollarsAndReturnString(update.tipAmount!, currency: "$")
                cell.displayNameLabel.text = "\(name) \(localizedCollected) \(update.soundName!) \(localizedFor) \(tipAmountInDollarString)."
                cell.displayNameLabel.textColor = color.green()
            } else {
                cell.displayNameLabel.text = "\(name) \(localizedFollowedYou)"
                cell.displayNameLabel.textColor = .white
            }
            
        } else {
            loadUserInfoFromCloud(update.artist.objectId, cell: cell, indexPath: indexPath)
        }
        
        //createdAt
        cell.city.text = self.uiElement.formatDateAndReturnString(update.createdAt)
        
        return cell
    }

    func loadUserInfoFromCloud(_ userId: String, cell: ProfileTableViewCell, indexPath: IndexPath) {
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                let artist = self.uiElement.newArtistObject(user)
                if let userImageFile = artist.image {
                    cell.profileImage.kf.setImage(with: URL(string: userImageFile))
                }
                self.updates[indexPath.row].artist = artist
                if let soundId = self.updates[indexPath.row].soundId {
                    self.loadSound(soundId, cell: cell, indexPath: indexPath)
                } else {
                    let name = self.getName(artist)
                    cell.displayNameLabel.text = "\(name) \(self.localizedFollowedYou)"
                    cell.displayNameLabel.textColor = .white
                }
            }
        }
    }
    
    func loadSound(_ soundId: String, cell: ProfileTableViewCell, indexPath: IndexPath) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: soundId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                let title = object["title"] as! String
                let tipAmountInDollarString = self.uiElement.convertCentsToDollarsAndReturnString(self.updates[indexPath.row].tipAmount!, currency: "$")
                let name = self.getName(self.updates[indexPath.row].artist)
                cell.displayNameLabel.text = "\(name) \(self.localizedCollected) \(title) \(self.localizedFor) \(tipAmountInDollarString)."
                cell.displayNameLabel.textColor = self.color.green()
                self.updates[indexPath.row].soundName = title
            }
        }
    }
    
    func getName(_ artist: Artist) -> String {
        if let username = artist.username {
            return username
        } else if let artistName = artist.name {
            return artistName
        }
        return ""
    }
    
    func loadNewFollows() {
        let query = PFQuery(className: "Follow")
        query.whereKey("toUserId", equalTo: PFUser.current()!.objectId!)
        query.whereKey("isRemoved", equalTo: false)
        var followIds = [String]()
        for update in updates {
            if let followId = update.followId {
                followIds.append(followId)
            }
        }
        query.whereKey("objectId", notContainedIn: followIds)
        query.limit = 25
        query.addDescendingOrder("createdAt")
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let userObjectId = object["fromUserId"] as! String
                        let artist = Artist(objectId: userObjectId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil)
                        let update = Update(object.createdAt!, artist: artist, tipAmount: nil, soundId: nil, soundName: nil, tipId: nil, followId: object.objectId!)
                        self.updates.append(update)
                    }
                }
                self.loadNewTips()
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func loadNewTips() {
        let query = PFQuery(className: "Tip")
        query.whereKey("toUserId", equalTo: PFUser.current()!.objectId!)
        var tipIds = [String]()
        for update in updates {
            if let tipId = update.tipId {
                tipIds.append(tipId)
            }
        }
        query.whereKey("objectId", notContainedIn: tipIds)
        query.limit = 25
        query.addDescendingOrder("updatedAt")
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let userObjectId = object["fromUserId"] as! String
                        let tipAmount = object["amount"] as! Int
                        let soundId = object["soundId"] as! String
                        let artist = Artist(objectId: userObjectId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil)
                        let update = Update(object.updatedAt!, artist: artist, tipAmount: tipAmount, soundId: soundId, soundName: nil, tipId: object.objectId!, followId: nil)
                        self.updates.append(update)
                    }
                }
                
                    self.updates.sort(by: {$0.createdAt > $1.createdAt})
                   self.tableView.reloadData()
                    if self.updates.count > 0 {
                        SKStoreReviewController.requestReview()
                    }
            } else {
                print("Error: \(error!)")
            }
        }
    }
}

class Update {
    var createdAt: Date!
    var artist: Artist!
    var tipAmount: Int?
    var soundId: String?
    var soundName: String?
    var tipId: String?
    var followId: String?
    
    init(_ createdAt: Date, artist: Artist, tipAmount: Int?, soundId: String?, soundName: String?, tipId: String?, followId: String?) {
        self.createdAt = createdAt
        self.artist = artist
        self.tipAmount = tipAmount
        self.soundId = soundId
        self.soundName = soundName
        self.tipId = tipId
        self.followId = followId
    }
}

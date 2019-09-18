//
//  SoundList.swift
//  soundbrew
//
//  Created by Dominic  Smith on 3/21/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//
//  This class handles the logic behind showing Sounds Uploaded to Soundbrew.
//  SoundsViewController.swift utilize this class
//
// MARK: tableView, sounds, artist, tags filter, data, miniplayer, comment, search

import Foundation
import UIKit
import Parse
import AppCenterAnalytics

class SoundList: NSObject, PlayerDelegate {
    var target: UIViewController!
    var tableView: UITableView?
    var sounds = [Sound]()
    let uiElement = UIElement()
    let color = Color()
    var profileUserId: String?
    var player: Player?
    var collectionSoundIds = [String]()

    var followUserIds = [String]()
    var soundType: String!
    var didLoadCollection = false
    var searchText: String?
    var domSmithUserId = "AWKPPDI4CB"
    var linkObjectId: String?
    
    init(target: UIViewController, tableView: UITableView?, soundType: String, userId: String?, tags: Tag?, searchText: String?, descendingOrder: String?, linkObjectId: String?) {
        super.init()
        self.target = target
        self.tableView = tableView
        self.soundType = soundType
        self.profileUserId = userId
        self.selectedTagForFiltering = tags
        self.searchText = searchText
        self.linkObjectId = linkObjectId
        if let descendingOrder = descendingOrder {
            self.descendingOrder = descendingOrder
        }
        player = Player.sharedInstance
        player?.target = target
        player?.tableView = tableView
        determineTypeOfSoundToLoad(soundType)
    }
    
    lazy var noResultsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 20)
        label.text = "Welcome to Soundbrew! The latest releases from artists you follow will appear here."
        label.numberOfLines = 0
        return label
    }()
    
    func showNoResultsLabel() {
        self.tableView?.isHidden = true
        target.view.addSubview(noResultsLabel)
        noResultsLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(target.view).offset(uiElement.uiViewTopOffset(target))
            make.left.equalTo(target.view).offset(uiElement.leftOffset)
            make.right.equalTo(target.view).offset(uiElement.rightOffset)
        }
    }
    
    //mark: tableView
    let filterSoundsReuse = "filterSoundsReuse"
    func setUpTableView() {
        if let player = self.player {
            player.tableView = self.tableView
        }
    }
    
    //mark: artist
    var selectedArtist: Artist!
    
    func prepareToShowSelectedArtist(_ segue: UIStoryboardSegue) {
        let viewController = segue.destination as! ProfileViewController
        viewController.profileArtist = selectedArtist
    }
    
    func selectedArtist(_ artist: Artist?) {
        if let selectedArtist = artist {
            self.selectedArtist = selectedArtist
            self.segueToProfile()
        }
    }
    
    func segueToProfile() {
        target.performSegue(withIdentifier: "showProfile", sender: self)
    }
    
    //mark: sounds
    var selectedSound: Sound?
    var descendingOrder = "createdAt"
    
    func soundCell(_ indexPath: IndexPath, cell: SoundListTableViewCell) -> UITableViewCell {
        cell.selectionStyle = .none
        
        if sounds.indices.contains(indexPath.row) {
            let sound = sounds[indexPath.row]
            if let currentSoundPlaying = self.player?.currentSound {
                if currentSoundPlaying.objectId == sound.objectId {
                    changeArtistSongColor(cell, color: color.blue(), playIconName: "playIcon_blue")
                    
                } else {
                    changeArtistSongColor(cell, color: .white, playIconName: "playIcon")
                }
                
            } else {
                changeArtistSongColor(cell, color: .white, playIconName: "playIcon")
            }
            
            cell.menuButton.addTarget(self, action: #selector(self.didPressMenuButton(_:)), for: .touchUpInside)
            cell.menuButton.tag = indexPath.row
            
            if let soundURL = sound.artURL {
                cell.soundArtImage.kf.setImage(with: URL(string: soundURL), placeholder: UIImage(named: "sound"))
            } else {
                cell.soundArtImage.image = UIImage(named: "sound")
            }
            
            cell.soundTitle.text = sound.title
            
            if let name = sound.artist?.name {
                cell.artistLabel.text = name
                if let image = sound.artist?.image {
                    cell.artistImage.kf.setImage(with: URL(string: image))
                } else {
                    cell.artistImage.image = UIImage(named: "profile_icon")
                }
                
            } else {
                loadArtist(cell, userId: sound.artist!.objectId, row: indexPath.row)
            }
            
            cell.artistButton.addTarget(self, action: #selector(didPressArtistButton(_:)), for: .touchUpInside)
            cell.artistButton.tag = indexPath.row
            
            let formattedDate = self.uiElement.formatDateAndReturnString(sound.createdAt!)
            cell.soundDate.text = formattedDate
            
            cell.collectorsButton.addTarget(self, action: #selector(didPressCollectorsButton(_:)), for: .touchUpInside)
            cell.collectorsButton.tag = indexPath.row
            if let tippers = sound.tippers {
                var tipLabel = "Collectors"
                if tippers == 1 {
                    tipLabel = "Collector"
                }
                
                cell.collectorsLabel.text = "\(tippers) \(tipLabel)"
            } else {
                cell.collectorsLabel.text = "0 Collectors"
            }
        }
        
        return cell
    }
    
    @objc func didPressCollectorsButton(_ sender: UIButton) {
        self.selectedSound = sounds[sender.tag]
        target.performSegue(withIdentifier: "showTippers", sender: self)
        
        MSAnalytics.trackEvent("SoundList", withProperties: ["Button" : "Collectors", "description": "User pressed view collectors button."])
    }
    
    @objc func didPressArtistButton(_ sender: UIButton) {
        let row = sender.tag
        if sounds.indices.contains(sender.tag) {
            self.selectedArtist(sounds[row].artist)
        }
    }
    
    func prepareToShowTippers(_ segue: UIStoryboardSegue) {
        let viewController = segue.destination as! PeopleViewController
        viewController.sound = selectedSound
    }
    
    @objc func didPressMenuButton(_ sender: UIButton) {
        let row = sender.tag
        if sounds.indices.contains(sender.tag) {
            let sound = sounds[sender.tag]
            
            var plays = 0
            if let soundPlays = sound.plays {
                plays = soundPlays
            }
            
            var tips = 0
            if let soundTips = sound.tips {
                tips = soundTips
            }
            let tipsInDollarString = self.uiElement.convertCentsToDollarsAndReturnString(tips, currency: "$")
            
            var menuAlert: UIAlertController!
            
            if let currentUser = PFUser.current() {
                if sound.artist!.objectId == currentUser.objectId {
                menuAlert = UIAlertController(title: "\(plays) Plays \n \(tipsInDollarString) in Tips", message: nil, preferredStyle: .actionSheet)
                    
                    menuAlert.addAction(UIAlertAction(title: "Edit Sound", style: .default, handler: { action in
                        self.selectedSound = sound
                        self.target.performSegue(withIdentifier: "showEditSoundInfo", sender: self)
                        
                        MSAnalytics.trackEvent("Soundlist Menu", withProperties: ["Button" : "Edit Sound", "description": "User pressed Edit Sound Info."])
                    }))
                    
                    menuAlert.addAction(UIAlertAction(title: "Delete Sound", style: .default, handler: { action in
                        self.deleteSong(sound.objectId!, row: row)
                        
                        MSAnalytics.trackEvent("Soundlist Menu", withProperties: ["Button" : "Delete Sound", "description": "User pressed Delete Sound."])
                    }))
                    
                } else {
                    menuAlert = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
                    menuAlert.addAction(UIAlertAction(title: "Go to Artist", style: .default, handler: { action in
                        self.selectedArtist(sound.artist)
                        
                        MSAnalytics.trackEvent("Soundlist Menu", withProperties: ["Button" : "Go To Artist", "description": "User pressed go to artist."])
                    }))
                }
                
            } else {
                menuAlert = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
                menuAlert.addAction(UIAlertAction(title: "Go to Artist", style: .default, handler: { action in
                    self.selectedArtist(sound.artist)
                    
                    MSAnalytics.trackEvent("Soundlist Menu", withProperties: ["Button" : "Go To Artist", "description": "User pressed go to artist."])

                }))
            }
            
            menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            target.present(menuAlert, animated: true, completion: nil)
        }
        
        MSAnalytics.trackEvent("SoundList", withProperties: ["Button" : "Menu", "description": "User pressed menu button."])
    }
    
    func changeArtistSongColor(_ cell: SoundListTableViewCell, color: UIColor, playIconName: String) {
        cell.soundTitle.textColor = color
        cell.artistLabel.textColor = color
        cell.soundDate.textColor = color
        cell.collectorsLabel.textColor = color
    }
    
    func determineTypeOfSoundToLoad(_ soundType: String) {
        self.sounds.removeAll()
        self.isUpdatingData = true
        
        switch soundType {
        case "chart":
            loadSounds(descendingOrder, collectionIds: nil, userId: nil, searchText: nil, followIds: nil)
            break
            
        case "discover":
            self.loadWorldCreatedAtSounds()
            break
            
        case "uploads":
            loadSounds(descendingOrder, collectionIds: nil, userId: profileUserId!, searchText: nil, followIds: nil)
            break
            
        case "collection":
            if let profileUserId = self.profileUserId {
                self.loadCollection(descendingOrder, profileUserId: profileUserId)
            }
            break
            
        case "search":
            loadSounds("plays", collectionIds: nil, userId: nil, searchText: searchText, followIds: nil)
            break
            
        case "follow":
            if let profileUserId = self.profileUserId {
                self.loadFollowing(descendingOrder, profileUserId: profileUserId)
            }
            break
            
        case "drafts":
            if let userId = self.profileUserId {
                self.loadSounds(descendingOrder, collectionIds: nil, userId: userId, searchText: nil, followIds: nil)
            }
            break
            
        default:
            break
        }
    }
    
    func updateSounds() {
        self.isUpdatingData = false
        if self.player != nil {
            self.sounds.sort(by: {$0.relevancyScore > $1.relevancyScore})
            if self.sounds.count > 0 {
                self.player!.sounds = self.sounds
                self.player!.fetchAudioData(0, prepareAndPlay: false)
            }
        }
        self.tableView?.reloadData()
    }
    
    func prepareToShowSoundInfo(_ segue: UIStoryboardSegue) {
        if let selectedSound = self.selectedSound {
            let viewController = segue.destination as! SoundInfoViewController
            selectedSound.isDraft = false
            viewController.soundThatIsBeingEdited = selectedSound
        }
    }
    
    //mark: tags filter
    var selectedTagForFiltering: Tag!

    //mark: data
    func loadSound(_ objectId: String) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                let sound = self.uiElement.newSoundObject(object)
                self.sounds.append(sound)
                self.updateSounds()
            }
        }
    }
    
    //To insure that data isn't loaded again when user is at bottom of screen
    var isUpdatingData = false
    var thereIsMoreDataToLoad = true
    
    func loadSounds(_ descendingOrder: String, collectionIds: Array<String>?, userId: String?, searchText: String?, followIds: Array<String>?) {
        
        isUpdatingData = true 
        
        let query = PFQuery(className: "Post")
        
        if let collectionIds = collectionIds {
            query.whereKey("objectId", containedIn: collectionIds)
            //query.whereKey("objectId", containsAllObjectsIn: collectionIds)
        }
        
        if let followIds = followIds {
            query.whereKey("userId", containedIn: followIds)
        }
        
        if let userId = userId {
            query.whereKey("userId", equalTo: userId)
        }
        
        if let searchText = searchText {
            query.whereKey("title", matchesRegex: searchText)
            query.whereKey("title", matchesRegex: searchText.lowercased())
        }
        query.limit = 50
        if sounds.count != 0 {
            query.whereKey("objectId", notContainedIn: sounds.map {$0.objectId!})
        }
        
        if self.soundType == "drafts" {
            query.whereKey("isDraft", equalTo: true)
            
        } else {
           query.whereKey("isRemoved", notEqualTo: true)
        }
        
        query.addDescendingOrder(descendingOrder)
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let sound = self.uiElement.newSoundObject(object)
                        self.sounds.append(sound)
                    }
                    
                    if objects.count == 0 {
                        self.thereIsMoreDataToLoad = false
                    }
                                        
                } else {
                    self.thereIsMoreDataToLoad = false
                    print("no colection 1")
                }
                
            } else {
                self.thereIsMoreDataToLoad = false
                
                print("Error: \(error!)")
            }
            self.updateSounds()
        }
    }
    
    func loadCollection(_ descendingOrder: String, profileUserId: String) {
        let query = PFQuery(className: "Tip")
        query.whereKey("fromUserId", equalTo: profileUserId)
       // query.whereKey("soundId", notContainedIn: self.collectionSoundIds)
        //query.limit = 50
        query.addDescendingOrder("createdAt")
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            self.didLoadCollection = true 
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        self.collectionSoundIds.append(object["soundId"] as! String)
                    }
                }
                
                if self.soundType == "collection" {
                    self.loadSounds(descendingOrder, collectionIds: self.collectionSoundIds, userId: nil, searchText: nil, followIds: nil)
                }
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func loadFollowing(_ descendingOrder: String, profileUserId: String) {
        let query = PFQuery(className: "Follow")
        query.whereKey("fromUserId", equalTo: profileUserId)
        query.whereKey("isRemoved", equalTo: false)
        // query.whereKey("soundId", notContainedIn: self.collectionSoundIds)
        //query.limit = 50
        query.addDescendingOrder("createdAt")
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            self.didLoadCollection = true
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        self.followUserIds.append(object["toUserId"] as! String)
                    }
                }
                
                if self.soundType == "follow" {
                    self.loadSounds(descendingOrder, collectionIds: nil, userId: nil, searchText: nil, followIds: self.followUserIds)
                }
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func loadArtist(_ cell: SoundListTableViewCell, userId: String, row: Int) {
        let query = PFQuery(className:"_User")
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                let artistUsername = user["username"] as? String
                
                let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: artistUsername, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil)
                
                if let name = user["artistName"] as? String {
                    cell.artistLabel.text = name
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
                    cell.artistImage.kf.setImage(with: URL(string: image.url!))
                }
                
                if let bio = user["bio"] as? String {
                    artist.bio = bio 
                }
                
                if let website = user["website"] as? String {
                    artist.website = website
                }
                
                //issue with crashing between loads
                if self.sounds.indices.contains(row) {
                    self.sounds[row].artist = artist
                }
            }
        }
    }
    
    func deleteSong(_ objectId: String, row: Int) {
        let menuAlert = UIAlertController(title: "Remove \(self.sounds[row].title ?? "this sound") from Soundbrew?", message: nil, preferredStyle: .alert)
        
        menuAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        
        menuAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            let query = PFQuery(className: "Post")
            query.getObjectInBackground(withId: objectId) {
                (post: PFObject?, error: Error?) -> Void in
                if let error = error {
                    print(error)
                    
                } else if let post = post {
                    post["isRemoved"] = true
                    post["isDraft"] = false 
                    post.saveEventually()
                    self.sounds.remove(at: row)
                    self.tableView?.reloadData()
                }
            }
        }))        
        
        target.present(menuAlert, animated: true, completion: nil)
    }
    
    //
    var worldCreatedAtSounds = [Sound]()
    var worldTopSounds = [Sound]()
    var mixedWorldSounds = [Sound]()
    
    func mixSounds(_ createdAtSounds: Array<Sound>, topSounds: Array<Sound>) -> Array<Sound> {
        var mixSounds: Array<Sound> = []
        let totalSoundsCount = createdAtSounds.count + topSounds.count
        for i in 0..<totalSoundsCount {
            if i % 2 == 0 {
                if createdAtSounds.indices.contains(i / 2) {
                    mixSounds.append(createdAtSounds[i / 2])
                }
                
            } else {
                if topSounds.indices.contains(i / 2) {
                    mixSounds.append(topSounds[i / 2])
                }
            }
        }
        
        return mixSounds
    }
    
    func loadWorldCreatedAtSounds() {
        self.worldCreatedAtSounds.removeAll()
        self.worldTopSounds.removeAll()
        self.mixedWorldSounds.removeAll()
        
        let query = PFQuery(className: "Post")
        query.whereKey("isRemoved", notEqualTo: true)
        query.addDescendingOrder("createdAt")
        query.limit = 10
        if let tag = self.selectedTagForFiltering {
            query.whereKey("tags", contains: tag.name)
        }
        if sounds.count != 0 {
         query.whereKey("objectId", notContainedIn: sounds.map {$0.objectId!})
         }
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let sound = self.uiElement.newSoundObject(object)
                        self.worldCreatedAtSounds.append(sound)
                    }
                    self.worldCreatedAtSounds.sort(by: {$0.relevancyScore > $1.relevancyScore})
                    self.loadWorldTopSounds()
                }
            }
        }
    }
    
    func loadWorldTopSounds() {
        let query = PFQuery(className: "Post")
        query.whereKey("isRemoved", notEqualTo: true)
        //query.addDescendingOrder("plays")
        query.addDescendingOrder("tips")
        query.whereKey("objectId", notContainedIn: worldCreatedAtSounds.map {$0.objectId!})
        query.limit = 10
        if sounds.count != 0 {
         query.whereKey("objectId", notContainedIn: sounds.map {$0.objectId!})
         }
        if let tag = self.selectedTagForFiltering {
            query.whereKey("tags", contains: tag.name)
        }
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let sound = self.uiElement.newSoundObject(object)
                        self.worldTopSounds.append(sound)
                    }
                    self.worldTopSounds.sort(by: {$0.relevancyScore > $1.relevancyScore})
                    self.mixedWorldSounds = self.mixSounds(self.worldCreatedAtSounds, topSounds: self.worldTopSounds)
                    
                    var newSounds: Array<Sound>!
                    newSounds = self.mixedWorldSounds
                    
                    for newSound in newSounds {
                        self.sounds.append(newSound)
                    }

                    if objects.count == 0 {
                        self.thereIsMoreDataToLoad = false 
                    }
                    
                    self.updateSounds()
                    
                } else {
                    self.thereIsMoreDataToLoad = false
                }
                
            } else {
                self.thereIsMoreDataToLoad = false
                print("Error: \(error!)")
            }
        }
    }
    
}

//
//  SoundList.swift
//  soundbrew
//
//  Created by Dominic  Smith on 3/21/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//
//  This class handles the logic behind showing Sounds Uploaded to Soundbrew.
//  SoundlistViewController.swift and ProfileViewController.swift utilize this class
//
// MARK: tableView, sounds, selected artist, tags filter, data, miniplayer


import Foundation
import UIKit
import Parse
import DeckTransition

class SoundList: NSObject, PlayerDelegate, TagDelegate {
    
    var target: UIViewController!
    var tableView: UITableView?
    var sounds = [Sound]()
    var miniPlayerView: MiniPlayerView?
    let uiElement = UIElement()
    let color = Color()
    var userId: String?
    var player: Player?
    var likedSoundIds = [String]()
    var followUserIds = [String]()
    var soundType: String!
    var didLoadLikedSounds = false
    var searchText: String?
    
    init(target: UIViewController, tableView: UITableView?, soundType: String, userId: String?, tags: Array<Tag>?, searchText: String?) {
        super.init()
        self.target = target
        self.tableView = tableView
        self.soundType = soundType
        self.userId = userId
        self.selectedTagsForFiltering = tags
        self.searchText = searchText
        player = Player.sharedInstance
        
        setUpMiniPlayer()
        determineTypeOfSoundToLoad(soundType)
    }
    
    //mark: tableView
    let filterSoundsReuse = "filterSoundsReuse"
    func setUpTableView() {
        if let player = self.player {
            player.tableview = self.tableView
        }
    }
    
    //mark: miniPlayer
    func setUpMiniPlayer() {
        if let tabBarView = target.tabBarController?.view {
            miniPlayerView = MiniPlayerView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            miniPlayerView?.player = self.player
            //miniPlayerView.player = soundList.player
            tabBarView.addSubview(miniPlayerView!)
            let slide = UISwipeGestureRecognizer(target: self, action: #selector(self.miniPlayerWasSwiped))
            slide.direction = .up
            miniPlayerView?.addGestureRecognizer(slide)
            miniPlayerView?.addTarget(self, action: #selector(self.miniPlayerWasPressed(_:)), for: .touchUpInside)
            
            miniPlayerView?.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(45)
                make.right.equalTo(tabBarView)
                make.left.equalTo(tabBarView)
                make.bottom.equalTo(tabBarView).offset(-49)
            }
            
            if let player = self.player?.player  {
                if player.isPlaying {
                    miniPlayerView?.playBackButton.setImage(UIImage(named: "pause_white"), for: .normal)
                    
                } else {
                    miniPlayerView?.playBackButton.setImage(UIImage(named: "play_white"), for: .normal)
                }
                miniPlayerView?.playBackButton.isEnabled = true
            }
            setUpTableView()
        }
    }
    
    @objc func miniPlayerWasSwiped() {
        showPlayerViewController()
    }
    
    @objc func miniPlayerWasPressed(_ sender: UIButton) {
        showPlayerViewController()
    }
    
    func showPlayerViewController() {
        let modal = PlayerV2ViewController()
        modal.player = self.player
        modal.playerDelegate = self
        let transitionDelegate = DeckTransitioningDelegate()
        modal.transitioningDelegate = transitionDelegate
        modal.modalPresentationStyle = .custom
        target.present(modal, animated: true, completion: nil)
    }
    
    //mark: selected artist
    var selectedArtist: Artist!
    
    func prepareToShowSelectedArtist(_ segue: UIStoryboardSegue) {
        let viewController = segue.destination as! ProfileViewController
        viewController.artist = selectedArtist
    }
    
    func selectedArtist(_ artist: Artist?) {
        //TODO: if selected artist is already on artist page, don't segue
        if let selectedArtist = artist {
            self.selectedArtist = selectedArtist
            target.performSegue(withIdentifier: "showProfile", sender: self)
        }
    }
    
    //mark: sounds
    func sound(_ indexPath: IndexPath, cell: SoundListTableViewCell) -> UITableViewCell {
        cell.selectionStyle = .none
        let sound = sounds[indexPath.row]
        if let currentSoundPlaying = self.player?.currentSound {
            if currentSoundPlaying.objectId == sound.objectId {
                changeArtistSongColor(cell, color: color.blue(), playIconName: "playIcon_blue")
                
            } else {
                changeArtistSongColor(cell, color: color.black(), playIconName: "playIcon")
            }
            
        } else {
            changeArtistSongColor(cell, color: color.black(), playIconName: "playIcon")
        }
        
        cell.menuButton.addTarget(self, action: #selector(self.didPressMenuButton(_:)), for: .touchUpInside)
        cell.menuButton.tag = indexPath.row
        
        cell.soundArtImage.kf.setImage(with: URL(string: sound.artURL))
        cell.soundTitle.text = sound.title
        
        if let plays = sound.plays {
            cell.soundPlays.text = "\(plays)"
            
        } else {
            cell.soundPlays.text = "0"
        }
        
        if let artist = sound.artist?.name {
            cell.soundArtist.text = artist
            
        } else {
            loadArtist(cell, userId: sound.artist!.objectId, row: indexPath.row)
        }
        
        return cell
    }
    
    @objc func didPressMenuButton(_ sender: UIButton) {
        let row = sender.tag
        let sound = sounds[sender.tag]
        
        let menuAlert = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
        menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if sound.artist!.objectId == PFUser.current()!.objectId! {
            menuAlert.addAction(UIAlertAction(title: "Delete Sound", style: .default, handler: { action in
                self.deleteSong(sound.objectId, row: row)
            }))
            
            menuAlert.addAction(UIAlertAction(title: "Edit Sound Info", style: .default, handler: { action in
                //TODO
            }))
            
            menuAlert.addAction(UIAlertAction(title: "Edit Sound Audio", style: .default, handler: { action in
                //TODO
            }))
            
        } else {
            menuAlert.addAction(UIAlertAction(title: "Unlike Sound", style: .default, handler: { action in
                self.unlikeSound(sound.objectId, row: row)
            }))
        }
        
        target.present(menuAlert, animated: true, completion: nil)
    }
    
    func changeArtistSongColor(_ cell: SoundListTableViewCell, color: UIColor, playIconName: String) {
        cell.soundTitle.textColor = color
        cell.soundArtist.textColor = color
        cell.soundPlays.textColor = color
        cell.soundPlaysImage.image = UIImage(named: playIconName)
    }
    
    func determineTypeOfSoundToLoad(_ soundType: String) {
        self.sounds.removeAll()
        var descendingOrder = "createdAt"
        if let filter = self.uiElement.getUserDefault("filter") as? String {
            if filter == "popular" {
                descendingOrder = "playse"
            }
        }
        
        switch soundType {
        case "discover":
            loadSounds(descendingOrder, likeIds: nil, userId: nil, tags: selectedTagsForFiltering, followIds: nil, searchText: nil)
            break
            
        case "uploads":
            loadSounds(descendingOrder, likeIds: nil, userId: userId!, tags: selectedTagsForFiltering, followIds: nil, searchText: nil)
            break
            
        case "likes":
            self.loadLikes(descendingOrder)
            break
            
        case "follows":
            self.loadFollows(descendingOrder)
            break
            
        case "search":
            loadSounds(descendingOrder, likeIds: nil, userId: nil, tags: nil, followIds: nil, searchText: self.searchText)
            break 
            
        default:
            break
        }
    }
    
    func sortSounds(_ selectedTags: Array<Tag>) {
        for i in 0..<self.sounds.count {
            let tags = self.sounds[i].tags
            let selectedTagNames = selectedTags.map {$0.name!}
            var relevancyScore = 0
            
            for tag in tags! {
                if selectedTagNames.contains(tag) {
                    var type: String?
                    let query = PFQuery(className: "Tag")
                    query.whereKey("tag", equalTo: tag)
                    query.getFirstObjectInBackground {
                        (object: PFObject?, error: Error?) -> Void in
                        if object != nil && error == nil {
                            type = object?["type"] as? String
                            if let type = type {
                                switch type {
                                case "genre":
                                    relevancyScore = relevancyScore + 4
                                    break
                                    
                                case "city":
                                    relevancyScore = relevancyScore + 3
                                    break
                                    
                                case "activity":
                                    relevancyScore = relevancyScore + 2
                                    break
                                    
                                case "mood":
                                    relevancyScore = relevancyScore + 2
                                    print("tea")
                                    break
                                    
                                default:
                                    relevancyScore = relevancyScore + 1
                                    break
                                }
                            }
                            self.sounds[i].relevancyScore = relevancyScore
                        }
                    }
                }
            }
            
            //print("\(self.sounds[i].title!): \(self.sounds[i].relevancyScore)")
        }
        
        self.sounds.sort(by: {$0.relevancyScore > $1.relevancyScore})
        print("updating SOunds")
        updateSounds()
    }
    
    func updateSounds() {
        //checking for this, because some users may not be artists... don't want people to have to click straight to their collections ... this way app will load collection automatically.
        if self.soundType == "uploads" && self.sounds.count == 0 && !self.didLoadLikedSounds {
            self.soundType = "likes"
            self.determineTypeOfSoundToLoad(self.soundType)
            
        } else if let player = self.player {
            player.sounds = self.sounds
        }
        
        self.tableView?.reloadData()
        
        if self.soundType == "uploads" || self.soundType == "likes" && self.sounds.count != 0 {
            if let currentUser = PFUser.current() {
                if currentUser.objectId == self.userId! && self.userId! != "AWKPPDI4CB" {
                    SKStoreReviewController.requestReview()
                }
            }
        }
    }
    
    //mark: tags filter
    var selectedTagsForFiltering: Array<Tag>?
    var soundFilter: String!
    var xPositionForTags = UIElement().leftOffset
    var soundOrder: String!
    
    func soundFilterOptions(_ indexPath: IndexPath, cell: SoundListTableViewCell) -> UITableViewCell {
        cell.selectionStyle = .none
        cell.newButton.addTarget(self, action: #selector(self.didPressSoundOrderButton(_:)), for: .touchUpInside)
        cell.newButton.tag = 0
        cell.popularButton.addTarget(self, action: #selector(self.didPressSoundOrderButton(_:)), for: .touchUpInside)
        cell.popularButton.tag = 1
        if let filter = uiElement.getUserDefault("filter") as? String {
            if filter == "recent" {
                soundOrder = "recent"
                cell.newButton.setTitleColor(color.black(), for: .normal)
                cell.popularButton.setTitleColor(color.darkGray(), for: .normal)
                
            } else {
                soundOrder = "popular"
                cell.popularButton.setTitleColor(color.black(), for: .normal)
                cell.newButton.setTitleColor(color.darkGray(), for: .normal)
            }
            
        } else {
            soundOrder = "recent"
        }
        
        cell.tagsScrollview.subviews.forEach({ $0.removeFromSuperview() })
        xPositionForTags = uiElement.leftOffset
        if let tags = self.selectedTagsForFiltering {
            if tags.count != 0 {
                for tag in tags {
                    self.addSelectedTags(cell.tagsScrollview, tagName: tag.name)
                }
                
            } else {
                self.addSelectedTags(cell.tagsScrollview, tagName: "Filter")
            }
            
        } else if cell.tagsScrollview.subviews.count == 0 {
            self.addSelectedTags(cell.tagsScrollview, tagName: "Filter")
        }
        
        return cell
    }
    @objc func didPressSoundOrderButton(_ sender: UIButton) {
        if sender.tag == 0 {
            soundOrder = "recent"
            self.uiElement.setUserDefault("filter", value: "recent")
            
        } else {
            soundOrder = "popular"
            self.uiElement.setUserDefault("filter", value: "popular")
        }
        
        determineTypeOfSoundToLoad(soundType)
    }

    func prepareToShowTags(_ segue: UIStoryboardSegue) {
        let viewController = segue.destination as! TagsViewController
        viewController.tagDelegate = self
        if let tags = self.selectedTagsForFiltering {
            viewController.chosenTagsArray = tags
        }
    }
    
    func changeTags(_ value: Array<Tag>?) {
        //Only want to reload data if tags changed
        var currentTagObjectIds = [String]()
        if let selectedTagsForFiltering = self.selectedTagsForFiltering {
            currentTagObjectIds = selectedTagsForFiltering.map {$0.objectId}
        }
        if let newTags = value {
            print(newTags)
            let newTagObjectIds = newTags.map {$0.objectId}
            if currentTagObjectIds != newTagObjectIds {
                self.selectedTagsForFiltering = newTags
                determineTypeOfSoundToLoad(soundType)
                
            }
            
        } else {
            self.selectedTagsForFiltering = nil
            determineTypeOfSoundToLoad(soundType)
        }
        
        /*if self.tags != value {

        } else {
            if let filter = self.uiElement.getUserDefault("filter") as? String {
                if self.soundFilter != filter {
                    self.sounds.removeAll()
                    determineTypeOfSoundToLoad(soundType)
                }
            }
        }*/
    }
    
    func addSelectedTags(_ scrollview: UIScrollView, tagName: String) {
        let buttonTitleWithX = "\(tagName)"
        //not using snpakit to set button frame becuase not able to get button width from button title.
        let buttonTitleWidth = uiElement.determineChosenTagButtonTitleWidth(buttonTitleWithX)
        
        let tagButton = UIButton()
        tagButton.frame = CGRect(x: xPositionForTags, y: uiElement.elementOffset, width: buttonTitleWidth, height: 30)
        tagButton.setTitle(tagName, for: .normal)
        tagButton.setTitleColor(color.black(), for: .normal)
        tagButton.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        tagButton.layer.cornerRadius = 5
        tagButton.layer.borderWidth = 1
        tagButton.layer.borderColor = color.darkGray().cgColor
        tagButton.addTarget(self, action: #selector(self.didPressTagButton(_:)), for: .touchUpInside)
        scrollview.addSubview(tagButton)
        
        xPositionForTags = xPositionForTags + Int(tagButton.frame.width) + uiElement.elementOffset
        scrollview.contentSize = CGSize(width: xPositionForTags, height: 35)
    }
    
    @objc func didPressTagButton(_ sender: UIButton) {
        target.performSegue(withIdentifier: "showTags", sender: self)
    }
    
    /*func weighTag(_ tag: String, selectedTags: Array<Tag>) -> Int {
        var type: String?
        let selectedTagNames = selectedTags.map {$0.name!}
        var relevancyScore = 0
        
        if selectedTagNames.contains(tag) {
            let query = PFQuery(className: "Tag")
            query.whereKey("tag", equalTo: tag)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if object != nil && error == nil {
                    type = object?["type"] as? String
                    if let type = type {
                        switch type {
                        case "genre":
                            relevancyScore = 4
                            break
                            
                        case "city":
                            relevancyScore = 3
                            break
                            
                        case "activity":
                            relevancyScore = 2
                            break
                            
                        case "mood":
                            relevancyScore = 2
                            break
                            
                        default:
                            relevancyScore = 1
                            break
                        }
                    }
                }
            }
        }
        //print("\(tag): \(relevancyScore)")
        return relevancyScore
    }*/
    
    //mark: data
    func loadSounds(_ descendingOrder: String, likeIds: Array<String>?, userId: String?, tags: Array<Tag>?, followIds: Array<String>?, searchText: String?) {
        let query = PFQuery(className: "Post")
        if let likeIds = likeIds {
            query.whereKey("objectId", containedIn: likeIds)
        }
        
        if let userId = userId {
            query.whereKey("userId", equalTo: userId)
        }
        
        if let tags = tags {
            let tagNames = tags.map {$0.name!}
            //query.whereKey("tags", containedIn: tagNames)
            query.whereKey("tags", containsAllObjectsIn: tagNames)
        }

        if let followIds = followIds {
            query.whereKey("userId", containedIn: followIds)
        }
        
        if let searchText = searchText {
            query.whereKey("title", hasPrefix: searchText)
        }
        
        query.addDescendingOrder(descendingOrder)
        query.limit = 100
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let title = object["title"] as! String
                        let art = object["songArt"] as! PFFileObject
                        let audio = object["audioFile"] as! PFFileObject
                        let tags = object["tags"] as! Array<String>
                        let userId = object["userId"] as! String
                        var soundPlays: Int?
                        if let plays = object["plays"] as? Int {
                            soundPlays = plays
                        }
                        
                        let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: "", website: "", bio: "", email: "", instagramUsername: nil, twitterUsername: nil, snapchatUsername: nil, isFollowedByCurrentUser: nil)
                        
                        /*var relevancyScore = 0
                        if let selectedTagsForFiltering = self.selectedTagsForFiltering {
                            for tag in tags {
                                relevancyScore = relevancyScore + self.weighTag(tag, selectedTags: selectedTagsForFiltering)
                            }
                        }*/
                        
                        let sound = Sound(objectId: object.objectId, title: title, artURL: art.url!, artImage: nil, artFile: art, tags: tags, createdAt: object.createdAt!, plays: soundPlays, audio: audio, audioURL: audio.url!, relevancyScore: 0, audioData: nil, artist: artist, isLiked: nil)
                        
                        self.sounds.append(sound)
                    }
                    
                    self.updateSounds()
                    
                    /*if let selectedTagsForFiltering = self.selectedTagsForFiltering {
                        self.sortSounds(selectedTagsForFiltering)
                        
                    } else {
                        self.updateSounds()
                    }*/
                    
                    //self.sounds.sort(by: {$0.relevancyScore > $1.relevancyScore})
                }
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func loadLikes(_ descendingOrder: String) {
        let query = PFQuery(className: "Like")
        query.whereKey("userId", equalTo: userId!)
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            self.didLoadLikedSounds = true 
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        self.likedSoundIds.append(object["postId"] as! String)
                    }
                }
                
                self.loadSounds(descendingOrder, likeIds: self.likedSoundIds, userId: nil, tags: self.selectedTagsForFiltering, followIds: nil, searchText: nil)
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func loadFollows(_ descendingOrder: String) {
        let query = PFQuery(className: "Follow")
        query.whereKey("fromUserId", equalTo: userId!)
        query.whereKey("isRemoved", equalTo: false)
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        self.followUserIds.append(object["toUserId"] as! String)
                    }
                }
                
                self.loadSounds(descendingOrder, likeIds: nil, userId: nil, tags: self.selectedTagsForFiltering, followIds: self.followUserIds, searchText: nil)
                
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
                let artistName = user["artistName"] as? String
                let artistCity = user["city"] as? String
                
                var isArtistVerified: Bool?
                if let verified = user["artistVerified"] as? Bool {
                    isArtistVerified = verified
                }
                cell.soundArtist.text = artistName!
                
                var instagramUsername: String?
                if let igUsername = user["instagramHandle"] as? String {
                    instagramUsername = igUsername
                }
                
                var twitterUsername: String?
                if let twtrUsername = user["twitterHandle"] as? String {
                    twitterUsername = twtrUsername
                }
                
                var snapchatUsername: String?
                if let snapUsername = user["snapchatHandle"] as? String {
                    snapchatUsername = snapUsername
                }
                
                let artist = Artist(objectId: user.objectId, name: artistName, city: artistCity, image: nil, isVerified: isArtistVerified, username: "", website: "", bio: "", email: "", instagramUsername: instagramUsername, twitterUsername: twitterUsername, snapchatUsername: snapchatUsername, isFollowedByCurrentUser: nil)
                self.sounds[row].artist = artist
            }
        }
    }
    
    func deleteSong(_ objectId: String, row: Int) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: objectId) {
            (post: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let post = post {
                post.deleteInBackground {
                    (success: Bool, error: Error?) in
                    if (success) {
                        self.sounds.remove(at: row)
                        self.tableView?.reloadData()
                        
                    } else if let error = error {
                        UIElement().showAlert("Oops", message: error.localizedDescription, target: self.target)
                    }
                }
            }
        }
    }
    
    func unlikeSound(_ objectId: String, row: Int) {
        let query = PFQuery(className: "Like")
        query.whereKey("postId", equalTo: objectId)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                object.deleteInBackground {
                    (success: Bool, error: Error?) in
                    if (success) {
                        self.sounds.remove(at: row)
                        self.tableView?.reloadData()
                        
                    } else if let error = error {
                        UIElement().showAlert("Oops", message: error.localizedDescription, target: self.target)
                    }
                }
            }
        }
    }
}

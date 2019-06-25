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
// MARK: tableView, sounds, artist, tags filter, data, miniplayer, comment, search

import Foundation
import UIKit
import Parse
import DeckTransition

class SoundList: NSObject, PlayerDelegate {
    var target: UIViewController!
    var tableView: UITableView?
    var sounds = [Sound]()
    var miniPlayerView: MiniPlayerView?
    let uiElement = UIElement()
    let color = Color()
    var profileUserId: String?
    var player: Player?
    var likedSoundIds = [String]()
    var followUserIds = [String]()
    var soundType: String!
    var didLoadLikedSounds = false
    var searchText: String?
    var domSmithUserId = "AWKPPDI4CB"
    
    init(target: UIViewController, tableView: UITableView?, soundType: String, userId: String?, tags: Array<Tag>?, searchText: String?) {
        super.init()
        self.target = target
        self.tableView = tableView
        self.soundType = soundType
        self.profileUserId = userId
        self.selectedTagsForFiltering = tags
        self.searchText = searchText
        player = Player.sharedInstance
        player?.target = target
        player?.tableView = tableView
        setUpMiniPlayer()
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
    
    //mark: miniPlayer
    func setUpMiniPlayer() {
        if let tabBarView = target.tabBarController {
            miniPlayerView = MiniPlayerView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            miniPlayerView?.player = self.player
            tabBarView.view.addSubview(miniPlayerView!)
            let slide = UISwipeGestureRecognizer(target: self, action: #selector(self.miniPlayerWasSwiped))
            slide.direction = .up
            miniPlayerView?.addGestureRecognizer(slide)
            miniPlayerView?.addTarget(self, action: #selector(self.miniPlayerWasPressed(_:)), for: .touchUpInside)
            miniPlayerView?.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(45)
                make.right.equalTo(tabBarView.view)
                make.left.equalTo(tabBarView.view)
                make.bottom.equalTo(tabBarView.tabBar).offset(-(tabBarView.tabBar.frame.height))
            }
            
            if let player = self.player?.player  {
                if player.isPlaying {
                    miniPlayerView?.playBackButton.setImage(UIImage(named: "pause_white"), for: .normal)
                    miniPlayerView?.isHidden = false
                    
                } else {
                    miniPlayerView?.playBackButton.setImage(UIImage(named: "play_white"), for: .normal)
                }
                miniPlayerView?.playBackButton.isEnabled = true
                
            } else {
                miniPlayerView?.isHidden = true 
            }
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
        let tabBarController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController
        let navigationController = tabBarController?.selectedViewController as? UINavigationController
        let view = navigationController?.topViewController
        if let segueView = view {
            segueView.performSegue(withIdentifier: "showProfile", sender: self)
        }        
    }
    
    //mark: sounds
    var selectedSound: Sound!
    var descendingOrder = "createdAt"
    
    func soundCell(_ indexPath: IndexPath, cell: SoundListTableViewCell) -> UITableViewCell {
        cell.selectionStyle = .none
        
        if sounds.indices.contains(indexPath.row) {
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
        }
        
        return cell
    }
    
    @objc func didPressMenuButton(_ sender: UIButton) {
        let row = sender.tag
        if sounds.indices.contains(sender.tag) {
            let sound = sounds[sender.tag]
            
            let menuAlert = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
            menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            if let currentUser = PFUser.current() {
                if sound.artist!.objectId == currentUser.objectId {
                    menuAlert.addAction(UIAlertAction(title: "Delete Sound", style: .default, handler: { action in
                        self.deleteSong(sound.objectId, row: row)
                    }))
                    
                    menuAlert.addAction(UIAlertAction(title: "Edit Sound Info", style: .default, handler: { action in
                        self.selectedSound = sound
                        self.target.performSegue(withIdentifier: "showEditSoundInfo", sender: self)
                    }))
                    
                    /*menuAlert.addAction(UIAlertAction(title: "Edit Sound Audio", style: .default, handler: { action in
                        self.selectedSound = sound
                        self.target.performSegue(withIdentifier: "showUploadSound", sender: self)
                    }))*/
                    
                } else {
                    menuAlert.addAction(UIAlertAction(title: "Go to Artist", style: .default, handler: { action in
                        self.selectedArtist(sound.artist)
                    }))
                }
                
            } else {
                menuAlert.addAction(UIAlertAction(title: "Go to Artist", style: .default, handler: { action in
                    self.selectedArtist(sound.artist)
                }))
            }
            
            target.present(menuAlert, animated: true, completion: nil)
        }
    }
    
    func changeArtistSongColor(_ cell: SoundListTableViewCell, color: UIColor, playIconName: String) {
        cell.soundTitle.textColor = color
        cell.soundArtist.textColor = color
        cell.soundPlays.textColor = color
        cell.soundPlaysImage.image = UIImage(named: playIconName)
    }
    
    func determineTypeOfSoundToLoad(_ soundType: String) {
        self.sounds.removeAll()
        self.isUpdatingData = true
        
        switch soundType {
        case "playlist":
            self.loadFollows("")
            break
            
        case "uploads":
            loadSounds(descendingOrder, likeIds: nil, userId: profileUserId!)
            break
            
        case "likes":
            if let profileUserId = self.profileUserId {
                self.loadLikes(descendingOrder, profileUserId: profileUserId)
            }
            break
            
        default:
            break
        }
    }
    
    func updateSounds() {
        self.isUpdatingData = false
        //checking for this, because some users may not be artists... don't want people to have to click straight to their collections ... this way app will load collection automatically.
        if self.soundType == "uploads" && self.sounds.count == 0 && !self.didLoadLikedSounds {
            self.soundType = "likes"
            self.determineTypeOfSoundToLoad(self.soundType)
            
        } else if soundType == "follows" && self.sounds.count == 0 {
            showNoResultsLabel()
            
        } else if self.player != nil {
            self.sounds.sort(by: {$0.relevancyScore > $1.relevancyScore})
            self.tableView?.isHidden = false
            target.view.bringSubviewToFront(tableView!)
            self.player!.sounds = self.sounds
            self.player!.fetchAudioData(0, prepareAndPlay: false)
        }
        
        self.tableView?.reloadData()
        
        determineIfRateTheAppPopUpShouldShow()
    }
    
    func prepareToShowSoundInfo(_ segue: UIStoryboardSegue) {
        let viewController = segue.destination as! SoundInfoViewController
        viewController.soundThatIsBeingEdited = selectedSound
    }
    
    func prepareToShowSoundAudioUpload(_ segue: UIStoryboardSegue) {
        let viewController = segue.destination as! UploadSoundAudioViewController
        viewController.soundThatIsBeingEdited = selectedSound
    }
    
    func determineIfRateTheAppPopUpShouldShow() {
        if let currentUser = PFUser.current() {
            if sounds.count != 0 {
                if self.soundType == "uploads" || self.soundType == "likes" {
                    if currentUser.objectId == self.profileUserId! { //&&
                        //self.profileUserId! != domSmithUserId  {
                        SKStoreReviewController.requestReview()
                    }
                }
            }
        }
    }
    
    func newSoundObject(_ object: PFObject) -> Sound {
        let title = object["title"] as! String
        let art = object["songArt"] as! PFFileObject
        let audio = object["audioFile"] as! PFFileObject
        let tags = object["tags"] as! Array<String>
        let userId = object["userId"] as! String
        var plays: Int?
        if let soundPlays = object["plays"] as? Int {
            plays = soundPlays
        }
        
        var likes: Int?
        if let soundPlays = object["likes"] as? Int {
            likes = soundPlays
        }
        
        let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: "", website: "", bio: "", email: "", isFollowedByCurrentUser: nil, followerCount: nil)
        
        var relevancyScore = 0
        if let selectedTagsForFiltering = self.selectedTagsForFiltering {
            for tag in tags {
                let selectedTagNames = selectedTagsForFiltering.map {$0.name!}
                if selectedTagNames.contains(tag) {
                    relevancyScore += 1
                }
            }
        }
        
        let sound = Sound(objectId: object.objectId, title: title, artURL: art.url!, artImage: nil, artFile: art, tags: tags, createdAt: object.createdAt!, plays: plays, audio: audio, audioURL: audio.url!, relevancyScore: relevancyScore, audioData: nil, artist: artist, isLiked: nil, likes: likes, tmpFile: nil)
        
        return sound
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
        let currentSoundOrder = soundOrder
        if sender.tag == 0 {
            soundOrder = "recent"
            self.uiElement.setUserDefault("filter", value: "recent")
            
        } else {
            soundOrder = "popular"
            self.uiElement.setUserDefault("filter", value: "popular")
        }
        
        if currentSoundOrder != soundOrder {
            if let tableview = self.tableView {
                sounds.removeAll()
                tableview.reloadData()
            }
            determineTypeOfSoundToLoad(soundType)
        }
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
    
    //mark: data
    func loadSound(_ objectId: String) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                let sound = self.newSoundObject(object)
                self.sounds.append(sound)
                self.updateSounds()
            }
        }
    }
    
    //To insure that data isn't loaded again when user is at bottom of screen
    var isUpdatingData = false
    var thereIsMoreDataToLoad = true
    
    func loadSounds(_ descendingOrder: String, likeIds: Array<String>?, userId: String?) {
        let query = PFQuery(className: "Post")
        
        if let likeIds = likeIds {
            query.whereKey("objectId", containedIn: likeIds)
        }
        
        if let userId = userId {
            query.whereKey("userId", equalTo: userId)
        }
        
        if sounds.count != 0 {
            query.whereKey("objectId", notContainedIn: sounds.map {$0.objectId!})
        }
        query.whereKey("isRemoved", notEqualTo: true)
        query.addDescendingOrder(descendingOrder)
        query.limit = 50
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let sound = self.newSoundObject(object)
                        self.sounds.append(sound)
                    }
                    
                    if objects.count == 0 {
                        self.thereIsMoreDataToLoad = false
                        
                    } else {
                        self.updateSounds()
                    }
                    
                } else {
                    self.thereIsMoreDataToLoad = false
                }
                
            } else {
                self.thereIsMoreDataToLoad = false
                print("Error: \(error!)")
            }
        }
    }
    
    func loadLikes(_ descendingOrder: String, profileUserId: String) {
        let query = PFQuery(className: "Like")
        query.whereKey("userId", equalTo: profileUserId)
        query.whereKey("isRemoved", equalTo: false)
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            self.didLoadLikedSounds = true 
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        self.likedSoundIds.append(object["postId"] as! String)
                    }
                }
                
                if self.soundType == "likes" {
                    self.loadSounds(descendingOrder, likeIds: self.likedSoundIds, userId: nil)
                    
                } else if self.likedSoundIds.count == 0 {
                    self.loadWorldCreatedAtSounds()
                    
                } else {
                    self.loadLikesCreatedAtSounds()
                }
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func loadFollows(_ descendingOrder: String) {
        if let profileUserId = self.profileUserId {
            let query = PFQuery(className: "Follow")
            query.whereKey("fromUserId", equalTo: profileUserId)
            query.whereKey("isRemoved", equalTo: false)
            query.findObjectsInBackground {
                (objects: [PFObject]?, error: Error?) -> Void in
                if error == nil {
                    if let objects = objects {
                        for object in objects {
                            self.followUserIds.append(object["toUserId"] as! String)
                        }
                    }
                    self.loadFollowCreatedAtSounds()
                    
                } else {
                    print("Error: \(error!)")
                }
            }
            
        } else {
            self.loadWorldCreatedAtSounds()
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
                
                let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: artistUsername, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil)
                
                if let name = user["artistName"] as? String {
                    cell.soundArtist.text = name
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
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: objectId) {
            (post: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let post = post {
                post["isRemoved"] = true
                post.saveEventually()
                self.sounds.remove(at: row)
                self.tableView?.reloadData()
            }
        }
    }
    
    //
    var followCreatedAtSounds = [Sound]()
    var followTopSounds = [Sound]()
    var mixedFollowSounds = [Sound]()
    var likesCreatedAtSounds = [Sound]()
    var likesTopSounds = [Sound]()
    var mixedLikedSounds = [Sound]()
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
    
    func mixAllSounds(_ mixedFollowSounds: Array<Sound>, mixedLikedSounds: Array<Sound>, mixedWorldSounds: Array<Sound>)  -> Array<Sound> {
        var mixSounds: Array<Sound> = []
        let totalSoundsCount = mixedFollowSounds.count + mixedLikedSounds.count + mixedWorldSounds.count
        for i in 0..<totalSoundsCount {
            switch i % 3 {
            case 0:
                if mixedFollowSounds.indices.contains(i/3) {
                    mixSounds.append(mixedFollowSounds[i / 3])
                }
                break
                
            case 3:
                if mixedLikedSounds.indices.contains(i/3) {
                    mixSounds.append(mixedLikedSounds[i / 3])
                }
                break
                
            case 6:
                if mixedWorldSounds.indices.contains(i/3) {
                    mixSounds.append(mixedWorldSounds[i / 3])
                }
                break
                
            default:
                break
            }
        }
        
        return mixSounds
    }
    
    func loadFollowCreatedAtSounds() {
        self.followCreatedAtSounds.removeAll()
        self.followTopSounds.removeAll()
        self.mixedFollowSounds.removeAll()
        
        self.isUpdatingData = true
        let query = PFQuery(className: "Post")
        query.whereKey("userId", containedIn: followUserIds)
        query.whereKey("isRemoved", notEqualTo: true)
        query.addDescendingOrder("createdAt")
        query.limit = 10
        if let tags = self.selectedTagsForFiltering {
            let tagNames = tags.map {$0.name!}
            query.whereKey("tags", containedIn: tagNames)
        }
        if sounds.count != 0 {
            query.whereKey("objectId", notContainedIn: sounds.map {$0.objectId!})
        }
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let sound = self.newSoundObject(object)
                        self.followCreatedAtSounds.append(sound)
                    }
                    
                    //means current user hasn't followed anyone yet. Get their likes
                    if self.followCreatedAtSounds.count == 0 {
                         self.loadLikes("", profileUserId: self.profileUserId!)
                        
                    } else {
                        self.followCreatedAtSounds.sort(by: {$0.relevancyScore > $1.relevancyScore})
                        self.loadFollowTopSounds()
                    }
                }
            }
        }
    }
    
    func loadFollowTopSounds() {
        let query = PFQuery(className: "Post")
        query.whereKey("userId", containedIn: followUserIds)
        query.whereKey("isRemoved", notEqualTo: true)
        query.addDescendingOrder("plays")
        query.limit = 10
        query.whereKey("objectId", notContainedIn: followCreatedAtSounds.map {$0.objectId!})
        if let tags = self.selectedTagsForFiltering {
            let tagNames = tags.map {$0.name!}
            query.whereKey("tags", containedIn: tagNames)
        }
        if sounds.count != 0 {
         query.whereKey("objectId", notContainedIn: sounds.map {$0.objectId!})
         }
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let sound = self.newSoundObject(object)
                        self.followTopSounds.append(sound)
                    }
                    self.followTopSounds.sort(by: {$0.relevancyScore > $1.relevancyScore})
                    self.mixedFollowSounds = self.mixSounds(self.followCreatedAtSounds, topSounds: self.followTopSounds)
                    self.loadLikes("", profileUserId: self.profileUserId!)
                }
            }
        }
    }
    
    func loadLikesCreatedAtSounds() {
        self.likesCreatedAtSounds.removeAll()
        self.likesTopSounds.removeAll()
        self.mixedLikedSounds.removeAll()

        let query = PFQuery(className: "Post")
        query.whereKey("objectId", containedIn: likedSoundIds)
        query.whereKey("isRemoved", notEqualTo: true)
        query.addDescendingOrder("createdAt")
        query.limit = 10
        query.whereKey("objectId", notContainedIn: mixedFollowSounds.map {$0.objectId!})
        if let tags = self.selectedTagsForFiltering {
            let tagNames = tags.map {$0.name!}
            query.whereKey("tags", containedIn: tagNames)
        }
        if sounds.count != 0 {
         query.whereKey("objectId", notContainedIn: sounds.map {$0.objectId!})
         }
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let sound = self.newSoundObject(object)
                        self.likesCreatedAtSounds.append(sound)
                    }
                    self.likesCreatedAtSounds.sort(by: {$0.relevancyScore > $1.relevancyScore})
                    self.loadLikesTopSounds()
                }
            }
        }
    }
    
    func loadLikesTopSounds() {
        let query = PFQuery(className: "Post")
        query.whereKey("objectId", containedIn: likedSoundIds)
        query.whereKey("isRemoved", notEqualTo: true)
        query.addDescendingOrder("plays")
        query.whereKey("objectId", notContainedIn: mixedFollowSounds.map {$0.objectId!})
        query.whereKey("objectId", notContainedIn: likesCreatedAtSounds.map {$0.objectId!})
        query.limit = 10
        if let tags = self.selectedTagsForFiltering {
            let tagNames = tags.map {$0.name!}
            query.whereKey("tags", containedIn: tagNames)
        }
        if sounds.count != 0 {
         query.whereKey("objectId", notContainedIn: sounds.map {$0.objectId!})
         }
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let sound = self.newSoundObject(object)
                        self.likesTopSounds.append(sound)
                    }
                    self.likesTopSounds.sort(by: {$0.relevancyScore > $1.relevancyScore})
                    self.mixedLikedSounds = self.mixSounds(self.likesCreatedAtSounds, topSounds: self.likesTopSounds)
                    self.loadWorldCreatedAtSounds()
                }
            }
        }
    }
    
    func loadWorldCreatedAtSounds() {
        self.worldCreatedAtSounds.removeAll()
        self.worldTopSounds.removeAll()
        self.mixedWorldSounds.removeAll()
        
        let query = PFQuery(className: "Post")
        query.whereKey("isRemoved", notEqualTo: true)
        query.addDescendingOrder("createdAt")
        query.whereKey("objectId", notContainedIn: mixedFollowSounds.map {$0.objectId!})
        query.whereKey("objectId", notContainedIn: mixedLikedSounds.map {$0.objectId!})
        query.limit = 10
        if let tags = self.selectedTagsForFiltering {
            let tagNames = tags.map {$0.name!}
            query.whereKey("tags", containedIn: tagNames)
        }
        if sounds.count != 0 {
         query.whereKey("objectId", notContainedIn: sounds.map {$0.objectId!})
         }
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let sound = self.newSoundObject(object)
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
        query.addDescendingOrder("plays")
        query.whereKey("objectId", notContainedIn: mixedFollowSounds.map {$0.objectId!})
        query.whereKey("objectId", notContainedIn: mixedLikedSounds.map {$0.objectId!})
        query.whereKey("objectId", notContainedIn: worldCreatedAtSounds.map {$0.objectId!})
        query.limit = 10
        if sounds.count != 0 {
         query.whereKey("objectId", notContainedIn: sounds.map {$0.objectId!})
         }
        if let tags = self.selectedTagsForFiltering {
            let tagNames = tags.map {$0.name!}
            query.whereKey("tags", containedIn: tagNames)
        }
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let sound = self.newSoundObject(object)
                        self.worldTopSounds.append(sound)
                    }
                    self.worldTopSounds.sort(by: {$0.relevancyScore > $1.relevancyScore})
                    self.mixedWorldSounds = self.mixSounds(self.worldCreatedAtSounds, topSounds: self.worldTopSounds)
                    
                    var newSounds: Array<Sound>!
                    if self.mixedFollowSounds.count == 0 && self.mixedLikedSounds.count == 0 {
                        newSounds = self.mixedWorldSounds
                        
                    } else if self.mixedFollowSounds.count == 0 {
                        newSounds = self.mixSounds(self.mixedLikedSounds, topSounds: self.mixedWorldSounds)
                        
                    } else if self.mixedLikedSounds.count == 0 {
                        newSounds = self.mixSounds(self.mixedFollowSounds, topSounds: self.mixedWorldSounds)
                        
                    } else {
                        newSounds = self.mixAllSounds(self.mixedFollowSounds, mixedLikedSounds: self.mixedLikedSounds, mixedWorldSounds: self.mixedWorldSounds)
                    }
                    
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

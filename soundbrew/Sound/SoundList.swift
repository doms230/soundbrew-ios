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
// MARK: tableView, sounds, artist, tags filter, data, comment, search

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
    var userId: String?
    let player = Player.sharedInstance
    var collectionSoundIds = [String]()
    var creditSoundIds = [String]()
    var soundType: String!
    var didLoadCollection = false
    var searchText: String?
    var domSmithUserId = "AWKPPDI4CB"
    var linkObjectId: String?
    var playlist: Playlist?
    
    init(target: UIViewController, tableView: UITableView?, soundType: String, userId: String?, tags: Tag?, searchText: String?, descendingOrder: String?, linkObjectId: String?, playlist: Playlist?) {
        super.init()
        self.target = target
        self.tableView = tableView
        self.soundType = soundType
        self.userId = userId
        self.selectedTagForFiltering = tags
        self.searchText = searchText
        self.linkObjectId = linkObjectId
        self.playlist = playlist
        if let descendingOrder = descendingOrder {
            self.descendingOrder = descendingOrder
        }
        player.target = target
        player.tableView = tableView
        determineTypeOfSoundToLoad(soundType)
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
            target.performSegue(withIdentifier: "showProfile", sender: self)
        }
    }
    
    @objc func didPressArtistButton(_ sender: UIButton) {
        let row = sender.tag
        if sounds.indices.contains(sender.tag) {
            self.selectedArtist(sounds[row].artist)
        }
    }
    
    //mark: sounds
    var selectedSound: Sound?
    var descendingOrder = "createdAt"
    
    func soundCell(_ indexPath: IndexPath, tableView: UITableView, reuse: String) -> SoundListTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuse) as! SoundListTableViewCell
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        if sounds.indices.contains(indexPath.row) {
            let sound = sounds[indexPath.row]
            if let currentSoundPlaying = self.player.currentSound {
                if currentSoundPlaying.objectId == sound.objectId {
                    changeArtistSongColor(cell, color: color.blue(), playIconName: "playIcon_blue")
                } else {
                    changeArtistSongColor(cell, color: .white, playIconName: "playIcon")
                }
                
            } else {
                changeArtistSongColor(cell, color: .white, playIconName: "playIcon")
            }
            
            cell.artistImage.image = UIImage(named: "profile_icon")
            cell.artistLabel.text = "loading..."
            if let name = sound.artist?.name {
                cell.artistLabel.text = name
                if let image = sound.artist?.image {
                    cell.artistImage.kf.setImage(with: URL(string: image), placeholder: UIImage(named: "profile_icon"))
                }
            } else if let artist = sound.artist {
                artist.loadUserInfoFromCloud(nil, soundCell: cell, commentCell: nil, artistUsernameLabel: nil, artistImageButton: nil)
            }
            
            cell.artistButton.addTarget(self, action: #selector(didPressArtistButton(_:)), for: .touchUpInside)
            cell.artistButton.tag = indexPath.row
            
            if reuse == "soundReuse" {
                cell.menuButton.addTarget(self, action: #selector(self.didPressMenuButton(_:)), for: .touchUpInside)
                cell.menuButton.tag = indexPath.row
            }
            
            if let soundURL = sound.artFile?.url  {
                cell.soundArtImage.kf.setImage(with: URL(string: soundURL), placeholder: UIImage(named: "sound"))
            } else {
                cell.soundArtImage.image = UIImage(named: "sound")
            }
            
            cell.soundTitle.text = sound.title

            if let currentUser = PFUser.current()?.objectId, currentUser == self.domSmithUserId, let createdAt = sound.createdAt {
                var tipCount = 0
                var likeString = "likes"
                if let tips = sound.tipCount {
                    tipCount = tips
                    if tips == 1 {
                        likeString = "like"
                    }
                }
                cell.soundDate.text = "\(self.uiElement.formatDateAndReturnString(createdAt)) | \(tipCount) \(likeString)"
            } else {
                var hashtagString = ""
                if let hashtags = sound.tags {
                    for hashtag in hashtags {
                        if hashtagString == "" {
                            hashtagString = "#\(hashtag)"
                        } else {
                           hashtagString = "\(hashtagString), #\(hashtag)"
                        }
                    }
                }

                cell.soundDate.text = hashtagString
            }
        }
        
        return cell
    }
    
    func prepareToShowTippers(_ segue: UIStoryboardSegue) {
        let viewController = segue.destination as! PeopleViewController
        viewController.sound = selectedSound
    }
    
    @objc func didPressMenuButton(_ sender: UIButton) {
        let row = sender.tag
        if sounds.indices.contains(sender.tag) {
            let sound = sounds[sender.tag]
                        
            if let currentUser = PFUser.current(), sound.artist!.objectId == currentUser.objectId {
                let menuAlert = UIAlertController(title: "", message: nil, preferredStyle: .actionSheet)
                
                let localizedEditSound = NSLocalizedString("editSound", comment: "")
                menuAlert.addAction(UIAlertAction(title: localizedEditSound, style: .default, handler: { action in
                    if let isDraft = sound.isDraft, isDraft {
                        self.selectedSound = sound
                        self.target.performSegue(withIdentifier: "showEditSoundInfo", sender: self)
                    } else {
                        self.addSoundBackToDraftsToEdit(sound, row: row)
                    }
                }))

                let localizedDeleteSound = NSLocalizedString("deleteSound", comment: "")
                menuAlert.addAction(UIAlertAction(title: localizedDeleteSound, style: .default, handler: { action in
                    self.deleteSong(sound.objectId!, row: row)
                    }))
                
                self.addToPlaylistAlert(menuAlert, sound: sound)
                    
                let localizedCancel = NSLocalizedString("cancel", comment: "")
                menuAlert.addAction(UIAlertAction(title: localizedCancel, style: .cancel, handler: nil))
                    
                target.present(menuAlert, animated: true, completion: nil)
                
            } else {
                showOtherMenuAlert(sound, row: sender.tag)
            }
        }
    }
    
    func showOtherMenuAlert(_ sound: Sound, row: Int) {
        var alert: UIAlertController!
        
        if let currenUserObjectId = PFUser.current()?.objectId, currenUserObjectId == self.uiElement.d_innovatorObjectId {
            var shouldAddToFeaturedList = true
            var featuredTitle = "Feature this song?"
            if let isSoundFeatured = sound.isFeatured, isSoundFeatured {
                featuredTitle = "Un-Feature this song?"
                shouldAddToFeaturedList = false
            }
            
            alert = UIAlertController(title: "", message: nil , preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: featuredTitle, style: .default, handler: { action in
                self.showAddRemoveSongFromFeaturedPage(sound, shouldAddToFeaturedList: shouldAddToFeaturedList, row: row)
            }))
            
        } else {
            let localizedReportSound = NSLocalizedString("reportSound", comment: "")
            alert = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: localizedReportSound, style: .default, handler: { action in
                    self.showReportSoundAlert(sound)
            }))
        }
        
        if let playlist = playlist, let playlistUserId = playlist.artist?.objectId, let currentUserObjectId = PFUser.current()?.objectId, playlistUserId == currentUserObjectId {
            alert.addAction(UIAlertAction(title: "Remove from Playlist", style: .default, handler: { action in
                self.removeFromPlaylistAlert(playlist, sound: sound, row: row)
            }))
        } else {
            self.addToPlaylistAlert(alert, sound: sound)
        }
        
        let localizedCancel = NSLocalizedString("cancel", comment: "")
        alert.addAction(UIAlertAction(title: localizedCancel, style: .cancel, handler: nil))

        target.present(alert, animated: true, completion: nil)
    }
    
    func addToPlaylistAlert(_ alert: UIAlertController, sound: Sound) {
        alert.addAction(UIAlertAction(title: "Add To Playlist", style: .default, handler: { action in
            let modal = PlaylistViewController()
            modal.sound = sound
            self.target.present(modal, animated: true, completion: nil)
        }))
    }
    
    func removeFromPlaylistAlert(_ playlist: Playlist, sound: Sound, row: Int) {
        let alert = UIAlertController(title: "", message: "Remove \(sound.title ?? "this sound") from \(playlist.title ?? "this playlist")?" , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            self.sounds.remove(at: row)
            self.updateTableView()
            self.removeSoundFromPlaylist(playlist.objectId ?? "", soundId: sound.objectId ?? "")
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))

        target.present(alert, animated: true, completion: nil)
    }
    
    func removeSoundFromPlaylist(_ playlistId: String, soundId: String) {
        let query = PFQuery(className: "PlaylistSound")
        query.whereKey("playlistId", equalTo: playlistId)
        query.whereKey("soundId", equalTo: soundId)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
             if let object = object {
                object["isRemoved"] = true
                object.saveEventually {
                    (success: Bool, error: Error?) in
                    if (success) {
                        self.updatePlaylistCount(playlistId)
                    }
                }
             }
        }
    }
    
    func updatePlaylistCount(_ playlistId: String) {
        let query = PFQuery(className: "Playlist")
        query.getObjectInBackground(withId: playlistId) {
            (object: PFObject?, error: Error?) -> Void in
             if let object = object {
                object.incrementKey("count", byAmount: -1)
                object.saveEventually()
            }
        }
    }
    
    func showAddRemoveSongFromFeaturedPage(_ sound: Sound, shouldAddToFeaturedList: Bool, row: Int) {
        if let objectId = sound.objectId {
            let query = PFQuery(className: "Post")
            query.getObjectInBackground(withId: objectId) {
                (object: PFObject?, error: Error?) -> Void in
                if let object = object {
                    object["isFeatured"] = shouldAddToFeaturedList
                    object.saveEventually {
                        (success: Bool, error: Error?) in
                        if (success) {
                            self.sounds[row].isFeatured = shouldAddToFeaturedList
                        }
                    }
                }
            }
        }
    }
    
    func addSoundBackToDraftsToEdit(_ sound: Sound, row: Int) {
        if let objectId = sound.objectId {
            let query = PFQuery(className: "Post")
            query.getObjectInBackground(withId: objectId) {
                (object: PFObject?, error: Error?) -> Void in
                if let object = object {
                    object["isDraft"] = true
                    object["isRemoved"] = true
                    object.saveEventually {
                        (success: Bool, error: Error?) in
                        if (success) {
                            object.saveEventually()
                            self.sounds.remove(at: row)
                            DispatchQueue.main.async {
                                let menuAlert = UIAlertController(title: "Go to Drafts", message: "\(sound.title ?? "Your sound") has been added to your drafts on the new sounds page. You can edit and re-release from there.", preferredStyle: .alert)
                                menuAlert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                                self.target.present(menuAlert, animated: true, completion: nil)
                                self.tableView?.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func showReportSoundAlert(_ sound: Sound) {
        if let currentUserId = PFUser.current()?.objectId {
            let query = PFQuery(className: "Report")
            query.whereKey("userId", equalTo: currentUserId)
            query.whereKey("soundId", equalTo: sound.objectId!)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                 if let object = object {
                    let createdAt = object.createdAt
                    let localizedThankyou = NSLocalizedString("thankyou", comment: "")
                    let localizedYouReported = NSLocalizedString("youReported", comment: "")
                    let localizedOn = NSLocalizedString("on", comment: "")
                    let localizedIfYouHaveAnyQuestions = NSLocalizedString("ifYouHaveAnyQuestions", comment: "")
                    self.uiElement.showAlert("\(localizedThankyou)!", message: "\(localizedYouReported) \(sound.title!) \(localizedOn) \(self.uiElement.formatDateAndReturnString(createdAt!)). \(localizedIfYouHaveAnyQuestions) support@soundbrew.app.", target: self.target)
                 } else {
                    self.showReportAlert(currentUserId, soundId: sound.objectId!, title: sound.title!)
                }
            }
                        
        } else {
            let localizedSignupRequired = NSLocalizedString("signupRequired", comment: "")
            let localizedOnlyRegisteredUsers = NSLocalizedString("onlyRegisteredUsers", comment: "")
            self.uiElement.signupRequired(localizedSignupRequired, message: "\(localizedOnlyRegisteredUsers) support@soundbrew.app", target: self.target)
        }
    }
    
    func showReportAlert(_ currentUserId: String, soundId: String, title: String) {
        DispatchQueue.main.async {
            let localizedReport = NSLocalizedString("report", comment: "")
            let localizedReportMessage = NSLocalizedString("reportMessage", comment: "")
            let localizedNevermind = NSLocalizedString("nevermind", comment: "")
            let localizedThankyou = NSLocalizedString("thankyou", comment: "")
            let localizedReceivedReport = NSLocalizedString("receivedReport", comment: "")
            let menuAlert = UIAlertController(title: "\(localizedReport) \(title)?", message:  localizedReportMessage, preferredStyle: .alert)
            menuAlert.addAction(UIAlertAction(title: localizedNevermind, style: .cancel, handler: nil))
            menuAlert.addAction(UIAlertAction(title: localizedReport, style: .default, handler: { action in
                let newReport = PFObject(className: "Report")
                newReport["userId"] = currentUserId
                newReport["user"] = PFUser.current()
                newReport["soundId"] = soundId
                newReport.saveEventually {
                    (success: Bool, error: Error?) in
                    if (success) {
                        self.uiElement.showAlert(localizedThankyou, message: localizedReceivedReport, target: self.target)
                    }
                }
            }))
            self.target.present(menuAlert, animated: true, completion: nil)
        }
    }
    
    func changeArtistSongColor(_ cell: SoundListTableViewCell, color: UIColor, playIconName: String) {
        cell.soundTitle.textColor = color
        cell.artistLabel.textColor = color
        if color == .white {
            cell.soundDate.textColor = .darkGray
        } else {
            cell.soundDate.textColor = color
        }
    }
    
    func determineTypeOfSoundToLoad(_ soundType: String) {
        self.isUpdatingData = true
        switch soundType {
        case "playlist":
            if let playlistId = self.playlist?.objectId {
                self.loadPlaylistSounds(playlistId)
            }
            break
            
        case "forYou":
            if let currentUserId = PFUser.current()?.objectId {
                if currentUserId == self.domSmithUserId {
                    loadSounds(nil, postIds: nil, userId: nil, searchText: nil, followIds: nil, tag: nil, forYouTags: nil)
                } else {
                    loadLastLike(currentUserId)
                }
            }
            break
            
        case "discover":
            var tag: String?
            if let selectedTag = self.selectedTagForFiltering {
                tag = selectedTag.name
            }
            loadSounds("tippers", postIds: nil, userId: nil, searchText: nil, followIds: nil, tag: tag, forYouTags: nil)
            break
            
        case "uploads":
            loadSounds(descendingOrder, postIds: nil, userId: userId!, searchText: nil, followIds: nil, tag: nil, forYouTags: nil)
            break
            
        case "collection":
            if let profileUserId = self.userId {
                self.loadCollection(descendingOrder, profileUserId: profileUserId)
            }
            break
            
        case "credit":
            if let profileUserId = self.userId {
                self.loadCredit(descendingOrder, profileUserId: profileUserId)
            }
            break
            
        case "search":
            loadSounds("plays", postIds: nil, userId: nil, searchText: searchText, followIds: nil, tag: nil, forYouTags: nil)
            break
            
        case "follow":
            if let currentUserId = PFUser.current()?.objectId, currentUserId == self.domSmithUserId {
                loadSounds("createdAt", postIds: nil, userId: nil, searchText: nil, followIds: nil, tag: nil, forYouTags: nil)
            } else if let followUserIds = self.uiElement.getUserDefault("friends") as? [String] {
                self.loadSounds(descendingOrder, postIds: nil, userId: nil, searchText: nil, followIds: followUserIds, tag: nil, forYouTags: nil)
            }
            break
            
        case "drafts":
            if let userId = self.userId {
                self.loadSounds(descendingOrder, postIds: nil, userId: userId, searchText: nil, followIds: nil, tag: nil, forYouTags: nil)
            }
            break
            
        case "new":
            loadSounds("createdAt", postIds: nil, userId: nil, searchText: nil, followIds: nil, tag: nil, forYouTags: nil)
            break
            
        default:
            break
        }
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
    var playlistIds = [String]()
    var didLoadPlaylist = false
    func loadPlaylistSounds(_ playlistId: String) {
        let query = PFQuery(className: "PlaylistSound")
        print(playlistId)
        query.whereKey("playlistId", equalTo: playlistId)
        query.limit = 50
        query.addDescendingOrder("createdAt")
        query.whereKey("isRemoved", equalTo: false)
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            self.didLoadPlaylist = true
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        self.playlistIds.append(object["soundId"] as! String)
                    }
                }
                
                self.loadSounds(self.descendingOrder, postIds: self.playlistIds, userId: nil, searchText: nil, followIds: nil, tag: nil, forYouTags: nil)
            }
        }
    }
    
    func loadSound(_ objectId: String, isForYouPage: Bool, isForLastSoundUserListenedTo: Bool) {
        let query = PFQuery(className: "Post")
        query.cachePolicy = .networkElseCache
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print("loadSOund- SoundList.swift \(error)")
                
            } else if let object = object {
                if isForYouPage {
                    let tags = object["tags"] as! [String]?
                    self.loadSounds(nil, postIds: nil, userId: nil, searchText: nil, followIds: nil, tag: nil, forYouTags: tags)
                } else if isForLastSoundUserListenedTo {
                    let sound = self.uiElement.newSoundObject(object)
                    let player = self.player
                    player.sounds = [sound]
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "preparingSound"), object: nil)
                    player.setUpNextSong(false, at: 0, shouldPlay: false)
                    
                } else {
                    let sound = self.uiElement.newSoundObject(object)
                    self.sounds.append(sound)
                    self.isUpdatingData = false
                    DispatchQueue.main.async {
                        self.tableView?.reloadData()
                    }
                }
            }
        }
    }
    
    func loadLastLike(_ userId: String) {
        let query = PFQuery(className: "Tip")
        query.whereKey("fromUserId", equalTo: userId)
        query.cachePolicy = .networkElseCache
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print("load last like - Sound list: \(error)")
            }
             if let object = object {
                let soundId = object["soundId"] as! String
                self.loadSound(soundId, isForYouPage: true, isForLastSoundUserListenedTo: false)
             } else {
                self.loadSounds(nil, postIds: nil, userId: nil, searchText: nil, followIds: nil, tag: nil, forYouTags: nil)
            }
        }
    }
    
    //To insure that data isn't loaded again when user is at bottom of screen
    var isUpdatingData = false
    var thereIsMoreDataToLoad = true
    
    func updateTableView() {
        DispatchQueue.main.async {
            self.isUpdatingData = false
            if let tableView = self.tableView {
                tableView.reloadData()
                if let refreshControl = tableView.refreshControl {
                    refreshControl.endRefreshing()
                }
            }
        }
    }
    
    func loadSounds(_ descendingOrder: String?, postIds: Array<String>?, userId: String?, searchText: String?, followIds: Array<String>?, tag: String?, forYouTags: [String]?) {
        isUpdatingData = true
        let query = PFQuery(className: "Post")
        if let postIds = postIds {
            query.whereKey("objectId", containedIn: postIds)
        }
        
        if let followIds = followIds {
            query.whereKey("userId", containedIn: followIds)
        }
        
        if let userId = userId {
            query.whereKey("userId", equalTo: userId)
        }
        
        if let tag = tag {
          query.whereKey("tags", contains: tag)
        } else if let tags = forYouTags {
            query.whereKey("tags", containedIn: tags)
        }
        
        if let descendingOrder = descendingOrder {
            query.addDescendingOrder(descendingOrder)
        } else {
            query.whereKey("isFeatured", equalTo: true)
            query.addDescendingOrder("createdAt")
        }
        
        if let searchText = searchText {
            query.whereKey("title", matchesRegex: searchText.capitalized)
            query.whereKey("title", matchesRegex: searchText.uppercased(with: nil))
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
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let error = error {
                print("load sounds - Sound list: \(error)")
            }
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
                }
                
            } else {
                self.thereIsMoreDataToLoad = false                
            }
            
            self.updateTableView()
        }
    }
    
    func loadCollection(_ descendingOrder: String, profileUserId: String) {
        let query = PFQuery(className: "Tip")
        query.whereKey("fromUserId", equalTo: profileUserId)
        query.whereKey("soundId", notContainedIn: collectionSoundIds)
        query.limit = 50
        query.addDescendingOrder("createdAt")
        query.cachePolicy = .networkElseCache
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
                    self.loadSounds(descendingOrder, postIds: self.collectionSoundIds, userId: nil, searchText: nil, followIds: nil, tag: nil, forYouTags: nil)
                }
            }
        }
    }
    
    func loadCredit(_ descendingOrder: String, profileUserId: String) {
        let query = PFQuery(className: "Credit")
        query.whereKey("userId", equalTo: profileUserId)
        query.whereKey("postId", notContainedIn: collectionSoundIds)
        query.limit = 50
        query.addDescendingOrder("createdAt")
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            self.didLoadCollection = true
            if let error = error {
                print("load credit - Sound list: \(error)")
            }
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        self.creditSoundIds.append(object["postId"] as! String)
                    }
                }
                self.loadSounds(descendingOrder, postIds: self.creditSoundIds, userId: nil, searchText: nil, followIds: nil, tag: nil, forYouTags: nil)
            }
        }
    }
    
    func deleteSong(_ objectId: String, row: Int) {
        let localizedRemove = NSLocalizedString("remove", comment: "")
        let localizedThisSound = NSLocalizedString("thisSound", comment: "")
        let localizedFromSoundbrew = NSLocalizedString("fromSoundbrew", comment: "")

        let menuAlert = UIAlertController(title: "\(localizedRemove) \(self.sounds[row].title ?? localizedThisSound) \(localizedFromSoundbrew)?", message: nil, preferredStyle: .alert)
        
        let localizedNo = NSLocalizedString("no", comment: "")
        menuAlert.addAction(UIAlertAction(title: localizedNo, style: .cancel, handler: nil))
        
        let localizedYes = NSLocalizedString("yes", comment: "")
        menuAlert.addAction(UIAlertAction(title: localizedYes, style: .default, handler: { action in
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
                    DispatchQueue.main.async {
                        self.tableView?.reloadData()
                    }
                }
            }
        }))        
        
        target.present(menuAlert, animated: true, completion: nil)
    }
}

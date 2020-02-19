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
    var profileUserId: String?
    let player = Player.sharedInstance
    var collectionSoundIds = [String]()
    var creditSoundIds = [String]()
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
            self.segueToProfile()
        }
    }
    
    func segueToProfile() {
        target.performSegue(withIdentifier: "showProfile", sender: self)
    }
    
    //mark: sounds
    var selectedSound: Sound?
    var descendingOrder = "createdAt"
    
    func soundCell(_ indexPath: IndexPath, tableView: UITableView, reuse: String) -> UITableViewCell {
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
                artist.loadUserInfoFromCloud(nil, soundCell: cell, commentCell: nil)
            }
            
            cell.artistButton.addTarget(self, action: #selector(didPressArtistButton(_:)), for: .touchUpInside)
            cell.artistButton.tag = indexPath.row
            
            cell.menuButton.addTarget(self, action: #selector(self.didPressMenuButton(_:)), for: .touchUpInside)
            cell.menuButton.tag = indexPath.row
            
            if let soundURL = sound.artURL {
                cell.soundArtImage.kf.setImage(with: URL(string: soundURL), placeholder: UIImage(named: "sound"))
            } else {
                cell.soundArtImage.image = UIImage(named: "sound")
            }
            
            cell.soundTitle.text = sound.title
            
            let formattedDate = self.uiElement.formatDateAndReturnString(sound.createdAt!)
            cell.soundDate.text = formattedDate
            
            if let likes = sound.tipCount {
                cell.likesCountLabel.text = "\(likes)"
            } else {
                cell.likesCountLabel.text = "0"
            }
        }
        
        return cell
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
            
            var tips = 0
            if let soundTips = sound.tipCount {
                tips = soundTips
            }
            let tipsInDollarString = self.uiElement.convertCentsToDollarsAndReturnString(tips, currency: "$")
                        
            if let currentUser = PFUser.current() {
                if sound.artist!.objectId == currentUser.objectId {
                    //let localizedPlays = NSLocalizedString("plays", comment: "")
                    let localizedTips = NSLocalizedString("tips", comment: "")
                    let localizedIn = NSLocalizedString("in", comment: "")

                    let menuAlert = UIAlertController(title: "\(tipsInDollarString) \(localizedIn) \(localizedTips)", message: nil, preferredStyle: .actionSheet)
                        
                    if let isDraft = sound.isDraft, isDraft {
                        let localizedEditSound = NSLocalizedString("editSound", comment: "")
                        menuAlert.addAction(UIAlertAction(title: localizedEditSound, style: .default, handler: { action in
                            self.selectedSound = sound
                            self.target.performSegue(withIdentifier: "showEditSoundInfo", sender: self)
                        }))
                    }

                    let localizedDeleteSound = NSLocalizedString("deleteSound", comment: "")
                    menuAlert.addAction(UIAlertAction(title: localizedDeleteSound, style: .default, handler: { action in
                        self.deleteSong(sound.objectId!, row: row)
                        }))
                    
                        
                    let localizedCancel = NSLocalizedString("cancel", comment: "")
                    menuAlert.addAction(UIAlertAction(title: localizedCancel, style: .cancel, handler: nil))
                        
                    target.present(menuAlert, animated: true, completion: nil)
                    
                } else {
                    showOtherMenuAlert(sound)
                }
                
            } else {
                showOtherMenuAlert(sound)
            }
        }
    }
    
    func showOtherMenuAlert(_ sound: Sound) {
        let localizedReportSound = NSLocalizedString("reportSound", comment: "")
        let menuAlert = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
            menuAlert.addAction(UIAlertAction(title: localizedReportSound, style: .default, handler: { action in
                self.showReportSoundAlert(sound)
            }))
                
        let localizedCancel = NSLocalizedString("cancel", comment: "")
        menuAlert.addAction(UIAlertAction(title: localizedCancel, style: .cancel, handler: nil))
        
        target.present(menuAlert, animated: true, completion: nil)
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
            newReport["soundId"] = soundId
            newReport.saveEventually {
                (success: Bool, error: Error?) in
                if (success) {
                    self.uiElement.showAlert(localizedThankyou, message: localizedReceivedReport, target: self.target)
                }
            }
        }))
        target.present(menuAlert, animated: true, completion: nil)
    }
    
    func changeArtistSongColor(_ cell: SoundListTableViewCell, color: UIColor, playIconName: String) {
        cell.soundTitle.textColor = color
        cell.artistLabel.textColor = color
        let originalImage = UIImage(named: "sendTipColored")
        let tintedImage = originalImage?.withRenderingMode(.alwaysTemplate)
        cell.likesImage.image = tintedImage
        if color == .white {
            cell.soundDate.textColor = .darkGray
            cell.likesCountLabel.textColor = .darkGray
            cell.likesImage.tintColor = .darkGray
        } else {
            cell.soundDate.textColor = color
            cell.likesCountLabel.textColor = color
            cell.likesImage.tintColor = color
        }
    }
    
    func determineTypeOfSoundToLoad(_ soundType: String) {
        self.isUpdatingData = true
        
        switch soundType {
        case "yourSoundbrew":
            loadYourSoundbrew()
            break
        case "chart":
            loadSounds(nil, postIds: nil, userId: nil, searchText: nil, followIds: nil)
            break
            
        case "discover":
            loadWorldCreatedAtSounds()
            break
            
        case "uploads":
            loadSounds(descendingOrder, postIds: nil, userId: profileUserId!, searchText: nil, followIds: nil)
            break
            
        case "collection":
            if let profileUserId = self.profileUserId {
                self.loadCollection(descendingOrder, profileUserId: profileUserId)
            }
            break
            
        case "credit":
            if let profileUserId = self.profileUserId {
                self.loadCredit(descendingOrder, profileUserId: profileUserId)
            }
            break
            
        case "search":
            loadSounds("plays", postIds: nil, userId: nil, searchText: searchText, followIds: nil)
            break
            
        case "follow":
            if let followUserIds = self.uiElement.getUserDefault("friends") as? [String] {
                self.loadSounds(descendingOrder, postIds: nil, userId: nil, searchText: nil, followIds: followUserIds)
            }
            break
            
        case "drafts":
            if let userId = self.profileUserId {
                self.loadSounds(descendingOrder, postIds: nil, userId: userId, searchText: nil, followIds: nil)
            }
            break
            
        case "story":
            if let userId = self.profileUserId {
                self.loadStories(userId)
            }
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
    func loadSound(_ objectId: String) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                let sound = self.uiElement.newSoundObject(object)
                self.sounds.append(sound)
                self.isUpdatingData = false
                self.tableView?.reloadData()
            }
        }
    }
    
    //To insure that data isn't loaded again when user is at bottom of screen
    var isUpdatingData = false
    var thereIsMoreDataToLoad = true
    
    func updateTableView() {
        self.isUpdatingData = false
        if let tableView = self.tableView {
            tableView.reloadData()
            if let refreshControl = tableView.refreshControl {
                refreshControl.endRefreshing()
            }
        }
    }
    
    func loadSounds(_ descendingOrder: String?, postIds: Array<String>?, userId: String?, searchText: String?, followIds: Array<String>?) {
        
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
        
        if let descendingOrder = descendingOrder {
            query.addDescendingOrder(descendingOrder)
        } else {
            query.whereKey("createdAt", greaterThanOrEqualTo: Date().previous(.friday))
            query.addDescendingOrder("tippers")
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
            
            if self.soundType == "story" {
                self.player.sounds = self.sounds
                self.player.didSelectSoundAt(0)
            } else {
                self.updateTableView()
            }
        }
    }
    
    func loadCollection(_ descendingOrder: String, profileUserId: String) {
        let query = PFQuery(className: "Tip")
        query.whereKey("fromUserId", equalTo: profileUserId)
        query.whereKey("soundId", notContainedIn: collectionSoundIds)
        query.limit = 50
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
                    self.loadSounds(descendingOrder, postIds: self.collectionSoundIds, userId: nil, searchText: nil, followIds: nil)
                }
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func loadCredit(_ descendingOrder: String, profileUserId: String) {
        let query = PFQuery(className: "Credit")
        query.whereKey("userId", equalTo: profileUserId)
        query.whereKey("postId", notContainedIn: collectionSoundIds)
        query.limit = 50
        query.addDescendingOrder("createdAt")
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            self.didLoadCollection = true
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        self.creditSoundIds.append(object["postId"] as! String)
                    }
                }
                
                self.loadSounds(descendingOrder, postIds: self.creditSoundIds, userId: nil, searchText: nil, followIds: nil)
            }
        }
    }
        
    var storyPostIds = [String]()
    func loadStories(_ userId: String) {
        let query = PFQuery(className: "Story")
        query.whereKey("userId", equalTo: userId)
        query.addDescendingOrder("createdAt")
        query.limit = 25
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                for object in objects {
                    print(object["postId"] as! String)
                    self.storyPostIds.append(object["postId"] as! String)
                }
                self.loadSounds(self.descendingOrder, postIds: self.storyPostIds, userId: nil, searchText: nil, followIds: nil)
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
                if topSounds.indices.contains(i / 2) {
                    mixSounds.append(topSounds[i / 2])
                }
                
            } else {
                if createdAtSounds.indices.contains(i / 2) {
                    mixSounds.append(createdAtSounds[i / 2])
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
                    self.loadWorldTopSounds()
                }
            }
        }
    }
    
    func loadWorldTopSounds() {
        let query = PFQuery(className: "Post")
        query.whereKey("isRemoved", notEqualTo: true)
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
                    self.mixedWorldSounds = self.mixSounds(self.worldCreatedAtSounds, topSounds: self.worldTopSounds)
                    
                    var newSounds: Array<Sound>!
                    newSounds = self.mixedWorldSounds
                    
                    for newSound in newSounds {
                        self.sounds.append(newSound)
                    }

                    if objects.count == 0 {
                        self.thereIsMoreDataToLoad = false 
                    }
                    
                    self.updateTableView()
                    
                } else {
                    self.thereIsMoreDataToLoad = false
                }
                
            } else {
                self.thereIsMoreDataToLoad = false
                print("Error: \(error!)")
            }
        }
    }
    
    func loadYourSoundbrew() {
        let query = PFQuery(className: "Post")
        query.whereKey("isRemoved", notEqualTo: true)
        query.addDescendingOrder("tips")
        query.limit = 100
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let sound = UIElement().newSoundObject(object)
                        self.sounds.append(sound)
                    }
                    self.sounds.shuffle()
                    self.player.sounds = self.sounds
                    self.player.didSelectSoundAt(0)
                }
            }
        }
    }
}

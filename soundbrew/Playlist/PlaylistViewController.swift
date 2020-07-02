//
//  PlaylistViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/22/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import Kingfisher
import NotificationBannerSwift

class PlaylistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PlaylistDelegate {
    
    let uiElement = UIElement()
    let color = Color()
    
    var playlists = [Playlist]()
    var dividerLine: UIView!
    var sound: Sound!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        if let currentUserId = PFUser.current()?.objectId {
            let topView = self.uiElement.addSubViewControllerTopView(self, action: #selector(didPressDoneButton(_:)), doneButtonTitle: "", title: "Select Playlist")
            dividerLine = topView.2
            loadPlaylists(currentUserId)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func didPressDoneButton(_ sender: UIButton) {
        if sender.tag == 0 {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    //mark: tableview
    var tableView: UITableView!
    let selectPlaylistSoundsReuse = "selectPlaylistSoundsReuse"
    let newPlaylistReuse = "newCreditReuse"
    func setUpTableView(_ dividerLine: UIView) {
        self.tableView = UITableView()
        tableView.backgroundColor = color.black()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier:
            selectPlaylistSoundsReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: newPlaylistReuse)
        tableView.isOpaque = true
        self.tableView.separatorStyle = .none
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl
        refreshControl.endRefreshing()
        self.view.addSubview(tableView)
        self.tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(dividerLine.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    @objc func refresh(_ sender: UIRefreshControl) {
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return playlists.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return playlistCell(indexPath)
        } else {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: newPlaylistReuse) as! SoundInfoTableViewCell
            cell.backgroundColor = color.black()
            cell.selectionStyle = .none
            cell.titleLabel.text = "Create New Playlist"
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let banner = StatusBarNotificationBanner(title: "\(sound.title ?? "Selected Sound has been") added to \(playlists[indexPath.row].title ?? "selected playlist").", style: .info)
            banner.show()
            self.checkIfUserLikedSong()
            attachSoundToPlaylist(sound.objectId ?? "", playlistId: playlists[indexPath.row].objectId ?? "")
            
        } else {
            let newPlaylist = Playlist(objectId: nil, artist: nil, title: nil, image: nil, type: "playlist", count: 0)
            let modal = NewPlaylistViewController()
            modal.playlistDelegate = self
            modal.playlist = newPlaylist
            self.present(modal, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

    }
    
    func receivedPlaylist(_ playlist: Playlist?) {
        if let playlist = playlist {
            self.playlists.append(playlist)
            self.tableView.reloadData()
        }
    }
    
    func playlistCell(_ indexPath: IndexPath) -> SoundListTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: selectPlaylistSoundsReuse) as! SoundListTableViewCell
         cell.backgroundColor = color.black()
         cell.selectionStyle = .none
                    
        if playlists.indices.contains(indexPath.row) {
            let playlist = playlists[indexPath.row]
             
            cell.artistImage.image = UIImage(named: "profile_icon")
            cell.artistLabel.text = "loading..."
            if let name = playlist.artist?.name {
                cell.artistLabel.text = name
                if let image = playlist.artist?.image {
                    cell.artistImage.kf.setImage(with: URL(string: image), placeholder: UIImage(named: "profile_icon"))
                 }
             } else if let artist = playlist.artist {
                 artist.loadUserInfoFromCloud(nil, soundCell: cell, commentCell: nil, artistUsernameLabel: nil, artistImageButton: nil)
             }
             
            if let playlistImageURL = playlist.image?.url  {
                 cell.soundArtImage.kf.setImage(with: URL(string: playlistImageURL), placeholder: UIImage(named: "sound"))
            } else if playlist.objectId == "uploads" {
                cell.soundArtImage.image = UIImage(named: "upload")
            } else if playlist.objectId == "likes" {
                cell.soundArtImage.image = UIImage(named: "like")
            } else {
                cell.soundArtImage.image = UIImage(named: "sound")
            }
            
            if let count = playlist.count {
                cell.soundDate.text = "\(count) Sounds"
            }
             
            cell.soundTitle.text = playlist.title
            
            cell.circleImage.text = "⨁"
            
            cell.menuButton.isHidden = true
            
        }
        return cell
    }
    
    func loadPlaylists(_ currentUserId: String) {
        let query = PFQuery(className: "Playlist")
        query.whereKey("userId", equalTo: currentUserId)
        query.addDescendingOrder("createdAt")
        query.whereKey("isRemoved", equalTo: false)
        query.whereKey("objectId", notContainedIn: self.playlists.map {$0.objectId!})
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let error  = error {
                print("load playlists - PlaylistViewCOntroller: \(error)")
            }
            if let objects = objects {
                for object in objects {
                    let playlist = Playlist(objectId: object.objectId, artist: nil, title: nil, image: nil, type: nil, count: nil)
                    let artist = Artist(objectId: object["userId"] as? String, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, account: nil)
                    playlist.artist = artist
                    playlist.title = object["title"] as? String
                    playlist.image = object["image"] as? PFFileObject
                    playlist.type = object["type"] as? String
                    playlist.count = object["count"] as? Int
                    self.playlists.append(playlist)
                }
            }
            self.setUpTableView(self.dividerLine)
        }
    }
    
    func attachSoundToPlaylist(_ soundId: String, playlistId: String) {
        let newPlaylistSound = PFObject(className: "PlaylistSound")
        newPlaylistSound["playlistId"] = playlistId
        newPlaylistSound["soundId"] = soundId
        newPlaylistSound["isRemoved"] = false 
        newPlaylistSound.saveEventually()
        updatePlaylistCount(playlistId)
    }
    
    func updatePlaylistCount(_ playlistId: String) {
        let query = PFQuery(className: "Playlist")
        query.getObjectInBackground(withId: playlistId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print("update playlist Count - PlaylistViewCOntroller: \(error)")
            }
             if let object = object {
                object.incrementKey("count")
                object.saveEventually()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func checkIfUserLikedSong() {
        if let soundId = self.sound.objectId, let userId = PFUser.current()?.objectId {
            let query = PFQuery(className: "Tip")
            query.whereKey("fromUserId", equalTo: userId)
            query.whereKey("soundId", equalTo: soundId)
            query.cachePolicy = .networkElseCache
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if let error = error {
                    print("check if user liked soung - Like.swift: \(error)")
                }
                if object == nil {
                    if let currentSoundId = Player.sharedInstance.currentSound?.objectId, currentSoundId == soundId {
                        Player.sharedInstance.currentSound?.currentUserDidLikeSong = true
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "setSound"), object: nil)

                    }
                    self.newLike()
                }
            }
        }
    }
    
    func newLike() {
        if let soundId = self.sound.objectId, let fromUserId = PFUser.current()?.objectId, let toUserId = sound.artist?.objectId {
            let newPayment = PFObject(className: "Tip")
            newPayment["fromUserId"] = fromUserId
            newPayment["toUserId"] = toUserId
            newPayment["soundId"] = soundId
            newPayment.saveEventually()
            newMention(soundId, fromUserId: fromUserId, toUserId: toUserId)
        }
    }
    
    func newMention(_ soundId: String, fromUserId: String, toUserId: String) {
        if fromUserId != toUserId {
            let newMention = PFObject(className: "Mention")
            newMention["type"] = "like"
            newMention["fromUserId"] = fromUserId
            newMention["toUserId"] = toUserId
            newMention["postId"] = soundId
            newMention.saveEventually {
                (success: Bool, error: Error?) in
                if success && error == nil {
                    self.uiElement.sendAlert("liked \(self.sound.title ?? "your sound")!", toUserId: toUserId, shouldIncludeName: true)
                }
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

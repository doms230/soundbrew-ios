//
//  ProfileViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/11/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//
// mark: button actions, data, tableview, social buttons

//checing if self.tabBarController != nil  because there is no tabbvarcontroller when going to profile from commentviewcontroller

import UIKit
import Parse
import Kingfisher
import SnapKit
import SidebarOverlay
import NotificationBannerSwift
import Alamofire
import SwiftyJSON

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ArtistDelegate, PlayerDelegate, TagDelegate, PlaylistDelegate, AccountDelegate {
    
    let uiElement = UIElement()
    let color = Color()
    
    var profileArtist: Artist?
    
    var soundList: SoundList!
    var soundType = "uploads"
    var isFromNavigationStack = true
    var currentUser: PFUser?
    let player = Player.sharedInstance
    var followerOrFollowing: String!
    var earnings: Int! 
    
    lazy var profileImage: UIImageView = {
        let image = uiElement.soundbrewImageView(nil, cornerRadius: nil, backgroundColor: nil)
        return image
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = .black
        navigationController?.navigationBar.tintColor = .white
        determineTypeOfProfile()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setMiniPlayer()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
            case "showProfile":
                let backItem = UIBarButtonItem()
                backItem.title = ""
                navigationItem.backBarButtonItem = backItem
                
                let viewController = segue.destination as! ProfileViewController
                viewController.profileArtist = selectedArtist
                break
                
            case "showSounds":
                let backItem = UIBarButtonItem()
                                
                let viewController = segue.destination as! SoundsViewController
                
                if let newPlaylist = self.newPlaylist {
                    showPlaylistSounds(newPlaylist, backItem: backItem, viewController: viewController)
                    self.newPlaylist = nil 
                } else if let selectedTag = self.selectedTagFromPlayerView {
                    viewController.soundType = "discover"
                    viewController.selectedTagForFiltering = selectedTag
                    backItem.title = selectedTag.name
                } else if let indexPath = tableView.indexPathForSelectedRow {
                    if indexPath.section == 2 {
                        showPlaylistSounds(self.artistPlaylists[indexPath.row], backItem: backItem, viewController: viewController)
                    } else if indexPath.section == 3, let userId = profileArtist?.objectId, let username = profileArtist?.username {
                        if indexPath.row == 0 {
                            backItem.title = "\(username)'s Uploads"
                            viewController.soundType = "uploads"
                            viewController.userId = userId
                        } else {
                            backItem.title = "\(username)'s Likes"
                            viewController.soundType = "collection"
                            viewController.userId = userId
                        }
                    }
                }
                navigationItem.backBarButtonItem = backItem
                break
                
            case "showFollowerFollowing":
                let backItem = UIBarButtonItem()
                backItem.title = followerOrFollowing.capitalized
                navigationItem.backBarButtonItem = backItem
                
                let viewController = segue.destination as! PeopleViewController
                viewController.loadType = followerOrFollowing
                break
            
            case "showEarnings":
                let backItem = UIBarButtonItem()
                backItem.title = "Earnings"
                navigationItem.backBarButtonItem = backItem
                let viewController = segue.destination as! EarningsViewController
                if let earnings = Customer.shared.artist?.account?.weeklyEarnings {
                    viewController.earnings = earnings
                }
                break
                
            case "showAccountWebView":
                let backItem = UIBarButtonItem()
                backItem.title = "Account Info"
                navigationItem.backBarButtonItem = backItem
                MiniPlayerView.sharedInstance.isHidden = true
                default:
                    break
        }
    }
    
    func changeBio(_ value: String?) {
    }
    
    func receivedArtist(_ value: Artist?) {
        if let artist = value {
            self.profileArtist = artist
            self.tableView.reloadData()
            if let username = artist.username {
                self.uiElement.addTitleView(username, target: self)
            }
        }
    }
    
    func loadProfileData() {
        if let profileArtist = self.profileArtist {
            if let currentUser = PFUser.current(), currentUser.objectId != profileArtist.objectId {
                if let username = profileArtist.username {
                    if !username.contains("@") {
                        self.navigationItem.title = username
                    }
                }
                checkFollowStatus()
            }

            self.loadPlaylists(profileUserId: profileArtist.objectId)
            if self.tableView != nil {
                self.tableView.refreshControl?.endRefreshing()
            }
        }
    }
    
    //MARK: Tableview
    var tableView: UITableView!
    let profileReuse = "profileReuse"
    let soundReuse = "soundReuse"
    let spaceReuse = "spaceReuse"
    let dividerReuse = "dividerReuse"
    func setUpTableView() {
        let miniPlayerHeight = MiniPlayerView.sharedInstance.frame.height
        var tabBarControllerHeight: CGFloat = 50
        if let tabBar = self.tabBarController?.tabBar {
            tabBarControllerHeight = tabBar.frame.height
        }
        
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: profileReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: spaceReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: dividerReuse)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl
        self.view.addSubview(tableView)
        self.tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-(miniPlayerHeight + tabBarControllerHeight))
        }
        
        let player = Player.sharedInstance
        player.tableView = tableView
    }
    
    @objc func refresh(_ sender: UIRefreshControl) {
       self.loadProfileData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 2:
            return artistPlaylists.count
        case 3:
            return 2
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return profileInfoReuse()
        case 1:
            let cell = self.tableView.dequeueReusableCell(withIdentifier: dividerReuse) as! SoundInfoTableViewCell
            cell.backgroundColor = color.black()
            cell.selectionStyle = .none
            return cell
        case 2:
            return playlistCell(indexPath)
        case 3:
            return uploadsAndLikesPlaylistCell(indexPath)
        default:
            let cell = self.tableView.dequeueReusableCell(withIdentifier: spaceReuse) as! ProfileTableViewCell
            cell.backgroundColor = color.black()
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 || indexPath.section == 3 {
            self.performSegue(withIdentifier: "showSounds", sender: self)
        }
    }
    
    //mark: miniPlayer
    func setMiniPlayer() {
        let miniPlayerView = MiniPlayerView.sharedInstance
        miniPlayerView.superViewController = self
        miniPlayerView.tagDelegate = self
        miniPlayerView.playerDelegate = self
        miniPlayerView.isHidden = false 
    }
    
    //mark: selectedArtist
    var selectedArtist: Artist!
    
    func selectedArtist(_ artist: Artist?) {
        if let artist = artist {
            switch artist.objectId {
                case "addFunds":
                    self.performSegue(withIdentifier: "showAddFunds", sender: self)
                    break
                    
                case "signup":
                    self.performSegue(withIdentifier: "showWelcome", sender: self)
                    break
                    
                case "collectors":
                    self.performSegue(withIdentifier: "showTippers", sender: self)
                    break
                    
                default:
                    if artist.objectId != profileArtist?.objectId {
                        let player = Player.sharedInstance
                        self.selectedArtist = player.currentSound?.artist
                        self.performSegue(withIdentifier: "showProfile", sender: self)
                    }
                    break
            }
        }
    }
    
    //mark: Playlist
    var newPlaylist: Playlist?
    var artistPlaylists = [Playlist]()
    
    func showPlaylistSounds(_ playlist: Playlist, backItem: UIBarButtonItem, viewController: SoundsViewController) {
        backItem.title = playlist.title ?? "Playlist"
        viewController.soundType = "playlist"
        viewController.playlist = playlist
    }
    
    func receivedPlaylist(_ playlist: Playlist?) {
        if let newPlaylist = playlist {
            var didFindMatchingPlaylist = false
            for i in 0..<self.artistPlaylists.count {
                let playlist = self.artistPlaylists[i]
                if let currentObjectId = playlist.objectId, currentObjectId == newPlaylist.objectId {
                    self.artistPlaylists[i] = newPlaylist
                    didFindMatchingPlaylist = true
                    self.tableView.reloadData()
                    break
                }
            }
            if !didFindMatchingPlaylist {
                self.artistPlaylists.insert(newPlaylist, at: 0)
                self.tableView.reloadData()
            }
            
            self.newPlaylist = newPlaylist
            self.performSegue(withIdentifier: "showSounds", sender: self)
        }
    }
    
    func showNewEditPlaylistView(_ playlist: Playlist) {
        let modal = NewPlaylistViewController()
        modal.playlistDelegate = self
        modal.playlist = playlist
        self.present(modal, animated: true, completion: nil)
    }
    
    func deletePlaylist(_ playlistId: String, row: Int) {
        self.artistPlaylists.remove(at: row)
        self.tableView.reloadData()
        let query = PFQuery(className: "Playlist")
        query.getObjectInBackground(withId: playlistId) {
            (object: PFObject?, error: Error?) -> Void in
             if let object = object {
                object["isRemoved"] = true
                object.saveEventually()
            }
        }
    }
    
    func uploadsAndLikesPlaylistCell(_ indexPath: IndexPath) -> SoundListTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
         cell.backgroundColor = color.black()
         cell.selectionStyle = .none
        
        var playlist: Playlist!
        if indexPath.row == 0 {
            let uploadsPlaylist = Playlist(objectId: "uploads", artist: self.profileArtist, title: "Uploads", image: nil, type: nil, count: nil)
            playlist = uploadsPlaylist
        } else {
            let likesPlaylist = Playlist(objectId: "likes", artist: self.profileArtist, title: "Likes", image: nil, type: nil, count: nil)
            playlist = likesPlaylist
        }
                
        cell.artistImage.image = UIImage(named: "profile_icon")
        cell.artistLabel.text = "loading..."
        if let name = playlist.artist?.name {
            cell.artistLabel.text = name
            if let image = playlist.artist?.image {
                cell.artistImage.kf.setImage(with: URL(string: image), placeholder: UIImage(named: "profile_icon"))
             }
         } else if let artist = playlist.artist {
            artist.loadUserInfoFromCloud(nil, soundCell: cell, commentCell: nil, mentionCell: nil, artistUsernameLabel: nil, artistImageButton: nil)
         }
         
         cell.artistButton.addTarget(self, action: #selector(didPressArtistButton(_:)), for: .touchUpInside)
         cell.artistButton.tag = indexPath.row
         
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
        
        cell.menuButton.isHidden = true
        return cell 
    }
    
    func playlistCell(_ indexPath: IndexPath) -> SoundListTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
         cell.backgroundColor = color.black()
         cell.selectionStyle = .none
                    
        if artistPlaylists.indices.contains(indexPath.row) {
            let playlist = artistPlaylists[indexPath.row]
             
            cell.artistImage.image = UIImage(named: "profile_icon")
            cell.artistLabel.text = "loading..."
            if let name = playlist.artist?.name {
                cell.artistLabel.text = name
                if let image = playlist.artist?.image {
                    cell.artistImage.kf.setImage(with: URL(string: image), placeholder: UIImage(named: "profile_icon"))
                 }
             } else if let artist = playlist.artist {
                artist.loadUserInfoFromCloud(nil, soundCell: cell, commentCell: nil, mentionCell: nil, artistUsernameLabel: nil, artistImageButton: nil)
             }
             
             cell.artistButton.addTarget(self, action: #selector(didPressArtistButton(_:)), for: .touchUpInside)
             cell.artistButton.tag = indexPath.row
             
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
            
            if let currentUserId = PFUser.current()?.objectId, let playlistArtistId = playlist.artist?.objectId, currentUserId == playlistArtistId {
                cell.menuButton.isHidden = false 
                cell.menuButton.addTarget(self, action: #selector(self.didPressMenuButton(_:)), for: .touchUpInside)
                cell.menuButton.tag = indexPath.row
            } else {
                cell.menuButton.isHidden = true
            }

        }
        return cell 
    }
    
    @objc func didPressArtistButton(_ sender: UIButton) {
        self.selectedArtist = self.artistPlaylists[sender.tag].artist
        self.performSegue(withIdentifier: "showProfile", sender: self)
    }
    
    @objc func didPressMenuButton(_ sender: UIButton) {
        let menuAlert = UIAlertController(title: "", message: nil, preferredStyle: .actionSheet)
        
        menuAlert.addAction(UIAlertAction(title: "Edit Playlist", style: .default, handler: { action in
            self.showNewEditPlaylistView(self.artistPlaylists[sender.tag])
        }))

        menuAlert.addAction(UIAlertAction(title: "Delete Playlist", style: .default, handler: { action in
            let playlist = self.artistPlaylists[sender.tag]
            self.showDeletePlaylistAlert(playlist, row: sender.tag)
        }))
        
        /*menuAlert.addAction(UIAlertAction(title: "Share Playlist", style: .default, handler: { action in
            self.uiElement.createDynamicLink(nil, artist: nil, playlist: self.artistPlaylists[sender.tag], target: self)
        }))*/
            
        let localizedCancel = NSLocalizedString("cancel", comment: "")
        menuAlert.addAction(UIAlertAction(title: localizedCancel, style: .cancel, handler: nil))
            
        self.present(menuAlert, animated: true, completion: nil)
    }
    
    func showDeletePlaylistAlert(_ playlist: Playlist, row: Int) {
        let menuAlert = UIAlertController(title: "Delete \(playlist.title ?? "this playlist")?", message: nil, preferredStyle: .alert)
        
        menuAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            self.deletePlaylist(playlist.objectId ?? "", row: row)
        }))
            
        menuAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            
        self.present(menuAlert, animated: true, completion: nil)
    }
    
    func loadPlaylists(profileUserId: String) {
        let query = PFQuery(className: "Playlist")
        query.whereKey("userId", equalTo: profileUserId)
        query.addDescendingOrder("createdAt")
        query.whereKey("isRemoved", equalTo: false)
        query.cachePolicy = .networkElseCache
        query.limit = 50
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            self.artistPlaylists.removeAll()
            if let objects = objects {
                for object in objects {
                    let playlist = Playlist(objectId: object.objectId, artist: nil, title: nil, image: nil, type: nil, count: nil)
                    playlist.artist = self.profileArtist
                    playlist.title = object["title"] as? String
                    playlist.image = object["image"] as? PFFileObject
                    playlist.type = object["type"] as? String
                    playlist.count = object["count"] as? Int
                    self.artistPlaylists.append(playlist)
                }
            }
            if self.tableView != nil {
                self.tableView.reloadData()
            } else {
                self.setUpTableView()
            }
        }
    }
    
    //mark: profileInfo
    func determineTypeOfProfile() {
        if let currentUser = PFUser.current() {
            self.currentUser = currentUser
        }
                
        if profileArtist != nil {
            self.loadProfileData()
            self.setUpNavigationButtons()
            
        } else if let userId = self.uiElement.getUserDefault("receivedUserId") as? String {
            loadUserInfoFromCloud(userId, username: nil)
            UserDefaults.standard.removeObject(forKey: "receivedUserId")
            self.setUpNavigationButtons()
            
        } else if let username = self.uiElement.getUserDefault("receivedUsername") as? String {
            loadUserInfoFromCloud(nil, username: username)
            UserDefaults.standard.removeObject(forKey: "receivedUsername")
            self.setUpNavigationButtons()
            
        }  else if let currentArtist = Customer.shared.artist {
            isFromNavigationStack = false
            self.profileArtist = currentArtist
            self.loadPlaylists(profileUserId: currentArtist.objectId)
            if self.tableView != nil {
                self.tableView.refreshControl?.endRefreshing()
            }
            self.setUpNavigationButtons()
        } else {
            let localizedRegisterForUpdates = NSLocalizedString("registerForUpdates", comment: "")
            self.uiElement.welcomeAlert(localizedRegisterForUpdates, target: self)
        }
    }
    func profileInfoReuse() -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: profileReuse) as! ProfileTableViewCell
        cell.selectionStyle = .none
        cell.backgroundColor = color.black()
        if let artist = self.profileArtist {
            if let artistImage = artist.image {
                cell.profileImage.kf.setImage(with: URL(string: artistImage))
            }
            
            if let name = artist.name {
                cell.displayNameLabel.text = name
            }
            
            if let city = artist.city {
                cell.city.text = city
            }
            
            if let bio = artist.bio {
                cell.bio.text = bio
            }
            
            if let website = artist.website, !website.isEmpty {
                cell.websiteView.addTarget(self, action: #selector(self.didPressWebsiteButton(_:)), for: .touchUpInside)
                cell.website.text = website
                cell.followUserEditProfileButton.snp.makeConstraints { (make) -> Void in
                    make.top.equalTo(cell.websiteView.snp.bottom).offset(uiElement.topOffset)
                    make.width.equalTo(115)
                    make.left.equalTo(cell).offset(uiElement.leftOffset)
                    make.bottom.equalTo(cell)
                }
            } else {
                cell.followUserEditProfileButton.snp.makeConstraints { (make) -> Void in
                    make.top.equalTo(cell.bio.snp.bottom).offset(uiElement.topOffset)
                    make.width.equalTo(115)
                    make.left.equalTo(cell).offset(uiElement.leftOffset)
                    make.bottom.equalTo(cell)
                }
            }
            
            cell.followUserEditProfileButton.addTarget(self, action: #selector(self.didPressFollowUserEditProfileButton(_:)), for: .touchUpInside)
            cell.joinFanClubButton.addTarget(self, action: #selector(self.didPressJoinFanClubNewPlaylistButton(_:)), for: .touchUpInside)
            
            if artist.account != nil, let profileArtistId = self.profileArtist?.objectId, let currentArtistId = Customer.shared.artist?.objectId, profileArtistId != currentArtistId  {
                cell.sendGiftButton.addTarget(self, action: #selector(didPressSendArtistMoneyButton(_:)), for: .touchUpInside)
            } else {
                cell.sendGiftButton.isHidden = true
            }
            
            let localizedFollow = NSLocalizedString("follow", comment: "")
            let localizedEditProfile = NSLocalizedString("editProfile", comment: "")
            let localizedFollowing = NSLocalizedString("following", comment: "")
            
            if let currentUserID = PFUser.current()?.objectId {
                if currentUserID == self.profileArtist!.objectId {
                    cell.followUserEditProfileButton.setTitle(localizedEditProfile, for: .normal)
                    cell.followUserEditProfileButton.backgroundColor = color.black()
                    cell.followUserEditProfileButton.setTitleColor(.white, for: .normal)
                    cell.followUserEditProfileButton.layer.borderColor = color.lightGray().cgColor
                    cell.followUserEditProfileButton.layer.borderWidth = 1
                    cell.followUserEditProfileButton.clipsToBounds = true
                    cell.followUserEditProfileButton.tag = 0
                    
                    cell.joinFanClubButton.setTitle("New Playlist", for: .normal)
                    cell.joinFanClubButton.backgroundColor = color.black()
                    cell.joinFanClubButton.setTitleColor(.white, for: .normal)
                    cell.joinFanClubButton.layer.borderColor = color.lightGray().cgColor
                    cell.joinFanClubButton.layer.borderWidth = 1
                    cell.joinFanClubButton.clipsToBounds = true
                    
                } else {
                    if let isFollowedByCurrentUser = self.profileArtist!.isFollowedByCurrentUser {
                        if isFollowedByCurrentUser {
                            cell.followUserEditProfileButton.setTitle(localizedFollowing, for: .normal)
                            cell.followUserEditProfileButton.backgroundColor = .darkGray
                            cell.followUserEditProfileButton.setTitleColor(.white, for: .normal)
                            cell.followUserEditProfileButton.tag = 1
                        } else {
                            cell.followUserEditProfileButton.setTitle(localizedFollow, for: .normal)
                            cell.followUserEditProfileButton.backgroundColor = color.blue()
                            cell.followUserEditProfileButton.setTitleColor(.white, for: .normal)
                            cell.followUserEditProfileButton.tag = 2
                        }
                    }
                    
                    if let productId = self.profileArtist?.account?.productId {
                        if Customer.shared.fanClubs.contains(productId) {
                            cell.joinFanClubButton.setTitle("💎", for: .normal)
                            cell.joinFanClubButton.backgroundColor = .darkGray
                        } else {
                            cell.joinFanClubButton.setTitle("Join Fan Club", for: .normal)
                            cell.joinFanClubButton.backgroundColor = color.blue()
                            cell.joinFanClubButton.setTitleColor(.white, for: .normal)
                        }
                    } else {
                        cell.joinFanClubButton.isHidden = true 
                    }
                }
            } else {
                cell.followUserEditProfileButton.setTitle(localizedFollow, for: .normal)
                cell.followUserEditProfileButton.backgroundColor = color.blue()
                cell.followUserEditProfileButton.setTitleColor(.white, for: .normal)
                cell.followUserEditProfileButton.tag = 3
            }
        }
        
        return cell
    }
    
    //mark: button actions
    @objc func didPressSendArtistMoneyButton(_ sender: UIButton) {
        let modal = SendMoneyViewController()
        modal.artist = self.profileArtist
        self.present(modal, animated: true, completion: nil)
    }
    
    @objc func didPressJoinFanClubNewPlaylistButton(_ sender: UIButton) {
        if self.profileArtist?.objectId == PFUser.current()?.objectId {
            let modal = NewPlaylistViewController()
            modal.playlistDelegate = self
            let playlist = Playlist(objectId: nil, artist: nil, title: nil, image: nil, type: "playlist", count: 0)
            modal.playlist = playlist
            self.present(modal, animated: true, completion: nil)
            
        } else {
            if let productId = self.profileArtist?.account?.productId, Customer.shared.fanClubs.contains(productId) {
                self.uiElement.showAlert("You're a Fan Club Member!", message: "You can manage your membership at soundbrew.app/fans", target: self)
            } else {
                self.uiElement.showAlert("Join \(self.profileArtist?.username ?? "this artist")'s Fan Club!", message: "Get access to exclusive sounds from \(self.profileArtist?.username ?? "this artist").\n You can join their fan club from their Soundbrew website profile.", target: self)
            }
        }
    }
    
    @objc func didPressFollowUserEditProfileButton(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            let modal = EditProfileViewController()
            modal.artistDelegate = self
            self.present(modal, animated: true, completion: nil)
            break
            
        case 1:
            if let currentUser = Customer.shared.artist {
                let unFollow = Follow(fromArtist: currentUser, toArtist: self.profileArtist!)
                unFollow.updateFollowStatus(false)
                self.profileArtist!.isFollowedByCurrentUser = false
                self.tableView.reloadData()
            }
            break
            
        case 2:
            if let currentUser = Customer.shared.artist {
                let unFollow = Follow(fromArtist: currentUser, toArtist: self.profileArtist!)
                unFollow.updateFollowStatus(true)
                self.profileArtist!.isFollowedByCurrentUser = true
                self.tableView.reloadData()
            }
            break
            
        default:
            let localizedSignupRequired = NSLocalizedString("signupRequired", comment: "")
            let localizedSignupRequiredMessage = NSLocalizedString("signupRequiredMessage", comment: "")
            self.uiElement.showAlert(localizedSignupRequired, message: localizedSignupRequiredMessage, target: self)
            break
        }
    }
    
    func setUpNavigationButtons() {        
        if let currentArtist = self.profileArtist, currentArtist.objectId == Customer.shared.artist?.objectId, self.so_containerViewController != nil {
            let menuButton = UIBarButtonItem(image: UIImage(named: "menu"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.didPressSettingsButton(_:)))
            self.navigationItem.rightBarButtonItem = menuButton
    
            if let username = currentArtist.username {
                if isFromNavigationStack {
                    if let username = self.profileArtist?.username {
                        if !username.contains("@") {
                            self.navigationItem.title = username
                        }
                    }
                    
                } else {
                    if !username.contains("@") {
                        self.uiElement.addTitleView(username, target: self)
                    } else {
                        self.uiElement.addTitleView("Your Profile", target: self)
                    }
                }
            }
            
        } else {
            let shareButton = UIBarButtonItem(image: UIImage(named: "share_small"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.didPressShareProfileButton(_:)))
            self.navigationItem.rightBarButtonItem = shareButton
            
            if let username = self.profileArtist?.username {
                if !username.contains("@") {
                    self.navigationItem.title = username
                }
            }
        }
    }
    
    @objc func didPressWebsiteButton(_ sender: UIButton) {
        if let website = self.profileArtist?.website {
            if let websiteURL = URL(string: website) {
                if UIApplication.shared.canOpenURL(websiteURL) {
                    UIApplication.shared.open(websiteURL, options: [:], completionHandler: nil)
                }
            }
        }
    }
    
    @objc func didPressShareProfileButton(_ sender: UIBarButtonItem) {
        if let artist = profileArtist {
            self.uiElement.createDynamicLink(nil, artist: artist, playlist: nil, target: self)
        }
    }
    
    @objc func didPressSettingsButton(_ sender: UIBarButtonItem) {
        if let container = self.so_containerViewController {
            let sideView = container.sideViewController as! SettingsViewController
            sideView.artist = Customer.shared.artist
            sideView.loadFollowerFollowingStats()
            sideView.tableView.reloadData()
            container.isSideViewControllerPresented = true
        }
    }
    
    //Mark: Data
    func loadArtistName(_ userId: String, label: UILabel) {
        let query = PFQuery(className: "_User")
        query.cachePolicy = .networkElseCache
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let user = user {
                if let username = user["username"] as? String {
                    label.text = username
                }
            }
        }
    }
    
    func loadUserInfoFromCloud(_ userId: String?, username: String?) {
        let query = PFQuery(className: "_User")
        if let userId = userId {
            query.whereKey("objectId", equalTo: userId)
        } else if let username = username {
            query.whereKey("username", equalTo: username)
        }
        query.cachePolicy = .networkElseCache
          query.getFirstObjectInBackground {
              (user: PFObject?, error: Error?) -> Void in
                if let user = user {
                    self.profileArtist = self.uiElement.newArtistObject(user)
                    self.loadProfileData()
                }
          }
    }
    
    func checkFollowStatus() {
        if let currentUserID = PFUser.current()?.objectId {
            let query = PFQuery(className: "Follow")
            query.whereKey("fromUserId", equalTo: currentUserID)
            query.whereKey("toUserId", equalTo: profileArtist!.objectId!)
            query.whereKey("isRemoved", equalTo: false)
            query.cachePolicy = .networkElseCache
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if object != nil {
                    self.profileArtist?.isFollowedByCurrentUser = true
                } else {
                    self.profileArtist?.isFollowedByCurrentUser = false
                }
                if self.tableView == nil {
                    self.setUpTableView()
                } else {
                   self.tableView.reloadData()
                }
            }
        }
    }
    
    //mark: tags
    var selectedTagFromPlayerView: Tag?
    func receivedTags(_ chosenTags: Array<Tag>?) {
        if let tags = chosenTags {
            let tag = tags[0]
            self.selectedTagFromPlayerView = tag
            self.performSegue(withIdentifier: "showSounds", sender: self)
        }
    }
    
    //mark: account
    func showNewAccount(_ country: String) {
        let account = Account(nil, productId: nil)
        account.country = country
        account.currency = "usd"
        let modal = NewAccountViewController()
        modal.newAccount = account
        self.present(modal, animated: true, completion: nil)
    }
    func receivedAccount(_ account: Account?) {
    }
}

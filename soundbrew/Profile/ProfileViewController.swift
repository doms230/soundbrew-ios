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
import TwitterKit
import AppCenterAnalytics

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ArtistDelegate, PlayerDelegate, TagDelegate, PlaylistDelegate {
    
    let uiElement = UIElement()
    let color = Color()
    
    var profileArtist: Artist?
    
    var soundList: SoundList!
    var soundType = "uploads"
    var isFromNavigationStack = true
    var currentUser: PFUser?
    let player = Player.sharedInstance
    var followerOrFollowing: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        determineTypeOfProfile()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setMiniPlayer()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
            case "showEditProfile":
                let localizedEditProfile = NSLocalizedString("editProfile", comment: "")
                let backItem = UIBarButtonItem()
                backItem.title = localizedEditProfile
                navigationItem.backBarButtonItem = backItem
                
                let editProfileController = segue.destination as! EditProfileViewController
                editProfileController.artistDelegate = self
                break
                
            case "showEditSoundInfo":
                soundList.prepareToShowSoundInfo(segue)
                break
                
            case "showProfile":
                let backItem = UIBarButtonItem()
                backItem.title = ""
                navigationItem.backBarButtonItem = backItem
                
                let viewController = segue.destination as! ProfileViewController
                viewController.profileArtist = selectedArtist
                break
                
            case "showAddFunds":
                let localizedAddFunds = NSLocalizedString("", comment: "")
                let backItem = UIBarButtonItem()
                backItem.title = localizedAddFunds
                navigationItem.backBarButtonItem = backItem
                break
                
            case "showSounds":
                let backItem = UIBarButtonItem()
                backItem.title = showSoundsTitle
                navigationItem.backBarButtonItem = backItem
                
                let viewController = segue.destination as! SoundsViewController
                viewController.soundType = selectedSoundType
                viewController.userId = profileArtist?.objectId
                break
                
            case "showFollowerFollowing":
                let backItem = UIBarButtonItem()
                backItem.title = followerOrFollowing.capitalized
                navigationItem.backBarButtonItem = backItem
                
                let viewController = segue.destination as! PeopleViewController
                viewController.loadType = followerOrFollowing
                break
                
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
            
            self.loadCollection(profileArtist.objectId)
            self.loadCredits(profileArtist.objectId)
            self.loadSounds(nil, creditIds: nil, userId: profileArtist.objectId)
            if self.tableView != nil {
                self.tableView.refreshControl?.endRefreshing()
            }
        }
    }
    
    //MARK: Tableview
    var tableView: UITableView!
    let soundReuse = "soundReuse"
    let profileReuse = "profileReuse"
    let profileSoundReuse = "profileSoundReuse"
    
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: profileReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.register(TagTableViewCell.self, forCellReuseIdentifier: profileSoundReuse)
        tableView.separatorStyle = .none
        tableView.backgroundColor = color.black()
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl
        self.view.addSubview(tableView)
        self.tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-175)
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return profileInfoReuse()
        } else {
            return soundsReuse(indexPath)
        }
    }
    
    //mark: miniPlayer
    func setMiniPlayer() {
        let miniPlayerView = MiniPlayerView.sharedInstance
        miniPlayerView.superViewController = self
        miniPlayerView.tagDelegate = self
        miniPlayerView.playerDelegate = self
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
    func receivedPlaylist(_ chosenPlaylist: Playlist?) {
        if let newPlaylist = chosenPlaylist {
            print(newPlaylist.objectId)
        }
    }
    
    //mark: sounds
    var artistReleases = [Sound]()
    var artistCollection = [Sound]()
    var artistCredits = [Sound]()
    var collectionSoundIds = [String]()
    var creditSoundIds = [String]()
    var didloadReleases = false
    var didLoadCollection = false
    var didLoadCredits = false
    var showSoundsTitle: String!
    var selectedSoundType: String!
    
    func soundsReuse(_ indexPath: IndexPath) -> TagTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: profileSoundReuse) as! TagTableViewCell
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        
        if cell.tagsScrollview.subviews.count > 0 {
            for subview in cell.tagsScrollview.subviews{
                subview.removeFromSuperview()
            }
        }
        
        cell.tagTypeButton.addTarget(self, action: #selector(self.didPressViewAllSoundsButton(_:)), for: .touchUpInside)
        switch indexPath.section {
        case 1:
            let localizedNoReleasesYet = NSLocalizedString("noReleasesYet", comment: "")

            cell.TagTypeTitle.text = "Releases"
            if artistReleases.count == 0 && didloadReleases {
                cell.viewAllLabel.isHidden = true
                addNoSounds(cell.tagsScrollview, title: localizedNoReleasesYet)
            } else {
                cell.tagTypeButton.tag = 0
                cell.viewAllLabel.isHidden = false
                addSounds(cell.tagsScrollview, sounds: artistReleases, row: 0)
            }
            break
            
        case 2:
            cell.TagTypeTitle.text = "Likes"
            if artistCollection.count == 0 && didLoadCollection  {
                cell.viewAllLabel.isHidden = true
                addNoSounds(cell.tagsScrollview, title: "No Likes yet.")
            } else {
                cell.tagTypeButton.tag = 1
                cell.viewAllLabel.isHidden = false
                addSounds(cell.tagsScrollview, sounds: artistCollection, row: 1)
            }
            break
            
        case 3:
            cell.TagTypeTitle.text = "Credits"
            if artistCredits.count == 0 && didLoadCredits  {
                cell.viewAllLabel.isHidden = true
                addNoSounds(cell.tagsScrollview, title: "No credits yet.")
            } else {
                cell.tagTypeButton.tag = 2
                cell.viewAllLabel.isHidden = false
                addSounds(cell.tagsScrollview, sounds: artistCredits, row: 2)
            }
            break
            
        default:
            break
        }
        
        return cell 
    }
    
    @objc func didPressViewAllSoundsButton(_ sender: UIButton) {
        var shouldSegueToSounds = true
        if let artist = self.profileArtist {
            switch sender.tag {
            case 0:
                showSoundsTitle = "\(artist.username!)'s Releases"
                selectedSoundType = "uploads"
                if self.artistReleases.count == 0 {
                    shouldSegueToSounds = false
                }
                break
                
            case 1:
                showSoundsTitle = "\(artist.username!)'s Likes"
                selectedSoundType = "collection"
                if self.artistCollection.count == 0 {
                    shouldSegueToSounds = false
                }
                break
                
            case 2:
                showSoundsTitle = "\(artist.username!)'s Credits"
                selectedSoundType = "credit"
                if self.artistCredits.count == 0 {
                    shouldSegueToSounds = false
                }
                break
                
            default:
                break
            }
        }
        
        if shouldSegueToSounds {
            self.performSegue(withIdentifier: "showSounds", sender: self)
        }
    }
    
    func addNoSounds(_ scrollview: UIScrollView, title: String) {
        let titleLabel = UILabel()
        titleLabel.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 17)
        titleLabel.text = title
        titleLabel.textColor = .white
        scrollview.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(scrollview)
            make.left.equalTo(scrollview).offset(uiElement.leftOffset)
            make.right.equalTo(scrollview).offset(uiElement.rightOffset)
        }        
    }
    
    func addSounds(_ scrollview: UIScrollView, sounds: Array<Sound>, row: Int) {
        //not using snpakit to set button frame becuase not able to get button width from button title.
        let buttonHeight = 150
        let buttonWidth = 150
        var xPositionForFeatureTags = UIElement().leftOffset
        
        //for sound in sounds {
        for i in 0..<sounds.count {
            let sound = sounds[i]
            
            let soundArt = UIImageView()
            soundArt.kf.setImage(with: URL(string: sound.artFile?.url  ?? ""), placeholder: UIImage(named: "sound"))
            soundArt.contentMode = .scaleAspectFill
            soundArt.layer.cornerRadius = 5
            soundArt.layer.borderWidth = 1
            soundArt.layer.borderColor = color.purpleBlack().cgColor
            soundArt.clipsToBounds = true
            scrollview.addSubview(soundArt)
            soundArt.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(buttonHeight)
                make.top.equalTo(scrollview)
                make.left.equalTo(scrollview).offset(xPositionForFeatureTags)
            }
            
            let titleLabel = UILabel()
            titleLabel.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 17)
            titleLabel.text = sound.title
            titleLabel.textAlignment = .center
            titleLabel.textColor = .white
            scrollview.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(soundArt.snp.bottom)
                make.left.equalTo(soundArt)
                make.right.equalTo(soundArt)
            }
            
            let artistLabel = UILabel()
            artistLabel.font = UIFont(name: "\(uiElement.mainFont)", size: 15)
            self.loadArtistName(sound.artist!.objectId, label: artistLabel)
            artistLabel.textColor = .white
            artistLabel.textAlignment = .center
            scrollview.addSubview(artistLabel)
            artistLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(titleLabel.snp.bottom)
                make.left.equalTo(soundArt)
                make.right.equalTo(soundArt)
            }
            
            let dateLabel = UILabel()
            dateLabel.font = UIFont(name: "\(uiElement.mainFont)", size: 15)
            let formattedDate = self.uiElement.formatDateAndReturnString(sound.createdAt!)
            dateLabel.text = formattedDate
            dateLabel.textColor = .lightGray
            dateLabel.textAlignment = .center
            scrollview.addSubview(dateLabel)
            dateLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistLabel.snp.bottom)
                make.left.equalTo(soundArt)
                make.right.equalTo(soundArt)
            }
            
            let soundViewButton = UIButton()
            if row == 0 {
                //releases
                soundViewButton.addTarget(self, action: #selector(self.didPressArtistReleases(_:)), for: .touchUpInside)
            } else {
                //collection
                soundViewButton.addTarget(self, action: #selector(self.didPressArtistCollection(_:)), for: .touchUpInside)
            }
            soundViewButton.tag = i
            scrollview.addSubview(soundViewButton)
            soundViewButton.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(scrollview)
                make.left.equalTo(soundArt)
                make.right.equalTo(soundArt)
                make.bottom.equalTo(dateLabel.snp.bottom)
            }
            
            xPositionForFeatureTags = xPositionForFeatureTags + buttonWidth + uiElement.leftOffset
            scrollview.contentSize = CGSize(width: xPositionForFeatureTags, height: buttonHeight)
        }
    }
    
    @objc func didPressArtistReleases(_ sender: UIButton) {
        didSelectSound(artistReleases, row: sender.tag)
    }
    
    @objc func didPressArtistCollection(_ sender: UIButton) {
        didSelectSound(artistCollection, row: sender.tag)
    }
    
    func didSelectSound(_ sounds: Array<Sound>, row: Int) {
        self.player.sounds = sounds
        player.didSelectSoundAt(row)
    }
    
    func loadCollection(_ profileUserId: String) {
        let query = PFQuery(className: "Tip")
        query.whereKey("fromUserId", equalTo: profileUserId)
        query.addDescendingOrder("createdAt")
        query.limit = 5
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                for object in objects {
                    self.collectionSoundIds.append(object["soundId"] as! String)
                }
            }
            
            self.loadSounds(self.collectionSoundIds, creditIds: nil, userId: nil)
        }
    }
    
    func loadCredits(_ profileUserId: String) {
        let query = PFQuery(className: "Credit")
        query.whereKey("userId", equalTo: profileUserId)
        query.addDescendingOrder("createdAt")
        query.limit = 5
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                for object in objects {
                    self.creditSoundIds.append(object["postId"] as! String)
                }
            }
            
            self.loadSounds(nil, creditIds: self.creditSoundIds, userId: nil)
        }
    }
    
    func loadSounds(_ collectionIds: Array<String>?, creditIds: Array<String>?, userId: String?) {
        let query = PFQuery(className: "Post")
        if let collectionIds = collectionIds {
            query.whereKey("objectId", containedIn: collectionIds)
        } else if let creditIds = creditIds {
            query.whereKey("objectId", containedIn: creditIds)
        }
        if let userId = userId {
            query.whereKey("userId", equalTo: userId)
        }
        query.limit = 5
        query.whereKey("isRemoved", notEqualTo: true)
        query.whereKey("isDraft", notEqualTo: true)
        query.addDescendingOrder("createdAt")
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                var sounds = [Sound]()
                for object in objects {
                    let sound = self.uiElement.newSoundObject(object)
                    sounds.append(sound)
                }
                
                if collectionIds != nil {
                    self.artistCollection = sounds
                    self.didLoadCollection = true
                } else if creditIds != nil {
                    self.artistCredits = sounds
                    self.didLoadCredits = true
                } else {
                    self.artistReleases = sounds
                    self.didloadReleases = true
                }
                
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
            self.loadCollection(currentArtist.objectId)
            self.loadCredits(currentArtist.objectId)
            self.loadSounds(nil, creditIds: nil, userId: currentArtist.objectId)
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
            
            if let website = artist.website {
                cell.website.text = website 
                cell.websiteView.addTarget(self, action: #selector(didPressWebsiteButton(_:)), for: .touchUpInside)
            }
            
            cell.followUserEditProfileButton.addTarget(self, action: #selector(self.didPressFollowUserEditProfileButton(_:)), for: .touchUpInside)
            
            cell.subscribeUserCreatePlaylistButton.addTarget(self, action: #selector(self.didPressSubscribeUserCreatePlaylistButton(_:)), for: .touchUpInside)
            
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
                    
                    cell.subscribeUserCreatePlaylistButton.setTitle("Create Playlist", for: .normal)
                    cell.subscribeUserCreatePlaylistButton.backgroundColor = color.black()
                    cell.subscribeUserCreatePlaylistButton.setTitleColor(.white, for: .normal)
                    cell.subscribeUserCreatePlaylistButton.layer.borderColor = color.lightGray().cgColor
                    cell.subscribeUserCreatePlaylistButton.layer.borderWidth = 1
                    cell.subscribeUserCreatePlaylistButton.clipsToBounds = true
                    cell.subscribeUserCreatePlaylistButton.tag = 0
                    
                } else {
                    if let isFollowedByCurrentUser = self.profileArtist!.isFollowedByCurrentUser {
                        if isFollowedByCurrentUser {
                            cell.followUserEditProfileButton.setTitle(localizedFollowing, for: .normal)
                            cell.followUserEditProfileButton.backgroundColor = color.lightGray()
                            cell.followUserEditProfileButton.setTitleColor(color.black(), for: .normal)
                            cell.followUserEditProfileButton.tag = 1
                        } else {
                            cell.followUserEditProfileButton.setTitle(localizedFollow, for: .normal)
                            cell.followUserEditProfileButton.backgroundColor = color.blue()
                            cell.followUserEditProfileButton.setTitleColor(.white, for: .normal)
                            cell.followUserEditProfileButton.tag = 2
                        }
                    }
                    
                    //TODO: show subscribe option
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
    @objc func didPressSubscribeUserCreatePlaylistButton(_ sender: UIButton) {
        if sender.tag == 0 {
            let modal = EditBioViewController()
            modal.playlistDelegate = self
            modal.totalAllowedTextLength = 50
            self.present(modal, animated: true, completion: nil)
        } else {
            //TODO: show info about subscribing to user
        }
    }
    
    @objc func didPressFollowUserEditProfileButton(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            self.performSegue(withIdentifier: "showEditProfile", sender: self)
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
            self.uiElement.createDynamicLink("profile", sound: nil, artist: artist, target: self)
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
    var selectedTagFromPlayerView: Tag!
    func receivedTags(_ chosenTags: Array<Tag>?) {
        if let tags = chosenTags {
            self.selectedTagFromPlayerView = tags[0]
            self.selectedSoundType = "discover"
            self.showSoundsTitle = tags[0].name
            self.performSegue(withIdentifier: "showSounds", sender: self)
        }
    }
}

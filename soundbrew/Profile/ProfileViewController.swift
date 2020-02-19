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

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ArtistDelegate, PlayerDelegate, TagDelegate {
    
    let uiElement = UIElement()
    let color = Color()
    
    var profileArtist: Artist?
    
    var soundList: SoundList!
    var isCurrentUserProfile = false
    var soundType = "uploads"
    var profileSounds = [Sound]()
    var selectedIndex = 0
    var currentUser: PFUser?
    var player: Player?
    var followerOrFollowing: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
            isCurrentUserProfile = true
            self.profileArtist = currentArtist
            self.loadProfileData()
            self.setUpNavigationButtons()
        } else {
            let localizedRegisterForUpdates = NSLocalizedString("registerForUpdates", comment: "")
            self.uiElement.welcomeAlert(localizedRegisterForUpdates, target: self)
        }
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
        if let username = profileArtist?.username {
            if !username.contains("@") {
                self.navigationItem.title = username
            }
        }
        
        if currentUser != nil && currentUser?.objectId != profileArtist?.objectId {
            checkFollowStatus()
        }
        
        self.loadCollection(self.profileArtist!.objectId)
        self.loadCredits(self.profileArtist!.objectId)
        self.loadSounds(nil, creditIds: nil, userId: self.profileArtist?.objectId)
        self.tableView.refreshControl?.endRefreshing()
    }
    
    //MARK: Tableview
    let tableView = UITableView()
    let soundReuse = "soundReuse"
    let profileReuse = "profileReuse"
    let profileSoundReuse = "profileSoundReuse"
    
    func setUpTableView(_ miniPlayer: UIView?) {
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
    var miniPlayerView: MiniPlayerView?
    func setUpMiniPlayer() {
        let miniPlayerView = MiniPlayerView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        self.view.addSubview(miniPlayerView)
        let slide = UISwipeGestureRecognizer(target: self, action: #selector(self.miniPlayerWasSwiped))
        slide.direction = .up
        miniPlayerView.addGestureRecognizer(slide)
        miniPlayerView.addTarget(self, action: #selector(self.miniPlayerWasPressed(_:)), for: .touchUpInside)
        miniPlayerView.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-((self.tabBarController?.tabBar.frame.height)!))
        }
        
        setUpTableView(miniPlayerView)
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
    let localizedCollection = NSLocalizedString("collection", comment: "")
    
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
        if let artist = self.profileArtist {
            switch sender.tag {
            case 0:
                showSoundsTitle = "\(artist.username!)'s Releases"
                selectedSoundType = "uploads"
                break
                
            case 1:
                showSoundsTitle = "\(artist.username!)'s \(localizedCollection)"
                selectedSoundType = "collection"
                break
                
            case 2:
                showSoundsTitle = "\(artist.username!)'s Credits"
                selectedSoundType = "credit"
                break
                
            default:
                break
            }
        }
        self.performSegue(withIdentifier: "showSounds", sender: self)
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
            soundArt.kf.setImage(with: URL(string: sound.artURL ?? ""), placeholder: UIImage(named: "sound"))
            soundArt.contentMode = .scaleAspectFill
            soundArt.layer.cornerRadius = 5
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
        if let player = self.player {
            self.player?.sounds = sounds
            player.didSelectSoundAt(row)
            if self.miniPlayerView == nil && self.tabBarController != nil {
                self.setUpMiniPlayer()
            }
        }
    }
    
    func loadCollection(_ profileUserId: String) {
        let query = PFQuery(className: "Tip")
        query.whereKey("fromUserId", equalTo: profileUserId)
        query.addDescendingOrder("createdAt")
        query.limit = 5
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        self.collectionSoundIds.append(object["soundId"] as! String)
                    }
                }
                
                self.loadSounds(self.collectionSoundIds, creditIds: nil, userId: nil)
            }
        }
    }
    
    func loadCredits(_ profileUserId: String) {
        let query = PFQuery(className: "Credit")
        query.whereKey("userId", equalTo: profileUserId)
        query.addDescendingOrder("createdAt")
        query.limit = 5
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        self.creditSoundIds.append(object["postId"] as! String)
                    }
                }
                
                self.loadSounds(nil, creditIds: self.creditSoundIds, userId: nil)
            }
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
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
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
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    //mark: profileInfo
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
            
            cell.actionButton.addTarget(self, action: #selector(self.didPressActionButton(_:)), for: .touchUpInside)
            
            let localizedFollow = NSLocalizedString("follow", comment: "")
            let localizedEditProfile = NSLocalizedString("editProfile", comment: "")
            let localizedFollowing = NSLocalizedString("following", comment: "")
            
            if let currentUserID = PFUser.current()?.objectId {
                if currentUserID == self.profileArtist!.objectId {
                    cell.actionButton.setTitle(localizedEditProfile, for: .normal)
                    cell.actionButton.backgroundColor = color.black()
                    cell.actionButton.setTitleColor(.white, for: .normal)
                    cell.actionButton.layer.borderColor = color.lightGray().cgColor
                    cell.actionButton.layer.borderWidth = 1
                    cell.actionButton.clipsToBounds = true
                    cell.actionButton.tag = 0
                } else if let isFollowedByCurrentUser = self.profileArtist!.isFollowedByCurrentUser {
                    if isFollowedByCurrentUser {
                        cell.actionButton.setTitle(localizedFollowing, for: .normal)
                        cell.actionButton.backgroundColor = color.lightGray()
                        cell.actionButton.setTitleColor(color.black(), for: .normal)
                        cell.actionButton.tag = 1
                    } else {
                        cell.actionButton.setTitle(localizedFollow, for: .normal)
                        cell.actionButton.backgroundColor = color.blue()
                        cell.actionButton.setTitleColor(.white, for: .normal)
                        cell.actionButton.tag = 2
                    }
                }
            } else {
                cell.actionButton.setTitle(localizedFollow, for: .normal)
                cell.actionButton.backgroundColor = color.blue()
                cell.actionButton.setTitleColor(.white, for: .normal)
                cell.actionButton.tag = 3
            }
        }
        
        return cell
    }
    
    //mark: button actions
    @objc func didPressActionButton(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            self.performSegue(withIdentifier: "showEditProfile", sender: self)
            break
            
        case 1:
            updateFollowStatus(false)
            break
            
        case 2:
            updateFollowStatus(true)
            break
            
        default:
            let localizedSignupRequired = NSLocalizedString("signupRequired", comment: "")
            let localizedSignupRequiredMessage = NSLocalizedString("signupRequiredMessage", comment: "")
            self.uiElement.showAlert(localizedSignupRequired, message: localizedSignupRequiredMessage, target: self)
            break
        }
    }
    
    func setUpNavigationButtons() {
        player = Player.sharedInstance
        player?.target = self
        player?.tableView = tableView
        if self.player?.player != nil && self.tabBarController != nil {
            setUpMiniPlayer()
            
        } else {
            setUpTableView(nil)
        }
        
        if isCurrentUserProfile && self.currentUser != nil {
            let menuButton = UIBarButtonItem(image: UIImage(named: "menu"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.didPressSettingsButton(_:)))
            self.navigationItem.rightBarButtonItem = menuButton
            
        } else {
            let shareButton = UIBarButtonItem(image: UIImage(named: "share_small"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.didPressShareProfileButton(_:)))
            self.navigationItem.rightBarButtonItem = shareButton
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
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
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
          query.getFirstObjectInBackground {
              (user: PFObject?, error: Error?) -> Void in
                if let user = user {
                    self.profileArtist = self.uiElement.newArtistObject(user)
                    self.loadProfileData()
                }
          }
    }
    
    func newFollowRow() {
        self.profileArtist!.isFollowedByCurrentUser = true
        self.tableView.reloadData()
        if let currentUser = PFUser.current(){
            let newFollow = PFObject(className: "Follow")
            newFollow["fromUserId"] = currentUser.objectId
            newFollow["toUserId"] = profileArtist!.objectId
            newFollow["isRemoved"] = false
            newFollow.saveEventually {
                (success: Bool, error: Error?) in
                if success && error == nil {
                    self.updateFollowerCount(artist: self.profileArtist!, incrementFollows: true)
                    self.newMention(currentUser.objectId!)
                } else {
                    self.profileArtist!.isFollowedByCurrentUser = false
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func newMention(_ toUserId: String) {
        let newMention = PFObject(className: "Mention")
        newMention["type"] = "follow"
        newMention["fromUserId"] = PFUser.current()!.objectId!
        newMention["toUserId"] = toUserId
        newMention.saveEventually {
            (success: Bool, error: Error?) in
            if success && error == nil {
                //TODO: notification self.uiElement.sendAlert("\(currentUser.username!) followed you!", toUserId: self.profileArtist!.objectId)
            }
        }
    }
    
    func checkFollowStatus() {
        if let currentUserID = PFUser.current()?.objectId {
            let query = PFQuery(className: "Follow")
            query.whereKey("fromUserId", equalTo: currentUserID)
            query.whereKey("toUserId", equalTo: profileArtist!.objectId!)
            query.whereKey("isRemoved", equalTo: false)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if object != nil && error == nil {
                    self.profileArtist?.isFollowedByCurrentUser = true
                } else {
                    self.profileArtist?.isFollowedByCurrentUser = false
                }
                self.tableView.reloadData()
            }
        }
    }
    
    func updateLocalFriendsList(_ shouldAddArtist: Bool, userId: String) {
        var friendsList = [String]()
        if let friends = self.uiElement.getUserDefault("friends") as? [String] {
            friendsList = friends
        }
        
        if shouldAddArtist {
            friendsList.append(userId)
            self.uiElement.setUserDefault(friendsList, key: "friends")
        } else {
            for i in 0..<friendsList.count {
                let friend = friendsList[i]
                if friend == userId {
                    friendsList.remove(at: i)
                    self.uiElement.setUserDefault(friendsList, key: "friends")
                    break
                }
            }
        }
    }
    
    func updateFollowStatus(_ shouldFollowArtist: Bool) {
        if shouldFollowArtist {
            self.profileArtist!.isFollowedByCurrentUser = true
        } else {
            self.profileArtist!.isFollowedByCurrentUser = false
        }
        self.tableView.reloadData()
        
        if let currentUserID = PFUser.current()?.objectId {
            let query = PFQuery(className: "Follow")
            query.whereKey("fromUserId", equalTo: currentUserID)
            query.whereKey("toUserId", equalTo: profileArtist!.objectId!)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if error != nil {
                    if shouldFollowArtist {
                        self.newFollowRow()
                    }
                    
                } else if let object = object {
                    var shouldRemove = true
                    if shouldFollowArtist {
                        shouldRemove = false
                    }
                    object["isRemoved"] = shouldRemove
                    object.saveEventually {
                        (success: Bool, error: Error?) in
                        if success && error == nil {
                            self.updateFollowerCount(artist: self.profileArtist!, incrementFollows: shouldFollowArtist)
                            if shouldFollowArtist {
                                self.newMention(self.profileArtist!.objectId!)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func updateFollowerCount(artist: Artist, incrementFollows: Bool) {
        self.updateLocalFriendsList(incrementFollows, userId: artist.objectId!)
        
        let query = PFQuery(className: "Stats")
        query.whereKey("userId", equalTo: artist.objectId!)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if error != nil {
                self.newStatsRow(1, following: 0, userId: artist.objectId)
            } else if let object = object {
                if incrementFollows {
                    object.incrementKey("followers")
                } else {
                    object.incrementKey("followers", byAmount: -1)
                }
                
                object.saveEventually()
            }
        }
        
        if let currentUserID = PFUser.current()?.objectId {
            let query = PFQuery(className: "Stats")
            query.whereKey("userId", equalTo: currentUserID)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if error != nil {
                    self.newStatsRow(0, following: 1, userId: currentUserID)
                    
                } else if let object = object {
                    if incrementFollows {
                        object.incrementKey("following")
                    } else {
                        object.incrementKey("following", byAmount: -1)
                    }
                    
                    object.saveEventually()
                }
            }
        }
    }
    
    func newStatsRow(_ followers: Int, following: Int, userId: String) {
        let newFollow = PFObject(className: "Stats")
        newFollow["followers"] = followers
        newFollow["following"] = following
        newFollow["userId"] = userId
        newFollow.saveEventually()
    }
    
    //mark: tags
    var selectedTagFromPlayerView: Tag!
    func receivedTags(_ chosenTags: Array<Tag>?) {
        if let tags = chosenTags {
            self.selectedTagFromPlayerView = tags[0]
            self.selectedSoundType = "discover"
            self.performSegue(withIdentifier: "showSounds", sender: self)
        }
    }
}

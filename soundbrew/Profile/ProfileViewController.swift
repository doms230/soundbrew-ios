//
//  ProfileViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/11/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//
// mark: button actions, data, tableview, social buttons

import UIKit
import Parse
import Kingfisher
import SnapKit
import DeckTransition
import SidebarOverlay
import TwitterKit

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ArtistDelegate, PlayerDelegate {
    
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
    var paymentType: String!
    var followerOrFollowing: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let currentUser = PFUser.current(){
            self.currentUser = currentUser
        }
        
        if profileArtist != nil {
            self.executeTableViewSoundListFollowStatus()
            self.setUpNavigationButtons()
            
        } else if let userId = self.uiElement.getUserDefault("receivedUserId") as? String {
            loadUserInfoFromCloud(userId)
            UserDefaults.standard.removeObject(forKey: "receivedUserId")
            self.setUpNavigationButtons()
    
        } else if let currentArtist = Customer.shared.artist {
            isCurrentUserProfile = true
            self.profileArtist = currentArtist
            self.executeTableViewSoundListFollowStatus()
            self.setUpNavigationButtons()
            
        } else {
            self.title = "Your Profile"
            showWelcome()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let player = Player.sharedInstance
        if player.player != nil {
            setUpMiniPlayer()
        } else if PFUser.current() != nil {
            setUpTableView(nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showEditProfile":
            let backItem = UIBarButtonItem()
            backItem.title = "Edit Profile"
            navigationItem.backBarButtonItem = backItem
            
            let editProfileController = segue.destination as! EditProfileViewController
            editProfileController.artistDelegate = self
            break
            
        case "showEditSoundInfo":
            soundList.prepareToShowSoundInfo(segue)
            break
            
        case "showProfile":
            soundList.prepareToShowSelectedArtist(segue)
            break
            
        case "showAddFunds", "showEarnings":
            let backItem = UIBarButtonItem()
            backItem.title = "Add Funds"
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
    
    //mark: login | logout
    var login: Login!
    
    func showWelcome() {
        login = Login(target: self)
        login.signinButton.addTarget(self, action: #selector(signInAction(_:)), for: .touchUpInside)
        login.signupButton.addTarget(self, action: #selector(signupAction(_:)), for: .touchUpInside)
        login.loginInWithTwitterButton.addTarget(self, action: #selector(loginWithTwitterAction(_:)), for: .touchUpInside)
        login.welcomeView(explanationString: "Music you upload and collect will appear here!", explanationImageString: "smiley")
    }
    
    @objc func signInAction(_ sender: UIButton) {
        login.signInAction()
    }
    
    @objc func signupAction(_ sender: UIButton) {
        login.signupAction()
    }
    
    @objc func loginWithTwitterAction(_ sender: UIButton) {
        login.loginWithTwitterAction()
    }
    
    func changeBio(_ value: String?) {
    }
    
    func newArtistInfo(_ value: Artist?) {
        if let artist = value {
            self.profileArtist = artist
            self.tableView.reloadData()
        }
    }
    
    func executeTableViewSoundListFollowStatus() {
        if let username = profileArtist?.username {
            if !username.contains("@") {
                self.navigationItem.title = username
            }
        }
        
        player = Player.sharedInstance
        player?.target = self
        player?.tableView = tableView
        if self.player?.player != nil {
            setUpMiniPlayer()
            
        } else if PFUser.current() != nil {
            setUpTableView(nil)
            
        } else {
            showWelcome()
        }
        
        if currentUser != nil && currentUser?.objectId != profileArtist?.objectId {
            checkFollowStatus()
        }
    }
    
    func didPressSignoutButton() {
        let menuAlert = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
        menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        menuAlert.addAction(UIAlertAction(title: "Sign Out", style: .default, handler: { action in
            self.tableView.removeFromSuperview()
            self.showWelcome()
            
            PFUser.logOut()
            Customer.shared.artist = nil
            let store = TWTRTwitter.sharedInstance().sessionStore
            
            if let session = store.session() {
                store.logOutUserID(session.userID)
            }

        }))
        self.present(menuAlert, animated: true, completion: nil)
    }
    
    //MARK: Tableview
    let tableView = UITableView()
    let soundReuse = "soundReuse"
    let profileReuse = "profileReuse"
    let noSoundsReuse = "noSoundsReuse"
    let profileSoundReuse = "profileSoundReuse"
    
    func setUpTableView(_ miniPlayer: UIView?) {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: profileReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        tableView.register(TagTableViewCell.self, forCellReuseIdentifier: profileSoundReuse)
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
        
        self.loadCollection(self.profileArtist!.objectId)
        self.loadSounds(nil, userId: self.profileArtist?.objectId)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
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
            make.bottom.equalTo(self.view).offset(-49)
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
            let modal = PlayerV2ViewController()
            modal.player = player
            modal.playerDelegate = self
            let transitionDelegate = DeckTransitioningDelegate()
            modal.transitioningDelegate = transitionDelegate
            modal.modalPresentationStyle = .custom
            self.present(modal, animated: true, completion: nil)
        }
    }
    
    //mark: selectedArtist
    func selectedArtist(_ artist: Artist?) {
        if let artist = artist {
            if artist.objectId == "addFunds" {
                self.performSegue(withIdentifier: "showAddFunds", sender: self)
            } else if artist.objectId == "signup" {
                self.performSegue(withIdentifier: "showWelcome", sender: self)
            } else {
                soundList.selectedArtist(artist)
            }
        }
    }
    
    //mark: sounds
    var artistReleases = [Sound]()
    var artistCollection = [Sound]()
    var collectionSoundIds = [String]()
    var didloadReleases = false
    var didLoadCollection = false
    var showSoundsTitle: String!
    var selectedSoundType: String!
    
    func soundsReuse(_ indexPath: IndexPath) -> TagTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: profileSoundReuse) as! TagTableViewCell
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        if indexPath.section == 1 {
            cell.TagTypeTitle.text = "Releases"
            if artistReleases.count == 0 && didloadReleases {
                cell.viewAllLabel.isHidden = true
                addNoSounds(cell.tagsScrollview, title: "No Releases Yet.")
            } else {
                cell.tagTypeButton.addTarget(self, action: #selector(self.didPressViewAllSoundsButton(_:)), for: .touchUpInside)
                cell.tagTypeButton.tag = 0
                cell.viewAllLabel.isHidden = false
                addSounds(cell.tagsScrollview, sounds: artistReleases, row: 0)
            }
            
        } else {
            cell.TagTypeTitle.text = "Collection"
            if artistCollection.count == 0 && didLoadCollection  {
                cell.viewAllLabel.isHidden = true
                addNoSounds(cell.tagsScrollview, title: "Nothing in their collection yet.")
            } else {
                cell.tagTypeButton.addTarget(self, action: #selector(self.didPressViewAllSoundsButton(_:)), for: .touchUpInside)
                cell.tagTypeButton.tag = 1
                cell.viewAllLabel.isHidden = false
                addSounds(cell.tagsScrollview, sounds: artistCollection, row: 1)
            }
        }
        
        return cell 
    }
    
    @objc func didPressViewAllSoundsButton(_ sender: UIButton) {
        if let artist = self.profileArtist {
            if sender.tag == 0 {
                showSoundsTitle = "\(artist.username!)'s Releases"
                selectedSoundType = "uploads"
            } else {
                showSoundsTitle = "\(artist.username!)'s Collection"
                selectedSoundType = "collection"
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
            soundArt.kf.setImage(with: URL(string: sound.artURL!))
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
            scrollview.addSubview(dateLabel)
            dateLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(artistLabel.snp.bottom)
                make.left.equalTo(soundArt)
                make.right.equalTo(soundArt)
            }
            
            let soundViewButton = UIButton()
            if row == 0 {
                //releases
                soundViewButton.addTarget(self, action: #selector(self.didPressReleaseSound(_:)), for: .touchUpInside)
            } else {
                //collection
                soundViewButton.addTarget(self, action: #selector(self.didPressCollectionSound(_:)), for: .touchUpInside)
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
    
    @objc func didPressReleaseSound(_ sender: UIButton) {
        didSelectSound(artistReleases, row: sender.tag)
    }
    
    @objc func didPressCollectionSound(_ sender: UIButton) {
        didSelectSound(artistCollection, row: sender.tag)
    }
    
    func didSelectSound(_ sounds: Array<Sound>, row: Int) {
        if let player = self.player {
            player.sounds = sounds
            player.didSelectSoundAt(row)
            if self.miniPlayerView == nil {
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
                
                self.loadSounds(self.collectionSoundIds, userId: nil)
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func loadSounds(_ collectionIds: Array<String>?, userId: String?) {
        let query = PFQuery(className: "Post")
        if let collectionIds = collectionIds {
            query.whereKey("objectId", containedIn: collectionIds)
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
                    } else {
                        self.didloadReleases = true
                        self.artistReleases = sounds
                    }
                    self.tableView.reloadData()

                } else {
                    print("no colection 1")
                }
                
            } else {
                print("Error: \(error!)")
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
                //cell.website.setTitle(website, for: .normal)
                cell.website.text = website 
                cell.websiteView.addTarget(self, action: #selector(didPressWebsiteButton(_:)), for: .touchUpInside)
            }
            
            cell.actionButton.addTarget(self, action: #selector(self.didPressActionButton(_:)), for: .touchUpInside)
            if let currentUserID = PFUser.current()?.objectId {
                if currentUserID == self.profileArtist!.objectId {
                    cell.actionButton.setTitle("Edit Profile", for: .normal)
                    cell.actionButton.backgroundColor = color.black()
                    cell.actionButton.setTitleColor(.white, for: .normal)
                    cell.actionButton.layer.borderColor = color.lightGray().cgColor
                    cell.actionButton.layer.borderWidth = 1
                    cell.actionButton.clipsToBounds = true
                    cell.actionButton.tag = 0
                } else if let isFollowedByCurrentUser = self.profileArtist!.isFollowedByCurrentUser {
                    if isFollowedByCurrentUser {
                        cell.actionButton.setTitle("Following", for: .normal)
                        cell.actionButton.backgroundColor = color.lightGray()
                        cell.actionButton.setTitleColor(color.black(), for: .normal)
                        cell.actionButton.tag = 1
                    } else {
                        cell.actionButton.setTitle("Follow", for: .normal)
                        cell.actionButton.backgroundColor = color.blue()
                        cell.actionButton.setTitleColor(.white, for: .normal)
                        cell.actionButton.tag = 2
                    }
                }
            } else {
                cell.actionButton.setTitle("Follow", for: .normal)
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
            self.uiElement.showAlert("Sign up Required.", message: "Following artists on Soundbrew is the easiest way to keep up with their latest releases!", target: self)
            break
        }
    }
    
    func setUpNavigationButtons() {
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        
        if isCurrentUserProfile && self.currentUser != nil {
            let menuButton = UIBarButtonItem(image: UIImage(named: "menu"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.didPressSettingsButton(_:)))
            
            let shareButton = UIBarButtonItem(image: UIImage(named: "share_small"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.didPressShareProfileButton(_:)))
            
            self.navigationItem.rightBarButtonItems = [menuButton, shareButton]
            
        } else {
            let shareButton = UIBarButtonItem(image: UIImage(named: "share_small"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.didPressShareProfileButton(_:)))
            self.navigationItem.rightBarButtonItem = shareButton
        }
    }
    
    @objc func didPressWebsiteButton(_ sender: UIButton) {
        if let website = self.profileArtist?.website {
            let websiteURL = URL(string: website)!
            if UIApplication.shared.canOpenURL(websiteURL) {
                UIApplication.shared.open(websiteURL, options: [:], completionHandler: nil)
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
    
    func loadUserInfoFromCloud(_ userId: String) {
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                let username = user["username"] as? String
                
                var email: String?
                if user.objectId! == PFUser.current()!.objectId {
                    email = user["email"] as? String
                }
                
                let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: username, website: nil, bio: nil, email: email, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil)
                
                if let followerCount = user["followerCount"] as? Int {
                    artist.followerCount = followerCount
                }
                
                if let name = user["artistName"] as? String {
                    artist.name = name
                }
                
                if let username = user["username"] as? String {
                    artist.username = username
                }
                
                if let city = user["city"] as? String {
                    artist.city = city
                }
                
                if let userImageFile = user["userImage"] as? PFFileObject {
                    artist.image = userImageFile.url!
                }
                
                if let bio = user["bio"] as? String {
                    artist.bio = bio
                }
                
                if let artistVerification = user["artistVerification"] as? Bool {
                    artist.isVerified = artistVerification
                }
                
                if let website = user["website"] as? String {
                    artist.website = website
                }
                
                self.profileArtist = artist
                self.executeTableViewSoundListFollowStatus()
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
                    self.uiElement.sendAlert("\(currentUser.username!) followed you!", toUserId: self.profileArtist!.objectId)
                    
                } else {
                    self.profileArtist!.isFollowedByCurrentUser = false
                    self.tableView.reloadData()
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
                            var incrementFollows = false
                            if shouldFollowArtist {
                                incrementFollows = true
                            }
                            self.updateFollowerCount(artist: self.profileArtist!, incrementFollows: incrementFollows)
                        }
                    }
                }
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
    
    func updateFollowerCount(artist: Artist, incrementFollows: Bool) {
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
}

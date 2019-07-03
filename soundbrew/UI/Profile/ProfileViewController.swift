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

    var paymentType: String!
    
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
            setUpNavigationButtons()
            
        } else if let currentUser = self.currentUser {
            isCurrentUserProfile = true
            loadUserInfoFromCloud(currentUser.objectId!)
            setUpNavigationButtons()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if soundList != nil {
            executeTableViewSoundListFollowStatus()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showEditProfile":
            let navigationController = segue.destination as! UINavigationController
            let editProfileController = navigationController.topViewController as! EditProfileViewController
            editProfileController.artist = profileArtist
            editProfileController.artistDelegate = self
            break
            
        case "showEditSoundInfo":
            soundList.prepareToShowSoundInfo(segue)
            break
            
        case "showUploadSound":
            soundList.prepareToShowSoundAudioUpload(segue)
            break
            
        case "showProfile":
            soundList.prepareToShowSelectedArtist(segue)
            break
            
        case "showPayments":
            let view = segue.destination as! PaymentsViewController
            view.paymentType = paymentType
            let backItem = UIBarButtonItem()
            backItem.title = paymentType.capitalized
            navigationItem.backBarButtonItem = backItem
            break
            
        default:
            break
        }
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
        
        soundList = SoundList(target: self, tableView: tableView, soundType: "uploads", userId: profileArtist?.objectId, tags: nil, searchText: nil)
        
        let player = Player.sharedInstance
        if player.player != nil {
            setUpMiniPlayer()
            
        } else {
            setUpTableView(nil)
        }
        
        if currentUser != nil && currentUser?.objectId != profileArtist?.objectId {
            checkFollowStatus(self.currentUser!)
        }
    }
    
    //MARK: Tableview
    let tableView = UITableView()
    let reuse = "soundReuse"
    let profileReuse = "profileReuse"
    let listTypeHeaderReuse = "listTypeHeaderReuse"
    let noSoundsReuse = "noSoundsReuse"
    let actionProfileReuse = "actionProfileReuse"
    let uploadSoundReuse = "uploadSoundReuse"
    
    func setUpTableView(_ miniPlayer: UIView?) {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: profileReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: actionProfileReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: listTypeHeaderReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: reuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: uploadSoundReuse)
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = .white
        
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if isCurrentUserProfile && soundType == "uploads" {
            return 4
        }
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var soundListSection = 2
        if isCurrentUserProfile && soundType == "uploads" {
            soundListSection = 3
        }
        
        if section == soundListSection && soundList.sounds.count != 0 {
            return soundList.sounds.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return profileInfoReuse()
            
        case 1:
            return listHeadersReuse()
            
        case 2:
            if isCurrentUserProfile && soundType == "uploads" {
                return newSoundReuse()
            } else {
                return soundsReuse(indexPath)
            }
            
        default:
            return soundsReuse(indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isCurrentUserProfile && soundType == "uploads" {
            if indexPath.section == 2 {
                self.performSegue(withIdentifier: "showUploadSound", sender: self)
                
            } else if indexPath.section == 3 {
                if let player = soundList.player {
                    player.didSelectSoundAt(indexPath.row)
                    if self.miniPlayerView == nil {
                        self.setUpMiniPlayer()
                    }
                }
            }
            
        } else {
            if let player = soundList.player {
                player.didSelectSoundAt(indexPath.row)
                if self.miniPlayerView == nil {
                    self.setUpMiniPlayer()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if indexPath.row == soundList.sounds.count - 10 && !soundList.isUpdatingData && soundList.thereIsMoreDataToLoad {
            if soundList.soundType == "uploads" {
                soundList.loadSounds(soundList.descendingOrder, likeIds: nil, userId: profileArtist?.objectId)
                
            } else {
                soundList.loadSounds(soundList.descendingOrder, likeIds: soundList.likedSoundIds, userId: nil)
            }
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
            make.height.equalTo(90)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.view)
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
        soundList.selectedArtist(artist)
    }
    
    //mark: sounds
    func soundsReuse(_ indexPath: IndexPath) -> SoundListTableViewCell {
        if soundList.sounds.count == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
            
            if soundList.soundType == "uploads" {
                cell.headerTitle.text = "No releases yet."
                
            } else {
                cell.headerTitle.text = "Nothing in their collection yet."
            }
            
            return cell
            
        } else {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! SoundListTableViewCell
            profileSounds = soundList.sounds
            return soundList.soundCell(indexPath, cell: cell) as! SoundListTableViewCell
        }
    }
    
    func newSoundReuse() -> SoundListTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! SoundListTableViewCell
        cell.soundArtist.text = "Upload Sound"
        cell.soundArtImage.backgroundColor = color.darkGray()
        cell.soundArtImage.image = UIImage(named: "plus")
        cell.menuButton.isHidden = true
        cell.soundTitle.isHidden = true
        cell.soundPlays.isHidden = true
        cell.soundPlaysImage.isHidden = true
        cell.selectionStyle = .none
        return cell
    }
    
    //mark: profileInfo
    func profileInfoReuse() -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: profileReuse) as! ProfileTableViewCell
        
        cell.selectionStyle = .none
        
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
                cell.website.setTitle(website, for: .normal)
                cell.website.addTarget(self, action: #selector(didPressWebsiteButton(_:)), for: .touchUpInside)
            }
        }
        
        if let currentUser = self.currentUser {
            cell.actionButton.addTarget(self, action: #selector(didPressActionButton(_:)), for: .touchUpInside)
            
            if currentUser.objectId == profileArtist?.objectId {
                
                cell.actionButton.setTitle("Edit Profile", for: .normal)
                cell.actionButton.backgroundColor = .white
                cell.actionButton.layer.borderWidth = 1
                cell.actionButton.layer.borderColor = color.darkGray().cgColor
                cell.actionButton.setTitleColor(color.black(), for: .normal)
                
                cell.newSoundButton.addTarget(self, action: #selector(didPressNewSoundButton(_:)), for: .touchUpInside)
                cell.newSoundButton.isHidden = false
                
            } else {
                cell.newSoundButton.isHidden = true
                
                if let isFollowedByCurrentUser = profileArtist!.isFollowedByCurrentUser {
                    if isFollowedByCurrentUser {
                        cell.actionButton.setTitle("Following", for: .normal)
                        cell.actionButton.backgroundColor = color.darkGray()
                        cell.actionButton.setTitleColor(color.black(), for: .normal)
                        
                    } else {
                        cell.actionButton.setTitle("Follow", for: .normal)
                        cell.actionButton.backgroundColor = color.blue()
                        cell.actionButton.setTitleColor(.white, for: .normal)
                    }
                    
                } else {
                    cell.actionButton.setTitle("Follow", for: .normal)
                    cell.actionButton.backgroundColor = color.blue()
                    cell.actionButton.setTitleColor(.white, for: .normal)
                }
                
                cell.actionButton.layer.borderWidth = 0
            }
            
        } else {
            cell.actionButton.isHidden = true
            cell.newSoundButton.isHidden = true
        }
        
        return cell
    }
    
    func shareProfile() {
        if let artist = profileArtist {
            self.uiElement.createDynamicLink("profile", sound: nil, artist: artist, target: self)
        }
    }
    
    //mark: button actions
    func setUpNavigationButtons() {
        if isCurrentUserProfile && self.currentUser != nil {
            let menuButton = UIBarButtonItem(image: UIImage(named: "menu"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.didPressSettingsButton(_:)))
            self.navigationItem.rightBarButtonItem = menuButton
            
            let dismissButton = UIBarButtonItem(image: UIImage(named: "dismiss"), style: .plain, target: self, action: #selector(self.didPressDismissButton(_:)))
            self.navigationItem.leftBarButtonItem = dismissButton
            
        } else {
            let shareButton = UIBarButtonItem(image: UIImage(named: "share_small"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.didPressShareProfileButton(_:)))
            self.navigationItem.rightBarButtonItem = shareButton
        }
    }
    
    @objc func didPressDismissButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func didPressNewSoundButton(_ sender: UIButton) {
        if self.currentUser != nil {
            self.performSegue(withIdentifier: "showUploadSound", sender: self)
        }
    }
    
    @objc func didPressWebsiteButton(_ sender: UIButton) {
        if let website = self.profileArtist?.website {
            UIApplication.shared.open(URL(string: website)!, options: [:], completionHandler: nil)
        }
    }
    
    @objc func didPressActionButton(_ sender: UIButton) {
        if let currentUser = self.currentUser {
            if currentUser.objectId == profileArtist!.objectId {
                self.performSegue(withIdentifier: "showEditProfile", sender: self)
                
            } else if let isFollowedByCurrentUser = profileArtist?.isFollowedByCurrentUser {
                if isFollowedByCurrentUser {
                    unFollowerUser(currentUser)
                    
                } else {
                    followUser(currentUser)
                }
                
            } else {
                followUser(currentUser)
            }
            
        } else {
            self.uiElement.segueToView("Login", withIdentifier: "welcome", target: self)
        }
    }
    
    @objc func didPressShareProfileButton(_ sender: UIBarButtonItem) {
        shareProfile()
    }
    
    @objc func didPressSettingsButton(_ sender: UIBarButtonItem) {
        if let container = self.so_containerViewController {
            container.isSideViewControllerPresented = true
        }
    }
    
    @objc func didPressMySoundType(_ sender: UIButton) {
        let currentSoundType = soundList.soundType
        
        if sender.tag == 0 {
            soundList.soundType = "uploads"
            soundType = "uploads"
        } else {
            soundList.soundType = "likes"
            soundType = "likes"
        }
        
        if currentSoundType != soundList.soundType {
            self.tableView.reloadData()
            soundList.determineTypeOfSoundToLoad(soundList.soundType)
        }
    }
    
    //mark: headers
    func listHeadersReuse() -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: listTypeHeaderReuse) as! ProfileTableViewCell
        cell.selectionStyle = .none
        
        cell.firstListType.addTarget(self, action: #selector(didPressMySoundType(_:)), for: .touchUpInside)
        cell.firstListType.tag = 0
        
        cell.secondListType.addTarget(self, action: #selector(didPressMySoundType(_:)), for: .touchUpInside)
        cell.secondListType.tag = 1
        
        if soundList.soundType == "uploads" {
            cell.firstListType.setTitleColor(color.black(), for: .normal)
            cell.secondListType.setTitleColor(color.darkGray(), for: .normal)
            
        } else {
            cell.firstListType.setTitleColor(color.darkGray(), for: .normal)
            cell.secondListType.setTitleColor(color.black(), for: .normal)
        }
        
        return cell
    }
    
    //Mark: Data
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
                
                let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: username, website: nil, bio: nil, email: email, isFollowedByCurrentUser: nil, followerCount: nil)
                
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
    
    func followUser(_ currentUser: PFUser) {
        self.profileArtist!.isFollowedByCurrentUser = true
        self.tableView.reloadData()
        let newFollow = PFObject(className: "Follow")
        newFollow["fromUserId"] = currentUser.objectId
        newFollow["toUserId"] = profileArtist!.objectId
        newFollow["isRemoved"] = false
        newFollow.saveEventually {
            (success: Bool, error: Error?) in
            if success && error == nil {
                self.incrementFollowerCount(artist: self.profileArtist!, incrementFollows: true, decrementFollows: false)
                self.uiElement.sendAlert("\(currentUser.username!) followed you.", toUserId: self.profileArtist!.objectId)
                
            } else {
                self.profileArtist!.isFollowedByCurrentUser = false
                self.tableView.reloadData()
            }
        }
    }
    
    func unFollowerUser(_ currentUser: PFUser) {
        self.profileArtist!.isFollowedByCurrentUser = false
        self.tableView.reloadData()
        let query = PFQuery(className: "Follow")
        query.whereKey("fromUserId", equalTo: currentUser.objectId!)
        query.whereKey("toUserId", equalTo: profileArtist!.objectId!)
        query.whereKey("isRemoved", equalTo: false)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if error != nil {
                self.profileArtist!.isFollowedByCurrentUser = true
                self.tableView.reloadData()
                
            } else if let object = object {
                object["isRemoved"] = true
                object.saveEventually {
                    (success: Bool, error: Error?) in
                    if success && error == nil {
                        self.incrementFollowerCount(artist: self.profileArtist!, incrementFollows: false, decrementFollows: true)
                    }
                }
            }
        }
    }
    
    func checkFollowStatus(_ currentUser: PFUser) {
        let query = PFQuery(className: "Follow")
        query.whereKey("fromUserId", equalTo: currentUser.objectId!)
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
    
    func incrementFollowerCount(artist: Artist, incrementFollows: Bool, decrementFollows: Bool) {
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: artist.objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                if incrementFollows {
                    object.incrementKey("followerCount")
                    
                } else if decrementFollows {
                    object.incrementKey("followerCount", byAmount: -1)
                }
                
                object.saveEventually()
            }
        }
    }
}

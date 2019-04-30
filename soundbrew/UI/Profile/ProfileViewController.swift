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

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ArtistDelegate {
    
    let tableView = UITableView()
    let uiElement = UIElement()
    let color = Color()
    
    var artist: Artist?
    
    var soundList: SoundList!
    var profileSounds = [Sound]()
    
    var selectedIndex = 0
    
    var currentUser: PFUser?

    override func viewDidLoad() {
        super.viewDidLoad()

        let settingsButton = UIBarButtonItem(image: UIImage(named: "more"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.didPressSettingsButton(_:)))
        
        let shareButton = UIBarButtonItem(image: UIImage(named: "share"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.didPressShareProfileButton(_:)))
        
        self.navigationItem.rightBarButtonItems = [settingsButton, shareButton]
        
        if let currentUser = PFUser.current(){
            self.currentUser = currentUser
        }
        
        if artist != nil {
            self.executeTableViewSoundListFollowStatus()
            
        } else if let userId = self.uiElement.getUserDefault("receivedUserId") as? String {
            loadUserInfoFromCloud(userId)
            UserDefaults.standard.removeObject(forKey: "receivedUserId")
            
        } else if currentUser != nil {
            loadUserInfoFromCloud(currentUser!.objectId!)
            
        } else {
            self.uiElement.segueToView("Login", withIdentifier: "welcome", target: self)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if soundList != nil {
            var tags: Array<Tag>?
            if let soundListTags = soundList.selectedTagsForFiltering {
                tags = soundListTags
            }
            
            let soundType = soundList.soundType!
            soundList = SoundList(target: self, tableView: tableView, soundType: soundType, userId: self.artist?.objectId, tags: tags, searchText: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showEditProfile":
            let navigationController = segue.destination as! UINavigationController
            let editProfileController = navigationController.topViewController as! EditProfileViewController
            editProfileController.artist = artist
            editProfileController.artistDelegate = self
            break
            
        case "showEditSoundInfo":
            soundList.prepareToShowSoundInfo(segue)
            break
            
        case "showUploadSound":
            soundList.prepareToShowSoundAudioUpload(segue)
            break
            
        case "showTags":
            soundList.prepareToShowTags(segue)
            break
            
        case "showProfile":
            soundList.prepareToShowSelectedArtist(segue)
            break
            
        case "showComments":
            soundList.prepareToShowComments(segue)
            break
            
        default:
            break
        }
    }
    
    func changeBio(_ value: String?) {
    }
    
    func newArtistInfo(_ value: Artist?) {
        if let artist = value {
            self.artist = artist
            self.tableView.reloadData()
        }
    }
    
    func executeTableViewSoundListFollowStatus() {
        if let username = artist?.username {
            if !username.contains("@") {
                self.navigationItem.title = username
            }
        }
        
        soundList = SoundList(target: self, tableView: tableView, soundType: "uploads", userId: artist?.objectId, tags: nil, searchText: nil)
        self.setUpTableView()
        
        if currentUser != nil && currentUser?.objectId != artist?.objectId {
            checkFollowStatus(self.currentUser!)
        }
    }
    
    //MARK: Tableview
    let reuse = "soundReuse"
    let profileReuse = "profileReuse"
    let listTypeHeaderReuse = "listTypeHeaderReuse"
    let noSoundsReuse = "noSoundsReuse"
    let filterSoundsReuse = "filterSoundsReuse"
    let actionProfileReuse = "actionProfileReuse"
    
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: profileReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: actionProfileReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: listTypeHeaderReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: reuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: filterSoundsReuse)
        self.tableView.separatorStyle = .none
        self.view.addSubview(tableView)
        
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-50)
            //make.bottom.equalTo(self.tabBarController!.view.subviews[0])
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3 && soundList.sounds.count != 0 {
            return soundList.sounds.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 3 {
            if let player = soundList.player {
                player.didSelectSoundAt(indexPath.row)
                soundList.miniPlayerView?.isHidden = false
                tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = self.tableView.dequeueReusableCell(withIdentifier: profileReuse) as! ProfileTableViewCell
            
            cell.selectionStyle = .none
            
            if let artist = self.artist {
                if let artistImage = artist.image {
                    cell.profileImage.kf.setImage(with: URL(string: artistImage))
                }
                
                if let name = artist.name {
                    cell.displayName.text = name
                }
                
                if let city = artist.city {
                    cell.city.text = city
                }
                
                if let bio = artist.bio {
                    cell.username.text = bio 
                }
            }
                
            cell.actionButton.addTarget(self, action: #selector(didPressActionButton(_:)), for: .touchUpInside)
            if PFUser.current()!.objectId == artist?.objectId {
                cell.actionButton.setTitle("Edit Profile", for: .normal)
                cell.actionButton.backgroundColor = .white
                cell.actionButton.layer.borderWidth = 1
                cell.actionButton.layer.borderColor = color.darkGray().cgColor
                cell.actionButton.setTitleColor(color.black(), for: .normal)
                
            } else {
                if let isFollowedByCurrentUser = artist!.isFollowedByCurrentUser {
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
            
            return cell
            
        case 1:
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
            
        case 2:
            let cell = self.tableView.dequeueReusableCell(withIdentifier: filterSoundsReuse) as! SoundListTableViewCell
            return soundList.soundFilterOptions(indexPath, cell: cell)
            
        case 3:
            if soundList.sounds.count == 0 {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
                
                if let artist = self.artist {
                    if soundList.soundType == "uploads" {
                        if artist.objectId == PFUser.current()!.objectId {
                            cell.headerTitle.text = "You haven't released any sounds yet. Tap the 'New Sound' tab to get started."
                            
                        } else {
                            cell.headerTitle.text = "No releases yet."
                        }
                        
                    } else {
                        if artist.objectId == PFUser.current()!.objectId {
                            cell.headerTitle.text = "Sounds you like will appear here."
                            
                        } else {
                            cell.headerTitle.text = "Nothing in their collection yet."
                        }
                    }
                }
                
                return cell
                
            } else {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! SoundListTableViewCell
                profileSounds = soundList.sounds
                return soundList.sound(indexPath, cell: cell)
            }
            
        default:
            return self.tableView.dequeueReusableCell(withIdentifier: listTypeHeaderReuse) as! SoundListTableViewCell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if indexPath.row == soundList.sounds.count - 10 && !soundList.isUpdatingData && soundList.thereIsNoMoreDataToLoad {
            if soundList.soundType == "uploads" {
                soundList.loadSounds(soundList.descendingOrder, likeIds: nil, userId: artist?.objectId, tags: soundList.selectedTagsForFiltering, followIds: nil, searchText: nil)
                
            } else {
                soundList.loadSounds(soundList.descendingOrder, likeIds: soundList.likedSoundIds, userId: nil, tags: soundList.selectedTagsForFiltering, followIds: nil, searchText: nil)
            }
        }
    }
    
    //mark: social buttons
    var xPositionForSocialButtons = UIElement().leftOffset
    var instagramButton: UIButton?
    var snapchatButton: UIButton?
    var twitterButton: UIButton?
    var websiteButton: UIButton?
    
    func addSocialButton(_ scrollview: UIScrollView, buttonImageName: String) {
        let socialButton = UIButton()
        socialButton.frame = CGRect(x: xPositionForSocialButtons, y: 0, width: 30, height: 30)
        socialButton.setImage(UIImage(named: buttonImageName), for: .normal)
        socialButton.layer.cornerRadius = 15
        socialButton.clipsToBounds = true
        socialButton.addTarget(self, action: #selector(self.didPressSocialButton(_:)), for: .touchUpInside)
        scrollview.addSubview(socialButton)
        
        xPositionForSocialButtons = xPositionForSocialButtons + Int(socialButton.frame.width) + uiElement.leftOffset + 10
        scrollview.contentSize = CGSize(width: xPositionForSocialButtons, height: uiElement.buttonHeight)
        
        switch buttonImageName {
        case "instagram_logo":
            socialButton.tag = 0
            instagramButton = socialButton
            break
            
        case "twitter_logo":
            socialButton.tag = 1
            twitterButton = socialButton
            break
            
        case "snapchat_logo":
            socialButton.tag = 2
            snapchatButton = socialButton
            break
            
        case "website_logo":
            socialButton.tag = 3
            websiteButton = socialButton
            break 
            
        default:
            break
        }
    }
    
    @objc func didPressSocialButton(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            if let username = artist?.instagramUsername {
                let instagramURL = "https://www.instagram.com/\(username)"
                if isURLVerified(instagramURL) {
                    UIApplication.shared.open(URL(string: instagramURL)!, options: [:], completionHandler: nil)
                }
            }
            break
            
        case 1:
            if let username = artist?.twitterUsername {
                let twitterURL = "https://www.twitter.com/\(username)"
                if isURLVerified(twitterURL) {
                    UIApplication.shared.open(URL(string: twitterURL)!, options: [:], completionHandler: nil)
                }
            }
            break
            
        case 2:
            if let username = artist?.snapchatUsername {
                let snapchatURL = "https://www.snapchat.com/add/\(username)"
                if isURLVerified(snapchatURL) {
                    UIApplication.shared.open(URL(string: snapchatURL)!, options: [:], completionHandler: nil)
                }
            }
            break
            
        case 3:
            if let website = artist?.website {
                if isURLVerified(website) {
                    UIApplication.shared.open(URL(string: "\(website)")!, options: [:], completionHandler: nil)
                }
            }
            break
            
        default:
            break
        }
    }
    
    func isURLVerified(_ url: String) -> Bool {
        return UIApplication.shared.canOpenURL(URL(string: url)!)
    }
    
    //mark: button actions
    @objc func didPressWebsiteButton(_ sender: UIButton) {
        if let website = self.artist?.website {
            UIApplication.shared.open(URL(string: website)!, options: [:], completionHandler: nil)
        }
    }
    
    @objc func didPressActionButton(_ sender: UIButton) {
        if let currentUser = self.currentUser {
            if currentUser.objectId == artist!.objectId {
                self.performSegue(withIdentifier: "showEditProfile", sender: self)
                
            } else if let isFollowedByCurrentUser = artist?.isFollowedByCurrentUser {
                if isFollowedByCurrentUser {
                    unFollowerUser(currentUser)
                    
                } else {
                    followUser(currentUser)
                }
                
            } else {
                followUser(currentUser)
            }
        }
    }
    
    @objc func didPressShareProfileButton(_ sender: UIBarButtonItem) {
        if let artist = artist {
            self.uiElement.createDynamicLink("profile", sound: nil, artist: artist, target: self)
        }
    }
    
    @objc func didPressSettingsButton(_ sender: UIBarButtonItem) {
        let menuAlert = UIAlertController(title: nil , message: nil , preferredStyle: .actionSheet)
        menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        menuAlert.addAction(UIAlertAction(title: "Sign Out", style: .default, handler: { action in
            PFUser.logOut()
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "welcome")
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            //show window
            appDelegate.window?.rootViewController = controller
        }))
    
        self.present(menuAlert, animated: true, completion: nil)
    }
    
    @objc func didPressMySoundType(_ sender: UIButton) {
        if sender.tag == 0 {
            soundList.soundType = "uploads"
            
        } else {
            soundList.soundType = "likes"
        }
        
        soundList.determineTypeOfSoundToLoad(soundList.soundType)
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
                
                /*if !username!.contains("@") {
                    self.navigationItem.title = username
                }*/
                
                var email: String?
                if user.objectId! == PFUser.current()!.objectId {
                    email = user["email"] as? String
                }
                
                let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: username, website: nil, bio: nil, email: email, instagramUsername: nil, twitterUsername: nil, snapchatUsername: nil, isFollowedByCurrentUser: nil, followerCount: nil)
                
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
                
                if let instagramUsername = user["instagramHandle"] as? String {
                    artist.instagramUsername = instagramUsername
                }
                
                if let twitterUsername = user["twitterHandle"] as? String {
                    artist.twitterUsername = twitterUsername
                }
                
                if let snapchatUsername = user["snapchatHandle"] as? String {
                    artist.snapchatUsername = snapchatUsername
                }
                
                if let website = user["otherLink"] as? String {
                    artist.website = website
                }
                
                self.artist = artist
                self.executeTableViewSoundListFollowStatus()
                /*self.soundList = SoundList(target: self, tableView: self.tableView, soundType: "uploads", userId: artist.objectId, tags: nil, searchText: nil)
                self.setUpTableView()*/
            }
        }
    }
    
    func followUser(_ currentUser: PFUser) {
        self.artist!.isFollowedByCurrentUser = true
        self.tableView.reloadData()
        let newFollow = PFObject(className: "Follow")
        newFollow["fromUserId"] = currentUser.objectId
        newFollow["toUserId"] = artist!.objectId
        newFollow["isRemoved"] = false
        newFollow.saveEventually {
            (success: Bool, error: Error?) in
            if success && error == nil {
                self.incrementFollowerCount(artist: self.artist!, incrementFollows: true, decrementFollows: false)
                
            } else {
                self.artist!.isFollowedByCurrentUser = false
                self.tableView.reloadData()
            }
        }
    }
    
    func unFollowerUser(_ currentUser: PFUser) {
        self.artist!.isFollowedByCurrentUser = false
        self.tableView.reloadData()
        let query = PFQuery(className: "Follow")
        query.whereKey("fromUserId", equalTo: currentUser.objectId!)
        query.whereKey("toUserId", equalTo: artist!.objectId)
        query.whereKey("isRemoved", equalTo: false)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if error != nil {
                self.artist!.isFollowedByCurrentUser = true
                self.tableView.reloadData()
                
            } else if let object = object {
                object["isRemoved"] = true
                object.saveEventually {
                    (success: Bool, error: Error?) in
                    if success && error == nil {
                        self.incrementFollowerCount(artist: self.artist!, incrementFollows: false, decrementFollows: true)
                    }
                }
            }
        }
    }
    
    func checkFollowStatus(_ currentUser: PFUser) {
        let query = PFQuery(className: "Follow")
        query.whereKey("fromUserId", equalTo: currentUser.objectId!)
        query.whereKey("toUserId", equalTo: artist!.objectId)
        query.whereKey("isRemoved", equalTo: false)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if object != nil && error == nil {
                print("follwoing")
                self.artist?.isFollowedByCurrentUser = true
                
            } else {
                print("not following")
                self.artist?.isFollowedByCurrentUser = false
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

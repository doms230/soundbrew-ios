//
//  ProfileViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/11/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

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

        let menuButton = UIBarButtonItem(title: "...", style: .plain, target: self, action: #selector(self.didPressMenuButton(_:)))
        self.navigationItem.rightBarButtonItem = menuButton
        
        if let currentUser = PFUser.current(){
            self.currentUser = currentUser
        }
        
        if artist != nil {
            self.setUpTableView()
            soundList = SoundList(target: self, tableView: tableView, soundType: "uploads", userId: artist?.objectId, tags: nil)
            
            if currentUser != nil {
                checkFollowStatus(self.currentUser!)
            }
            
        } else {
            if currentUser != nil {
                loadUserInfoFromCloud(currentUser!.objectId!)
                
            } else {
                //show login view
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if soundList != nil {
            /*soundList.sounds = profileSounds
            soundList.player!.sounds = profileSounds
            soundList.target = self
            self.tableView.reloadData()*/
            
            var tags: Array<String>?
            if let soundListTags = soundList.tags {
                tags = soundListTags
            }
            
            soundList = SoundList(target: self, tableView: tableView, soundType: "uploads", userId: self.artist?.objectId, tags: tags)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEditProfile" {
            let navigationController = segue.destination as! UINavigationController
            let editProfileController = navigationController.topViewController as! EditProfileViewController
            editProfileController.artist = artist
            editProfileController.artistDelegate = self 
            
        } else {
            /*let viewController: SoundListViewController = segue.destination as! SoundListViewController
            viewController.userId = artist!.objectId
            //viewController.soundType = selectedViewAllSound
            viewController.soundTitle = "\(artist!.name!)'s \(selectedViewAllSound.capitalized)"*/
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
    
    //MARK: Tableview
    let reuse = "soundReuse"
    let profileReuse = "profileReuse"
    let uploadsCollectionHeaderReuse = "uploadsCollectionsHeaderReuse"
    let noSoundsReuse = "noSoundsReuse"
    let filterSoundsReuse = "filterSoundsReuse"
    let actionProfileReuse = "actionProfileReuse"
    
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: profileReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: actionProfileReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: uploadsCollectionHeaderReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: reuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: filterSoundsReuse)
        self.tableView.separatorStyle = .none
        //tableView.frame = view.bounds
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
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 4 && soundList.sounds.count != 0 {
            return soundList.sounds.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let player = soundList.player {
            player.didSelectSoundAt(indexPath.row)
            //soundList.setUpMiniPlayer()
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = self.tableView.dequeueReusableCell(withIdentifier: profileReuse) as! ProfileTableViewCell
            
            cell.selectionStyle = .none
            
            if let artist = artist {
                if let artistImage = artist.image {
                    cell.profileImage.kf.setImage(with: URL(string: artistImage))
                }
                
                if let name = artist.name {
                    cell.displayName.text = name
                }
               
                if let city = artist.city {
                     cell.city.text = city
                }
                
                if let username = artist.username {
                    cell.username.text = username
                }
            }
            
            return cell
            
        case 1:
            let cell = self.tableView.dequeueReusableCell(withIdentifier: actionProfileReuse) as! ProfileTableViewCell
            
            if let artist = self.artist {
                //social buttons are recreated multiple times, so have to check whether not they've already been created.
                if artist.instagramUsername != nil && instagramButton == nil {
                    if artist.instagramUsername! != "" {
                        addSocialButton(cell.socialScrollview, buttonImageName: "instagram_logo")
                    }
                }
                
                if artist.twitterUsername != nil && twitterButton == nil {
                    if artist.twitterUsername! != "" {
                        addSocialButton(cell.socialScrollview, buttonImageName: "twitter_logo")
                    }
                }
                
                if artist.snapchatUsername != nil && snapchatButton == nil {
                    if artist.snapchatUsername! != "" {
                        addSocialButton(cell.socialScrollview, buttonImageName: "snapchat_logo")
                    }
                }
                
                if artist.website != nil && websiteButton == nil {
                    if artist.website! != "" {
                        addSocialButton(cell.socialScrollview, buttonImageName: "website_logo")
                    }
                }
                
                cell.actionButton.addTarget(self, action: #selector(didPressActionButton(_:)), for: .touchUpInside)
                if let currentUser = PFUser.current() {
                    if currentUser.objectId == artist.objectId {
                        cell.actionButton.setTitle("Edit Profile", for: .normal)
                        cell.actionButton.backgroundColor = .white
                        cell.actionButton.layer.borderWidth = 1
                        cell.actionButton.layer.borderColor = color.black().cgColor
                        cell.actionButton.setTitleColor(color.black(), for: .normal)
                        
                    } else {
                        if let isFollowedByCurrentUser = artist.isFollowedByCurrentUser {
                            if isFollowedByCurrentUser {
                                cell.actionButton.setTitle("Following", for: .normal)
                                cell.actionButton.backgroundColor = color.gray()
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
                    cell.actionButton.setTitle("Follow", for: .normal)
                    cell.actionButton.backgroundColor = color.blue()
                    cell.actionButton.layer.borderWidth = 0
                    cell.actionButton.setTitleColor(.white, for: .normal)
                }
            }

            return cell
            
        case 2:
            let cell = self.tableView.dequeueReusableCell(withIdentifier: uploadsCollectionHeaderReuse) as! ProfileTableViewCell
            cell.selectionStyle = .none
           
            cell.uploadsButton.addTarget(self, action: #selector(didPressMySoundType(_:)), for: .touchUpInside)
            cell.uploadsButton.tag = 0
            
            cell.collectionButton.addTarget(self, action: #selector(didPressMySoundType(_:)), for: .touchUpInside)
            cell.collectionButton.tag = 1
            
            if soundList.soundType == "uploads" {
                cell.uploadsButton.setTitleColor(color.black(), for: .normal)
                cell.collectionButton.setTitleColor(color.gray(), for: .normal)
                
            } else {
                cell.uploadsButton.setTitleColor(color.gray(), for: .normal)
                cell.collectionButton.setTitleColor(color.black(), for: .normal)
            }
            
            return cell
            
        case 3:
            let cell = self.tableView.dequeueReusableCell(withIdentifier: filterSoundsReuse) as! SoundListTableViewCell
            return soundList.soundFilterOptions(indexPath, cell: cell)
            
        case 4:
            if soundList.sounds.count == 0 {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
                if soundList.soundType == "uploads" {
                    if artist!.objectId == PFUser.current()!.objectId {
                        cell.headerTitle.text = "You haven't uploaded any sounds yet. Tap the 'New Sound' tab to get started."
                    
                    } else {
                        cell.headerTitle.text = "\(String(describing: artist?.name)) hasn't yet."
                    }
                    
                    
                } else {
                    if artist!.objectId == PFUser.current()!.objectId {
                        cell.headerTitle.text = "Sounds you like will appear here."
                        
                    } else {
                        cell.headerTitle.text = "Nothing in \(artist!.name!)'s collection yet."
                    }
                }
                
                return cell
                
            } else {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! SoundListTableViewCell
                profileSounds = soundList.sounds
                return soundList.sound(indexPath, cell: cell)
            }
            
        default:
            return self.tableView.dequeueReusableCell(withIdentifier: uploadsCollectionHeaderReuse) as! SoundListTableViewCell
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
                self.performSegue(withIdentifier: "editProfile", sender: self)
                
            } else if let isFollowedByCurrentUser = artist?.isFollowedByCurrentUser {
                if isFollowedByCurrentUser {
                    unFollowerUser(currentUser)
                    
                } else {
                    followUser(currentUser)
                }
                
            } else {
                followUser(currentUser)
            }
            
        } else {
            //show login view
        }
    }
    
    @objc func didPressMenuButton(_ sender: UIBarButtonItem) {
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
                
                var email: String?
                if user.objectId! == PFUser.current()!.objectId {
                    email = user["email"] as? String
                }
                
                let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: username, website: nil, bio: nil, email: email, instagramUsername: nil, twitterUsername: nil, snapchatUsername: nil, isFollowedByCurrentUser: nil)
                
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
                
                self.soundList = SoundList(target: self, tableView: self.tableView, soundType: "uploads", userId: artist.objectId, tags: nil)
                self.setUpTableView()
                
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
            if error != nil {
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
                object.saveEventually()
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
}

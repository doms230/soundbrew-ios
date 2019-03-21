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
    
    var socialsAndStreamImages = [String]()
    
    var artist: Artist?
    
    var uploadedSounds = [Sound]()
    var likedSounds = [Sound]()
    var likedSoundsIds = [String]()
    var selectedViewAllSound = "uploads"
    
    var selectedIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        let menuButton = UIBarButtonItem(title: "...", style: .plain, target: self, action: #selector(self.didPressMenuButton(_:)))
        self.navigationItem.rightBarButtonItem = menuButton
        
        if artist != nil {
            self.setUpTableView()
            loadSounds("uploads")
            
        } else if let currentUserId = PFUser.current()?.objectId {
            loadUserInfoFromCloud(currentUserId)
            
        } else {
            self.uiElement.segueToView("Welcome", withIdentifier: "login", target: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEditProfile" {
            let navigationController = segue.destination as! UINavigationController
            let editProfileController = navigationController.topViewController as! EditProfileViewController
            editProfileController.artist = artist
            editProfileController.artistDelegate = self 
            
        } else {
            let viewController: SoundListViewController = segue.destination as! SoundListViewController
            viewController.userId = artist!.objectId
            viewController.soundType = selectedViewAllSound
            viewController.soundTitle = "\(artist!.name!)'s \(selectedViewAllSound.capitalized)"
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
    let reuse = "reuse"
    let profileReuse = "profileReuse"
    let uploadsLikesReuse = "uploadsLikesReuse"
    let noSoundsReuse = "noSoundsReuse"
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: profileReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: reuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: uploadsLikesReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
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
    
    //MARK: TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return likedSounds.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        var headerTitle: String!
        var viewAllButtonTag = 0
        var sounds = [Sound]()
        
        switch indexPath.section {
        case 0:
            let profileCell = self.tableView.dequeueReusableCell(withIdentifier: profileReuse) as! ProfileTableViewCell
            
            if let artist = artist {
                if let artistImage = artist.image {
                    profileCell.profileImage.kf.setImage(with: URL(string: artistImage))
                }
                
                if let name = artist.name {
                    profileCell.displayName.text = name
                }
               
                if let city = artist.city {
                     profileCell.city.text = city
                }
                
                if let bio = artist.username {
                    profileCell.bio.text = bio
                }
                
                //social buttons are recreated multiple times, so have to check whether not they've already been created.
                if artist.instagramUsername != nil && instagramButton == nil {
                    if artist.instagramUsername! != "" {
                        addSocialButton(profileCell.socialScrollview, buttonImageName: "instagram_logo")
                    }
                }
                
                if artist.twitterUsername != nil && twitterButton == nil {
                    if artist.twitterUsername! != "" {
                        addSocialButton(profileCell.socialScrollview, buttonImageName: "twitter_logo")
                    }
                }
                
                if artist.snapchatUsername != nil && snapchatButton == nil {
                   if artist.snapchatUsername! != "" {
                        addSocialButton(profileCell.socialScrollview, buttonImageName: "snapchat_logo")
                    }
                }
                
                if artist.website != nil && websiteButton == nil {
                    if artist.website! != "" {
                         addSocialButton(profileCell.socialScrollview, buttonImageName: "website_logo")
                    }
                }
                
                /*if let website = artist.website {
                    profileCell.website.setTitle("\(website)", for: .normal)
                    profileCell.website.addTarget(self, action: #selector(self.didPressWebsiteButton(_:)), for: .touchUpInside)
                }*/
                
                if let currentUser = PFUser.current() {
                    if currentUser.objectId == artist.objectId {
                        profileCell.actionButton.setTitle("Edit Profile", for: .normal)
                        profileCell.actionButton.backgroundColor = .white
                        profileCell.actionButton.layer.borderWidth = 1
                        profileCell.actionButton.layer.borderColor = color.black().cgColor
                        profileCell.actionButton.setTitleColor(color.black(), for: .normal)
                        
                    } else {
                        profileCell.actionButton.setTitle("Follow", for: .normal)
                        profileCell.actionButton.backgroundColor = color.blue()
                        profileCell.actionButton.layer.borderWidth = 0
                        profileCell.actionButton.setTitleColor(.white, for: .normal)
                    }
                    
                } else {
                    profileCell.actionButton.setTitle("Follow", for: .normal)
                    profileCell.actionButton.backgroundColor = color.blue()
                    profileCell.actionButton.layer.borderWidth = 0
                    profileCell.actionButton.setTitleColor(.white, for: .normal)
                }
                profileCell.actionButton.addTarget(self, action: #selector(didPressActionButton(_:)), for: .touchUpInside)
            }
            
            cell = profileCell
            break
            
        case 1:
            cell = self.tableView.dequeueReusableCell(withIdentifier: uploadsLikesReuse) as! SoundListTableViewCell
           /* headerTitle = "Uploaded Sounds"
            sounds = uploadedSounds
            viewAllButtonTag = 0*/
            break
            
        case 2:
            sounds = likedSounds
            /*headerTitle = "Liked Sounds"
            sounds = likedSounds
            viewAllButtonTag = 1*/
            if sounds.count == 0 {
                let noSoundsCell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
                //noSoundsCell.headerTitle.text = "No \(headerTitle!) Yet"
                cell = noSoundsCell
                
            } else {
                let mySoundsCell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! SoundListTableViewCell
                //mySoundsCell.headerTitle.text = headerTitle
                //mySoundsCell.viewButton.isHidden = false
                //mySoundsCell.viewButton.addTarget(self, action: #selector(self.didPressViewAllButton(_:)), for: .touchUpInside)
                //mySoundsCell.viewButton.tag = viewAllButtonTag
                
                //self.tableView.separatorStyle = .none
                
                var sound: Sound!
                sound = sounds[indexPath.row]
                
                mySoundsCell.soundArtImage.kf.setImage(with: URL(string: sound.artURL))
                mySoundsCell.soundTitle.text = sound.title
                
                if let plays = sound.plays {
                    mySoundsCell.soundPlays.text = "\(plays)"
                    
                } else {
                    mySoundsCell.soundPlays.text = "0"
                }
                
                if let artistName = sound.artist?.name {
                    mySoundsCell.soundArtist.text = artistName
                    
                } else {
                    loadArtist(mySoundsCell, userId: sound.artist!.objectId, row: indexPath.row)
                }
                
                cell = mySoundsCell
            }
            break
            
        default:
            break
        }
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    //mark: social buttons
    var xPositionForSocialButtons = UIElement().leftOffset
    var instagramButton: UIButton?
    var snapchatButton: UIButton?
    var twitterButton: UIButton?
    var websiteButton: UIButton?
    
    func addSocialButton(_ scrollview: UIScrollView, buttonImageName: String) {
        let socialButton = UIButton()
        socialButton.frame = CGRect(x: xPositionForSocialButtons, y: 0, width: 40, height: 40)
        socialButton.setImage(UIImage(named: buttonImageName), for: .normal)
        socialButton.layer.cornerRadius = 20
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
                UIApplication.shared.open(URL(string: "https://www.instagram.com/\(username)")!, options: [:], completionHandler: nil)
            }
            break
            
        case 1:
            if let username = artist?.twitterUsername {
                UIApplication.shared.open(URL(string: "https://www.twitter.com/\(username)")!, options: [:], completionHandler: nil)
            }
            break
            
        case 2:
            if let username = artist?.snapchatUsername {
                UIApplication.shared.open(URL(string: "https://www.snapchat.com/add/\(username)")!, options: [:], completionHandler: nil)
            }
            break
            
        case 3:
            if let website = artist?.website {
                UIApplication.shared.open(URL(string: "\(website)")!, options: [:], completionHandler: nil)
            }
            break
            
        default:
            break
        }
    }
    
    //mark: button actions
    @objc func didPressWebsiteButton(_ sender: UIButton) {
        if let website = self.artist?.website {
            UIApplication.shared.open(URL(string: website)!, options: [:], completionHandler: nil)
        }
    }
    
    @objc func didPressActionButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showEditProfile", sender: self)
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
    
    @objc func didPressViewAllButton(_ sender: UIButton) {
        if sender.tag == 0 {
            selectedViewAllSound = "uploads"
            
        } else {
            selectedViewAllSound = "likes"
        }
        
        self.performSegue(withIdentifier: "showSounds", sender: self)
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
                
                let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: username, website: nil, bio: nil, email: email, instagramUsername: nil, twitterUsername: nil, snapchatUsername: nil)
                
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
                
                self.setUpTableView()
                self.loadSounds("uploads")
            }
        }
    }
    
    func loadArtist(_ cell: SoundListTableViewCell, userId: String, row: Int) {
        let query = PFQuery(className:"_User")
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                let artistName = user["artistName"] as? String
                cell.soundArtist.text = artistName!
            }
        }
    }
    
    func loadLikedSounds() {
        let query = PFQuery(className: "Like")
        query.whereKey("userId", equalTo: self.artist!.objectId)
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        self.likedSoundsIds.append(object["postId"] as! String)
                    }
                }
                
                if objects?.count == 0 {
                    self.tableView.reloadData()
                    
                } else {
                    self.loadSounds("likes")
                }
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func loadSounds(_ soundType: String) {
        let query = PFQuery(className: "Post")
        
        if soundType == "uploads" {
            query.whereKey("userId", equalTo: self.artist!.objectId)
            
        } else {
            query.whereKey("objectId", containedIn: likedSoundsIds)
        }

        query.limit = 50
        query.addDescendingOrder("createdAt")
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let title = object["title"] as! String
                        let art = object["songArt"] as! PFFileObject
                        let audio = object["audioFile"] as! PFFileObject
                        let tags = object["tags"] as! Array<String>
                        let userId = object["userId"] as! String
                        var soundPlays: Int?
                        if let plays = object["plays"] as? Int {
                            soundPlays = plays
                        }
                        
                        let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: "", website: "", bio: "", email: "", instagramUsername: nil, twitterUsername: nil, snapchatUsername: nil)
                        let sound = Sound(objectId: object.objectId, title: title, artURL: art.url!, artImage: nil, artFile: nil, tags: tags, createdAt: object.createdAt!, plays: soundPlays, audio: audio, audioURL: audio.url!, relevancyScore: 0, audioData: nil, artist: artist, isLiked: nil)
                        
                        if soundType == "uploads" {
                            self.uploadedSounds.append(sound)
                            
                        } else {
                            self.likedSounds.append(sound)
                        }
                    }
                }
                
                self.tableView.reloadData()
                if soundType == "uploads" {
                    self.loadLikedSounds()
                }
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
}

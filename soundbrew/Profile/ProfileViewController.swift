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

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
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
            loadSounds("uploads")
            self.setUpTableView()
            
        } else if let currentUserId = PFUser.current()?.objectId {
            loadUserInfoFromCloud(currentUserId)
            
        } else {
            self.uiElement.segueToView("Welcome", withIdentifier: "login", target: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController: SoundListViewController = segue.destination as! SoundListViewController
        viewController.userId = artist!.objectId
        viewController.soundType = selectedViewAllSound
        viewController.soundTitle = "\(artist!.name!)'s \(selectedViewAllSound.capitalized)"
        
       /* let viewController: EditProfileViewController = segue.destination as! EditProfileViewController
        viewController.artist = artist*/
    }
    
    let reuse = "reuse"
    let profileReuse = "profileReuse"
    let profileSoundsReuse = "profileSoundsReuse"
    let noSoundsReuse = "noSoundsReuse"
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: profileReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: reuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: profileSoundsReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        self.tableView.separatorStyle = .singleLine
        //tableView.frame = view.bounds
        self.view.addSubview(tableView)
        
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            //make.bottom.equalTo(self.view).offset(-50)
            make.bottom.equalTo(self.tabBarController!.view.subviews[0])
        }
    }
    
    //MARK: TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /*func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if  section == 2 {
            let returnedView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 0)) //set these values as necessary
            return returnedView
        }
        
        return nil
    }*/
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        var headerTitle: String!
        var viewAllButtonTag = 0
        var sounds = [Sound]()
        
        switch indexPath.row {
        case 0:
            let profileCell = self.tableView.dequeueReusableCell(withIdentifier: profileReuse) as! ProfileTableViewCell
            
            if let artist = artist {
                if let artistImage = artist.image {
                    profileCell.artistImage.kf.setImage(with: URL(string: artistImage))
                }
                
                if let name = artist.name {
                    profileCell.artistName.text = name
                }
               
                if let city = artist.city {
                     profileCell.artistCity.text = city
                }
                if let bio = artist.bio {
                    profileCell.artistBio.text = bio
                }
                
                profileCell.actionButton.addTarget(self, action: #selector(didPressActionButton(_:)), for: .touchUpInside)
            }
            
            cell = profileCell
            //self.tableView.separatorStyle = .singleLine
            break
            
        case 1:
            headerTitle = "Uploaded Sounds"
            sounds = uploadedSounds
            viewAllButtonTag = 0
            break
            
        case 2:
            headerTitle = "Liked Sounds"
            sounds = likedSounds
            viewAllButtonTag = 1
            break
            
        default:
            break
        }
        
        if indexPath.row != 0 {
            if sounds.count == 0 {
                let noSoundsCell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
                noSoundsCell.headerTitle.text = "No \(headerTitle!) Yet"
                cell = noSoundsCell
                
            } else {
                let mySoundsCell = self.tableView.dequeueReusableCell(withIdentifier: profileSoundsReuse) as! SoundListTableViewCell
                mySoundsCell.headerTitle.text = headerTitle
                mySoundsCell.viewButton.isHidden = false
                mySoundsCell.viewButton.addTarget(self, action: #selector(self.didPressViewAllButton(_:)), for: .touchUpInside)
                mySoundsCell.viewButton.tag = viewAllButtonTag
                
                //self.tableView.separatorStyle = .none
                
                var sound: Sound!
                sound = sounds[indexPath.row - 1]
                
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
        }
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    //mark: button actions
    @objc func didPressActionButton(_ sender: UIButton) {
        let modal = EditProfileViewController()
        modal.modalPresentationStyle = .currentContext
        modal.artist = self.artist
        present(modal, animated: true, completion: nil)
        //self.performSegue(withIdentifier: "showEditProfile", sender: self)
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
                
                let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: username, website: nil, bio: nil, email: email)
                
                if let name = user["artistName"] as? String {
                    artist.name = name
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
        query.whereKey("userId", equalTo: PFUser.current()!.objectId!)
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

        query.limit = 3
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
                        
                        let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: "", website: "", bio: "", email: "")
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

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
    
    lazy var viewButton: UIButton = {
        let button = UIButton()
        button.setTitle("View", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = color.black()
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)", size: 20)
        return button
    }()

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
    }
    
    let reuse = "reuse"
    let profileReuse = "profileReuse"
    let headerReuse = "headerReuse"
    
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: profileReuse)
        tableView.register(MySoundsTableViewCell.self, forCellReuseIdentifier: reuse)
        tableView.register(MySoundsTableViewCell.self, forCellReuseIdentifier: headerReuse)
        self.tableView.separatorStyle = .none
        tableView.frame = view.bounds
        self.view.addSubview(tableView)
        
        self.view.addSubview(viewButton)
        viewButton.snp.makeConstraints { (make) -> Void in
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-50)
        }
    }
    
    //MARK: TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if  section == 2 {
            let returnedView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 0)) //set these values as necessary
            return returnedView
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
            
        case 1:
            return uploadedSounds.count + 1
            
        case 2:
            return likedSounds.count + 1
        
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        var headerTitle: String!
        var viewAllButtonTag = 0
        var sounds: Array<Sound>!
        
        if indexPath.section == 0 {
            let profileCell = self.tableView.dequeueReusableCell(withIdentifier: profileReuse) as! ProfileTableViewCell
            
            if let artist = artist {
                if let artistImage = artist.image {
                    profileCell.artistImage.kf.setImage(with: URL(string: artistImage))
                }
                profileCell.artistName.text = artist.name
                profileCell.artistCity.text = artist.city
                profileCell.artistBio.text = "Hey, I'm Dom! The best rapper aliveeeeeeee. Cha"
            }
            
            cell = profileCell
            self.tableView.separatorStyle = .none
            
        } else if indexPath.section == 1 {
            headerTitle = "Uploaded Sounds"
            sounds = uploadedSounds
            viewAllButtonTag = 0

        } else if indexPath.section == 2 {
            headerTitle = "Liked Sounds"
            sounds = likedSounds
            viewAllButtonTag = 1
        }
        
        if indexPath.section != 0 {
            if indexPath.row == 0 {
                let headerCell = self.tableView.dequeueReusableCell(withIdentifier: headerReuse) as! MySoundsTableViewCell
                if sounds.count == 0 {
                    headerCell.headerTitle.text = "No \(headerTitle!) Yet"
                    headerCell.viewButton.isHidden = true
                    
                } else {
                    headerCell.headerTitle.text = headerTitle
                    headerCell.viewButton.isHidden = false
                    headerCell.viewButton.addTarget(self, action: #selector(self.didPressViewAllButton(_:)), for: .touchUpInside)
                    headerCell.viewButton.tag = viewAllButtonTag
                }
                
                cell = headerCell
                
            } else {
                let mySoundsCell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! MySoundsTableViewCell
                
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
        
        menuAlert.addAction(UIAlertAction(title: "Edit Profile", style: .default, handler: { action in
            self.performSegue(withIdentifier: "showEditProfile", sender: self)
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
                let artistName = user["artistName"] as? String
                
                let artistCity = user["city"] as? String
                
                var artistURL = ""
                if let userImageFile = user["userImage"] as? PFFileObject {
                    artistURL = userImageFile.url!
                }
                
                var isArtistVerified: Bool?
                if let artistVerification = user["artistVerification"] as? Bool {
                    isArtistVerified = artistVerification
                }
                
                self.artist = Artist(objectId: user.objectId, name: artistName!, city: artistCity!, image: artistURL, isVerified: isArtistVerified)
                
                self.setUpTableView()
                self.loadSounds("uploads")
            }
        }
    }
    
    func loadArtist(_ cell: MySoundsTableViewCell, userId: String, row: Int) {
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
                        
                        let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil)
                        let sound = Sound(objectId: object.objectId, title: title, artURL: art.url!, artImage: nil, artFile: nil, tags: tags, createdAt: object.createdAt!, plays: soundPlays, audio: audio, audioURL: audio.url!, relevancyScore: 0, audioData: nil, artist: artist)
                        
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

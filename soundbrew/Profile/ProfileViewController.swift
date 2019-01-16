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
    
    var uploadedSoundsIsPressed = true
    var uploadedSounds = [Sound]()
    var likedSounds = [Sound]()
    var likedSoundsIds = [String]()
    
    var selectedIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        let menuButton = UIBarButtonItem(title: "...", style: .plain, target: self, action: #selector(self.didPressMenuButton(_:)))
        self.navigationItem.rightBarButtonItem = menuButton
        
        if PFUser.current() != nil {
            if artist != nil {
                loadSounds("uploads")
                self.setUpTableView()
                
            } else {
                loadUserInfoFromCloud(PFUser.current()!.objectId!)
            }
            
        } else {
            self.uiElement.segueToView("Login", withIdentifier: "welcome", target: self)
        }
    }
    
    let reuse = "reuse"
    let profileReuse = "profileReuse"
    
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MySoundsTableViewCell.self, forCellReuseIdentifier: reuse)
        tableView.register(MySoundsTableViewCell.self, forCellReuseIdentifier: profileReuse)
        self.tableView.separatorStyle = .singleLine
        tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    //MARK: TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            if uploadedSoundsIsPressed {
                return uploadedSounds.count
            }
            
            return likedSounds.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: MySoundsTableViewCell
        if indexPath.section == 0 {
            cell = self.tableView.dequeueReusableCell(withIdentifier: profileReuse) as! MySoundsTableViewCell
            
            if let artist = artist {
                cell.artistImage.kf.setImage(with: URL(string: artist.image))
                cell.artistName.text = artist.name
                cell.artistCity.text = artist.city
                cell.artistBio.text = "Hey, I'm Dom! The best rapper aliveeeeeeee. Cha"
            }
            
            cell.uploadsButton.addTarget(self, action: #selector(self.didPressUploadsButton(_:)), for: .touchUpInside)
            cell.likesButton.addTarget(self, action: #selector(self.didPressLikesButton(_:)), for: .touchUpInside)
            
            if uploadedSoundsIsPressed {
                cell.uploadsButton.setTitleColor(color.blue(), for: .normal)
                cell.likesButton.setTitleColor(color.black(), for: .normal)
                
            } else {
                cell.likesButton.setTitleColor(color.blue(), for: .normal)
                cell.uploadsButton.setTitleColor(color.black(), for: .normal)
            }
            
        } else {
            cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! MySoundsTableViewCell
            
            var sound: Sound!
            
            if uploadedSoundsIsPressed {
                sound = uploadedSounds[indexPath.row]
                
            } else {
                sound = likedSounds[indexPath.row]
            }
            
            cell.soundArtImage.kf.setImage(with: URL(string: sound.artURL))
            cell.soundTitle.text = sound.title
            
            if let plays = sound.plays {
                cell.soundPlays.text = "\(plays)"
                
            } else {
                cell.soundPlays.text = "0"
            }
            
            if let artistName = sound.artistName {
                cell.soundArtist.text = artistName
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
    
    @objc func didPressLikesButton(_ sender: UIButton) {
        if uploadedSoundsIsPressed {
            uploadedSoundsIsPressed = false
            self.tableView.reloadData()
        }
    }
    
    @objc func didPressUploadsButton(_ sender: UIButton) {
        if !uploadedSoundsIsPressed {
            uploadedSoundsIsPressed = true
            self.tableView.reloadData()
        }
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
                
                self.artist = Artist(objectId: user.objectId, name: artistName!, city: artistCity!, image: artistURL, instagramHandle: nil, instagramClicks: nil, twitterHandle: nil, twitterClicks: nil, soundcloud: nil, soundcloudClicks: nil, spotify: nil, spotifyClicks: nil, appleMusic: nil, appleMusicClicks: nil, otherLink: nil, otherLinkClicks: nil)
                
                self.setUpTableView()
                self.loadSounds("uploads")
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

        query.limit = 50
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
                        
                        let sound = Sound(objectId: object.objectId, title: title, artURL: art.url!, artImage: nil, userId: userId, tags: tags, createdAt: object.createdAt!, plays: soundPlays, audio: audio, audioURL: audio.url!, relevancyScore: 0, audioData: nil, artistName: nil, artistCity: nil, instagramHandle: nil, twitterHandle: nil, spotifyLink: nil, soundcloudLink: nil, appleMusicLink: nil, otherLink: nil, artistVerified: nil)
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

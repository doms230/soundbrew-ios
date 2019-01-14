//
//  MySoundsViewController.swift
//  soundbrew artists
//
//  Created by Dominic Smith on 10/11/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//TODO: Automatic loading of more sounds as the user scrolls

import UIKit
import Parse
import Kingfisher
import SnapKit

class MySoundsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let uiElement = UIElement()
    let color = Color()

    var sounds = [Sound]()
    var likedSoundsIds = [String]()
    var soundType: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        determinSoundType()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        /*let installation = PFInstallation.current()
        installation?.badge = 0
        installation?.saveInBackground()*/
    }
    
    lazy var soundTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: uiElement.titleLabelFontSize)
        label.text = "No Sounds Here Yet"
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    func determinSoundType() {
        if let soundType = self.soundType {
            if soundType == "Likes" {
                self.title = "Liked Sounds"
                self.loadLikedSounds()
                
            } else {
                self.title = "Uploaded Sounds"
                self.loadSounds()
            }
            
        } else {
            self.loadSounds()
        }
    }
    
    func showNoSoundsHereYetUI() {
        var soundMessage = "Sounds that you upload to Soundbrew will appear here."
        if soundType == "Likes" {
            soundMessage = "Sounds that you like on Soundbrew will appear here."
        }
        
        self.soundTitle.text = soundMessage
        self.view.addSubview(self.soundTitle)
        self.soundTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset((self.view.frame.height / 2) - 50)
            make.left.equalTo(self.view).offset(self.uiElement.leftOffset)
            make.right.equalTo(self.view).offset(self.uiElement.rightOffset)
        }
    }
    
    //mark: tableview
    var tableView: UITableView!
    let reuse = "reuse"
    let playFilterReuse = "playFilterReuse"
    
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MySoundsTableViewCell.self, forCellReuseIdentifier: reuse)
        tableView.register(MySoundsTableViewCell.self, forCellReuseIdentifier: playFilterReuse)
        self.tableView.separatorStyle = .singleLine
        tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
            
        } else {
            return sounds.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: MySoundsTableViewCell!
        
        if indexPath.section == 0 {
            cell = self.tableView.dequeueReusableCell(withIdentifier: playFilterReuse) as? MySoundsTableViewCell
            
        } else {
            cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as? MySoundsTableViewCell
            
            let sound = sounds[indexPath.row]
            
            cell.menuButton.addTarget(self, action: #selector(self.didPressMenuButton(_:)), for: .touchUpInside)
            cell.menuButton.tag = indexPath.row
            
            cell.soundArtImage.kf.setImage(with: URL(string: sound.artURL))
            cell.soundTitle.text = sound.title
            
            if let plays = sound.plays {
                cell.soundPlays.text = "\(plays)"
                
            } else {
                cell.soundPlays.text = "0"
            }
            
            if let artistName = sound.artistName {
                cell.soundArtist.text = artistName
                
            } else {
                loadArtist(cell, userId: sound.userId, row: indexPath.row)
            }
        }
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    //mark: button actions
    @objc func didPressMenuButton(_ sender: UIButton) {
        let row = sender.tag
        let sound = sounds[sender.tag]
        
        let menuAlert = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
        menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if sound.userId == PFUser.current()!.objectId! {
            menuAlert.addAction(UIAlertAction(title: "Delete Sound", style: .default, handler: { action in
                self.deleteSong(sound.objectId, row: row)
            }))
            
            menuAlert.addAction(UIAlertAction(title: "Edit Sound", style: .default, handler: { action in
                //TODO
            }))
            
        } else {
            menuAlert.addAction(UIAlertAction(title: "Unlike Sound", style: .default, handler: { action in
                self.unlikeSound(sound.objectId, row: row)
            }))
        }
        
        self.present(menuAlert, animated: true, completion: nil)
    }
    
    @objc func didPressUploadSoundButton(_ sender: UIButton) {
        tabBarController?.selectedIndex = 1
    }
    
    //mark: data
    func unlikeSound(_ objectId: String, row: Int) {
        let query = PFQuery(className: "Like")
        query.whereKey("postId", equalTo: objectId)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                object.deleteInBackground {
                    (success: Bool, error: Error?) in
                    if (success) {
                        self.sounds.remove(at: row)
                        self.tableView.reloadData()
                        
                    } else if let error = error {
                        UIElement().showAlert("Oops", message: error.localizedDescription, target: self)
                    }
                }
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
                    self.showNoSoundsHereYetUI()
                    
                } else {
                    self.loadSounds()
                }
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func loadSounds() {
        let query = PFQuery(className: "Post")
    
        if let soundType = self.soundType {
            if soundType == "Likes" {
                query.whereKey("objectId", containedIn: likedSoundsIds)
            } else {
                query.whereKey("userId", equalTo: PFUser.current()!.objectId!)
            }
        } else {
            query.addDescendingOrder("createdAt")
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
                        self.sounds.append(sound)
                    }
                }
                
                if objects?.count == 0 {
                    self.showNoSoundsHereYetUI()
                    
                } else {
                    self.setUpTableView()
                }
                
            } else {
                print("Error: \(error!)")
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
                self.sounds[row].artistName = artistName
                
                let artistCity = user["city"] as? String
                self.sounds[row].artistCity = artistCity!
        
                //self.tableView.reloadData()
            }
        }
    }
    
    func deleteSong(_ objectId: String, row: Int) {
        let query = PFQuery(className:"Post")
        query.getObjectInBackground(withId: objectId) {
            (post: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let post = post {
                post.deleteInBackground {
                    (success: Bool, error: Error?) in
                    if (success) {
                        self.sounds.remove(at: row)
                        self.tableView.reloadData()
                        
                    } else if let error = error {
                        UIElement().showAlert("Oops", message: error.localizedDescription, target: self)
                    }
                }
            }
        }
    }
}

//
//  SearchSoundsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 1/28/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//TODO: Automatic loading of more sounds as the user scrolls

import UIKit
import Parse
import Kingfisher
import SnapKit

class SoundListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let uiElement = UIElement()
    let color = Color()
    
    var sounds = [Sound]()
    var likedSoundIds = [String]()
    var soundTitle: String?
    var userId: String?
    var soundType = "search"
    var soundDescendingOrder = "createdAt"
    var soundDescendingOrderKey = "soundDescendingOrder"
    
    var popularRecentButton: UIBarButtonItem!
    var filterButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTitle()
        determineTypeOfSoundToLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        /*let installation = PFInstallation.current()
         installation?.badge = 0
         installation?.saveInBackground()*/
    }
    
    func setTitle() {
        if let title = self.soundTitle {
            self.title = title
        }
    }
    
    func determineTypeOfSoundToLoad() {
        if let soundDescendingOrder = uiElement.getUserDefault(self.soundDescendingOrderKey) as? String {
            self.soundDescendingOrder = soundDescendingOrder
            if soundDescendingOrder == "createdAt" {
                self.setUpNavigationViews("recent")
                
            } else {
                self.setUpNavigationViews("popular")
            }
            
        } else {
            self.setUpNavigationViews("recent")
        }
        
        switch soundType {
        case "search":
            loadSounds(soundDescendingOrder, containedIn: nil, userId: nil)
            break
            
        case "uploads":
            loadSounds(soundDescendingOrder, containedIn: nil, userId: userId!)
            break
            
        case "likes":
            self.loadLikes()
            break
            
        default:
            break
        }
    }
    
    func setUpNavigationViews(_ popularRecentButtonImage: String) {
        filterButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(didPressFilterbutton(_:)))
        
        popularRecentButton = UIBarButtonItem(image: UIImage(named: popularRecentButtonImage), style: .plain, target: self, action: #selector(didPressSoundPopularRecentButton(_:)))
        
        self.navigationItem.rightBarButtonItems = [filterButton, popularRecentButton]
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
        self.tableView.separatorStyle = .singleLine
        tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sounds.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! MySoundsTableViewCell
        
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
        
        if let artist = sound.artist?.name {
            cell.soundArtist.text = artist
            
        } else {
            loadArtist(cell, userId: sound.artist!.objectId, row: indexPath.row)
        }
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    //mark: button actions
    @objc func didPressFilterbutton(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "showTags", sender: self)
    }
    
    @objc func didPressSoundPopularRecentButton(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController (title: "Search Sounds By", message: nil, preferredStyle: .actionSheet)
        
        if self.soundDescendingOrder == "createdAt" {
            let popularAction = UIAlertAction(title: "Popular", style: .default) { (_) -> Void in
                self.sounds.removeAll()
                self.loadSounds("plays", containedIn: nil, userId: nil)
                self.uiElement.setUserDefault(self.soundDescendingOrderKey, value: "plays")
                self.popularRecentButton.image = UIImage(named: "popular")
                self.soundDescendingOrder = "popular"
            }
            
            alertController.addAction(popularAction)
            
        } else {
            let mostRecentAction = UIAlertAction(title: "Most Recent", style: .default) { (_) -> Void in
                self.sounds.removeAll()
                self.loadSounds("createdAt", containedIn: nil, userId: nil)
                self.uiElement.setUserDefault(self.soundDescendingOrderKey, value: "createdAt")
                self.popularRecentButton.image = UIImage(named: "recent")
                self.soundDescendingOrder = "createdAt"
            }
            alertController.addAction(mostRecentAction)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func didPressMenuButton(_ sender: UIButton) {
        let row = sender.tag
        let sound = sounds[sender.tag]
        
        let menuAlert = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
        menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        /*if sound.userId == PFUser.current()!.objectId! {
            menuAlert.addAction(UIAlertAction(title: "Delete Sound", style: .default, handler: { action in
                self.deleteSong(sound.objectId, row: row)
            }))
            
            menuAlert.addAction(UIAlertAction(title: "Edit Sound Info", style: .default, handler: { action in
                //TODO
            }))
            
            menuAlert.addAction(UIAlertAction(title: "Edit Sound Audio", style: .default, handler: { action in
                //TODO
            }))
            
        } else {
            menuAlert.addAction(UIAlertAction(title: "Unlike Sound", style: .default, handler: { action in
                self.unlikeSound(sound.objectId, row: row)
            }))
        }*/
        
        self.present(menuAlert, animated: true, completion: nil)
    }
    
    @objc func didPressUploadSoundButton(_ sender: UIButton) {
        tabBarController?.selectedIndex = 1
    }
    
    //mark: data
    func loadLikes() {
        let query = PFQuery(className: "Like")
        query.whereKey("userId", equalTo: userId!)
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        self.likedSoundIds.append(object["postId"] as! String)
                    }
                }
                
                self.loadSounds(self.soundDescendingOrder, containedIn: self.likedSoundIds, userId: nil)
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func loadSounds(_ descendingOrder: String, containedIn: Array<String>?, userId: String?) {
        let query = PFQuery(className: "Post")
        if let containedIn = containedIn {
            query.whereKey("objectId", containedIn: containedIn)
        }
        if let userId = userId {
            query.whereKey("userId", equalTo: userId)
        }
        query.addDescendingOrder(descendingOrder)
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
                        
                        let sound = Sound(objectId: object.objectId, title: title, artURL: art.url!, artImage: nil, tags: tags, createdAt: object.createdAt!, plays: soundPlays, audio: audio, audioURL: audio.url!, relevancyScore: 0, audioData: nil, artist: nil)
                        
                        let artist = Artist(objectId: userId, name: nil, city: nil, image: nil)
                        sound.artist = artist 
                        self.sounds.append(sound)
                    }
                }
                
                self.setUpTableView()
                
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
                let artistCity = user["city"] as? String
                
                cell.soundArtist.text = artistName!
                
                let artist = Artist(objectId: user.objectId, name: artistName, city: artistCity, image: nil)
                self.sounds[row].artist = artist
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
}

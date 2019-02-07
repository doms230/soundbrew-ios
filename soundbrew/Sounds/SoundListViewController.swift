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
import DeckTransition

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
    
    var tags: Array<String>?
    
    func showPlayerViewController() {
        let modal = PlayerV2ViewController()
        modal.player = self.player
        let transitionDelegate = DeckTransitioningDelegate()
        modal.transitioningDelegate = transitionDelegate
        modal.modalPresentationStyle = .custom
        present(modal, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTitle()
    }
    
    /*override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController: PlayerV2ViewController = segue.destination as! PlayerV2ViewController
        viewController.player = self.player
    }*/
    
    override func viewDidAppear(_ animated: Bool) {
        /*let installation = PFInstallation.current()
         installation?.badge = 0
         installation?.saveInBackground()*/
        
        if let tags = UserDefaults.standard.stringArray(forKey: "tags") {
            if tags.count == 0 {
                self.tags = nil
                
            } else {
                self.tags = tags
            }
        }
        
        self.sounds.removeAll()
        determineTypeOfSoundToLoad()
    }
    
    //mark: mini player
    var player: Player?
    var miniPlayerView: MiniPlayerView!
    
    func setUpMiniPlayer() {
        if let tabBarView = self.tabBarController?.view {            
            miniPlayerView = MiniPlayerView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            miniPlayerView.player = self.player
            tabBarView.addSubview(miniPlayerView)
            let slide = UISwipeGestureRecognizer(target: self, action: #selector(self.miniPlayerWasSwiped))
            slide.direction = .up
            miniPlayerView.addGestureRecognizer(slide)
            miniPlayerView.addTarget(self, action: #selector(self.miniPlayerWasPressed(_:)), for: .touchUpInside)
            
            miniPlayerView.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(45)
                make.right.equalTo(tabBarView)
                make.left.equalTo(tabBarView)
                make.bottom.equalTo(tabBarView).offset(-48)
            }
            
            if let player = self.player?.player {
                if player.isPlaying {
                    miniPlayerView.playBackButton.setImage(UIImage(named: "pause_white"), for: .normal)
                    
                } else {
                    miniPlayerView.playBackButton.setImage(UIImage(named: "play_white"), for: .normal)
                }
                miniPlayerView.playBackButton.isEnabled = true
            }
        }
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
            loadSounds(soundDescendingOrder, containedIn: nil, userId: nil, tags: tags)
            break
            
        case "uploads":
            loadSounds(soundDescendingOrder, containedIn: nil, userId: userId!, tags: tags)
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
        //tableView.frame = view.bounds
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.miniPlayerView.snp.top)
        }
    }
    
    func changeArtistSongColor(_ cell: MySoundsTableViewCell, color: UIColor, playIconName: String) {
        cell.soundTitle.textColor = color
        cell.soundArtist.textColor = color
        cell.soundPlays.textColor = color
        cell.soundPlaysImage.image = UIImage(named: playIconName)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sounds.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let player = player {
            player.didSelectSoundAt(indexPath.row)
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! MySoundsTableViewCell
        
        let sound = sounds[indexPath.row]
        if let player = self.player {
            if player.sounds[player.currentSoundIndex].objectId == sound.objectId {
                changeArtistSongColor(cell, color: color.blue(), playIconName: "playIcon_blue")
                
            } else {
                changeArtistSongColor(cell, color: color.black(), playIconName: "playIcon")
            }
            
        } else {
            changeArtistSongColor(cell, color: color.black(), playIconName: "playIcon")
        }
        
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
    @objc func miniPlayerWasSwiped() {
        showPlayerViewController()
    }
    
    @objc func miniPlayerWasPressed(_ sender: UIButton) {
        showPlayerViewController()
    }
    
    @objc func didPressFilterbutton(_ sender: UIBarButtonItem) {
        //self.performSegue(withIdentifier: "showTags", sender: self)
        let modal = TagsViewController()
        modal.modalPresentationStyle = .formSheet
        present(modal, animated: true, completion: nil)
    }
    
    @objc func didPressSoundPopularRecentButton(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController (title: "Search Sounds By", message: nil, preferredStyle: .actionSheet)
        
        if self.soundDescendingOrder == "createdAt" {
            let popularAction = UIAlertAction(title: "Popular", style: .default) { (_) -> Void in
                self.sounds.removeAll()
                self.loadSounds("plays", containedIn: nil, userId: nil, tags: self.tags)
                self.uiElement.setUserDefault(self.soundDescendingOrderKey, value: "plays")
                self.popularRecentButton.image = UIImage(named: "popular")
                self.soundDescendingOrder = "popular"
            }
            
            alertController.addAction(popularAction)
            
        } else {
            let mostRecentAction = UIAlertAction(title: "Most Recent", style: .default) { (_) -> Void in
                self.sounds.removeAll()
                self.loadSounds("createdAt", containedIn: nil, userId: nil, tags: self.tags)
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
        
        if sound.artist!.objectId == PFUser.current()!.objectId! {
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
        }
        
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
                
                self.loadSounds(self.soundDescendingOrder, containedIn: self.likedSoundIds, userId: nil, tags: nil)
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func loadSounds(_ descendingOrder: String, containedIn: Array<String>?, userId: String?, tags: Array<String>?) {
        let query = PFQuery(className: "Post")
        if let containedIn = containedIn {
            query.whereKey("objectId", containedIn: containedIn)
        }
        if let userId = userId {
            query.whereKey("userId", equalTo: userId)
        }
        if let tags = tags {
            query.whereKey("tags", containedIn: tags)
        }
        query.addDescendingOrder(descendingOrder)
        query.limit = 100
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
                        let sound = Sound(objectId: object.objectId, title: title, artURL: art.url!, artImage: nil, artFile: art, tags: tags, createdAt: object.createdAt!, plays: soundPlays, audio: audio, audioURL: audio.url!, relevancyScore: 0, audioData: nil, artist: artist)
                        
                        self.sounds.append(sound)
                    }
                }
                
                if self.tableView == nil {
                    self.player = Player(sounds: self.sounds)
                    self.setUpMiniPlayer()
                    self.setUpTableView()
                    
                } else {
                    if let player = self.player {
                        player.sounds = self.sounds
                    }
                    self.tableView.reloadData()
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
                let artistCity = user["city"] as? String
                
                var isArtistVerified: Bool?
                if let verified = user["artistVerified"] as? Bool {
                    isArtistVerified = verified
                }
                cell.soundArtist.text = artistName!
                
                let artist = Artist(objectId: user.objectId, name: artistName, city: artistCity, image: nil, isVerified: isArtistVerified)
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


//
//  SearchSoundsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 1/28/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//  MARK: Data, tableview, player, tags, button actions
//TODO: Automatic loading of more sounds as the user scrolls

import UIKit
import Parse
import Kingfisher
import SnapKit
import DeckTransition

class SoundListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TagDelegate, PlayerDelegate {

    let uiElement = UIElement()
    let color = Color()
    
    var sounds = [Sound]()
    var likedSoundIds = [String]()
    var soundTitle: String?
    var userId: String?
    var soundType = "search"
    var soundFilter: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpFilterButton()
        determineTypeOfSoundToLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfile" {
            let viewController = segue.destination as! ProfileViewController
            viewController.artist = selectedArtist
            
        } else if segue.identifier == "showTags" {
            let viewController = segue.destination as! TagsViewController
            viewController.tagDelegate = self 
            if let tags = self.tags {
                viewController.chosenTagsArray = tags
            }
        }
    }
    
    //mark: tags
    var tags: Array<String>?
    var filterButton: UIBarButtonItem!
    
    func changeTags(_ value: Array<String>?) {
        if self.tags != value {
            self.tags = value
            self.sounds.removeAll()
            determineTypeOfSoundToLoad()
            if let value = value {
                if value.count > 1 {
                    filterButton.title! = "\(value.count) Filters"
                    
                } else {
                    filterButton.title! = "\(value.count) Filter"
                }
            }
            
        } else {
            filterButton.title! = "Filter"
            if let filter = self.uiElement.getUserDefault("filter") as? String {
                if self.soundFilter != filter {
                    self.sounds.removeAll()
                    determineTypeOfSoundToLoad()
                }
            }
        }
    }
    
    @objc func didpressFilterButton(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "showTags", sender: self)
    }
    
    func setUpFilterButton() {
        filterButton = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(self.didpressFilterButton(_:)))
        self.navigationItem.rightBarButtonItem = filterButton
    }
    
    //mark: player
    var player: Player?
    var miniPlayerView: MiniPlayerView!
    var selectedArtist: Artist!
    
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
                make.height.equalTo(55)
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
    
    @objc func miniPlayerWasSwiped() {
        showPlayerViewController()
    }
    
    @objc func miniPlayerWasPressed(_ sender: UIButton) {
        showPlayerViewController()
    }
    
    func showPlayerViewController() {
        let modal = PlayerV2ViewController()
        modal.player = self.player
        modal.playerDelegate = self 
        let transitionDelegate = DeckTransitioningDelegate()
        modal.transitioningDelegate = transitionDelegate
        modal.modalPresentationStyle = .custom
        present(modal, animated: true, completion: nil)
    }
    
    func selectedArtist(_ artist: Artist?) {
        if let selectedArtist = artist {
            self.selectedArtist = selectedArtist
            self.performSegue(withIdentifier: "showProfile", sender: self)
        }
    }
    
    func setUpSound(_ indexPath: IndexPath) {
        let sound = sounds[indexPath.row]
        if let currentSoundPlaying = self.miniPlayerView.sound {
            if currentSoundPlaying.objectId == sound.objectId {
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
    }

    func determineTypeOfSoundToLoad() {
        var descendingOrder: String!
        if let filter = self.uiElement.getUserDefault("filter") as? String {
            if filter == "recent" {
                descendingOrder = "createdAt"
                self.soundFilter = "recent"
                
            } else {
                descendingOrder = "plays"
                self.soundFilter = "popular"
            }
            
        } else {
            descendingOrder = "createdAt"
            self.soundFilter = "recent"
        }
        
        switch soundType {
        case "search":
            loadSounds(descendingOrder, containedIn: nil, userId: nil, tags: tags)
            break
            
        case "uploads":
            loadSounds(descendingOrder, containedIn: nil, userId: userId!, tags: tags)
            break
            
        case "likes":
            self.loadLikes(descendingOrder)
            break
            
        default:
            break
        }
    }
    
    //mark: tableview
    var tableView: UITableView!
    var cell: SoundListTableViewCell!
    
    let reuse = "reuse"
    let playFilterReuse = "playFilterReuse"
    let recentPopularReuse = "recentPopularReuse"
    let filterTagsReuse = "filterTagsReuse"
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: reuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: recentPopularReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: filterTagsReuse)
        self.tableView.separatorStyle = .singleLine
        //tableView.frame = view.bounds
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.miniPlayerView.snp.top)
        }
        
        if let player = self.player {
            player.tableview = self.tableView
        }
    }
    
    func changeArtistSongColor(_ cell: SoundListTableViewCell, color: UIColor, playIconName: String) {
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
        cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as? SoundListTableViewCell
        setUpSound(indexPath)
        cell.selectionStyle = .none
        return cell
    }
    
    //mark: button actions
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
    
    //mark: data
    func loadLikes(_ descendingOrder: String) {
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
                
                self.loadSounds(descendingOrder, containedIn: self.likedSoundIds, userId: nil, tags: nil)
                
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
                        
                        let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: "", website: "", bio: "", email: "")
                        let sound = Sound(objectId: object.objectId, title: title, artURL: art.url!, artImage: nil, artFile: art, tags: tags, createdAt: object.createdAt!, plays: soundPlays, audio: audio, audioURL: audio.url!, relevancyScore: 0, audioData: nil, artist: artist, isLiked: nil)
                        
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
    
    func loadArtist(_ cell: SoundListTableViewCell, userId: String, row: Int) {
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
                
                let artist = Artist(objectId: user.objectId, name: artistName, city: artistCity, image: nil, isVerified: isArtistVerified, username: "", website: "", bio: "", email: "")
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


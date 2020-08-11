//
//  SearchSoundsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 1/28/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//  MARK: Data, tableview, player, tags, button actions, tableview, tags

import UIKit
import Parse
import Kingfisher
import SnapKit
import AppCenterCrashes

class SoundsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, PlayerDelegate, TagDelegate, UISearchBarDelegate, UITabBarControllerDelegate {
    
    var soundList: SoundList!
    let uiElement = UIElement()
    let color = Color()
    var soundType = "forYou"
    var playlist: Playlist?
    
    func doesMatchSoundType() -> Bool {
        if soundType == "follow" || soundType ==  "forYou" {
            return true
        }
        return false
    }
    var userId: String?
    var isNewUser: Bool?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = .black
        navigationController?.navigationBar.tintColor = .white
        
        if doesMatchSoundType() {
            self.setUpMiniPlayer()
            createTopView()
            
            if PFUser.current() != nil {
                let changeSoundTypeButton = UIBarButtonItem(image: UIImage(named: "dismiss_nav"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.didPressSoundTypeButton(_:)))
                
                self.navigationItem.rightBarButtonItem = changeSoundTypeButton
            }
            
        } else {
            self.setUpTableView()
            if soundType == "playlist", let playlist = self.playlist, playlist.objectId != nil {
                let shuffleButton = UIBarButtonItem(image: UIImage(named: "shuffle"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.didPressShuffleButton(_:)))
                
                let shareButton = UIBarButtonItem(image: UIImage(named: "share_small"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.didPressSharePlaylistButton(_:)))
                
                if  let currentUserId = PFUser.current()?.objectId, playlist.artist?.objectId == currentUserId {
                    let addSoundsToPlaylistButton = UIBarButtonItem(image: UIImage(named: "new_nav"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.didPressAddSoundsToPlaylistButton(_:)))
                    self.navigationItem.rightBarButtonItems = [addSoundsToPlaylistButton, shuffleButton, shareButton]
                    
                } else {
                    self.navigationItem.rightBarButtonItems = [shuffleButton, shareButton]
                }
            }
        }
        setupNotificationCenter()
    }
    
    override func didReceiveMemoryWarning() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    
   @objc func didPressSoundTypeButton(_ sender: UIButton) {
        let alertController = UIAlertController (title: "Show My", message: "", preferredStyle: .actionSheet)
    
        let followingAction = UIAlertAction(title: "Following", style: .default) { (_) -> Void in
            self.soundType = "follow"
            self.createTopView()
            self.showSoundList()
        }
        alertController.addAction(followingAction)
    
        let forYouAction = UIAlertAction(title: "For You", style: .default) { (_) -> Void in
            self.soundType = "forYou"
            self.createTopView()
            self.showSoundList()
        }
        alertController.addAction(forYouAction)
    
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
    
        if soundType == "follow" {
            followingAction.isEnabled = false
        } else {
            forYouAction.isEnabled = false
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tabBarController?.delegate = self
        setMiniPlayer()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showProfile":
            soundList.prepareToShowSelectedArtist(segue)
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
            break
            
        case "showSounds":
            var viewController: SoundsViewController
            if let navigationController = segue.destination as? UINavigationController {
                viewController = navigationController.topViewController as! SoundsViewController
            } else {
                viewController = segue.destination as! SoundsViewController
            }            
            
            viewController.selectedTagForFiltering = self.selectedTagFromPlayerView
            viewController.soundType = "discover"
            
            let backItem = UIBarButtonItem()
            backItem.title = self.selectedTagFromPlayerView.name
            navigationItem.backBarButtonItem = backItem
            break
            
        case "showSearch":
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
            
            let viewController = segue.destination as! SearchViewController
            viewController.playlist = playlist
            break
            
        default:
            break
        }
    }
    
    @objc func didPressShuffleButton(_ sender: UIBarButtonItem) {
        if soundList != nil {
            soundList.sounds.shuffle()
            let player = Player.sharedInstance
            player.sounds = soundList.sounds
            player.currentSoundIndex = -1
            if self.tableView != nil {self.tableView.reloadData()}
        }
    }
    
    @objc func didPressSharePlaylistButton(_ sender: UIBarButtonItem) {
        self.uiElement.createDynamicLink(nil, artist: nil, playlist: self.playlist, target: self)
    }
    
    @objc func didPressAddSoundsToPlaylistButton(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "showSearch", sender: self)
    }
    
    func checkForDefaultValue() {
        if let soundId = self.uiElement.getUserDefault("newSoundId") as? String {
            UserDefaults.standard.removeObject(forKey: "newSoundId")
            loadDynamicLinkSound(soundId, shouldShowShareSoundView: true, shouldPlay: true)
        } else {
            //loadLastListen()
        }
       /* if let soundId = self.uiElement.getUserDefault("receivedSoundId") as? String {
            UserDefaults.standard.removeObject(forKey: "receivedSoundId")
            loadDynamicLinkSound(soundId, shouldShowShareSoundView: false, shouldPlay: true)
        } else if let soundId = self.uiElement.getUserDefault("newSoundId") as? String {
            UserDefaults.standard.removeObject(forKey: "newSoundId")
            loadDynamicLinkSound(soundId, shouldShowShareSoundView: true, shouldPlay: true)
        } else {
            self.loadLastListen()
        }
        
        if self.uiElement.getUserDefault("receivedUserId") != nil {
            self.performSegue(withIdentifier: "showProfile", sender: self)
        } else if self.uiElement.getUserDefault("receivedUsername") != nil {
            self.performSegue(withIdentifier: "showProfile", sender: self)
        }*/
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if self.tableView != nil {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
    
    func setupNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSoundUpdate), name: NSNotification.Name(rawValue: "setSound"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveFriendsLoaded), name: NSNotification.Name(rawValue: "friendsLoaded"), object: nil)
    }
    
    @objc func didReceiveSoundUpdate(){
        //need to update current sound as playing on soundlist .. turns blue 
        if self.tableView != nil {
            self.tableView.reloadData()
        }
    }
    
    @objc func didReceiveFriendsLoaded() {
        showSoundList()
    }
    
    func showSoundList() {
        soundList = SoundList(target: self, tableView: tableView, soundType: soundType, userId: userId, tags: selectedTagForFiltering, searchText: nil, descendingOrder: "createdAt", linkObjectId: nil, playlist: playlist)
    }
    
    //mark: Page Title
    func createTopView() {
        var soundTypeTitle = "Following"
        if soundType == "forYou" {
            soundTypeTitle = "For You"
        }
        self.uiElement.addTitleView(soundTypeTitle, target: self)
    }
    
    @objc func didPressSearchButton(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "showSearch", sender: self)
    }
        
    //mark: tableview
    var tableView: UITableView!
    let soundReuse = "soundReuse"
    let noSoundsReuse = "noSoundsReuse"
    func setUpTableView() {
        let miniPlayerHeight = MiniPlayerView.sharedInstance.frame.height
        var tabBarControllerHeight: CGFloat = 50
        if let tabBar = self.tabBarController?.tabBar {
            tabBarControllerHeight = tabBar.frame.height
        }

        self.tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        tableView.backgroundColor = color.black()
        tableView.isOpaque = true
        self.tableView.separatorStyle = .none
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl
        refreshControl.endRefreshing()
        self.view.addSubview(tableView)
        self.tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-(miniPlayerHeight + tabBarControllerHeight))
        }
        
        showSoundList()
        if self.soundType == "forYou" {
            soundList.shouldPlaySoundsForYouPage = true
        }

        let player = Player.sharedInstance
        player.tableView = tableView
    }
    
    @objc func refresh(_ sender: UIRefreshControl) {
       showSoundList()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsInSectionSoundList()
    }
    
    func numberOfRowsInSectionSoundList() -> Int {
        if soundList != nil, soundList.sounds.count != 0 {
            return soundList.sounds.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellForRowAtSoundList(indexPath, tableView: tableView)
    }
    
    func cellForRowAtSoundList(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        if soundList.sounds.count == 0 {
            return noSoundCell()
        } else {
            return soundList.soundCell(indexPath, tableView: tableView, reuse: soundReuse)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let player = soundList.player
        player.sounds = soundList.sounds
        player.didSelectSoundAt(indexPath.row)
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == soundList.sounds.count - 10 && !soundList.isUpdatingData && soundList.thereIsMoreDataToLoad {
            soundList.determineTypeOfSoundToLoad(soundType)
        }
    }
    
    func noSoundCell() -> SoundListTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
        cell.backgroundColor = color.black()
        if soundList.isUpdatingData {
            cell.headerTitle.text = ""
            cell.artistButton.isHidden = true
        } else  if soundType == "follow" {
            cell.headerTitle.text = "Follow your favorite artists to keep up with their latest uploads!"
            cell.artistButton.setTitle("Discover Sounds", for: .normal)
            cell.artistButton.addTarget(self, action: #selector(self.didPressDiscoverButton(_:)), for: .touchUpInside)
            cell.artistButton.isHidden = false 
        } else if selectedTagForFiltering != nil {
            let localizedNoResultsFor = NSLocalizedString("noResultsFor", comment: "")
            cell.headerTitle.text = "\(localizedNoResultsFor) \(selectedTagForFiltering.name!)"
            cell.artistButton.isHidden = true
        } else if soundType == "playlist" {
            cell.headerTitle.text = "Tap the menu button at the top right corner to add sounds to this playlist!"
            cell.artistButton.isHidden = true
        } else if soundType == "uploads" {
            cell.headerTitle.text = "No Uploads Yet."
            cell.artistButton.isHidden = true
        } else if soundType == "collection" {
            cell.headerTitle.text = "No Likes Yet."
            cell.artistButton.isHidden = true
        }
        
        return cell
    }
    
    @objc func didPressDiscoverButton(_ sender: UIButton) {
        self.soundType = "forYou"
        self.createTopView()
        self.showSoundList()
    }
    
    //mark: miniPlayer
    func setMiniPlayer() {
        let miniPlayerView = MiniPlayerView.sharedInstance
        miniPlayerView.superViewController = self
        miniPlayerView.tagDelegate = self
        miniPlayerView.playerDelegate = self
    }
    
    func setUpMiniPlayer() {
    let miniPlayerView = MiniPlayerView.sharedInstance
        if let tabBarController = self.tabBarController, !tabBarController.tabBar.subviews.contains(miniPlayerView) {
            tabBarController.view.addSubview(miniPlayerView)
            miniPlayerView.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(75)
                make.right.equalTo(tabBarController.tabBar)
                make.left.equalTo(tabBarController.tabBar)
                make.bottom.equalTo(tabBarController.tabBar.snp.top)
            }
        }
       // self.loadLastListen()
        checkForDefaultValue()
        setUpTableView()
    }
    
    //mark: selectedArtist
    func selectedArtist(_ artist: Artist?) {
        if let artist = artist {
            switch artist.objectId {
            case "addFunds":
                self.performSegue(withIdentifier: "showAddFunds", sender: self)
                break
                
            case "signup":
                self.performSegue(withIdentifier: "showWelcome", sender: self)
                break
                
            case "collectors":
                self.performSegue(withIdentifier: "showTippers", sender: self)
                break
                
            case "comments":
                self.performSegue(withIdentifier: "showComments", sender: self)
                break
                
            default:
                soundList.selectedArtist(artist)
                break
            }
        }
    }
    
    /*func loadLastListen() {
        if let currentUserId = PFUser.current()?.objectId {
            let query = PFQuery(className: "Listen")
            query.whereKey("userId", equalTo: currentUserId)
            query.addDescendingOrder("updatedAt")
            query.cachePolicy = .networkElseCache
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if let object = object {
                    if let soundId = object["postId"] as? String {
                        self.loadDynamicLinkSound(soundId, shouldShowShareSoundView: false, shouldPlay: false)
                    }
                }
            }
        }
    }*/
    
    func loadDynamicLinkSound(_ objectId: String?, shouldShowShareSoundView: Bool, shouldPlay: Bool) {
        let query = PFQuery(className: "Post")
        if let objectId = objectId {
            query.whereKey("objectId", equalTo: objectId)
            query.addDescendingOrder("updatedAt")
        } else {
            query.whereKey("isFeatured", equalTo: true)
            query.addDescendingOrder("tippers")
        }
        query.whereKey("isRemoved", notEqualTo: true)
        query.cachePolicy = .networkElseCache
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if let object = object {
                let sound = self.uiElement.newSoundObject(object)
                if shouldShowShareSoundView {
                    self.uiElement.showShareOptions(self, sound: sound)
                }
                self.resetPlayer(sounds: [sound], shouldPlay: shouldPlay)
            }
        }
    }
    
    func resetPlayer(sounds: [Sound], shouldPlay: Bool) {
        let player = Player.sharedInstance
        player.sounds = sounds
        player.currentSoundIndex = 0
        player.setUpNextSong(false, at: 0, shouldPlay: shouldPlay, selectedSound: sounds[0])
    }
        
    //mark: tags
    var selectedTagForFiltering: Tag!
    var selectedTagFromPlayerView: Tag!
    func receivedTags(_ chosenTags: Array<Tag>?) {
        if let tags = chosenTags {
            self.selectedTagFromPlayerView = tags[0]
            self.performSegue(withIdentifier: "showSounds", sender: self)
        }
    }
}


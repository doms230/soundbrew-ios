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
    var soundType = "follow"
    func doesMatchSoundType() -> Bool {
        if soundType == "follow" || soundType ==  "forYou" {
            return true
        }
        return false
    }
    var userId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpMiniPlayer()

        self.view.backgroundColor = color.black()
        setupNotificationCenter()
        
        if doesMatchSoundType() {
            if let selectedIndex = self.tabBarController?.selectedIndex {
                if selectedIndex == 1 {
                    self.soundType = "forYou"
                }
            }
            createTopView()
        } else {
            showSoundList()
        }
        
        if let soundId = self.uiElement.getUserDefault("receivedSoundId") as? String {
            UserDefaults.standard.removeObject(forKey: "receivedSoundId")
            loadDynamicLinkSound(soundId, shouldShowShareSoundView: false)
        } else if let soundId = self.uiElement.getUserDefault("newSoundId") as? String {
            UserDefaults.standard.removeObject(forKey: "newSoundId")
            loadDynamicLinkSound(soundId, shouldShowShareSoundView: true)
        } else if self.uiElement.getUserDefault("receivedUserId") != nil {
            self.performSegue(withIdentifier: "showProfile", sender: self)
        } else if self.uiElement.getUserDefault("receivedUsername") != nil {
            self.performSegue(withIdentifier: "showProfile", sender: self)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tabBarController?.delegate = self
        if tableView == nil {
            setUpTableView()
        } /*else {
            self.tableView.reload
        }*/
        //setUpTableView()
        setMiniPlayer()
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
    
    func setupNotificationCenter() {
      //  NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSoundUpdate), name: NSNotification.Name(rawValue: "setSound"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveFriendsLoaded), name: NSNotification.Name(rawValue: "friendsLoaded"), object: nil)
    }
    
    @objc func didReceiveFriendsLoaded() {
        showSoundList()
    }
    
   /* @objc func didReceiveSoundUpdate(){
        if self.view.window != nil {

        }
    }*/
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showProfile":
            soundList.prepareToShowSelectedArtist(segue)
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
            break
            
        case "showSounds":
            let viewController = segue.destination as! SoundsViewController
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
            break
            
        default:
            break 
        }
    }
    
    func showSoundList() {
        soundList = SoundList(target: self, tableView: tableView, soundType: soundType, userId: userId, tags: selectedTagForFiltering, searchText: nil, descendingOrder: "createdAt", linkObjectId: nil)
    }
    
    //mark: Page Title
    func createTopView() {
        var soundTypeTitle = "Following"
        if soundType == "forYou" {
            soundTypeTitle = "For You"
            let searchUIButton = UIBarButtonItem(image: UIImage(named: "search_filled"), style: .plain, target: self, action: #selector(self.didPressSearchButton(_:)))
            self.navigationItem.rightBarButtonItem = searchUIButton
        }
        
        self.uiElement.addTitleView(soundTypeTitle, target: self)
        showSoundList()
    }
    
    @objc func didPressSearchButton(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "showSearch", sender: self)
    }
        
    //mark: tableview
    var tableView: UITableView!
    let soundReuse = "soundReuse"
    let noSoundsReuse = "noSoundsReuse"
    func setUpTableView() {
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
            make.bottom.equalTo(self.view).offset(-170)
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
        }
        
        return cell
    }
    
    @objc func didPressDiscoverButton(_ sender: UIButton) {
        if let tabBar = self.tabBarController {
            tabBar.selectedIndex = 1
        }
    }
    
    //mark: miniPlayer
    func setMiniPlayer() {
        let miniPlayerView = MiniPlayerView.sharedInstance
        miniPlayerView.superViewController = self
        miniPlayerView.tagDelegate = self
        miniPlayerView.playerDelegate = self
    }
    func setUpMiniPlayer() {
        if let tabBarController = self.tabBarController {
            let miniPlayerView = MiniPlayerView.sharedInstance
            miniPlayerView.superViewController = self
            miniPlayerView.tagDelegate = self
            miniPlayerView.playerDelegate = self
            tabBarController.view.addSubview(miniPlayerView)
            miniPlayerView.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(75)
                make.right.equalTo(tabBarController.tabBar)
                make.left.equalTo(tabBarController.tabBar)
                make.bottom.equalTo(tabBarController.tabBar.snp.top)
            }
        }
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
    
    func loadDynamicLinkSound(_ objectId: String, shouldShowShareSoundView: Bool) {
        let query = PFQuery(className: "Post")
        query.cachePolicy = .networkElseCache
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let object = object {
                let sound = self.uiElement.newSoundObject(object)
                if shouldShowShareSoundView {
                    self.uiElement.showShareOptions(self, sound: sound)
                }
                self.resetPlayer(sounds: [sound])
            }
        }
    }
    
    func resetPlayer(sounds: [Sound]) {
        let player = Player.sharedInstance
        player.player = nil
        player.sounds = sounds
        player.currentSound = sounds[0]
        player.currentSoundIndex = 0
        player.setUpNextSong(false, at: 0)
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


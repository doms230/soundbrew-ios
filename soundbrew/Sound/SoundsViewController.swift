//
//  SearchSoundsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 1/28/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//  MARK: Data, tableview, player, tags, button actions, tableview, tags
//TODO: Automatic loading of more sounds as the user scrolls

import UIKit
import Parse
import Kingfisher
import SnapKit
import AppCenterCrashes

class SoundsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, PlayerDelegate, TagDelegate {
    
    var soundList: SoundList!
    let uiElement = UIElement()
    let color = Color()
    var soundType = "forYou"
    func doesMatchHomeSoundType() -> Bool {
        if soundType == "forYou" || soundType ==  "follow" || soundType ==  "yourCity" {
            return true
        }
        return false
    }
    var userId: String?
    var newUserArtistForEditing: Artist?
    
    lazy var tagsScrollview: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        setupNotificationCenter()
        if doesMatchHomeSoundType() {
            createTopView()
        } else {
            showSounds()
        }
        
        if let soundId = self.uiElement.getUserDefault("receivedSoundId") as? String {
            UserDefaults.standard.removeObject(forKey: "receivedSoundId")
            loadDynamicLinkSound(soundId, shouldShowShareSoundView: false)
        }
        
        if newUserArtistForEditing != nil {
            self.performSegue(withIdentifier: "showEditProfile", sender: self)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let player = Player.sharedInstance
        if player.player != nil {
            setUpMiniPlayer()
        } else {
            setUpTableView(nil)
        }
    }
    
    func setupNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSoundUpdate), name: NSNotification.Name(rawValue: "setSound"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveFriendsLoaded), name: NSNotification.Name(rawValue: "friendsLoaded"), object: nil)
    }
    
    @objc func didReceiveFriendsLoaded() {
        //TODO
    }
    
    @objc func didReceiveSoundUpdate(){
        if self.view.window != nil {
            let player = Player.sharedInstance
            if player.player != nil {
                self.setUpMiniPlayer()
            } else {
                self.setUpTableView(nil)
            }
        }
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
            let viewController = segue.destination as! SoundsViewController
            viewController.selectedTagForFiltering = self.selectedTagFromPlayerView
            viewController.soundType = "discover"
            
            let backItem = UIBarButtonItem()
            backItem.title = self.selectedTagFromPlayerView.name
            navigationItem.backBarButtonItem = backItem
            break
            
        case "showEditProfile":
            let viewController = segue.destination as! EditProfileViewController
            viewController.artist = newUserArtistForEditing
            
            let backItem = UIBarButtonItem()
            backItem.title = "Complete Profile"
            navigationItem.backBarButtonItem = backItem
            break
            
        default:
            break 
        }
    }
    
    func showSounds() {
        soundList = SoundList(target: self, tableView: tableView, soundType: soundType, userId: userId, tags: selectedTagForFiltering, searchText: nil, descendingOrder: "createdAt", linkObjectId: nil)
    }
    
    //mark: feature titles
    var forYouButton: UIButton!
    var followingButton: UIButton!
    func createTopView() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        var leftOffset = 0
        forYouButton = setUpButton("For You", i: 0, leftOffset: leftOffset, view: view)
        leftOffset = leftOffset + 150 + uiElement.leftOffset
        followingButton = setUpButton("Following", i: 1, leftOffset: leftOffset, view: view)
        let leftBarButton = UIBarButtonItem(customView: view)
        self.navigationItem.leftBarButtonItem = leftBarButton
        showSounds()
    }
    
    func setUpButton(_ title: String, i: Int, leftOffset: Int, view: UIView) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 30)
        button.addTarget(self, action: #selector(self.didPressFeaturedButton(_:)), for: .touchUpInside)
        button.tag = i
        if i == 1 {
            button.setTitleColor(.darkGray, for: .normal)
        }
        view.addSubview(button)
        button.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.width.equalTo(150)
            make.top.equalTo(view).offset(uiElement.bottomOffset * 3)
            make.left.equalTo(view).offset(leftOffset)
        }
        return button
    }
    
    @objc func didPressFeaturedButton(_ sender: UIButton) {
        sender.setTitleColor(.white, for: .normal)
        if sender.tag == 0 {
            followingButton.setTitleColor(.darkGray, for: .normal)
            soundType = "forYou"
        } else {
            forYouButton.setTitleColor(.darkGray, for: .normal)
            soundType = "follow"
        }

        soundList.sounds.removeAll()
        self.tableView.refreshControl?.beginRefreshing()
        self.tableView.reloadData()
        showSounds()
    }
        
    //mark: tableview
    var tableView = UITableView()
    let soundReuse = "soundReuse"
    let noSoundsReuse = "noSoundsReuse"
    let soundHeaderReuse = "soundHeaderReuse"
    let storyReuse = "tagsReuse"
    let featuredTitleReuse = "featuredTitleReuse"
    func setUpTableView(_ miniPlayer: UIView?) {
        self.tableView.removeFromSuperview()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundHeaderReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: storyReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: featuredTitleReuse)
        tableView.backgroundColor = color.black()
        self.tableView.separatorStyle = .none
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl
        refreshControl.endRefreshing()
        if let miniPlayer = miniPlayer {
            self.view.addSubview(tableView)
            self.tableView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.view)
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
                make.bottom.equalTo(miniPlayer.snp.top)
            }
           /* if doesMatchHomeSoundType() {
                self.view.addSubview(tableView)
                self.tableView.snp.makeConstraints { (make) -> Void in
                    make.top.equalTo(self.forYouButton.snp.bottom)
                    make.left.equalTo(self.view)
                    make.right.equalTo(self.view)
                    make.bottom.equalTo(miniPlayer.snp.top)
                }
                
            } else {
                self.view.addSubview(tableView)
                self.tableView.snp.makeConstraints { (make) -> Void in
                    make.top.equalTo(self.view)
                    make.left.equalTo(self.view)
                    make.right.equalTo(self.view)
                    make.bottom.equalTo(miniPlayer.snp.top)
                }
            }*/

            
        } else {
            self.view.addSubview(tableView)
            self.tableView.frame = self.view.bounds
            /*if doesMatchHomeSoundType() {
                self.view.addSubview(tableView)
                self.tableView.snp.makeConstraints { (make) -> Void in
                    make.top.equalTo(self.forYouButton.snp.bottom)
                    make.left.equalTo(self.view)
                    make.right.equalTo(self.view)
                    make.bottom.equalTo(self.view)
                }
                
            } else {
                self.view.addSubview(tableView)
                self.tableView.snp.makeConstraints { (make) -> Void in
                    make.top.equalTo(self.view)
                    make.left.equalTo(self.view)
                    make.right.equalTo(self.view)
                    make.bottom.equalTo(self.view)
                }
            }*/
        }
        
        let player = Player.sharedInstance
        player.tableView = tableView
    }
    
    @objc func refresh(_ sender: UIRefreshControl) {
       showSounds()
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
        if doesMatchHomeSoundType() {
            if indexPath.section == 1 {
                didSelectRowAt(indexPath.row)
            }
            
        } else {
            didSelectRowAt(indexPath.row)
        }
    }
    
    func didSelectRowAt(_ row: Int) {
        //TESTING: PLAYER
        let player = soundList.player
        player.sounds = soundList.sounds
        player.didSelectSoundAt(row)
        if miniPlayerView == nil {
            self.setUpMiniPlayer()
        } else {
            self.tableView.reloadData()
        }
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
        } else  if soundType == "follow" {
            //let localizedLatestReleases = NSLocalizedString("latestReleases", comment: "")
            cell.headerTitle.text = "Follow people to keep up with their latest uploads!"
        } else if soundType == "yourCity" {
            cell.headerTitle.text = "Keep up with uploads in your city by adding your city to your profile!"
        } else if selectedTagForFiltering != nil {
            let localizedNoResultsFor = NSLocalizedString("noResultsFor", comment: "")
            cell.headerTitle.text = "\(localizedNoResultsFor) \(selectedTagForFiltering.name!)"
        }
        
        return cell
    }
    
    //mark: miniPlayer
    var miniPlayerView: MiniPlayerView?
    func setUpMiniPlayer() {
        DispatchQueue.main.async {
            self.miniPlayerView?.removeFromSuperview()
            self.miniPlayerView = MiniPlayerView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            if let miniPlayer = self.miniPlayerView {
                self.view.addSubview(miniPlayer)
                let slide = UISwipeGestureRecognizer(target: self, action: #selector(self.miniPlayerWasSwiped))
                slide.direction = .up
                self.miniPlayerView!.addGestureRecognizer(slide)
                self.miniPlayerView!.addTarget(self, action: #selector(self.miniPlayerWasPressed(_:)), for: .touchUpInside)
                self.miniPlayerView!.snp.makeConstraints { (make) -> Void in
                    make.height.equalTo(50)
                    make.right.equalTo(self.view)
                    make.left.equalTo(self.view)
                    make.bottom.equalTo(self.view).offset(-((self.tabBarController?.tabBar.frame.height)!))
                }
                self.setUpTableView(miniPlayer)
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
        let modal = PlayerViewController()
        modal.playerDelegate = self
        modal.tagDelegate = self
        self.present(modal, animated: true, completion: nil)
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
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
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


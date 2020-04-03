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
    var soundType = "chart"
    var userId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        setupNotificationCenter()
        showSounds()
        if soundType == "chart" {
            //self.title = "Soundbrew"
            loadFriendStories()
        }
        
        if let soundId = self.uiElement.getUserDefault("receivedSoundId") as? String {
            UserDefaults.standard.removeObject(forKey: "receivedSoundId")
            loadDynamicLinkSound(soundId, shouldShowShareSoundView: false)
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
        if !didGetInitialFriendsList {
            loadFriendStories()
        }
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
            
        case "showStories":
            let viewController = segue.destination as! HomeViewController
            viewController.stories = self.stories
            break
            
        case "showSounds":
            let viewController = segue.destination as! SoundsViewController
            viewController.selectedTagForFiltering = self.selectedTagFromPlayerView
            viewController.soundType = "discover"
            
            let backItem = UIBarButtonItem()
            backItem.title = self.selectedTagFromPlayerView.name
            navigationItem.backBarButtonItem = backItem
            break
            
        default:
            break 
        }
    }
    
    func showSounds() {
        if soundType == "follow" {
            if let userId = PFUser.current()?.objectId {
                self.userId = userId
            } else {
                self.userId = ""
            }
        }
        soundList = SoundList(target: self, tableView: tableView, soundType: soundType, userId: userId, tags: selectedTagForFiltering, searchText: nil, descendingOrder: "createdAt", linkObjectId: nil)
    }
    
    //mark: tableview
    var tableView = UITableView()
    let soundReuse = "soundReuse"
    let noSoundsReuse = "noSoundsReuse"
    let soundHeaderReuse = "soundHeaderReuse"
    let storyReuse = "tagsReuse"
    let featuredTitleReuse = "featuredTitleReuse"
    func setUpTableView(_ miniPlayer: UIView?) {
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
            
        } else {
            self.tableView.frame = view.bounds
            self.view.addSubview(tableView)
        }
    }
    
    @objc func refresh(_ sender: UIRefreshControl) {
       showSounds()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if soundType == "chart" {
            return 3
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if soundType == "chart" {
            if section == 2 {
               return numberOfRowsInSectionSoundList()
            }
            return 1
            
        } else {
            return numberOfRowsInSectionSoundList()
        }
    }
    
    func numberOfRowsInSectionSoundList() -> Int {
        if soundList != nil, soundList.sounds.count != 0 {
            return soundList.sounds.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if soundType == "chart" {
            if indexPath.section == 0 {
                if stories.count == 0 {
                    return noStoryCell()
                } else {
                    return storyCell()
                }
            } else if indexPath.section == 1 {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: featuredTitleReuse) as! SoundListTableViewCell
                cell.backgroundColor = color.black()
                return cell
                
            } else {
                return cellForRowAtSoundList(indexPath, tableView: tableView)
            }
            
        } else {
            return cellForRowAtSoundList(indexPath, tableView: tableView)
        }
    }
    
    func cellForRowAtSoundList(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        if soundList.sounds.count == 0 {
            return noSoundCell()
            
        } else {
            return soundList.soundCell(indexPath, tableView: tableView, reuse: soundReuse)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRowAt(indexPath.row)
    }
    
    func didSelectRowAt(_ row: Int) {
        //TESTING: PLAYER
        let player = soundList.player
        player.sounds = soundList.sounds
        player.didSelectSoundAt(row)
        if miniPlayerView == nil {
            self.setUpMiniPlayer()
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
            let localizedLoading = NSLocalizedString("loading", comment: "")
            cell.headerTitle.text = localizedLoading
        } else  if soundType == "following" {
            let localizedLatestReleases = NSLocalizedString("latestReleases", comment: "")
            cell.headerTitle.text = localizedLatestReleases
        } else if selectedTagForFiltering != nil {
            let localizedNoResultsFor = NSLocalizedString("noResultsFor", comment: "")
            cell.headerTitle.text = "\(localizedNoResultsFor) \(selectedTagForFiltering.name!)"
        }
        
        return cell
    }
    
    //mark: miniPlayer
    var miniPlayerView: MiniPlayerView?
    func setUpMiniPlayer() {
        miniPlayerView = MiniPlayerView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        if let miniPlayer = self.miniPlayerView {
            self.view.addSubview(miniPlayer)
            let slide = UISwipeGestureRecognizer(target: self, action: #selector(self.miniPlayerWasSwiped))
            slide.direction = .up
            miniPlayerView!.addGestureRecognizer(slide)
            miniPlayerView!.addTarget(self, action: #selector(self.miniPlayerWasPressed(_:)), for: .touchUpInside)
            miniPlayerView!.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(50)
                make.right.equalTo(self.view)
                make.left.equalTo(self.view)
                make.bottom.equalTo(self.view).offset(-((self.tabBarController?.tabBar.frame.height)!))
            }
            
            setUpTableView(miniPlayer)
        }
    }
    
    @objc func miniPlayerWasSwiped() {
        showPlayerViewController()
    }
    
    @objc func miniPlayerWasPressed(_ sender: UIButton) {
        showPlayerViewController()
    }
    
    func showPlayerViewController() {
        let player = Player.sharedInstance
        if player.player != nil {
            let modal = PlayerViewController()
            modal.playerDelegate = self
            modal.tagDelegate = self 
            self.present(modal, animated: true, completion: nil)
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
    
    //mark: Story
    var selectedStory: UIButton?
    var stories = [Story]()
    var didGetInitialFriendsList = false
    func storyCell() -> SoundListTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: storyReuse) as! SoundListTableViewCell
        cell.selectionStyle = .none
        cell.backgroundColor = color.black()
        cell.tagsScrollview.backgroundColor = color.black()
        
        //not using snpakit to set button frame becuase not able to get button width from button title.
        let artistImageViewDiameter = 65
        
        var xPositionForFeatureTags = UIElement().leftOffset
        let scrollview = cell.tagsScrollview
        var iMax = 6
        if stories.count < 6 {
            //some people's stories may be less than 5
            iMax = stories.count
        }
        for i in 0..<iMax {
            var story: Story?
            if i != 5 {
                story = stories[i]
            }
            
            let storyButton = UIButton()
            storyButton.layer.cornerRadius = 3
            storyButton.clipsToBounds = true
            
            let artistImageView = UIImageView()
            artistImageView.layer.cornerRadius = CGFloat(artistImageViewDiameter / 2)
            artistImageView.clipsToBounds = true
            artistImageView.contentMode = .scaleAspectFill
            
            let artistName = self.newLabel(.white)
            let storyType = self.newLabel(.darkGray)
            
            if let story = story {
                if let image = story.artist.image   {
                    artistImageView.kf.setImage(with: URL(string: image), placeholder: UIImage(named: "profile_icon"))
                } else {
                    artistImageView.image = UIImage(named: "profile_icon")
                }
                
                if let username = story.artist.username {
                    artistName.text = username
                } else {
                     artistName.text = "loading"
                    story.artist.loadUserInfoFromCloud(nil, soundCell: nil, commentCell: nil, HomeCollectionCell: nil, artistUsernameLabel: artistName, artistImageButton: artistImageView)
                }
                
                if let type = story.type {
                    storyType.text = "New \(type.capitalized)"
                } else {
                    storyType.text = "New Update"
                }
                
                storyButton.addTarget(self, action: #selector(self.didPressStoryButton), for: .touchUpInside)
                storyButton.tag = i
                
            } else {
                artistImageView.image = UIImage(named: "background")
                artistName.text = "Show More"
                storyType.text = ""
                storyButton.addTarget(self, action: #selector(self.didPressViewMoreStoriesButton), for: .touchUpInside)
            }
            
            scrollview.addSubview(storyButton)
            storyButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(100)
                make.top.equalTo(scrollview)
                make.left.equalTo(scrollview).offset(xPositionForFeatureTags)
            }
            
            storyButton.addSubview(artistImageView)
            artistImageView.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(artistImageViewDiameter)
                make.top.equalTo(storyButton).offset(uiElement.elementOffset)
                make.centerX.equalTo(storyButton)
            }
            
            storyButton.addSubview(artistName)
            artistName.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(artistImageViewDiameter)
                make.top.equalTo(artistImageView.snp.bottom)
                make.centerX.equalTo(storyButton)
            }
            
            storyButton.addSubview(storyType)
            storyType.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(artistImageViewDiameter)
                make.top.equalTo(artistName.snp.bottom)
               // make.centerX.equalTo(storyButton)
                make.left.equalTo(storyButton).offset(uiElement.leftOffset)
                make.right.equalTo(storyButton).offset(uiElement.rightOffset)
            }
            
            xPositionForFeatureTags = xPositionForFeatureTags + 100 + uiElement.leftOffset
            scrollview.contentSize = CGSize(width: xPositionForFeatureTags, height: 100)
        }
                
        return cell
    }
    
    func noStoryCell() -> SoundListTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
        cell.backgroundColor = color.black()
        if didGetInitialFriendsList {
           // cell.headerTitle.text = "Keep up with new uploads, likes, and credits from your friends and favorite artists."
            cell.headerTitle.text = ""
        }
        return cell
    }
    
    func newLabel(_ textColor: UIColor) -> UILabel {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)", size: 12)
        label.textColor = textColor
        label.textAlignment = .center
        return label
    }
    
    @objc func didPressStoryButton(_ sender: UIButton) {
        selectedStory?.setBackgroundImage(UIImage(), for: .normal)
        
        selectedStory = sender
        sender.setBackgroundImage(UIImage(named: "background"), for: .normal)
        
        let story = stories[sender.tag]
        soundList = SoundList(target: self, tableView: nil, soundType: "story", userId: story.artist.objectId, tags: nil, searchText: nil, descendingOrder: "createdAt", linkObjectId: nil)
    }
    
    @objc func didPressViewMoreStoriesButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showStories", sender: self)
    }

    func loadFriendStories() {
        stories.removeAll()
        if let friendUserIds = self.uiElement.getUserDefault("friends") as? [String] {
            didGetInitialFriendsList = true
            let storyObjectIds = self.stories.map {$0.objectId}
            if friendUserIds.count == 0 {
                self.tableView.reloadSections(IndexSet(integersIn: 0...0), with: .none)
            } else {
                for i in 0..<friendUserIds.count {
                    let friendUserId = friendUserIds[i]
                    let query = PFQuery(className: "Story")
                    query.whereKey("userId", equalTo: friendUserId)
                    query.addDescendingOrder("createdAt")
                    query.getFirstObjectInBackground {
                          (object: PFObject?, error: Error?) -> Void in
                        if let object = object, !storyObjectIds.contains(object.objectId) {
                            let friend = Artist(objectId: friendUserId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil)
                             let story = Story(friend, lastUpdated: object.createdAt, type: nil, objectId: object.objectId!)
                             if let type = object["type"] as? String {
                                 story.type = type
                             }
                            self.stories.append(story)
                        }
                        
                        //is last index
                        if i == friendUserIds.count - 1 {
                            self.stories.sort(by: {$0.lastUpdated! > $1.lastUpdated!})
                            self.tableView.reloadSections(IndexSet(integersIn: 0...0), with: .none)
                        }
                    }
                }
            }
        } else {
            self.tableView.reloadSections(IndexSet(integersIn: 0...0), with: .none)
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


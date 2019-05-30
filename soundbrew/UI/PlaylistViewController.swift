//
//  SearchSoundsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 1/28/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//  MARK: Data, tableview, player, tags, button actions
//TODO: Automatic loading of more sounds as the user scrolls
//mark: tableview, navigation, tags

import UIKit
import Parse
import Kingfisher
import SnapKit
import AppCenterCrashes

class PlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var soundList: SoundList!
    var searchSounds = [Sound]()
    var searchUsers = [Artist]()
    var searchTags = [Tag]()
    let uiElement = UIElement()
    let color = Color()
    var playlistType = "discover"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        soundList = SoundList(target: self, tableView: tableView, soundType: "discover", userId: nil, tags: selectedTagsForFiltering, searchText: nil)
        
        setupNavigationItems()
        setUpTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //showSounds(playlistType)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showProfile":
            soundList.prepareToShowSelectedArtist(segue)
            break
            
        case "showTags":
            soundList.prepareToShowTags(segue)
            break
            
        case "showEditSoundInfo":
            soundList.prepareToShowSoundInfo(segue)
            break
            
        case "showUploadSound":
            soundList.prepareToShowSoundAudioUpload(segue)
            break
            
        case "showComments":
            soundList.prepareToShowComments(segue)
            break
            
        default:
            break 
        }
    }
    
    func showSounds(_ soundType: String) {
        self.soundList.sounds.removeAll()
        self.tableView.reloadData()
        
        var tags: Array<Tag>?
        if selectedTagsForFiltering.count != 0 {
            tags = selectedTagsForFiltering
        }
        
        soundList = SoundList(target: self, tableView: tableView, soundType: soundType, userId: PFUser.current()?.objectId, tags: tags, searchText: nil)
    }
    
    //mark: tableview
    var tableView = UITableView()
    let soundReuse = "soundReuse"
    let tagsReuse = "tagsReuse"
    
    func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: tagsReuse)
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if selectedTagsForFiltering.count != 0 {
            return 3
        }
        
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var soundSection = 0
        
        if selectedTagsForFiltering.count != 0 {
            soundSection = 1
        }
        
        if section == soundSection {
            return soundList.sounds.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var soundSection = 0
        
        if selectedTagsForFiltering.count != 0 {
            soundSection = 1
            
            if indexPath.section == 0 {
                return tagCell(indexPath)
            }
        }
        
        if indexPath.section == soundSection {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
            return soundList.sound(indexPath, cell: cell)
        }
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
        return soundList.sound(indexPath, cell: cell)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedTagsForFiltering.count == 0 && indexPath.section == 0 {
            didSelectSoundAt(indexPath.row)
            
        } else if selectedTagsForFiltering.count != 0 && indexPath.section == 1 {
            didSelectSoundAt(indexPath.row)
        }
    }
    
    func didSelectSoundAt(_ row: Int) {
        if let player = soundList.player {
            player.didSelectSoundAt(row, soundList: soundList)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if indexPath.row == soundList.sounds.count - 10 && !soundList.isUpdatingData && soundList.thereIsNoMoreDataToLoad {
            print("close to pbottom")
            soundList.loadSounds(soundList.descendingOrder, likeIds: nil, userId: nil, tags: soundList.selectedTagsForFiltering, followIds: nil, searchText: nil)
        }
    }
    
    //mark: playlist filter
    func playlistFilterOptions(_ indexPath: IndexPath, cell: SoundListTableViewCell) -> UITableViewCell {
        var discoverButtonTitleColor = color.black()
        var followingButtonTitleColor = color.black()
        var collectionButtonTitleColor = color.black()
        switch playlistType {
        case "discover":
            followingButtonTitleColor = color.darkGray()
            collectionButtonTitleColor = color.darkGray()
            break
            
        case "follows":
            discoverButtonTitleColor = color.darkGray()
            collectionButtonTitleColor = color.darkGray()
            break
            
        case "likes":
            discoverButtonTitleColor = color.darkGray()
            followingButtonTitleColor = color.darkGray()
            break
            
        default:
            break
        }
        
        cell.selectionStyle = .none
        cell.discoverButton.addTarget(self, action: #selector(self.didPressPlayListFilterButton(_:)), for: .touchUpInside)
        cell.discoverButton.tag = 0
        cell.discoverButton.setTitleColor(discoverButtonTitleColor, for: .normal)
        
        cell.followingButton.addTarget(self, action: #selector(self.didPressPlayListFilterButton(_:)), for: .touchUpInside)
        cell.followingButton.tag = 1
        cell.followingButton.setTitleColor(followingButtonTitleColor, for: .normal)
        
        cell.collectionButton.addTarget(self, action: #selector(self.didPressPlayListFilterButton(_:)), for: .touchUpInside)
        cell.collectionButton.tag = 2
        cell.collectionButton.setTitleColor(collectionButtonTitleColor, for: .normal)
        
        return cell
    }
    
    @objc func didPressPlayListFilterButton(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            playlistType = "discover"
            showSounds(playlistType)
            break
            
        case 1:
            playlistType = "follows"
            showSounds(playlistType)
            break
            
        case 2:
            playlistType = "likes"
            showSounds(playlistType)
            break
            
        default:
            break
        }
    }
    
    //mark: tags
    var selectedTagsForFiltering = [Tag]()
    var xPositionForTags = UIElement().leftOffset
    
    func tagCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: tagsReuse) as! SoundListTableViewCell
        cell.selectionStyle = .none
        cell.tagsScrollview.subviews.forEach({ $0.removeFromSuperview() })
        xPositionForTags = uiElement.leftOffset
        if selectedTagsForFiltering.count != 0 {
            for i in 0..<selectedTagsForFiltering.count {
                let tag = selectedTagsForFiltering[i]
                self.addSelectedTags(cell.tagsScrollview, tag: tag, index: i)
            }
        }
        
        return cell
    }
    
    func addSelectedTags(_ scrollview: UIScrollView, tag: Tag, index: Int) {
        let name = "\(tag.name!)"
        //not using snpakit to set button frame becuase not able to get button width from button title.
        let buttonTitleWidth = uiElement.determineChosenTagButtonTitleWidth(name)
        
        let tagButton = UIButton()
        tagButton.frame = CGRect(x: xPositionForTags, y: uiElement.elementOffset, width: buttonTitleWidth, height: 30)
        tagButton.setTitle( name, for: .normal)
        tagButton.setTitleColor(.white, for: .normal)
        tagButton.setBackgroundImage(UIImage(named: "background"), for: .normal)
        tagButton.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        tagButton.layer.cornerRadius = 5
        tagButton.tag = index
        scrollview.addSubview(tagButton)
        
        xPositionForTags = xPositionForTags + Int(tagButton.frame.width) + uiElement.elementOffset
        scrollview.contentSize = CGSize(width: xPositionForTags, height: 35)
    }
    
    //mark: navigation
    var soundOrder: UIBarButtonItem!
    var soundType: UIBarButtonItem!
    
    func setupNavigationItems() {
        var soundOrderImage = "recent"
        var tag = 0
        if let filter = uiElement.getUserDefault("filter") as? String {
            if filter == "recent" {
                soundOrderImage = "recent"
               tag = 0
            } else {
                soundOrderImage = "popular"
                tag = 1
            }
        }
        soundOrder = UIBarButtonItem(image: UIImage(named: soundOrderImage), style: .plain, target: self, action: #selector(self.didPresssFilterType(_:)))
        soundOrder.tag = tag
        
        var soundTypeImage = "discover_nav"
        var soundTypeTag = 0
        if let soundType = uiElement.getUserDefault("soundType") as? String {
            switch soundType {
            case "discover_nav":
                soundTypeTag = 0
                soundTypeImage = "discover_nav"
                playlistType = "discover"
                break
                
            case "profile_nav":
                soundTypeTag = 1
                soundTypeImage = "profile_nav"
                playlistType = "follows"
                break
                
            case "collection_nav":
                soundTypeTag = 2
                soundTypeImage = "collection_nav"
                playlistType = "likes"
                break
                
            default:
                break
            }
        }
        
        soundType = UIBarButtonItem(image: UIImage(named: soundTypeImage), style: .plain, target: self, action: #selector(self.didPressSoundType(_:)))
        soundType.tag = soundTypeTag
        
        self.navigationItem.rightBarButtonItems = [soundType, soundOrder]
    }
    
    @objc func didPresssFilterType(_ sender: UIBarButtonItem) {
        
        let alertController = UIAlertController (title: "Filter By:" , message: nil, preferredStyle: .actionSheet)
        
        let recentAction = UIAlertAction(title: "Recent Sounds", style: .default) { (_) -> Void in
            self.soundOrder.image = UIImage(named: "recent")
            self.soundOrder.tag = 0
            self.uiElement.setUserDefault("filter", value: "recent")
            self.soundList.determineTypeOfSoundToLoad(self.playlistType)
        }
        alertController.addAction(recentAction)
        
        let topAction = UIAlertAction(title: "Top Sounds", style: .default) { (_) -> Void in
            self.soundOrder.image = UIImage(named: "popular")
            self.soundOrder.tag = 1
            self.uiElement.setUserDefault("filter", value: "popular")
            self.soundList.determineTypeOfSoundToLoad(self.playlistType)
        }
        alertController.addAction(topAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if self.soundOrder.tag == 0 {
            recentAction.isEnabled = false
            
        } else {
            topAction.isEnabled = false
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func didPressSoundType(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController (title: "Show Sounds From:" , message: nil, preferredStyle: .actionSheet)
        
        let discoverAction = UIAlertAction(title: "The World", style: .default) { (_) -> Void in
            self.soundType.image = UIImage(named: "discover_nav")
            self.soundType.tag = 0
            self.playlistType = "discover"
            self.soundList.determineTypeOfSoundToLoad(self.playlistType)
        }
        alertController.addAction(discoverAction)
        
        var userId: String?
        if let pfUserId = PFUser.current()?.objectId {
            userId = pfUserId
        }
        
        let followAction = UIAlertAction(title: "People You Follow", style: .default) { (_) -> Void in
            self.soundType.image = UIImage(named: "profile_nav")
            self.soundType.tag = 1
            self.playlistType = "follows"
        
            self.soundList.profileUserId = userId
            self.soundList.determineTypeOfSoundToLoad(self.playlistType)
        }
        alertController.addAction(followAction)
        
        let collectionAction = UIAlertAction(title: "Your Collection", style: .default) { (_) -> Void in
            self.soundType.image = UIImage(named: "collection_nav")
            self.soundType.tag = 2
            self.playlistType = "likes"
            self.soundList.profileUserId = userId
            self.soundList.determineTypeOfSoundToLoad(self.playlistType)
        }
        alertController.addAction(collectionAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        switch soundType.tag {
        case 0:
            discoverAction.isEnabled = false
            break
            
        case 1:
            followAction.isEnabled = false
            break
            
        case 2:
            collectionAction.isEnabled = false
            break
            
        default:
            break
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
}


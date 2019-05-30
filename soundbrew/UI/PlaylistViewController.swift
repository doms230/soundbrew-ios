//
//  SearchSoundsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 1/28/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//  MARK: Data, tableview, player, tags, button actions
//TODO: Automatic loading of more sounds as the user scrolls
//mark: tableview, Search, tags

import UIKit
import Parse
import Kingfisher
import SnapKit
import AppCenterCrashes

class PlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
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
        setupSearchBar()
        setUpTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if soundList != nil && !searchIsActive {
            showSounds(playlistType)
        }
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
    let recentPopularReuse = "recentPopularReuse"
    let soundReuse = "soundReuse"
    let playlistSoundsReuse = "playlistSoundsReuse"
    let searchProfileReuse = "searchProfileReuse"
    //in this case, will be changed to Artists and Sounds ... Doing this to avoid repetion in code
    let SearchListTypeHeaderReuse = "SearchListTypeHeaderReuse"
    let searchTagViewReuse = "searchTagViewReuse"
    let tagsReuse = "tagsReuse"
    
    func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: recentPopularReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: tagsReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: playlistSoundsReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchProfileReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: SearchListTypeHeaderReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchTagViewReuse)
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if selectedTagsForFiltering.count != 0 && !searchIsActive {
            return 3
            
        } else if selectedTagsForFiltering.count == 0 && !searchIsActive {
            return 2
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var soundSection = 1
        
        if selectedTagsForFiltering.count != 0 && !searchIsActive{
            soundSection = 2
        }
        
         if searchIsActive {
            return searchTags.count
            
         } else if section == soundSection {
            return soundList.sounds.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchIsActive {
            return searchTags[indexPath.row].cell(tableView, reuse: searchTagViewReuse)
            
        } else {
            var soundSection = 1
            var filterSection = 0
            if selectedTagsForFiltering.count != 0 {
                soundSection = 2
                filterSection = 1
                
                if indexPath.section == 0 {
                    return tagCell(indexPath)
                }
            }
            
            if indexPath.section == filterSection {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: playlistSoundsReuse) as! SoundListTableViewCell
                return playlistFilterOptions(indexPath, cell: cell)
                //return soundList.soundFilterOptions(indexPath, cell: cell)
                //this is where the yeas will go
                
            } else if indexPath.section == soundSection {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
                return soundList.sound(indexPath, cell: cell)
            }
        }
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
        return soundList.sound(indexPath, cell: cell)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        if searchIsActive {
            selectedTagsForFiltering.append(searchTags[indexPath.row])
            exitSearch()
            showSounds(playlistType)
            
        } else if selectedTagsForFiltering.count != 0 && indexPath.section == 2 && !searchIsActive {
            didSelectSoundAt(indexPath.row)
            
        } else if selectedTagsForFiltering.count == 0 && indexPath.section == 1  && !searchIsActive {
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
        let name = "X | \(tag.name!)"
        //not using snpakit to set button frame becuase not able to get button width from button title.
        let buttonTitleWidth = uiElement.determineChosenTagButtonTitleWidth(name)
        
        let tagButton = UIButton()
        tagButton.frame = CGRect(x: xPositionForTags, y: uiElement.elementOffset, width: buttonTitleWidth, height: 30)
        tagButton.setTitle( name, for: .normal)
        tagButton.setTitleColor(color.black(), for: .normal)
        tagButton.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        tagButton.layer.cornerRadius = 5
        tagButton.layer.borderWidth = 1
        tagButton.layer.borderColor = color.darkGray().cgColor
        tagButton.tag = index
        tagButton.addTarget(self, action: #selector(self.didPressTagButton(_:)), for: .touchUpInside)
        scrollview.addSubview(tagButton)
        
        xPositionForTags = xPositionForTags + Int(tagButton.frame.width) + uiElement.elementOffset
        scrollview.contentSize = CGSize(width: xPositionForTags, height: 35)
    }
    
    @objc func didPressTagButton(_ sender: UIButton) {
        selectedTagsForFiltering.remove(at: sender.tag)
        self.tableView.reloadData()
        
        var tags: Array<Tag>?
        if selectedTagsForFiltering.count != 0 {
            tags = selectedTagsForFiltering
        }
        soundList.soundType = "discover"
        soundList = SoundList(target: self, tableView: tableView, soundType: "discover", userId: nil, tags: tags, searchText: nil)
    }
    
    func loadTags(_ text: String) {
        let query = PFQuery(className: "Tag")
        if !text.isEmpty {
            query.whereKey("tag", matchesRegex: text.lowercased())
        }
        query.addDescendingOrder("count")
        query.limit = 25
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    var tagResults = [Tag]()
                    for object in objects {
                        let name = object["tag"] as! String
                        let count = object["count"] as! Int
                        let type = object["type"] as? String
                        let image = object["image"] as? PFFileObject
                        
                        let tag = Tag(objectId: object.objectId, name: name, count: count, isSelected: false, type: type, image: image?.url)
                        tagResults.append(tag)
                    }
                    self.searchTags = tagResults
                }
                self.tableView.reloadData()
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    //mark: Search
    var searchIsActive = false
    var soundOrder: UIBarButtonItem!
    
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width - 100, height: 10))
        searchBar.placeholder = "Tags"
        
        let searchTextField = searchBar.value(forKey: "_searchField") as? UITextField
        searchTextField?.backgroundColor = color.lightGray()
        searchBar.delegate = self
        return searchBar
    }()
    
    func setupSearchBar() {
        let leftNavBarButton = UIBarButtonItem(customView: searchBar)
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
        self.navigationItem.rightBarButtonItem = soundOrder
        self.navigationItem.leftBarButtonItem = leftNavBarButton
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
    
    func exitSearch() {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = ""
        searchBar.placeholder = "Tags"
        searchTags.removeAll()
        self.searchBar.resignFirstResponder()
        searchIsActive = false
        self.tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        searchIsActive = true
        searchBar.placeholder = "Try 'Happy' or 'lofi'"
        self.tableView.reloadData()
        loadTags(searchBar.text!)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        soundList.soundType = "search"
        searchIsActive = true
        loadTags(searchBar.text!)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        exitSearch()
    }
    
    func searchUsers(_ text: String) {
        let nameQuery = PFQuery(className: "_User")
        nameQuery.whereKey("artistName", matchesRegex: text.lowercased())
        nameQuery.whereKey("artistName", matchesRegex: text)
        
        let usernameQuery = PFQuery(className: "_User")
        usernameQuery.whereKey("username", matchesRegex: text.lowercased())
        
        let query = PFQuery.orQuery(withSubqueries: [nameQuery, usernameQuery])
        query.limit = 50
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    var userResults = [Artist]()
                    for user in objects {
                        let username = user["username"] as? String
                        
                        var email: String?
                        
                        if let currentUser = PFUser.current() {
                            if currentUser.objectId! == user.objectId! {
                                email = user["email"] as? String
                            }
                        }
                        
                        let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: username, website: nil, bio: nil, email: email, isFollowedByCurrentUser: nil, followerCount: nil)
                        
                        if let followerCount = user["followerCount"] as? Int {
                            artist.followerCount = followerCount
                        }
                        
                        if let name = user["artistName"] as? String {
                            artist.name = name
                        }
                        
                        if let username = user["username"] as? String {
                            artist.username = username
                        }
                        
                        if let city = user["city"] as? String {
                            artist.city = city
                        }
                        
                        if let userImageFile = user["userImage"] as? PFFileObject {
                            artist.image = userImageFile.url!
                        }
                        
                        if let bio = user["bio"] as? String {
                            artist.bio = bio
                        }
                        
                        if let artistVerification = user["artistVerification"] as? Bool {
                            artist.isVerified = artistVerification
                        }
                        
                        if let website = user["website"] as? String {
                            artist.website = website
                        }
                        
                        userResults.append(artist)
                    }
                    
                    self.searchUsers = userResults
                }
                
                self.tableView.reloadData()
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
}


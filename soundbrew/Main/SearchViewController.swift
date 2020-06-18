//
//  SearchViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 8/7/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import SnapKit
import Kingfisher
import AppCenterAnalytics
import NotificationBannerSwift

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, PlayerDelegate, TagDelegate {
    let color = Color()
    let uiElement = UIElement()
    var soundType: String!
    var soundList: SoundList!
    var isLoadingResults = false
    var playlist: Playlist?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        setupSearchBar()
        if playlist == nil {
            setupTags()
        } else {
            handleTableViewLogic()
            if let currentUserId = PFUser.current()?.objectId {
                soundList = SoundList(target: self, tableView: tableView, soundType: "collection", userId: currentUserId, tags: nil, searchText: nil, descendingOrder: nil, linkObjectId: nil, playlist: nil)
            }
        }
    }
    
    func setupTags() {
        for featureTagType in featureTagTypes {
            loadTags(featureTagType, searchText: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let localizedBack = NSLocalizedString("back", comment: "")
        let backItem = UIBarButtonItem()
        backItem.title = localizedBack
        navigationItem.backBarButtonItem = backItem
        setMiniPlayer()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showProfile":
            if soundList == nil {
                let viewController = segue.destination as! ProfileViewController
                viewController.profileArtist = selectedArtist
                
            } else {
               soundList.prepareToShowSelectedArtist(segue)
            }
            
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
            break
            
        case "showTags":
            let desi = segue.destination as! ChooseTagsViewController
            desi.tagType = selectedTagType
            desi.isSelectingTagsForPlaylist = true
            
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
            break
            
        case "showSounds":
            let viewController = segue.destination as! SoundsViewController
            viewController.selectedTagForFiltering = self.selectedTag
            viewController.soundType = soundType
            
            let backItem = UIBarButtonItem()
            backItem.title = self.selectedTag.name
            navigationItem.backBarButtonItem = backItem
            break
            
        default:
            break
        }
    }
    
    func showSounds(_ selectedTag: Tag, soundType: String) {
        self.selectedTag = selectedTag
        self.soundType = soundType
        self.performSegue(withIdentifier: "showSounds", sender: self)
    }
    
    //mark: tableview
    var tableView: UITableView!
    let reuse = "reuse"
    let soundReuse = "soundReuse"
    let searchProfileReuse = "searchProfileReuse"
    let searchTagViewReuse = "searchTagViewReuse"
    let selectPlaylistSoundsReuse = "selectPlaylistSoundsReuse"
    func setUpTableView() {
        tableView = UITableView()
        tableView.backgroundColor = color.black()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TagTableViewCell.self, forCellReuseIdentifier: reuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchProfileReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchTagViewReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: selectPlaylistSoundsReuse)
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-170)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.playlist == nil {
            return 3
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if playlist == nil {
            if section == 0 {
                return searchUsers.count
            } else if section == 1 {
                return searchTags.count
            } else {
                if soundList != nil {
                    return soundList.sounds.count
                } else {
                    return 0
                }
            }
            
        } else {
            if soundList != nil {
                return soundList.sounds.count
            } else {
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if playlist == nil {
            if indexPath.section == 0 {
                return searchUsers[indexPath.row].cell(tableView, reuse: searchProfileReuse)
            } else if indexPath.section == 1 {
                return searchTags[indexPath.row].cell(tableView, reuse: searchTagViewReuse)
            } else {
                return soundList.soundCell(indexPath, tableView: tableView, reuse: soundReuse)
            }
            
        } else {
            let cell = soundList.soundCell(indexPath, tableView: tableView, reuse: selectPlaylistSoundsReuse)
            cell.circleImage.text = "⨁"
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        if playlist == nil {
            if indexPath.section == 0 {
                self.selectedArtist = searchUsers[indexPath.row]
                self.performSegue(withIdentifier: "showProfile", sender: self)
            } else if indexPath.section == 1 {
                let tag = searchTags[indexPath.row]
                showSounds(tag, soundType: "discover")
                MSAnalytics.trackEvent("Selected Tag", withProperties: ["Tag" : "\(tag.name ?? "")"])
            } else {
                didSelectSoundAt(row: indexPath.row)
            }
            
        } else if let playlistId = playlist?.objectId, let playlistTitle = playlist?.title, let soundTitle = soundList.sounds[indexPath.row].title, let soundId = soundList.sounds[indexPath.row].objectId {
            attachSoundToPlaylist(soundId, playlistId: playlistId)
            let banner = StatusBarNotificationBanner(title: "\(soundTitle) added to \(playlistTitle).", style: .success)
            banner.show()
            if soundList.sounds.indices.contains(indexPath.row) {
                soundList.sounds.remove(at: indexPath.row)
                self.tableView.reloadData()
            }
        }
    }
    
    func didSelectSoundAt(row: Int) {
        let player = soundList.player
        player.sounds = soundList.sounds
        player.didSelectSoundAt(row)
        if self.tableView == nil {
            self.setUpTableView()
        } else {
            self.tableView.reloadData()
        }
    }
    
    func attachSoundToPlaylist(_ soundId: String, playlistId: String) {
        let newPlaylistSound = PFObject(className: "PlaylistSound")
        newPlaylistSound["playlistId"] = playlistId
        newPlaylistSound["soundId"] = soundId
        newPlaylistSound.saveEventually()
        updatePlaylistCount(playlistId)
    }
    
    func updatePlaylistCount(_ playlistId: String) {
        let query = PFQuery(className: "Playlist")
        query.getObjectInBackground(withId: playlistId) {
            (object: PFObject?, error: Error?) -> Void in
             if let object = object {
                object.incrementKey("count")
                object.saveEventually()
            }
        }
    }
    
    /*func noResultsCell() -> SoundListTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
        cell.backgroundColor = color.black()
        if isLoadingResults {
            cell.headerTitle.text = ""
        } else {
            let localizedNoResults = NSLocalizedString("noResults", comment: "")
            cell.headerTitle.text = localizedNoResults
        }
        return cell
    }*/
    
    //mark: tags
    var featureTagTypes = ["genre","city", "mood", "activity"]
    var selectedTag: Tag!
    var selectedTagType: String!
    
    func receivedTags(_ chosenTags: Array<Tag>?) {
        if let tags = chosenTags {
            showSounds(tags[0], soundType: "discover")
        }
    }
    
    func loadTags(_ type: String, searchText: String?) {
        let query = PFQuery(className: "Tag")

        if let text = searchText {
            self.searchTags.removeAll()
            query.whereKey("tag", matchesRegex: text.lowercased())
            query.limit = 5
        } else {
            if type != "all" {
                query.whereKey("type", equalTo: type)
            } else {
                 query.whereKey("type", notContainedIn: self.featureTagTypes)
            }
            query.limit = 5
        }
        
        query.addDescendingOrder("count")
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                for object in objects {
                    let tagName = object["tag"] as! String
                    let tagCount = object["count"] as! Int
                    
                    let newTag = Tag(objectId: object.objectId, name: tagName, count: tagCount, isSelected: false, type: nil, imageURL: nil, uiImage: nil)
                    
                    if let image = object["image"] as? PFFileObject {
                        newTag.imageURL = image.url
                    }
                    
                    if let tagType = object["type"] as? String {
                        if !tagType.isEmpty {
                            newTag.type = tagType
                        }
                    }
                    self.searchTags.append(newTag)
                }
            }
            
            self.handleTableViewLogic()
        }
    }
    
    func handleTableViewLogic() {
        self.isLoadingResults = false
        if self.tableView == nil {
            self.setUpTableView()
        } else {
            self.tableView.reloadData()
        }
    }
    
    //mark: miniPlayer
    func setMiniPlayer() {
        let miniPlayerView = MiniPlayerView.sharedInstance
        miniPlayerView.superViewController = self
        miniPlayerView.tagDelegate = self
        miniPlayerView.playerDelegate = self
    }
    
    //mark: selectedArtist
    var selectedArtist: Artist?
    
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
                
                default:
                    if soundList == nil {
                       self.selectedArtist = artist
                        self.performSegue(withIdentifier: "showProfile", sender: self)
                    } else {
                      soundList.selectedArtist(artist)
                    }
                    break
            }
        }
    }
    
    //mark: search
    var isSearchActive = false
    var searchUsers = [Artist]()
    var searchTags = [Tag]()
    var searchType = 0
    
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width - 50, height: 10))
        var searchPlaceholder = "Search Soundbrew"
        if self.playlist != nil {
            searchPlaceholder = "Search Sounds"
        }
        searchBar.placeholder = searchPlaceholder
        searchBar.delegate = self
        if #available(iOS 13.0, *) {
            let searchTextField = searchBar.searchTextField
            searchTextField.backgroundColor = color.black()
            searchTextField.textColor = .white
        } else {
            let searchTextField = searchBar.value(forKey: "_searchField") as! UITextField
            searchTextField.backgroundColor = color.black()
            searchTextField.textColor = .white
        }
                
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        return searchBar
    }()
    
    func setupSearchBar() {
        let rightNavBarButton = UIBarButtonItem(customView: searchBar)
        self.navigationItem.rightBarButtonItem = rightNavBarButton
        self.searchBar.becomeFirstResponder()
    }
    
    @objc func didPressSearchTypeButton(_ sender: UIButton) {
       let currentSearchType = self.searchType
        self.searchType = sender.tag
        if currentSearchType != self.searchType {
            search()
        }
    }
    
    func search() {
        isLoadingResults = true
        if playlist != nil {
            soundList = SoundList(target: self, tableView: tableView, soundType: "search", userId: nil, tags: nil, searchText: searchBar.text!, descendingOrder: nil, linkObjectId: nil, playlist: nil)
        } else {
            loadTags("", searchText: searchBar.text!)
            searchUsers(searchBar.text!)
            soundList = SoundList(target: self, tableView: tableView, soundType: "search", userId: nil, tags: nil, searchText: searchBar.text!, descendingOrder: nil, linkObjectId: nil, playlist: nil)
        }
        handleTableViewLogic()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearchActive = true
        handleTableViewLogic()
        MSAnalytics.trackEvent("SearchViewController", withProperties: ["Button" : "Search", "description": "User did start Searching."])
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        search()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        //searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = ""
        self.searchBar.resignFirstResponder()
        isSearchActive = false
        handleTableViewLogic()
    }
    
    func searchUsers(_ text: String) {
        self.searchUsers.removeAll()
        let nameQuery = PFQuery(className: "_User")
        nameQuery.whereKey("artistName", matchesRegex: text.lowercased())
        nameQuery.whereKey("artistName", matchesRegex: text)
        
        let usernameQuery = PFQuery(className: "_User")
        usernameQuery.whereKey("username", matchesRegex: text.lowercased())
        
        let query = PFQuery.orQuery(withSubqueries: [nameQuery, usernameQuery])
        query.limit = 5
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                for user in objects {
                    let artist = self.uiElement.newArtistObject(user)
                    if artist.username != nil {
                        self.searchUsers.append(artist)
                    }
                }
            }
            
            self.isLoadingResults = false
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

//
//  SearchSoundsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 1/28/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//  MARK: Data, tableview, player, tags, button actions
//TODO: Automatic loading of more sounds as the user scrolls
//mark: tableview, Search

import UIKit
import Parse
import Kingfisher
import SnapKit

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var soundList: SoundList!
    var searchSounds = [Sound]()
    var searchUsers = [Artist]()
    let uiElement = UIElement()
    let color = Color()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        soundList = SoundList(target: self, tableView: tableView, soundType: "discover", userId: nil, tags: nil, searchText: nil)
        
        setupSearchBar()
        setUpTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if soundList != nil && !searchIsActive {
            
            /*soundList.sounds = searchSounds
            soundList.player!.sounds = searchSounds
            soundList.target = self
            soundList.tableView = self.tableView
            soundList.soundType = "search"*/
            var tags: Array<Tag>?
            if let soundListTags = soundList.selectedTagsForFiltering {
                tags = soundListTags
            }
            soundList = SoundList(target: self, tableView: tableView, soundType: "discover", userId: nil, tags: tags, searchText: nil)
            //self.tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfile" {
            soundList.prepareToShowSelectedArtist(segue)
            
        } else if segue.identifier == "showTags" {
            soundList.prepareToShowTags(segue)
            
        } else if segue.identifier == "showEditSoundInfo" {
            soundList.prepareToShowSoundInfo(segue)
            
        } else if segue.identifier == "showUploadSound" {
            soundList.prepareToShowSoundAudioUpload(segue)
        }
    }
    
    //mark: tableview
    var tableView = UITableView()
    let recentPopularReuse = "recentPopularReuse"
    let soundReuse = "soundReuse"
    let filterSoundsReuse = "filterSoundsReuse"
    let searchProfileReuse = "searchProfileReuse"
    //in this case, will be changed to Artists and Sounds ... Doing this to avoid repetion in code
    let uploadsCollectionsHeaderReuse = "releasesCollectionsHeaderReuse"
    
    func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: recentPopularReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: filterSoundsReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchProfileReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: uploadsCollectionsHeaderReuse)
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
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            if searchIsActive && searchType == profileSearch {
                return searchUsers.count
                
            } else {
                return soundList.sounds.count
            }
        }

        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchIsActive {
            if indexPath.section == 0 {
                return searchTypeCell()
                
            } else if searchType == profileSearch {
                return searchProfileCell(indexPath)
                
            } else {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
                return soundList.sound(indexPath, cell: cell)
            }
            
        } else {
            if indexPath.section == 0 {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: filterSoundsReuse) as! SoundListTableViewCell
                return soundList.soundFilterOptions(indexPath, cell: cell)
                
            } else {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
                return soundList.sound(indexPath, cell: cell)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if searchType == profileSearch && searchIsActive {
                tableView.cellForRow(at: indexPath)?.isSelected = false
                soundList.selectedArtist = searchUsers[indexPath.row]
                self.performSegue(withIdentifier: "showProfile", sender: self)
                
            } else {
                if let player = soundList.player {
                    player.didSelectSoundAt(indexPath.row)
                    if soundList.miniPlayerView == nil {
                        soundList.setUpMiniPlayer()
                    }
                    tableView.reloadData()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if indexPath.row == soundList.sounds.count - 10 && !soundList.isUpdatingData && soundList.thereIsNoMoreDataToLoad {
            soundList.loadSounds(soundList.descendingOrder, likeIds: nil, userId: nil, tags: soundList.selectedTagsForFiltering, followIds: nil, searchText: nil)
        }
    }
    
    //mark: Search
    var searchIsActive = false
    var searchType = "profile"
    let profileSearch = "profile"
    let soundSearch = "search"
    
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width - 5, height: 10))
        searchBar.placeholder = "Search"
        
        let searchTextField = searchBar.value(forKey: "_searchField") as? UITextField
        searchTextField?.backgroundColor = color.lightGray()
        searchBar.delegate = self
        return searchBar
    }()
    
    func setupSearchBar() {
        let leftNavBarButton = UIBarButtonItem(customView: searchBar)
        self.navigationItem.leftBarButtonItem = leftNavBarButton
    }
    
    @objc func didPressProfileSoundsButton(_ sender: UIButton) {
        if sender.tag == 0 {
            searchType = profileSearch
            
        } else {
            searchType = soundSearch
        }
        
        self.tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        searchIsActive = true
        self.tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        soundList.soundType = "search"
        searchIsActive = true
        if searchType == profileSearch {
            if !searchBar.text!.isEmpty {
                searchUsers(searchBar.text!)
            }
            
        } else {
            //soundList.loadSounds("plays", likeIds: nil, userId: nil, tags: nil, followIds: nil, searchText: searchText)
            soundList = SoundList(target: self, tableView: tableView, soundType: "search", userId: nil, tags: nil, searchText: searchText)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        self.searchBar.resignFirstResponder()
        soundList.soundType = "discover"
        searchIsActive = false
        soundList = SoundList(target: self, tableView: tableView, soundType: "discover", userId: nil, tags: nil, searchText: nil)
    }
    
    func searchProfileCell(_ indexPath: IndexPath) -> UITableViewCell {
        let artist = searchUsers[indexPath.row]
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: searchProfileReuse) as! ProfileTableViewCell
        
        cell.selectionStyle = .gray
        
        if let artistImage = artist.image {
            cell.profileImage.kf.setImage(with: URL(string: artistImage))
            
        } else {
            cell.profileImage.image = UIImage(named: "profile_icon")
        }
        
        if let name = artist.name {
            cell.displayName.text = name
            
        } else {
            cell.displayName.text = ""
        }
        
        if let username = artist.username {
            //email was set as username in prior version of Soundbrew and email is private.
            if username.contains("@") {
                cell.username.text = ""
                
            } else {
                cell.username.text = username
            }
        }
        
        return cell
    }
    
    func searchTypeCell() -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: uploadsCollectionsHeaderReuse) as! ProfileTableViewCell
        
        cell.releasesButton.setTitle("Accounts", for: .normal)
        cell.releasesButton.addTarget(self, action: #selector(self.didPressProfileSoundsButton(_:)), for: .touchUpInside)
        cell.releasesButton.tag = 0
        
        cell.collectionButton.setTitle("Sounds", for: .normal)
        cell.collectionButton.addTarget(self, action: #selector(self.didPressProfileSoundsButton(_:)), for: .touchUpInside)
        cell.collectionButton.tag = 1
        
        if searchType == profileSearch {
            cell.releasesButton.setTitleColor(color.black(), for: .normal)
            cell.collectionButton.setTitleColor(color.darkGray(), for: .normal)
            
        } else {
            cell.collectionButton.setTitleColor(color.black(), for: .normal)
            cell.releasesButton.setTitleColor(color.darkGray(), for: .normal)
        }
        
        return cell
    }
    
    func searchUsers(_ text: String) {
        self.searchUsers.removeAll()
        
        let nameQuery = PFQuery(className: "_User")
        nameQuery.whereKey("artistName", hasPrefix: text)
        
        let usernameQuery = PFQuery(className: "_User")
        usernameQuery.whereKey("username", hasPrefix: text.lowercased())
        
        let query = PFQuery.orQuery(withSubqueries: [nameQuery, usernameQuery])
        query.limit = 100
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for user in objects {
                        let username = user["username"] as? String
                        
                        var email: String?
                        if user.objectId! == PFUser.current()!.objectId {
                            email = user["email"] as? String
                        }
                        
                        let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: username, website: nil, bio: nil, email: email, instagramUsername: nil, twitterUsername: nil, snapchatUsername: nil, isFollowedByCurrentUser: nil, followerCount: nil)
                        
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
                        
                        if let instagramUsername = user["instagramHandle"] as? String {
                            artist.instagramUsername = instagramUsername
                        }
                        
                        if let twitterUsername = user["twitterHandle"] as? String {
                            artist.twitterUsername = twitterUsername
                        }
                        
                        if let snapchatUsername = user["snapchatHandle"] as? String {
                            artist.snapchatUsername = snapchatUsername
                        }
                        
                        if let website = user["otherLink"] as? String {
                            artist.website = website
                        }
                        
                        self.searchUsers.append(artist)
                    }
                }
                
                self.tableView.reloadData()
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
}


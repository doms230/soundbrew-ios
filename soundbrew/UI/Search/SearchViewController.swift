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

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var soundList: SoundList!
    var searchSounds = [Sound]()
    var searchUsers = [Artist]()
    var searchTags = [Tag]()
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
    
    func showDiscoverSounds() {
        searchBar.setShowsCancelButton(false, animated: true)
        
        var tags: Array<Tag>?
        if selectedTagsForFiltering.count != 0 {
            tags = selectedTagsForFiltering
        }
        self.searchBar.resignFirstResponder()
        soundList.soundType = "discover"
        searchIsActive = false
        soundList = SoundList(target: self, tableView: tableView, soundType: "discover", userId: nil, tags: tags, searchText: nil)
        
        searchBar.text = ""
        searchBar.placeholder = "Search"
        searchTags.removeAll()
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
    }
    
    //mark: tableview
    var tableView = UITableView()
    let recentPopularReuse = "recentPopularReuse"
    let soundReuse = "soundReuse"
    let filterSoundsReuse = "filterSoundsReuse"
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
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: filterSoundsReuse)
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
        if selectedTagsForFiltering.count != 0 {
            return 3
        }
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var soundSection = 1
        
        if selectedTagsForFiltering.count != 0 {
            soundSection = 2
        }
        
         if section == 1 && searchIsActive {
            switch searchType {
            case tagSearch:
                return searchTags.count
                
            case profileSearch:
                return searchUsers.count
                
            case soundSearch:
                return soundList.sounds.count
                
            default:
                return 1
            }
            
         } else if section == soundSection {
            return soundList.sounds.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchIsActive {
            if indexPath.section == 0 {
                return searchTypeCell()
                
            } else {
                switch searchType {
                case tagSearch:
                    return searchTagCell(indexPath)
                    
                case profileSearch:
                    return searchProfileCell(indexPath)
                    
                case soundSearch:
                    let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
                    return soundList.sound(indexPath, cell: cell)
                    
                default:
                    return searchTagCell(indexPath)
                }
            }
            
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
                let cell = self.tableView.dequeueReusableCell(withIdentifier: filterSoundsReuse) as! SoundListTableViewCell
                return soundList.soundFilterOptions(indexPath, cell: cell)
                
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
        if indexPath.section == 1 {
            switch searchType {
            case tagSearch:
                selectedTagsForFiltering.append(searchTags[indexPath.row])
                showDiscoverSounds()
                break
                
            case profileSearch:
                soundList.selectedArtist = searchUsers[indexPath.row]
                self.performSegue(withIdentifier: "showProfile", sender: self)
                break
                
            case soundSearch:
                if let player = soundList.player {
                    player.didSelectSoundAt(indexPath.row)
                    soundList.miniPlayerView?.isHidden = false
                    tableView.reloadData()
                }
                break
                
            default:
                break
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if indexPath.row == soundList.sounds.count - 10 && !soundList.isUpdatingData && soundList.thereIsNoMoreDataToLoad {
            soundList.loadSounds(soundList.descendingOrder, likeIds: nil, userId: nil, tags: soundList.selectedTagsForFiltering, followIds: nil, searchText: nil)
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
                let tagName = selectedTagsForFiltering[i].name
                self.addSelectedTags(cell.tagsScrollview, tagName: "X | \(tagName!)", index: i)
            }
        }
        
        return cell
    }
    
    func addSelectedTags(_ scrollview: UIScrollView, tagName: String, index: Int) {
        let buttonTitleWithX = "\(tagName)"
        //not using snpakit to set button frame becuase not able to get button width from button title.
        let buttonTitleWidth = uiElement.determineChosenTagButtonTitleWidth(buttonTitleWithX)
        
        let tagButton = UIButton()
        tagButton.frame = CGRect(x: xPositionForTags, y: uiElement.elementOffset, width: buttonTitleWidth, height: 30)
        tagButton.setTitle(tagName, for: .normal)
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
        
        var tags: Array<Tag>?
        if selectedTagsForFiltering.count != 0 {
            tags = selectedTagsForFiltering
        }
        soundList.soundType = "discover"
        soundList = SoundList(target: self, tableView: tableView, soundType: "discover", userId: nil, tags: tags, searchText: nil)
    }
    
    func searchTagCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: searchTagViewReuse) as! ProfileTableViewCell
        if searchTags.indices.contains(indexPath.row) {
            let tag = searchTags[indexPath.row]
            
            cell.selectionStyle = .gray
            
            if let image = tag.image {
                cell.profileImage.kf.setImage(with: URL(string: image))
                
            } else {
                cell.profileImage.image = UIImage(named: "hashtag")
            }
            
            cell.displayName.text = tag.name            
        }
        
        
        return cell
    }
    
    func searchTags(_ text: String) {
        self.searchTags.removeAll()
        
        let query = PFQuery(className: "Tag")
        query.whereKey("tag", matchesRegex: text.lowercased())
        query.addDescendingOrder("count")
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let name = object["tag"] as! String
                        let count = object["count"] as! Int
                        let type = object["type"] as? String
                        let image = object["image"] as? PFFileObject
                        
                        let tag = Tag(objectId: object.objectId, name: name, count: count, isSelected: false, type: type, image: image?.url)
                        self.searchTags.append(tag)
                    }
                }
                self.tableView.reloadData()
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    //mark: Search
    var searchIsActive = false
    var searchType = "tag"
    let profileSearch = "profile"
    let soundSearch = "search"
    let tagSearch = "tag"
    
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
        switch sender.tag {
        case 0:
            searchType = tagSearch
            searchBar.placeholder = "Mood, Activity, Genre, City, Anything"
            break
            
        case 1:
            searchType = profileSearch
            searchBar.placeholder = "Name, Username"
            break
            
        case 2:
            searchType = soundSearch
            searchBar.placeholder = "Sound Name"
            break
            
        default:
            break
        }
        
        self.tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        searchIsActive = true
        self.tableView.reloadData()
        
        switch searchType {
        case tagSearch:
            searchBar.placeholder = "Mood, Activity, Genre, City, Anything"
            break
            
        case profileSearch:
            searchBar.placeholder = "Name, Username"
            break
            
        case soundSearch:
            searchBar.placeholder = "Sound Name"
            break
            
        default:
            break
            
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        soundList.soundType = "search"
        searchIsActive = true
        
        if !searchBar.text!.isEmpty {
            switch searchType {
            case tagSearch:
                searchTags(searchBar.text!)
                break
                
            case profileSearch:
                searchUsers(searchBar.text!)
                break
                
            case soundSearch:
                soundList = SoundList(target: self, tableView: tableView, soundType: "search", userId: nil, tags: nil, searchText: searchText)
                break
                
            default:
                break
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        showDiscoverSounds()
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
        let cell = self.tableView.dequeueReusableCell(withIdentifier: SearchListTypeHeaderReuse) as! ProfileTableViewCell
        
        cell.isSearchActive = true
        
        cell.firstListType.setTitle("Tags", for: .normal)
        cell.firstListType.addTarget(self, action: #selector(self.didPressProfileSoundsButton(_:)), for: .touchUpInside)
        cell.firstListType.tag = 0
        
        cell.secondListType.setTitle("Accounts", for: .normal)
        cell.secondListType.addTarget(self, action: #selector(self.didPressProfileSoundsButton(_:)), for: .touchUpInside)
        cell.secondListType.tag = 1
        
        cell.thirdListType.setTitle("Sounds", for: .normal)
        cell.thirdListType.addTarget(self, action: #selector(self.didPressProfileSoundsButton(_:)), for: .touchUpInside)
        cell.thirdListType.tag = 2
        
        switch searchType {
        case tagSearch:
            cell.firstListType.setTitleColor(color.black(), for: .normal)
            cell.secondListType.setTitleColor(color.darkGray(), for: .normal)
            cell.thirdListType.setTitleColor(color.darkGray(), for: .normal)
            break
            
        case profileSearch:
            cell.firstListType.setTitleColor(color.darkGray(), for: .normal)
            cell.secondListType.setTitleColor(color.black(), for: .normal)
            cell.thirdListType.setTitleColor(color.darkGray(), for: .normal)
            break
            
        case soundSearch:
            cell.firstListType.setTitleColor(color.darkGray(), for: .normal)
            cell.secondListType.setTitleColor(color.darkGray(), for: .normal)
            cell.thirdListType.setTitleColor(color.black(), for: .normal)
            break
            
        default:
            break
        }
        
        return cell
    }
    
    func searchUsers(_ text: String) {
        self.searchUsers.removeAll()
        
        let nameQuery = PFQuery(className: "_User")
        //nameQuery.whereKey("artistName", hasPrefix: text)
        //nameQuery.whereKey("artistName", hasPrefix: text.lowercased())
        nameQuery.whereKey("artistName", matchesRegex: text.lowercased())
        nameQuery.whereKey("artistName", matchesRegex: text)
        
        let usernameQuery = PFQuery(className: "_User")
        usernameQuery.whereKey("artistName", matchesRegex: text.lowercased())
        //usernameQuery.whereKey("username", hasPrefix: text.lowercased())
        
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


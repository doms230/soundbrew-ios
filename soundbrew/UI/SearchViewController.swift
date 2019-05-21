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
            var tags: Array<Tag>?
            if let soundListTags = soundList.selectedTagsForFiltering {
                tags = soundListTags
            }
            soundList = SoundList(target: self, tableView: tableView, soundType: "discover", userId: nil, tags: tags, searchText: nil)
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
        self.exitSearch()
        
        var tags: Array<Tag>?
        if selectedTagsForFiltering.count != 0 {
            tags = selectedTagsForFiltering
        }
        
        soundList.soundType = "discover"
        soundList = SoundList(target: self, tableView: tableView, soundType: "discover", userId: nil, tags: tags, searchText: nil)        
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
        if selectedTagsForFiltering.count != 0 && !searchIsActive {
            return 3
        }
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var soundSection = 1
        
        if selectedTagsForFiltering.count != 0 && !searchIsActive{
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
                    return searchTags[indexPath.row].cell(tableView, reuse: searchTagViewReuse)
                    
                case profileSearch:
                    return searchUsers[indexPath.row].cell(tableView, reuse: searchProfileReuse)
                    
                case soundSearch:
                    let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
                    return soundList.sound(indexPath, cell: cell)
                    
                default:
                    return searchTags[indexPath.row].cell(tableView, reuse: searchTagViewReuse)
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
        if indexPath.section == 1 && searchIsActive {
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
                didSelectSoundAt(indexPath.row)
                break
                
            default:
                break
            }
            
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
    
    func searchTags(_ text: String?) {
        let query = PFQuery(className: "Tag")
        if let text = text {
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
    
    func exitSearch() {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = ""
        searchBar.placeholder = "Search"
        searchTags.removeAll()
        self.searchBar.resignFirstResponder()
        searchIsActive = false
        self.tableView.reloadData()
    }
    
    func search() {
        switch searchType {
        case tagSearch:
            searchBar.placeholder = "Try 'Happy' or 'LoFi'"
            if searchBar.text!.isEmpty {
                searchTags(nil)
                
            } else {
                searchTags(searchBar.text!)
            }
            break
            
        case profileSearch:
            searchBar.placeholder = "Name, Username"
            if !searchBar.text!.isEmpty {
                searchUsers(searchBar.text!)
                
            } else {
                self.tableView.reloadData()
            }
            
            break
            
        case soundSearch:
            searchBar.placeholder = "Sound Name"
            soundList = SoundList(target: self, tableView: tableView, soundType: "search", userId: nil, tags: nil, searchText: searchBar.text!)
            break
            
        default:
            break
        }
    }
    
    @objc func didPressSearchTypeButton(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            searchType = tagSearch
            break
            
        case 1:
            searchType = profileSearch
            break
            
        case 2:
            searchType = soundSearch
            break
            
        default:
            break
        }
        
        self.tableView.reloadData()
        
        search()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        searchIsActive = true
        self.tableView.reloadData()
        search()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        soundList.soundType = "search"
        searchIsActive = true
        search()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        exitSearch()
    }
    
    func searchTypeCell() -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: SearchListTypeHeaderReuse) as! ProfileTableViewCell
        
        cell.isSearchActive = true
        
        cell.firstListType.setTitle("Tags", for: .normal)
        cell.firstListType.addTarget(self, action: #selector(self.didPressSearchTypeButton(_:)), for: .touchUpInside)
        cell.firstListType.tag = 0
        
        cell.secondListType.setTitle("Accounts", for: .normal)
        cell.secondListType.addTarget(self, action: #selector(self.didPressSearchTypeButton(_:)), for: .touchUpInside)
        cell.secondListType.tag = 1
        
        cell.thirdListType.setTitle("Sounds", for: .normal)
        cell.thirdListType.addTarget(self, action: #selector(self.didPressSearchTypeButton(_:)), for: .touchUpInside)
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


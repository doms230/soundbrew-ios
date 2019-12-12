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

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, PlayerDelegate {
    let color = Color()
    let uiElement = UIElement()
    var soundType: String!
    
    var isLoadingResults = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        setupSearchBar()
        setupTags()
        checkForProfileDynamicLink()
        search()
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
            
            break
            
        case "showEditSoundInfo":
            soundList.prepareToShowSoundInfo(segue)
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
            if let tagImage = self.selectedTag.uiImage {
                viewController.soundHeaderImage = tagImage
            } else {
                viewController.soundHeaderImage = UIImage(named: "background")
            }
            
            let backItem = UIBarButtonItem()
            backItem.title = self.selectedTag.name
            navigationItem.backBarButtonItem = backItem
            break
            
        case "showTippers":
            if let currentSound = Player.sharedInstance.currentSound {
                let viewController = segue.destination as! PeopleViewController
                viewController.sound = currentSound
            }
            let localizedCollectors = NSLocalizedString("collectors", comment: "")
            let backItem = UIBarButtonItem()
            backItem.title = localizedCollectors
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
    let filterSoundsReuse = "filterSoundsReuse"
    let chartsReuse = "chartsReuse"
    let searchTagViewReuse = "searchTagViewReuse"
    let noSoundsReuse = "noSoundsReuse"
    func setUpTableView(_ miniPlayer: UIView?) {
        tableView = UITableView()
        tableView.backgroundColor = color.black()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TagTableViewCell.self, forCellReuseIdentifier: reuse)
        tableView.register(TagTableViewCell.self, forCellReuseIdentifier: chartsReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: filterSoundsReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchProfileReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchTagViewReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearchActive {
            if section == 0 {
                //search title section
                return 1
            } else {
                //search content section
                if searchType == 0 && searchTags.count != 0 {
                    return searchTags.count
                } else if searchType == 1  && searchUsers.count != 0 {
                    return searchUsers.count
                } else if searchType == 2 && soundList != nil {
                    if soundList.sounds.count != 0 {
                        return soundList.sounds.count
                    }
                    return 1 
                }
                
                return 1
            }
            
        } else if section == 0 {
          return 1
        }
        return featureTagTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSearchActive {
            if indexPath.section == 0 {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: filterSoundsReuse) as! SoundListTableViewCell
                cell.selectionStyle = .none 
                cell.backgroundColor = color.black()
                
                cell.searchTagsButton.addTarget(self, action: #selector(didPressSearchTypeButton(_:)), for: .touchUpInside)
                cell.searchTagsButton.tag = 0
                
                cell.searchArtistsButton.addTarget(self, action: #selector(didPressSearchTypeButton(_:)), for: .touchUpInside)
                cell.searchArtistsButton.tag = 1
                
                cell.searchSoundsButton.addTarget(self, action: #selector(didPressSearchTypeButton(_:)), for: .touchUpInside)
                cell.searchSoundsButton.tag = 2
                
                if searchType == 0 {
                    cell.searchTagsButton.setTitleColor(.white, for: .normal)
                    cell.searchArtistsButton.setTitleColor(.darkGray, for: .normal)
                    cell.searchSoundsButton.setTitleColor(.darkGray, for: .normal)
                    
                } else if searchType == 1 {
                    cell.searchTagsButton.setTitleColor(.darkGray, for: .normal)
                    cell.searchArtistsButton.setTitleColor(.white, for: .normal)
                    cell.searchSoundsButton.setTitleColor(.darkGray, for: .normal)
                } else {
                    cell.searchTagsButton.setTitleColor(.darkGray, for: .normal)
                    cell.searchArtistsButton.setTitleColor(.darkGray, for: .normal)
                    cell.searchSoundsButton.setTitleColor(.white, for: .normal)
                }
                return cell
                
            } else {
                if searchType == 0 && searchTags.count != 0 {
                    return searchTags[indexPath.row].cell(tableView, reuse: searchTagViewReuse)
                    
                } else if searchType == 1 && searchUsers.count != 0 {
                    return searchUsers[indexPath.row].cell(tableView, reuse: searchProfileReuse)
                    
                } else if searchType == 2 && soundList != nil {
                    if soundList.sounds.count != 0 {
                        return soundList.soundCell(indexPath, tableView: tableView, reuse: soundReuse)
                    } else {
                        return noResultsCell()
                    }
                    
                } else {
                    return noResultsCell()
                }
            }
            
        } else if indexPath.section == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: chartsReuse) as! TagTableViewCell
            cell.selectionStyle = .none
            cell.backgroundColor = color.black()
            cell.newChartsButton.addTarget(self, action: #selector(didPressChartsButton(_:)), for: .touchUpInside)
            cell.newChartsButton.tag = 0
            
            cell.topChartsButton.addTarget(self, action: #selector(didPressChartsButton(_:)), for: .touchUpInside)
            cell.topChartsButton.tag = 1
            
            cell.followButton.addTarget(self, action: #selector(didPressChartsButton(_:)), for: .touchUpInside)
            cell.followButton.tag = 2
            
            return cell
        }
        return featureTagCell(indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSearchActive && indexPath.section == 1 {
            tableView.cellForRow(at: indexPath)?.isSelected = false
            if searchType == 0 {
                let tag = searchTags[indexPath.row]
                showSounds(tag, soundType: "discover")
                MSAnalytics.trackEvent("Selected Tag", withProperties: ["Tag" : "\(tag.name ?? "")"])
            } else if searchType == 1 {
                self.selectedArtist = searchUsers[indexPath.row]
                self.performSegue(withIdentifier: "showProfile", sender: self)
            } else if searchType == 2 {
                didSelectSoundAt(row: indexPath.row)
            }
        }
    }
    
    func didSelectSoundAt(row: Int) {
        if let player = soundList.player {
            player.didSelectSoundAt(row)
            if player.player != nil {
                self.setUpMiniPlayer()
            } else if self.tableView == nil {
                self.setUpTableView(nil)
            } else {
                self.tableView.reloadData()
            }
        }
    }
    
    func noResultsCell() -> SoundListTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
        cell.backgroundColor = color.black()
        if isLoadingResults {
            cell.headerTitle.text = ""
        } else {
            let localizedNoResults = NSLocalizedString("noResults", comment: "")
            cell.headerTitle.text = localizedNoResults
        }
        return cell
    }
    
    @objc func didPressChartsButton(_ sender: UIButton) {
        let tag = Tag(objectId: nil, name: "new", count: 0, isSelected: false, type: nil, imageURL: nil, uiImage: nil)
        var soundType = "chart"
        if sender.tag == 1 {
            tag.name = "top"
        } else if sender.tag == 2 {
            tag.name = "following"
            soundType = "follow"
        }
        showSounds(tag, soundType: soundType)
    }
    
    //mark: tags
    var featureTagTypes = ["genre","city", "mood", "activity"]
    var topGenreTags = [Tag]()
    var topMoodTags = [Tag]()
    var topActivityTags = [Tag]()
    var topCityTags = [Tag]()
    var chartTags = [Tag]()
    var featureTagScrollview: UIScrollView!
    var selectedTag: Tag!
    var selectedTagType: String!
    let localizedMore = NSLocalizedString("more", comment: "")
    
    func featureTagCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! TagTableViewCell
        cell.selectionStyle = .none
        cell.backgroundColor = color.black()
        cell.tagsScrollview.backgroundColor = color.black()
        
        switch indexPath.row {
        case 0:
            //genre
            cell.TagTypeTitle.text = "Genre"
            addTags(cell.tagsScrollview, tags: topGenreTags, row: indexPath.row)
            break
            
        case 1:
            //city
            let localizedCity = NSLocalizedString("city", comment: "")
            cell.TagTypeTitle.text = localizedCity
            addTags(cell.tagsScrollview, tags: topCityTags, row: indexPath.row)
            break
            
        case 2:
            //mood
            let localizedMood = NSLocalizedString("mood", comment: "")
            cell.TagTypeTitle.text = localizedMood
            addTags(cell.tagsScrollview, tags: topMoodTags, row: indexPath.row)
            break
            
        case 3:
            //activity
            let localizedActivity = NSLocalizedString("activity", comment: "")
            cell.TagTypeTitle.text = localizedActivity
            addTags(cell.tagsScrollview, tags: topActivityTags, row: indexPath.row)
            break
            
        default:
            break
        }
        
        return cell
    }
    
    func addTags(_ scrollview: UIScrollView, tags: Array<Tag>, row: Int) {
        //not using snpakit to set button frame becuase not able to get button width from button title.
        let buttonHeight = 115
        let buttonWidth = 170
        
        var xPositionForFeatureTags = UIElement().leftOffset
        
        for i in 0..<tags.count {
            let tag = tags[i]
            let tagButton = UIButton()
            tagButton.tag = row
            if let tagImage = tag.imageURL {
                tagButton.kf.setBackgroundImage(with: URL(string: tagImage), for: .normal, placeholder: UIImage(named: "hashtag"))
                tagButton.titleLabel?.backgroundColor = color.black().withAlphaComponent(0.5)
                tagButton.titleLabel?.layer.cornerRadius = 3
                tagButton.titleLabel?.clipsToBounds = true
                tagButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: CGFloat(uiElement.leftOffset), bottom: CGFloat(uiElement.topOffset), right: 0)
            } else {
                tagButton.setBackgroundImage(UIImage(named: "background"), for: .normal)
                tagButton.titleLabel?.backgroundColor = .clear
                tagButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: CGFloat(uiElement.leftOffset), bottom: CGFloat((buttonHeight / 2) - 10), right: 0)
            }
            
            tagButton.layer.cornerRadius = 5
            tagButton.clipsToBounds = true
            tagButton.setTitle(tag.name, for: .normal)
            tagButton.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 20)
            tagButton.setTitleColor(.white, for: .normal)
            tagButton.contentHorizontalAlignment = .left
            tagButton.contentVerticalAlignment = .bottom
            scrollview.addSubview(tagButton)
            tagButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(buttonHeight)
                make.width.equalTo(buttonWidth)
                make.top.equalTo(scrollview)
                make.left.equalTo(scrollview).offset(xPositionForFeatureTags)
            }
            
            xPositionForFeatureTags = xPositionForFeatureTags + buttonWidth + uiElement.leftOffset
            scrollview.contentSize = CGSize(width: xPositionForFeatureTags, height: buttonHeight)
            
            if !tags.indices.contains(i + 1) {
                tagButton.addTarget(self, action: #selector(self.didPressViewMoreTagsButton(_:)), for: .touchUpInside)
            } else {
                tagButton.addTarget(self, action: #selector(self.didPressTagButton(_:)), for: .touchUpInside)
            }
        }
    }
    
    @objc func didPressTagButton(_ sender: UIButton) {
        let typeTags = [topGenreTags, topCityTags, topMoodTags, topActivityTags]
        determineSelectedTag(sender, tags: typeTags[sender.tag])
    }
    
    @objc func didPressViewMoreTagsButton(_ sender: UIButton) {
        let selectedTagType = featureTagTypes[sender.tag]
        self.selectedTagType = selectedTagType
        self.performSegue(withIdentifier: "showTags", sender: self)
        MSAnalytics.trackEvent("SearchViewController", withProperties: ["Button" : "View All \(selectedTagType)", "description": "User pressed view all button."])
    }
    
    func determineSelectedTag(_ selectedButton: UIButton, tags: Array<Tag>) {
        let selectedTagTitle = selectedButton.titleLabel!.text!
        for tag in tags {
            if selectedTagTitle == tag.name {
                tag.uiImage = selectedButton.imageView?.image
                showSounds(tag, soundType: "discover")
                MSAnalytics.trackEvent("Selected Tag", withProperties: ["Tag" : "\(selectedTagTitle)"])
            }
        }
    }
    
    func loadTags(_ type: String, searchText: String?) {
        
        let query = PFQuery(className: "Tag")

        if let text = searchText {
            self.searchTags.removeAll()
            query.whereKey("tag", matchesRegex: text.lowercased())
            query.limit = 25
        } else {
            if type != "all" {
                query.whereKey("type", equalTo: type)
            } else {
                 query.whereKey("type", notContainedIn: self.featureTagTypes)
            }
            query.limit = 5
        }
        
        query.addDescendingOrder("count")
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    var tags = [Tag]()
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
                        tags.append(newTag)
                    }
                    
                    if searchText != nil {
                        self.searchTags = tags
                        
                    } else {
                        let browseMoreTag = Tag(objectId: nil, name: "", count: 0, isSelected: false, type: nil, imageURL: nil, uiImage: nil)
                        
                        switch type {
                        case "genre":
                            self.topGenreTags = tags
                            let podcastTagURL = "https://www.soundbrew.app/parse/files/A839D96FA14FCC48772EB62B99FA1/1cf81b20a726ecc5a24173bfcec35dc2_Hashtag_long.png"
                            let podcastTag = Tag(objectId: "AYfH0Ex5i2", name: "podcast", count: 0, isSelected: false, type: "genre", imageURL: podcastTagURL, uiImage: nil)
                            self.topGenreTags.insert(podcastTag, at: 0)
                            browseMoreTag.name = "\(self.localizedMore.capitalized) Genres"
                            self.topGenreTags.append(browseMoreTag)
                            break
                            
                        case "mood":
                            self.topMoodTags = tags
                            let localizedMores = NSLocalizedString("moods", comment: "")
                            browseMoreTag.name = "\(self.localizedMore.capitalized) \(localizedMores)"
                            self.topMoodTags.append(browseMoreTag)
                            break
                            
                        case "activity":
                            self.topActivityTags = tags
                            let localizedActivities = NSLocalizedString("activities", comment: "")
                            browseMoreTag.name = "\(self.localizedMore.capitalized) \(localizedActivities)"
                            self.topActivityTags.append(browseMoreTag)
                            break
                            
                        case "city":
                            self.topCityTags = tags
                            let localizedCities = NSLocalizedString("cities", comment: "")
                            browseMoreTag.name = "\(self.localizedMore.capitalized) \(localizedCities)"
                            self.topCityTags.append(browseMoreTag)
                            break
                            
                        default:
                            break
                        }
                    }
                }
                
                self.isLoadingResults = false
                let player = Player.sharedInstance
                if player.player != nil {
                    self.setUpMiniPlayer()
                } else if self.tableView == nil {
                    self.setUpTableView(nil)
                } else {
                    self.tableView.reloadData()
                }
                
            } else {
                print("Error: \(error!)")
                let localizedOops = NSLocalizedString("oops", comment: "")
                self.uiElement.showAlert(localizedOops, message: "\(error!.localizedDescription)", target: self)
            }
        }
    }
    
    //mark: miniPlayer
    var miniPlayerView: MiniPlayerView?
    func setUpMiniPlayer() {
        miniPlayerView = MiniPlayerView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        self.view.addSubview(miniPlayerView!)
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
        
        setUpTableView(miniPlayerView)
    }
    
    @objc func miniPlayerWasSwiped() {
        showPlayerViewController()
        MSAnalytics.trackEvent("Mini Player", withProperties: ["View" : "SearchViewController", "description": "User did start Searching."])
    }
    
    @objc func miniPlayerWasPressed(_ sender: UIButton) {
        showPlayerViewController()
        MSAnalytics.trackEvent("Mini Player", withProperties: ["View" : "SearchViewController", "description": "User did start Searching."])
    }
    
    func showPlayerViewController() {
        let player = Player.sharedInstance
        if player.player != nil {
            let modal = PlayerViewController()
            modal.playerDelegate = self
            self.present(modal, animated: true, completion: nil)
        }
    }
    
    //mark: selectedArtist
    var selectedArtist: Artist?
    
    func selectedArtist(_ artist: Artist?) {
        if let artist = artist {
            if artist.objectId == "addFunds" {
                self.performSegue(withIdentifier: "showAddFunds", sender: self)
            } else if artist.objectId == "signup" {
                self.performSegue(withIdentifier: "showWelcome", sender: self)
            } else if artist.objectId == "collectors" {
                self.performSegue(withIdentifier: "showTippers", sender: self)
            } else {
                if soundList == nil {
                   self.selectedArtist = artist
                    self.performSegue(withIdentifier: "showProfile", sender: self)
                } else {
                  soundList.selectedArtist(artist)
                }
            }
        }
    }
    
    //mark: search
    var isSearchActive = false
    var searchUsers = [Artist]()
    var searchTags = [Tag]()
    var soundList: SoundList!
    var searchType = 0
    
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width - 5, height: 10))
        searchBar.placeholder = "Search"
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
        let leftNavBarButton = UIBarButtonItem(customView: searchBar)
        self.navigationItem.leftBarButtonItem = leftNavBarButton
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
        if searchType == 0 {
            loadTags("", searchText: searchBar.text!)
        } else if searchType == 1 {
            searchUsers(searchBar.text!)
        } else {
            soundList = SoundList(target: self, tableView: tableView, soundType: "search", userId: nil, tags: nil, searchText: searchBar.text!, descendingOrder: nil, linkObjectId: nil)
        }
        
        let player = Player.sharedInstance
        if player.player != nil {
            self.setUpMiniPlayer()
        } else if self.tableView == nil {
            self.setUpTableView(nil)
        } else {
            self.tableView.reloadData()
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearchActive = true
        self.tableView.reloadData()
        searchBar.setShowsCancelButton(true, animated: true)
                
        MSAnalytics.trackEvent("SearchViewController", withProperties: ["Button" : "Search", "description": "User did start Searching."])
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        search()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = ""
        self.searchBar.resignFirstResponder()
        isSearchActive = false
        self.tableView.reloadData()
    }
    
    func searchUsers(_ text: String) {
        self.searchUsers.removeAll()
        let nameQuery = PFQuery(className: "_User")
        nameQuery.whereKey("artistName", matchesRegex: text.lowercased())
        nameQuery.whereKey("artistName", matchesRegex: text)
        
        let usernameQuery = PFQuery(className: "_User")
        usernameQuery.whereKey("username", matchesRegex: text.lowercased())
        
        let cityQuery = PFQuery(className: "_User")
        cityQuery.whereKey("artistName", matchesRegex: text.lowercased())
        
        let query = PFQuery.orQuery(withSubqueries: [nameQuery, usernameQuery, cityQuery])
        query.limit = 50
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for user in objects {
                        let username = user["username"] as? String
                        
                        var email: String?
                        
                        if let currentUser = PFUser.current() {
                            if currentUser.objectId! == user.objectId! {
                                email = user["email"] as? String
                            }
                        }
                        
                        let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: false, username: username, website: nil, bio: nil, email: email, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil)
                        
                        if let followerCount = user["followerCount"] as? Int {
                            artist.followerCount = followerCount
                        }
                        
                        if let name = user["artistName"] as? String {
                            artist.name = name
                        }
                        
                        if let username = user["username"] as? String {
                            if username.contains("@") {
                                artist.username = ""
                            } else {
                                artist.username = username
                            }
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
                        
                        self.searchUsers.append(artist)
                    }
                }
                
                self.isLoadingResults = false
                self.tableView.reloadData()
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
        
    //mark: dynamic link
    func checkForProfileDynamicLink() {
        if self.uiElement.getUserDefault("receivedUserId") != nil || self.uiElement.getUserDefault("receivedUsername") != nil {
            self.performSegue(withIdentifier: "showProfile", sender: self)
        }
    }
}

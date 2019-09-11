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
import DeckTransition
class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, PlayerDelegate {
    let color = Color()
    let uiElement = UIElement()
    var soundType: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        setupSearchBar()
        for featureTagType in featureTagTypes {
            loadTags(featureTagType)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        navigationItem.backBarButtonItem = backItem
        
        let player = Player.sharedInstance
        if player.player != nil {
            self.setUpMiniPlayer()
        } else if self.tableView == nil {
            self.setUpTableView(nil)
        } else {
            self.tableView.reloadData()
        }
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
    let filterSoundsReuse = "filterSoundsReuse"
    let chartsReuse = "chartsReuse"
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
                return 1
            } else {
                if searchType == 0 {
                    return searchUsers.count
                } else if soundList != nil {
                    return soundList.sounds.count
                } else {
                    return 0
                }
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
                cell.backgroundColor = color.black()
                cell.newButton.setTitle("Artists", for: .normal)
                cell.newButton.addTarget(self, action: #selector(didPressSearchTypeButton(_:)), for: .touchUpInside)
                cell.newButton.tag = 0
                
                cell.popularButton.setTitle("Music", for: .normal)
                cell.popularButton.addTarget(self, action: #selector(didPressSearchTypeButton(_:)), for: .touchUpInside)
                cell.popularButton.tag = 1
                
                if searchType == 0 {
                    cell.newButton.setTitleColor(.white, for: .normal)
                    cell.popularButton.setTitleColor(.darkGray, for: .normal)
                    
                } else {
                    cell.newButton.setTitleColor(.darkGray, for: .normal)
                    cell.popularButton.setTitleColor(.white, for: .normal)
                }
                return cell
                
            } else {
                if searchType == 0 {
                    return searchUsers[indexPath.row].cell(tableView, reuse: searchProfileReuse)
                } else {
                    let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
                    cell.backgroundColor = color.black()
                    return soundList.soundCell(indexPath, cell: cell)
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
            return cell
        }
        return featureTagCell(indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSearchActive && indexPath.section == 1 {
            tableView.cellForRow(at: indexPath)?.isSelected = false
            if searchType == 0 {
                self.selectedArtist = searchUsers[indexPath.row]
                self.performSegue(withIdentifier: "showProfile", sender: self)
            } else {
                didSelectSoundAt(row: indexPath.row)
            }
        }
    }
    
    func didSelectSoundAt(row: Int) {
        if let player = soundList.player {
            player.didSelectSoundAt(row)
            tableView.reloadData()
        }
    }
    
    @objc func didPressSearchTypeButton(_ sender: UIButton) {
       let currentSearchType = self.searchType
        self.searchType = sender.tag
        if currentSearchType != self.searchType {
            self.tableView.reloadData()
        }
    }
    
    @objc func didPressChartsButton(_ sender: UIButton) {
        let tag = Tag(objectId: nil, name: "new", count: 0, isSelected: false, type: nil, image: nil)
        if sender.tag == 1 {
            tag.name = "top"
        }
        showSounds(tag, soundType: "chart")
    }
    
    //mark: tags
    var featureTagTypes = ["genre","city", "mood", "activity", "more"]
    var topGenreTags = [Tag]()
    var topMoodTags = [Tag]()
    var topActivityTags = [Tag]()
    var topCityTags = [Tag]()
    var topAllTags = [Tag]()
    var chartTags = [Tag]()
    var featureTagScrollview: UIScrollView!
    var selectedTag: Tag!
    var selectedTagType: String!
    
    func featureTagCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! TagTableViewCell
        cell.selectionStyle = .none
        cell.backgroundColor = color.black()
        cell.tagsScrollview.backgroundColor = color.black()
        cell.tagTypeButton.tag = indexPath.row
        cell.TagTypeTitle.text = "\(featureTagTypes[indexPath.row].capitalized)"
        cell.tagTypeButton.addTarget(self, action: #selector(self.didPressViewAllTagsButton(_:)), for: .touchUpInside)
        
        switch indexPath.row {
        case 0:
            //genre
            addTags(cell.tagsScrollview, tags: topGenreTags, row: 0)
            break
            
        case 1:
            //city
            addTags(cell.tagsScrollview, tags: topCityTags, row: 3)
            
            break
            
        case 2:
            //mood
            addTags(cell.tagsScrollview, tags: topMoodTags, row: 1)
            
            break
            
        case 3:
            //activity
            addTags(cell.tagsScrollview, tags: topActivityTags, row: 2)
            break
            
        default:
            //all
            addTags(cell.tagsScrollview, tags: topAllTags, row: 4)
            break
        }
        
        return cell
    }
    
    @objc func didPressViewAllTagsButton(_ sender: UIButton) {
        let selectedTagType = featureTagTypes[sender.tag]
        
        //want to insure that feature tag types like activity, mood, etc aren't shown
        if selectedTagType == "all" {
            self.selectedTagType = "more"
        } else {
            self.selectedTagType = featureTagTypes[sender.tag]
        }
        self.performSegue(withIdentifier: "showTags", sender: self)
    }
    
    func addTags(_ scrollview: UIScrollView, tags: Array<Tag>, row: Int) {
        //not using snpakit to set button frame becuase not able to get button width from button title.
        let buttonHeight = 130
        let buttonWidth = 200
        var xPositionForFeatureTags = UIElement().leftOffset
        
        for tag in tags {
            let tagButton = UIButton()
            tagButton.setBackgroundImage(UIImage(named: "hashtag"), for: .normal)
            /*if let tagImage = tag.image {
                tagButton.kf.setBackgroundImage(with: URL(string: tagImage), for: .normal)
             } else {
             tagButton.setBackgroundImage(UIImage(named: "hashtag"), for: .normal)
             }*/
            tagButton.layer.cornerRadius = 5
            tagButton.clipsToBounds = true
            tagButton.tag = row
            tagButton.setTitle(tag.name, for: .normal)
            tagButton.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 20)
            tagButton.setTitleColor(.white, for: .normal)
            tagButton.contentHorizontalAlignment = .left
            tagButton.contentVerticalAlignment = .bottom
            tagButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: CGFloat(uiElement.leftOffset), bottom: CGFloat(uiElement.topOffset), right: 0)
            tagButton.addTarget(self, action: #selector(self.didPressTagButton(_:)), for: .touchUpInside)
            scrollview.addSubview(tagButton)
            tagButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(buttonHeight)
                make.width.equalTo(buttonWidth)
                make.top.equalTo(scrollview)
                make.left.equalTo(scrollview).offset(xPositionForFeatureTags)
            }
            
            xPositionForFeatureTags = xPositionForFeatureTags + buttonWidth + uiElement.leftOffset
            scrollview.contentSize = CGSize(width: xPositionForFeatureTags, height: buttonHeight)
        }
    }
    
    @objc func didPressTagButton(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            determineSelectedTag(selectedTagTitle: sender.titleLabel!.text!, tags: topGenreTags)
            break
            
        case 1:
            determineSelectedTag(selectedTagTitle: sender.titleLabel!.text!, tags: topMoodTags)
            break
            
        case 2:
            determineSelectedTag(selectedTagTitle: sender.titleLabel!.text!, tags: topActivityTags)
            break
            
        case 3:
            determineSelectedTag(selectedTagTitle: sender.titleLabel!.text!, tags: topCityTags)
            break
            
        default:
            determineSelectedTag(selectedTagTitle: sender.titleLabel!.text!, tags: topAllTags)
            break
        }
    }
    
    func determineSelectedTag(selectedTagTitle: String, tags: Array<Tag>) {
        for tag in tags {
            if selectedTagTitle == tag.name {
                showSounds(tag, soundType: "discover")
            }
        }
    }
    
    func loadTags(_ type: String) {
        let query = PFQuery(className: "Tag")
        if type != "all" {
            query.whereKey("type", equalTo: type)
        } else {
             query.whereKey("type", notContainedIn: self.featureTagTypes)
        }
        query.addDescendingOrder("count")
        query.limit = 5
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let tagName = object["tag"] as! String
                        let tagCount = object["count"] as! Int
                        
                        let newTag = Tag(objectId: object.objectId, name: tagName, count: tagCount, isSelected: false, type: nil, image: nil)
                        
                        if let image = object["image"] as? PFFileObject {
                            newTag.image = image.url
                        }
                        
                        if let tagType = object["type"] as? String {
                            if !tagType.isEmpty {
                                newTag.type = tagType
                            }
                        }
                        
                        switch type {
                        case "genre":
                            self.topGenreTags.append(newTag)
                            break
                            
                        case "mood":
                            self.topMoodTags.append(newTag)
                            break
                            
                        case "activity":
                            self.topActivityTags.append(newTag)
                            break
                            
                        case "city":
                            self.topCityTags.append(newTag)
                            break
                            
                        default:
                            self.topAllTags.append(newTag)
                            break
                        }
                    }
                }
                
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
                self.uiElement.showAlert("Oops", message: "\(error!)", target: self)
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
            make.bottom.equalTo(self.view).offset(-49)
        }
        
        setUpTableView(miniPlayerView)
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
            let modal = PlayerV2ViewController()
            modal.player = player
            modal.playerDelegate = self
            let transitionDelegate = DeckTransitioningDelegate()
            modal.transitioningDelegate = transitionDelegate
            modal.modalPresentationStyle = .custom
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
    var searchSounds = [Sound]()
    var searchUsers = [Artist]()
    var soundList: SoundList!
    var searchType = 0
    
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width - 5, height: 10))
        searchBar.placeholder = "Artists & Music"
        
        let searchTextField = searchBar.value(forKey: "_searchField") as? UITextField
        searchTextField?.backgroundColor = color.black()
        searchTextField?.textColor = .white
        searchBar.delegate = self
        
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        return searchBar
    }()
    
    func setupSearchBar() {
        let leftNavBarButton = UIBarButtonItem(customView: searchBar)
        self.navigationItem.leftBarButtonItem = leftNavBarButton
    }
    
    func search() {
        if searchType == 0 {
            searchUsers(searchBar.text!)
        } else {
            soundList = SoundList(target: self, tableView: tableView, soundType: "search", userId: nil, tags: nil, searchText: searchBar.text!, descendingOrder: nil)
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
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            search()
            
        } else {
            if searchType == 0 {
                self.searchUsers.removeAll()
            } else {
                self.soundList.sounds.removeAll()
            }
            self.tableView.reloadData()
        }
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
        cityQuery.whereKey("city", matchesRegex: text.lowercased())
        
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

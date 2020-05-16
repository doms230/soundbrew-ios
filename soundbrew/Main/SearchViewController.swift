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

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, PlayerDelegate, TagDelegate {
    let color = Color()
    let uiElement = UIElement()
    var soundType: String!
    var soundList: SoundList!
    var isLoadingResults = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        setupSearchBar()
        setupTags()
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
        
        let player = Player.sharedInstance
        if player.player != nil {
            setUpMiniPlayer()
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
    let filterSoundsReuse = "filterSoundsReuse"
    let searchTagViewReuse = "searchTagViewReuse"
    let noSoundsReuse = "noSoundsReuse"
    let newSoundsReuse = "newSoundsReuse"
    func setUpTableView(_ miniPlayer: UIView?) {
        tableView = UITableView()
        tableView.backgroundColor = color.black()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TagTableViewCell.self, forCellReuseIdentifier: reuse)
        tableView.register(TagTableViewCell.self, forCellReuseIdentifier: newSoundsReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: filterSoundsReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchProfileReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchTagViewReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        tableView.register(TagTableViewCell.self, forCellReuseIdentifier: newSoundsReuse)
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
            
        } else if !isSearchActive && section == 0 {
            return 1
        }
        
        return featureTagTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
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
        let player = soundList.player
        player.didSelectSoundAt(row)
        if player.player != nil {
            self.setUpMiniPlayer()
        } else if self.tableView == nil {
            self.setUpTableView(nil)
        } else {
            self.tableView.reloadData()
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
          //  if error == nil {

                
         /*   } else {
                print("Error: \(error!)")
                let localizedOops = NSLocalizedString("oops", comment: "")
                self.uiElement.showAlert(localizedOops, message: "\(error!.localizedDescription)", target: self)
            }*/
        }
    }
    
    func handleTableViewLogic() {
        self.isLoadingResults = false
        let player = Player.sharedInstance
        if player.player != nil {
            self.setUpMiniPlayer()
        } else if self.tableView == nil {
            self.setUpTableView(nil)
        } else {
            self.tableView.reloadData()
        }
    }
    
    //mark: miniPlayer
    var miniPlayerView: MiniPlayerView?
    func setUpMiniPlayer() {
        DispatchQueue.main.async {
            self.miniPlayerView = MiniPlayerView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            self.miniPlayerView?.superViewController = self 
            self.view.addSubview(self.miniPlayerView!)
             let slide = UISwipeGestureRecognizer(target: self, action: #selector(self.miniPlayerWasSwiped))
             slide.direction = .up
            self.miniPlayerView!.addGestureRecognizer(slide)
            self.miniPlayerView!.addTarget(self, action: #selector(self.miniPlayerWasPressed(_:)), for: .touchUpInside)
            self.miniPlayerView!.snp.makeConstraints { (make) -> Void in
                 make.height.equalTo(75)
                 make.right.equalTo(self.view)
                 make.left.equalTo(self.view)
                 make.bottom.equalTo(self.view).offset(-((self.tabBarController?.tabBar.frame.height)!))
             }
            self.setUpTableView(self.miniPlayerView)
        }
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
            modal.tagDelegate = self
            self.present(modal, animated: true, completion: nil)
        }
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
        if searchType == 0 {
            loadTags("", searchText: searchBar.text!)
        } else if !searchBar.text!.isEmpty {
            if searchType == 1 {
                searchUsers(searchBar.text!)
            } else {
                soundList = SoundList(target: self, tableView: tableView, soundType: "search", userId: nil, tags: nil, searchText: searchBar.text!, descendingOrder: nil, linkObjectId: nil)
            }
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
        query.limit = 50
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

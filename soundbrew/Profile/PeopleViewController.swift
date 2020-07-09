//
//  FollowersFollowingViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/10/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse

class PeopleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    let color = Color()
    let uiElement = UIElement()
    
    var artists = [Artist]()
    var filteredArtists = [Artist]()
    
    var soundCredits = [Credit]()
    
    var loadType = "following"
    var sound: Sound!
    
    var playerDelegate: PlayerDelegate?

    //credits
    var isAddingNewCredit = false
    var creditArtistObjectIds = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTopView()
        
        if sound == nil {
            loadFollowersFollowing(loadType)
        } else {
            switch loadType {
            case "likes":
                loadLikes()
                break
            case "listens":
                loadListens()
                break
            default:
                break
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showProfile":
            let viewController = segue.destination as! ProfileViewController
            viewController.profileArtist = selectedArtist
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
            break
            
        default:
            break
        }
    }
    
    @objc func didPressExitButton(_ sender: UIButton) {
        if sender.tag == 0 {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    lazy var appTitle: UILabel = {
        let label = UILabel()
        label.text = "Soundbrew"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 15)
        label.textAlignment = .center
        return label
    }()
    
    //mark: top view
    var dividerLine: UIView!
    
    func setupTopView() {
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        if isAddingNewCredit || sound != nil {
            let topView = self.uiElement.addSubViewControllerTopView(self, action: #selector(didPressExitButton(_:)), doneButtonTitle: "", title: loadType.capitalized)
            dividerLine = topView.2
        }
    }
    
    //MARK: Tableview
    let tableView = UITableView()
    let searchProfileReuse = "searchProfileReuse"
    let noSoundsReuse = "noSoundsReuse"
    let searchReuse = "searchReuse"
    func setUpTableView() {
        let miniPlayerHeight = MiniPlayerView.sharedInstance.frame.height
        var tabBarControllerHeight: CGFloat = 50
        if let tabBar = self.tabBarController?.tabBar {
            tabBarControllerHeight = tabBar.frame.height
        }
        
        self.filteredArtists = self.artists
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchProfileReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = color.black()
        tableView.tintColor = color.black()
        self.view.addSubview(tableView)
        if isAddingNewCredit || sound != nil {
            tableView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.dividerLine.snp.bottom)
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
                make.bottom.equalTo(self.view)
            }
        } else if sound == nil {
            tableView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.view)
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
                make.bottom.equalTo(self.view).offset(-(miniPlayerHeight + tabBarControllerHeight))
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if isAddingNewCredit {
            return 2
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isAddingNewCredit {
            if section == 1 && self.filteredArtists.count != 0 {
                return filteredArtists.count
            }
        } else if filteredArtists.count != 0 {
            return filteredArtists.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isAddingNewCredit {
            if indexPath.section == 0 {
                return searchCell()
            } else {
                 if filteredArtists.count == 0 {
                    return noResultsCell()
                } else {
                    return peopleCell(indexPath)
                }
            }

        } else if filteredArtists.count == 0 {
            return noResultsCell()
        } else {
            return peopleCell(indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        
        if isAddingNewCredit {
            if indexPath.section == 1 {
                if filteredArtists.count == 0 {
                    let url = "https://www.soundbrew.app/ios"
                    let text = "Hey, download and sign up for Soundbrew so I can credit you on my next upload!"
                    let activityViewController = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = self.view
                    self.present(activityViewController, animated: true, completion: { () -> Void in
                    })
                    
                } else if self.filteredArtists.indices.contains(indexPath.row) {
                    selectedArtist(self.filteredArtists[indexPath.row])
                }
            }
            
        } else if self.filteredArtists.indices.contains(indexPath.row) {
            selectedArtist(self.filteredArtists[indexPath.row])
        }
    }
    
    func peopleCell(_ indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: searchProfileReuse) as! ProfileTableViewCell
        cell.backgroundColor = color.black()
        self.filteredArtists[indexPath.row].loadUserInfoFromCloud(cell, soundCell: nil, commentCell: nil, artistUsernameLabel: nil, artistImageButton: nil)
        return cell
    }
    
    func noResultsCell() -> SoundListTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        if isAddingNewCredit {
            cell.headerTitle.text = "No results. Tap here to invite someone to Soundbrew."
        } else if sound != nil {
            cell.headerTitle.text = "No \(loadType) yet."
        } else if loadType == "followers" {
            let localizedNoFollowers = NSLocalizedString("noFollowers", comment: "")
            cell.headerTitle.text = localizedNoFollowers
        } else if loadType == "following" {
            let localizedNotFollowingAnyone = NSLocalizedString("notFollowingAnyone", comment: "")
            cell.headerTitle.text = localizedNotFollowingAnyone
        }
        
        return cell
    }
    
    //mark: selectedArtist
    var selectedArtist: Artist!
    var artistDelegate: ArtistDelegate?
    
    func selectedArtist(_ artist: Artist?) {
        if let artist = artist {
            if isAddingNewCredit {
                if let artistDelegate = self.artistDelegate {
                    self.dismiss(animated: true, completion: {() in
                        artistDelegate.receivedArtist(artist)
                    })
                }
            } else if loadType == "following" || loadType == "followers" || loadType == "fans" {
                selectedArtist = artist
                self.performSegue(withIdentifier: "showProfile", sender: self)
            } else if let playerDelegate = self.playerDelegate {
                    self.dismiss(animated: false, completion: {() in
                        playerDelegate.selectedArtist(artist)
                    })
            }
        }
    }
    
    func loadFollowersFollowing(_ loadType: String) {
        let query = PFQuery(className: "Follow")
        if loadType == "followers" {
            query.whereKey("toUserId", equalTo: PFUser.current()!.objectId!)
        } else if loadType == "following" {
            query.whereKey("fromUserId", equalTo: PFUser.current()!.objectId!)
        } else if loadType == "fans" {
            query.whereKey("toUserId", equalTo: PFUser.current()!.objectId!)
             query.whereKey("isFan", equalTo: true)
        }
        query.whereKey("isRemoved", equalTo: false)
        query.limit = 50
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                for object in objects {
                    var userId: String!
                    if loadType == "followers" || loadType == "fans"  {
                        userId = object["fromUserId"] as? String
                    } else if loadType == "following" {
                        userId = object["toUserId"] as? String
                    }
                    let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, fanCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, account: nil)
                    self.artists.append(artist)
                }
            }
            
            self.setUpTableView()
        }
    }
    
    func loadLikes() {
        let query = PFQuery(className: "Tip")
        query.whereKey("soundId", equalTo: sound.objectId!)
        query.limit = 50
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                for object in objects {
                    let userId = object["fromUserId"] as? String
                    let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, fanCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, account: nil)
                    
                    let userIds = self.artists.map {$0.objectId}
                    if !userIds.contains(userId) {
                        self.artists.append(artist)
                    }
                }
            }
            
            self.setUpTableView()
        }
    }
    
    func loadListens() {
        let query = PFQuery(className: "Listen")
        query.whereKey("postId", equalTo: sound.objectId!)
        query.limit = 50
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                for object in objects {
                    let userId = object["userId"] as? String
                    let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, fanCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, account: nil)
                    
                    let userIds = self.artists.map {$0.objectId}
                    if !userIds.contains(userId) {
                        self.artists.append(artist)
                    }
                }
            }
            
            self.setUpTableView()
        }
    }

    //mark: search
    var isSearchActive = false
    var searchTags = [Tag]()
    var soundList: SoundList!
    var searchType = 0
    var searchBar: UISearchBar!
    
    func searchCell() -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: searchReuse) as! ProfileTableViewCell
        cell.selectionStyle = .none
        cell.backgroundColor = color.black()
        cell.searchBar.backgroundColor = color.black()
        self.searchBar = cell.searchBar
        self.searchBar.delegate = self
        searchBar.becomeFirstResponder()
        return cell
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearchActive = true
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchUsers(searchBar.text!)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = ""
        self.searchBar.resignFirstResponder()
        isSearchActive = false
        self.tableView.reloadData()
    }
    
    func searchUsers(_ text: String) {
        self.filteredArtists.removeAll()
        let nameQuery = PFQuery(className: "_User")
        nameQuery.whereKey("artistName", matchesRegex: text.lowercased())
        nameQuery.whereKey("artistName", matchesRegex: text)
        
        let usernameQuery = PFQuery(className: "_User")
        usernameQuery.whereKey("username", matchesRegex: text.lowercased())
        
        let query = PFQuery.orQuery(withSubqueries: [nameQuery, usernameQuery])
        query.whereKey("objectId", notContainedIn: self.creditArtistObjectIds)
        query.limit = 50
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                for user in objects {
                    let username = user["username"] as? String
                    
                    var email: String?
                    
                    if let currentUser = PFUser.current() {
                        if currentUser.objectId! == user.objectId! {
                            email = user["email"] as? String
                        }
                    }
                    
                    let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: false, username: username, website: nil, bio: nil, email: email, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, fanCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, account: nil)
                    
                    artist.isVerified = user["isVerified"] as? Bool
                    artist.followerCount = user["followerCount"] as? Int
                    
                    if let name = user["artistName"] as? String {
                        artist.name = name
                    } else {
                        artist.name = ""
                    }
                    
                    if let username = user["username"] as? String {
                        if username.contains("@") {
                            artist.username = ""
                        } else {
                            artist.username = username
                        }
                    }
                     
                    artist.city = user["city"] as? String
                    artist.image = (user["userImage"] as? PFFileObject)?.url
                    artist.bio = user["bio"] as? String
                    artist.isVerified = user["artistVerification"] as? Bool
                    artist.website = user["website"] as? String
                    
                    var account: Account?
                    
                    if let accountId = user["accountId"] as? String, !accountId.isEmpty {
                        account = Account(accountId, productId: nil)
                    }
                    
                    if let productId = user["productId"] as? String, !productId.isEmpty {
                        account?.productId = productId
                    }
                    
                    self.filteredArtists.append(artist)
                }
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadSections([1], with: .automatic)
            }
        }
    }
}

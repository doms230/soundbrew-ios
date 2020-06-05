//
//  FollowersFollowingViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/10/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import AppCenterAnalytics

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
                
            case "credits":
                loadCredits()
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
    
    lazy var exitButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "dismiss"), for: .normal)
        button.addTarget(self, action: #selector(self.didPressExitButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressExitButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
        MSAnalytics.trackEvent("PlayerViewController", withProperties: ["Button" : "Exit Button", "Description": "User Exited PlayerViewController."])
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
    func setupTopView() {
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        if isAddingNewCredit {
            let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.didPressExitButton(_:)))
            navigationItem.leftBarButtonItem = cancelButton
        } else if sound != nil {
            self.title = "\(loadType.capitalized)"
            self.view.addSubview(exitButton)
            exitButton.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(25)
                make.top.equalTo(self.view).offset(uiElement.topOffset)
                make.left.equalTo(self.view).offset(uiElement.leftOffset)
            }
            
            appTitle.text = loadType.capitalized
            self.view.addSubview(appTitle)
            appTitle.snp.makeConstraints { (make) -> Void in
                make.centerX.equalTo(self.view)
                make.centerY.equalTo(exitButton)
            }
        }
    }
    
    //MARK: Tableview
    let tableView = UITableView()
    let searchProfileReuse = "searchProfileReuse"
    let noSoundsReuse = "noSoundsReuse"
    let searchReuse = "searchReuse"
    let creditProfileReuse = "creditProfileReuse"
    func setUpTableView() {
        self.filteredArtists = self.artists
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchProfileReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: creditProfileReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = color.black()
        tableView.tintColor = color.black()
        self.view.addSubview(tableView)
        if sound == nil {
            tableView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.view)
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
                make.bottom.equalTo(self.view).offset(-165)
            }
        } else {
            tableView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(exitButton.snp.bottom)
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
                make.bottom.equalTo(self.view)
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
        } else {
            if loadType == "credits" && self.soundCredits.count != 0 {
                return soundCredits.count
            } else if filteredArtists.count != 0 {
                return filteredArtists.count
            }
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

        } else {
            if loadType == "credits" {
                if soundCredits.count == 0 {
                    return noResultsCell()
                } else {
                    return creditsCell(indexPath)
                }
            }
            
            if filteredArtists.count == 0 {
                return noResultsCell()
            } else {
                return peopleCell(indexPath)
            }
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
            
        } else {
            if loadType == "credits" {
                if self.soundCredits.indices.contains(indexPath.row) {
                    selectedArtist(self.soundCredits[indexPath.row].artist)
                }
                
            } else if self.filteredArtists.indices.contains(indexPath.row) {
                selectedArtist(self.filteredArtists[indexPath.row])
            }
        }
    }
    
    func creditsCell(_ indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: creditProfileReuse) as! ProfileTableViewCell
        cell.backgroundColor = color.black()
        let credit = self.soundCredits[indexPath.row]
        credit.artist?.loadUserInfoFromCloud(cell, soundCell: nil, commentCell: nil, artistUsernameLabel: nil, artistImageButton: nil)
        if let title = credit.title {
            cell.creditTitle.text = title
        }
        
        if let percentage = credit.percentage {
            cell.creditPercentage.text = "\(percentage)%"
        }
        
        return cell
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
            } else if loadType == "following" || loadType == "followers" {
                selectedArtist = artist
                self.performSegue(withIdentifier: "showProfile", sender: self)
                MSAnalytics.trackEvent("People View Controller", withProperties: ["Button" : "Did Select Person"])
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
        }
        query.whereKey("isRemoved", equalTo: false)
        query.limit = 50
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                for object in objects {
                    var userId: String!
                    if loadType == "followers" {
                        userId = object["fromUserId"] as? String
                    } else if loadType == "following" {
                        userId = object["toUserId"] as? String
                    }
                    let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, accountId: nil)
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
                    let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, accountId: nil)
                    
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
                    let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, accountId: nil)
                    
                    let userIds = self.artists.map {$0.objectId}
                    if !userIds.contains(userId) {
                        self.artists.append(artist)
                    }
                }
            }
            
            self.setUpTableView()
        }
    }
    
    func loadCredits() {
        let query = PFQuery(className: "Credit")
        query.whereKey("postId", equalTo: sound.objectId!)
        query.addAscendingOrder("createdAt")
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                for object in objects {
                    let userId = object["userId"] as? String
                    let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, accountId: nil)
                    
                    let userIds = self.artists.map {$0.objectId}
                    if !userIds.contains(userId) {
                        let credit = Credit(objectId: object.objectId, artist: artist, title: nil, percentage: 0)
                        if let title = object["title"] as? String {
                            credit.title = title
                        }
                        if let percentage = object["percentage"] as? Int {
                            credit.percentage = percentage
                        }
                        self.soundCredits.append(credit)
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
                    
                    let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: false, username: username, website: nil, bio: nil, email: email, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, accountId: nil)
                    
                    if let followerCount = user["followerCount"] as? Int {
                        artist.followerCount = followerCount
                    }
                    
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
                    
                    self.filteredArtists.append(artist)
                }
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadSections([1], with: .automatic)
            }
        }
    }
}

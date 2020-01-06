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
    
    var loadType = "following"
    var sound: Sound!
    
    var isAddingNewCredit = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
                
        if sound == nil || isAddingNewCredit {
            loadFollowersFollowing(loadType)
        } else {
            loadTippers()
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
    
    //MARK: Tableview
    let tableView = UITableView()
    let searchTagViewReuse = "searchTagViewReuse"
    let noSoundsReuse = "noSoundsReuse"
    let searchReuse = "searchReuse"
    func setUpTableView() {
        self.filteredArtists = self.artists
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchTagViewReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.backgroundColor = color.black()
        self.tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            if filteredArtists.count == 0 {
                return 1
            }
            return filteredArtists.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: searchReuse) as! ProfileTableViewCell
            cell.backgroundColor = color.black()
            self.searchBar = cell.searchBar
            return cell
            
        } else {
            if filteredArtists.count == 0 {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
                cell.backgroundColor = color.black()
                
                if isAddingNewCredit {
                    cell.headerTitle.text = "No results. Tap here to invite someone to Soundbrew."
                } else if sound != nil {
                    let localizedNoCollectors = NSLocalizedString("noCollectors", comment: "")
                    cell.headerTitle.text = localizedNoCollectors
                } else if loadType == "followers" {
                    let localizedNoFollowers = NSLocalizedString("noFollowers", comment: "")
                    cell.headerTitle.text = localizedNoFollowers
                } else if loadType == "following" {
                    let localizedNotFollowingAnyone = NSLocalizedString("notFollowingAnyone", comment: "")
                    cell.headerTitle.text = localizedNotFollowingAnyone
                }
                
                return cell
            } else {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: searchTagViewReuse) as! ProfileTableViewCell
                cell.backgroundColor = color.black()
                self.filteredArtists[indexPath.row].loadUserInfoFromCloud(cell, soundCell: nil)
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            tableView.cellForRow(at: indexPath)?.isSelected = false
            if self.filteredArtists.indices.contains(indexPath.row) {
                //selectedArtist = self.filteredArtists[indexPath.row]
                selectedArtist(self.filteredArtists[indexPath.row])
            }
        }
    }
    
    //mark: selectedArtist
    var selectedArtist: Artist!
    var artistDelegate: ArtistDelegate?
    
    func selectedArtist(_ artist: Artist?) {
        if let artist = artist {
            if isAddingNewCredit {
                print("selected artists is adding new credit")
                if let artistDelegate = self.artistDelegate {
                    self.dismiss(animated: true, completion: {() in
                        artistDelegate.receivedArtist(artist)
                    })
                }
            } else {
                selectedArtist = artist
                self.performSegue(withIdentifier: "showProfile", sender: self)
                MSAnalytics.trackEvent("People View Controller", withProperties: ["Button" : "Did Select Person"])
            }
            
            
           /* if isAddingNewCredit {
                print("selected artists is adding new credit")
                if let artistDelegate = self.artistDelegate {
                    self.dismiss(animated: true, completion: {() in
                        artistDelegate.receivedArtist(artist)
                    })
                }
            } else if artist.objectId == "addFunds" {
                self.performSegue(withIdentifier: "showAddFunds", sender: self)
            } else if artist.objectId == "signup" {
                self.performSegue(withIdentifier: "showWelcome", sender: self)
            } else {
                selectedArtist = artist
                self.performSegue(withIdentifier: "showProfile", sender: self)
                MSAnalytics.trackEvent("People View Controller", withProperties: ["Button" : "Did Select Person"])
            }*/
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
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        var userId: String!
                        if loadType == "followers" {
                            userId = object["fromUserId"] as? String
                        } else if loadType == "following" {
                            userId = object["toUserId"] as? String
                        }
                        let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil)
                        self.artists.append(artist)
                    }
                }
                
                self.setUpTableView()
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func loadTippers() {
        let query = PFQuery(className: "Tip")
        query.whereKey("soundId", equalTo: sound.objectId!)
        query.limit = 50
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let userId = object["fromUserId"] as? String
                        let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil)
                        
                        let userIds = self.artists.map {$0.objectId}
                        if !userIds.contains(userId) {
                            self.artists.append(artist)
                        }
                    }
                }
                
                self.setUpTableView()
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    //mark: search
    var isSearchActive = false
    var searchTags = [Tag]()
    var soundList: SoundList!
    var searchType = 0
    var searchBar: UISearchBar!
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearchActive = true
        self.tableView.reloadData()
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //isLoadingResults = true
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
                        
                        self.filteredArtists.append(artist)
                    }
                }
                
                //self.isLoadingResults = false
                self.tableView.reloadData()
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
}

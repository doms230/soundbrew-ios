//
//  FollowersFollowingViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/10/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import DeckTransition
import AppCenterAnalytics

class PeopleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let color = Color()
    let uiElement = UIElement()
    
    var artists = [Artist]()
    
    var loadType: String!
    var sound: Sound!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        
        if sound == nil {
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
            break
            
        default:
            break
        }
    }
    
    //MARK: Tableview
    let tableView = UITableView()
    let searchTagViewReuse = "searchTagViewReuse"
    let noSoundsReuse = "noSoundsReuse"
    func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchTagViewReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.backgroundColor = color.black()
        self.tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if artists.count == 0 {
            return 1
        }
        return artists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if artists.count == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
            cell.backgroundColor = color.black()
            
            if sound != nil {
                cell.headerTitle.text = "No Tippers yet."
            } else if loadType == "followers" {
                cell.headerTitle.text = "No followers yet."
            } else if loadType == "following" {
                cell.headerTitle.text = "You're not following anyone yet."
            }
            
            return cell
        } else {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: searchTagViewReuse) as! ProfileTableViewCell
            cell.backgroundColor = color.black()
            self.artists[indexPath.row].loadUserInfoFromCloud(self.artists[indexPath.row].objectId, target: self, cell: cell)
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        selectedArtist = self.artists[indexPath.row]
        self.performSegue(withIdentifier: "showProfile", sender: self)
        
        MSAnalytics.trackEvent("People View Controller", withProperties: ["Button" : "Did Select Person"])
    }
    
    //mark: selectedArtist
    var selectedArtist: Artist!
    
    func selectedArtist(_ artist: Artist?) {
        if let artist = artist {
            if artist.objectId == "addFunds" {
                self.performSegue(withIdentifier: "showAddFunds", sender: self)
            } else if artist.objectId == "signup" {
                self.performSegue(withIdentifier: "showWelcome", sender: self)
            } else {
                selectedArtist = artist
                self.performSegue(withIdentifier: "showProfile", sender: self)
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
}

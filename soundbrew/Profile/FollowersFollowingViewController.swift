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

class PeopleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PlayerDelegate {

    let color = Color()
    let uiElement = UIElement()
    
    var artists = [Artist]()
    
    var loadType: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        
        loadFollowersFollowing(loadType)
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
    func setUpTableView(_ miniPlayer: UIView?) {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchTagViewReuse)
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.backgroundColor = color.black()
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: searchTagViewReuse) as! ProfileTableViewCell
        cell.backgroundColor = color.black()
        self.artists[indexPath.row].loadUserInfoFromCloud(self.artists[indexPath.row].objectId, target: self, cell: cell)
        
        return cell 
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        selectedArtist = self.artists[indexPath.row]
        self.performSegue(withIdentifier: "showProfile", sender: self)
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
            make.bottom.equalTo(self.view).offset(-50)
        }
        
        setUpTableView(miniPlayerView!)
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
                
                let player = Player.sharedInstance
                if player.player != nil {
                    self.setUpMiniPlayer()
                } else if PFUser.current() != nil {
                    self.setUpTableView(nil)
                }
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
}

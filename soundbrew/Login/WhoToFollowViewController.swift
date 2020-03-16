//
//  WhoToFollowViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 3/12/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import Kingfisher
import SnapKit

class WhoToFollowViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let color = Color()
    let uiElement = UIElement()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Who To Follow"
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        loadPeopleToFollow()
        setupDoneButton()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
        
        let viewController = segue.destination as! AddFundsViewController
        viewController.isOnboarding = true 
        
    }
    
    func setupDoneButton() {
        let localizedDone = NSLocalizedString("done", comment: "")
        let doneButton = UIBarButtonItem(title: localizedDone, style: .plain, target: self, action: #selector(self.didPressDoneButton(_:)))
        self.navigationItem.rightBarButtonItem = doneButton
    }
    
    @objc func didPressDoneButton(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "showAddFunds", sender: self)
    }
    
    //mark: TableView
    var tableView = UITableView()
    let titleReuse = "titleReuse"
    let peopleToFollowReuse = "peopleToFollowReuse"
    func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WhoToFollowTableViewCell.self, forCellReuseIdentifier: titleReuse)
        tableView.register(WhoToFollowTableViewCell.self, forCellReuseIdentifier: peopleToFollowReuse)
        tableView.backgroundColor = color.black()
        self.tableView.separatorStyle = .none
        self.tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return peopleToFollow.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: titleReuse) as! WhoToFollowTableViewCell
            return cell
            
        } else {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: peopleToFollowReuse) as! WhoToFollowTableViewCell
            
            let artist = peopleToFollow[indexPath.row]
            if let name = artist.name {
                cell.displayNameLabel.text = name
            }
            
            if let username = artist.username {
                cell.usernameLabel.text = username
            }
            
            if let bio = artist.bio {
                cell.bioLabel.text = bio
            }
            
            if let image = artist.image {
                cell.profileImage.kf.setImage(with: URL(string: image))
            } else {
                cell.profileImage.image = UIImage(named: "profile_icon")
            }
            
            cell.followButton.tag = indexPath.row
            cell.followButton.addTarget(self, action: #selector(self.didPressFollowButton(_:)), for: .touchUpInside)
            
            if let isFollowedByCurrentUser = artist.isFollowedByCurrentUser, isFollowedByCurrentUser {
                cell.followButton.setTitle("Following", for: .normal)
                cell.followButton.backgroundColor = .lightGray
                cell.followButton.setTitleColor(color.black(), for: .normal)
            } else {
                cell.followButton.setTitle("Follow", for: .normal)
                cell.followButton.backgroundColor = color.blue()
                cell.followButton.setTitleColor(.white, for: .normal)
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

    }
    
    var peopleToFollow = [Artist]()
    func loadPeopleToFollow() {
        let query = PFQuery(className: "_User")
        query.limit = 50
        query.whereKeyExists("bio")
        query.whereKeyExists("artistName")
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil, let objects = objects {
                for user in objects {
                    let userObject = self.uiElement.newArtistObject(user)
                    userObject.isFollowedByCurrentUser = false
                    self.peopleToFollow.append(userObject)
                }
                self.setUpTableView()
            }
        }
    }
    
    @objc func didPressFollowButton(_ sender: UIButton) {
        let toArtist = peopleToFollow[sender.tag]
        if let fromArtist = Customer.shared.artist {
            let follow = Follow(fromArtist: fromArtist, toArtist: toArtist)
            if let isFollowedByCurrentUser = toArtist.isFollowedByCurrentUser, isFollowedByCurrentUser {
                follow.updateFollowStatus(false)
                peopleToFollow[sender.tag].isFollowedByCurrentUser = false
            } else {
                follow.updateFollowStatus(true)
                peopleToFollow[sender.tag].isFollowedByCurrentUser = true
            }
            self.tableView.reloadData()
        }
    }
}

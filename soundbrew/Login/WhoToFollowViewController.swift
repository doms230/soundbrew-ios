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
        loadPeopleToFollow()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
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
                    self.peopleToFollow.append(userObject)
                }
                self.setUpTableView()
            }
        }
    }
    
    //following logic
    

}

//
//  ArtistProfileViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 10/17/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit
import Parse
import Kingfisher

class ArtistProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView()
    let uiElement = UIElement()
    let color = Color()
    
    var userId: String!
    
    var socialsAndStreams = [String]()
    var socialsAndStreamImages = [String]()
    
    lazy var userImage: UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = 25
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.image = UIImage(named: "profile_icon")
        return image
    }()
    
    lazy var artistName: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 20)
        label.text = "Artist Name"
        label.textColor = .white
        return label
    }()
    
    lazy var artistCity: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 20)
        label.text = "Artist City"
        label.textColor = .white
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        loadUserInfoFromCloud(userId)
    }
    
    let reuse = "reuse"
    
    func setUpViews() {
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        self.view.addSubview(userImage)
        userImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(50)
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        self.view.addSubview(artistName)
        artistName.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(userImage.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(artistCity)
        artistCity.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(artistName.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ArtistProfileTableViewCell.self, forCellReuseIdentifier: reuse)
        tableView.separatorStyle = .none
        tableView.backgroundColor = color.black()
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(artistCity.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    //MARK: TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return socialsAndStreams.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! ArtistProfileTableViewCell
        cell.backgroundColor = color.black()
        cell.socialStreamImage.image = UIImage(named: socialsAndStreamImages[indexPath.row])
        cell.socialStreamButton.setTitle(socialsAndStreams[indexPath.row], for: .normal)
        cell.socialStreamButton.addTarget(self, action: #selector(self.didPressSocialStreamButton(_:)), for: .touchUpInside)
        return cell
    }
    
    //mark: button actions
    @objc func didPressSocialStreamButton(_ sender: UIButton) {
        var isAbleToShowLink = false
        
        if let senderTitle = sender.titleLabel?.text {
            let url = (URL(string: senderTitle))
            if let url = url {
                isAbleToShowLink = true
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        
        if !isAbleToShowLink {
            self.uiElement.showAlert("Problem with URL", message: "Double check the link, then click the 'Edit Profile' button to update.", target: self)
        }
    }
    
    @objc func didPressEditProfileButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showEditProfile", sender: self)
    }
    
    //Mark: Data
    func loadUserInfoFromCloud(_ userId: String) {
        let query = PFQuery(className:"_User")
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                if let instagramHandle = user["instagramHandle"] as? String {
                    if !instagramHandle.isEmpty {
                        self.socialsAndStreams.append("https://www.instagram.com/\(instagramHandle)")
                        self.socialsAndStreamImages.append("ig_logo")
                    }
                }
                
                if let twitterHandle = user["twitterHandle"] as? String {
                    if !twitterHandle.isEmpty {
                        self.socialsAndStreams.append("https://www.twitter.com/\(twitterHandle)")
                        self.socialsAndStreamImages.append("twitter_logo")
                    }
                }
                
                if let soundCloudLink = user["soundCloudLink"] as? String {
                    if !soundCloudLink.isEmpty {
                        self.socialsAndStreams.append(soundCloudLink)
                        self.socialsAndStreamImages.append("soundcloud_logo")
                    }
                }
                
                if let appleMusicLink = user["appleMusicLink"] as? String {
                    if !appleMusicLink.isEmpty {
                        self.socialsAndStreams.append(appleMusicLink)
                        self.socialsAndStreamImages.append("appleMusic_logo")
                    }
                }
                
                if let spotifyLink = user["spotifyLink"] as? String {
                    if !spotifyLink.isEmpty {
                        self.socialsAndStreams.append(spotifyLink)
                        self.socialsAndStreamImages.append("spotify_logo")
                    }
                }
                
                if let otherLlink = user["otherLink"] as? String {
                    if !otherLlink.isEmpty {
                        self.socialsAndStreams.append(otherLlink)
                        self.socialsAndStreamImages.append("link_logo")
                    }
                }
                
                self.artistName.text = user["artistName"] as? String
                self.artistCity.text = user["city"] as? String
                if let userImageFile = user["userImage"] as? PFFile {
                    self.userImage.kf.setImage(with: URL(string: userImageFile.url!), placeholder: UIImage(named: "profile_icon") , options: nil, progressBlock: nil, completionHandler: nil)
                }
                
                self.tableView.reloadData()
            }
        }
    }
}

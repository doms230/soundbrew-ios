//
//  ProfileViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/11/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import Kingfisher
import SnapKit

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let tableView = UITableView()
    let uiElement = UIElement()
    let color = Color()
    
    var socialsAndStreams = [String]()
    var socialsAndStreamImages = [String]()
    
    var artist: Artist!
    
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
        return label
    }()
    
    lazy var artistCity: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 20)
        label.text = "Artist City"
        return label
    }()
    
    lazy var editProfileButton: UIButton = {
        let button = UIButton()
        button.setTitle("Edit Profile", for: .normal)
        button.backgroundColor = color.blue()
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 17)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true 
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let menuButton = UIBarButtonItem(title: "...", style: .plain, target: self, action: #selector(self.didPressMenuButton(_:)))
        self.navigationItem.rightBarButtonItem = menuButton
        
        setUpViews()
        loadUserInfoFromCloud(PFUser.current()!.objectId!)
    }
    
    let reuse = "reuse"
    
    func setUpViews() {
        self.title = "Profile"
        
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
        
        self.editProfileButton.addTarget(self, action: #selector(self.didPressEditProfileButton(_:)), for: .touchUpInside)
        self.view.addSubview(editProfileButton)
        editProfileButton.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(100)
            make.top.equalTo(artistCity.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: reuse)
        self.tableView.separatorStyle = .none
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(editProfileButton.snp.bottom)
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
        let cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! ProfileTableViewCell
        cell.selectionStyle = .none
        cell.socialStreamImage.image = UIImage(named: socialsAndStreamImages[indexPath.row])
        cell.socialStreamClicks.text = socialsAndStreams[indexPath.row]
        return cell
    }
    
    //mark: button actions
    @objc func didPressMenuButton(_ sender: UIBarButtonItem) {
        let menuAlert = UIAlertController(title: nil , message: nil , preferredStyle: .actionSheet)
        menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        menuAlert.addAction(UIAlertAction(title: "Sign Out", style: .default, handler: { action in
            PFUser.logOut()
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "welcome")
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            //show window
            appDelegate.window?.rootViewController = controller
        }))
        
        self.present(menuAlert, animated: true, completion: nil)
    }
    
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
    
    func determineTableViewSize() {
        self.appendSocialStream(artist.instagramHandle, socialStreamClicks: artist.instagramClicks, logo: "ig_logo")
        self.appendSocialStream(artist.twitterHandle, socialStreamClicks: artist.twitterClicks, logo: "twitter_logo")
        self.appendSocialStream(artist.soundcloud, socialStreamClicks: artist.soundcloudClicks, logo: "soundcloud_logo")
        self.appendSocialStream(artist.spotify, socialStreamClicks: artist.spotifyClicks, logo: "spotify_logo")
        self.appendSocialStream(artist.appleMusic, socialStreamClicks: artist.appleMusicClicks, logo: "appleMusic_logo")
        self.appendSocialStream(artist.otherLink, socialStreamClicks: artist.otherLinkClicks, logo: "link_logo")
        
        self.tableView.reloadData()
    }
    
    func appendSocialStream(_ socialStream: String?, socialStreamClicks: Int?, logo: String ) {
        if socialStream != nil {
            if let clicks = socialStreamClicks {
                self.socialsAndStreams.append("\(clicks) Clicks")
                
            } else {
                self.socialsAndStreams.append("Clicks N/A")
            }
            self.socialsAndStreamImages.append(logo)
        }
    }
    
    //Mark: Data
    func loadUserInfoFromCloud(_ userId: String) {
        let query = PFQuery(className:"_User")
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                let artistName = user["artistName"] as? String
                self.artistName.text = artistName
                
                let artistCity = user["city"] as? String
                self.artistCity.text = artistCity
                
                var artistURL = ""
                if let userImageFile = user["userImage"] as? PFFileObject {
                    artistURL = userImageFile.url!
                    //self.userImage.kf.setImage(with: URL(string: userImageFile.url!), placeholder: UIImage(named: "profile_icon"), options: nil, progressBlock: nil, completionHandler: nil)
                    
                    self.userImage.kf.setImage(with: URL(string: userImageFile.url!))
                }
                
                self.artist = Artist(objectId: user.objectId, name: artistName!, city: artistCity!, image: artistURL, instagramHandle: nil, instagramClicks: nil, twitterHandle: nil, twitterClicks: nil, soundcloud: nil, soundcloudClicks: nil, spotify: nil, spotifyClicks: nil, appleMusic: nil, appleMusicClicks: nil, otherLink: nil, otherLinkClicks: nil)
                
                if let instagramHandle = user["instagramHandle"] as? String {
                    if !instagramHandle.isEmpty {
                        self.artist.instagramHandle = instagramHandle
                    }
                }
                
                if let twitterHandle = user["twitterHandle"] as? String {
                    if !twitterHandle.isEmpty {
                        self.artist.twitterHandle = twitterHandle
                    }
                }
                
                if let soundCloudLink = user["soundCloudLink"] as? String {
                    if !soundCloudLink.isEmpty {
                        self.artist.soundcloud = soundCloudLink
                    }
                }
                
                if let appleMusicLink = user["appleMusicLink"] as? String {
                    if !appleMusicLink.isEmpty {
                        self.artist.appleMusic = appleMusicLink
                    }
                }
                
                if let spotifyLink = user["spotifyLink"] as? String {
                    if !spotifyLink.isEmpty {
                        self.artist.spotify = spotifyLink
                    }
                }
                
                if let otherLlink = user["otherLink"] as? String {
                    if !otherLlink.isEmpty {
                        self.artist.otherLink = otherLlink
                    }
                }
                
                self.loadClicks()
            }
        }
    }
    
    func loadClicks() {
        let query = PFQuery(className: "Click")
        query.whereKey("userId", equalTo: PFUser.current()!.objectId!)
        query.getFirstObjectInBackground { (object: PFObject?, error: Error?) in
            if let error = error {
                print(error.localizedDescription)
                
            } else if let object = object {
                if let instagramClicks = object["instagramClicks"] as? Int {
                    self.artist.instagramClicks = instagramClicks
                    print(instagramClicks)
                }
                
                if let twitterClicks = object["twitterClicks"] as? Int {
                    self.artist.twitterClicks = twitterClicks
                }
                
                if let soundcloudClicks = object["soundcloudClicks"] as? Int {
                    self.artist.soundcloudClicks = soundcloudClicks
                }
                
                if let spotifyClicks = object["spotifyClicks"] as? Int {
                    self.artist.spotifyClicks = spotifyClicks
                }
                
                if let appleMusicClicks = object["appleMusicClicks"] as? Int {
                    self.artist.appleMusicClicks = appleMusicClicks
                }
                
                if let otherLinkClicks = object["otherLinkClicks"] as? Int {
                    self.artist.otherLinkClicks = otherLinkClicks
                }
            }
            
            self.determineTableViewSize()
        }
    }
}

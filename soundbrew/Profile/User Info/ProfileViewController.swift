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
    
    var socialsAndStreamImages = [String]()
    
    var artist: Artist!
    
    var selectedIndex = 0
    
    lazy var userImage: UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = 50
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
        
        if PFUser.current() != nil {
            setUpViews()
            loadUserInfoFromCloud(PFUser.current()!.objectId!)
            
        } else {
            self.uiElement.segueToView("Login", withIdentifier: "welcome", target: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSounds" {
            let mySoundsVC: MySoundsViewController = segue.destination as! MySoundsViewController
            mySoundsVC.soundType = "Uploads"
            if selectedIndex == 0 {
                mySoundsVC.soundType = "Uploads"
                
            } else {
                mySoundsVC.soundType = "Likes"
            }
        }
    }
    
    let reuse = "reuse"
    
    func setUpViews() {
        self.view.addSubview(userImage)
        userImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(100)
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
        
       /* self.editProfileButton.addTarget(self, action: #selector(self.didPressEditProfileButton(_:)), for: .touchUpInside)
        self.view.addSubview(editProfileButton)
        editProfileButton.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(100)
            make.top.equalTo(artistCity.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }*/
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: reuse)
        self.tableView.separatorStyle = .none
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
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! ProfileTableViewCell
        cell.selectionStyle = .none
        
        var imageName = "soundwave"
        var labelTitle = "My Uploads"
        
        if indexPath.row == 1 {
            imageName = "like"
            labelTitle = "Liked Tracks"
        }
        
        cell.soundImage.image = UIImage(named: imageName)
        cell.soundLabel.text = labelTitle
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        self.performSegue(withIdentifier: "showSounds", sender: self)
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
        
        menuAlert.addAction(UIAlertAction(title: "Edit Profile", style: .default, handler: { action in
            self.performSegue(withIdentifier: "showEditProfile", sender: self)
        }))
        
        self.present(menuAlert, animated: true, completion: nil)
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
                    self.userImage.kf.setImage(with: URL(string: userImageFile.url!))
                }
                
                self.artist = Artist(objectId: user.objectId, name: artistName!, city: artistCity!, image: artistURL, instagramHandle: nil, instagramClicks: nil, twitterHandle: nil, twitterClicks: nil, soundcloud: nil, soundcloudClicks: nil, spotify: nil, spotifyClicks: nil, appleMusic: nil, appleMusicClicks: nil, otherLink: nil, otherLinkClicks: nil)
                
                self.tableView.reloadData()
            }
        }
    }
}

//
//  SettingsViewController.swift
//  soundbrew
//
//  Created by Dominic Smith on 7/2/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import SidebarOverlay
import GoogleSignIn

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let uiElement = UIElement()
    let color = Color()
    
    var artist: Artist?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        let customer = Customer.shared
        artist = customer.artist
        loadFollowerFollowingStats()
    }
    
    //Mark: sign out
    let localizedSignout = NSLocalizedString("signout", comment: "")
    let localizedCancel = NSLocalizedString("cancel", comment: "")
    
    lazy var signOut: UIButton = {
        let button = UIButton()
        button.setTitle(localizedSignout, for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(self.didPressSignoutButton(_:)), for: .touchUpInside)
        return button
    }()
    
    @objc func didPressSignoutButton(_ sender: UIButton) {
        let menuAlert = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
        menuAlert.addAction(UIAlertAction(title: localizedCancel, style: .cancel, handler: nil))
        menuAlert.addAction(UIAlertAction(title: localizedSignout, style: .default, handler: { action in
            self.tableView.removeFromSuperview()
            PFUser.logOut()
            GIDSignIn.sharedInstance().signOut()
            Customer.shared.artist = nil
            if self.uiElement.getUserDefault("friends") != nil {
                self.uiElement.setUserDefault(nil, key: "friends")
            }
            
           let player = Player.sharedInstance
            player.pause()
            player.player = nil
            player.sounds = nil
            player.currentSound = nil
            player.currentSoundIndex = 0
            
            self.uiElement.newRootView("NewUser", withIdentifier: "welcome")
        }))
        self.present(menuAlert, animated: true, completion: nil)
    }
    
    lazy var provideFeedbackButton: UIButton = {
        let localizedProvideFeedback = NSLocalizedString("provideFeedback", comment: "")
        let button = UIButton()
        button.setTitle(localizedProvideFeedback, for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(self.didPressProvideFeedbackButton(_:)), for: .touchUpInside)
        return button
    }()
    
    @objc func didPressProvideFeedbackButton(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "https://www.soundbrew.app/support")!, options: [:], completionHandler: nil)
    }
    
    lazy var connectWithUsButton: UIButton = {
        let localizedConnectWithUs = NSLocalizedString("connectWithUs", comment: "")
        let button = UIButton()
        button.setTitle(localizedConnectWithUs, for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(self.didPressConnectWithUsButton(_:)), for: .touchUpInside)
        return button
    }()
    
    @objc func didPressConnectWithUsButton(_ sender: UIButton) {
        let localizedConnectWithUs = NSLocalizedString("connectWithUs", comment: "")
        let menuAlert = UIAlertController(title: localizedConnectWithUs, message: nil , preferredStyle: .actionSheet)
        menuAlert.addAction(UIAlertAction(title: localizedCancel, style: .cancel, handler: nil))
        menuAlert.addAction(UIAlertAction(title: "Twitter", style: .default, handler: { action in
        UIApplication.shared.open(URL(string: "https://www.twitter.com/sound_brew")!, options: [:], completionHandler: nil)
        }))
        menuAlert.addAction(UIAlertAction(title: "Instagram", style: .default, handler: { action in
            UIApplication.shared.open(URL(string: "https://www.instagram.com/sound_brew")!, options: [:], completionHandler: nil)
        }))
        self.present(menuAlert, animated: true, completion: nil)
    }
    
    func setupBottomButtons() {
        DispatchQueue.main.async {
            self.view.addSubview(self.provideFeedbackButton)
            self.provideFeedbackButton.snp.makeConstraints { (make) -> Void in
                make.left.equalTo(self.view).offset(self.uiElement.leftOffset)
                make.right.equalTo(self.view).offset(self.uiElement.rightOffset)
                if let tabBarHeight = self.tabBarController?.tabBar.frame.height {
                    make.bottom.equalTo(self.view).offset(-(tabBarHeight) + CGFloat(self.uiElement.bottomOffset))
                } else {
                    make.bottom.equalTo(self.view).offset(self.uiElement.bottomOffset * 2)
                }
            }
            
            self.view.addSubview(self.connectWithUsButton)
            self.connectWithUsButton.snp.makeConstraints { (make) -> Void in
                make.left.equalTo(self.provideFeedbackButton)
                make.right.equalTo(self.provideFeedbackButton)
                make.bottom.equalTo(self.provideFeedbackButton.snp.top).offset(self.uiElement.bottomOffset)
            }
            
            self.view.addSubview(self.signOut)
            self.signOut.snp.makeConstraints { (make) -> Void in
                make.left.equalTo(self.provideFeedbackButton)
                make.right.equalTo(self.provideFeedbackButton)
                make.bottom.equalTo(self.connectWithUsButton.snp.top).offset(self.uiElement.bottomOffset)
            }
        }
        
        setUpTableView()
    }
    
    //MARK: Tableview
    let tableView = UITableView()
    let settingsReuse = "settingsReuse"
    let settingsTitleReuse = "settingsTitleReuse"
    func setUpTableView() {
        DispatchQueue.main.async {
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: self.settingsReuse)
            self.tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: self.settingsTitleReuse)
            self.tableView.separatorStyle = .none
            self.tableView.backgroundColor = self.color.black()
            self.view.addSubview(self.tableView)
            self.tableView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.uiElement.uiViewTopOffset(self))
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
                make.bottom.equalTo(self.signOut.snp.top)
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            if self.artist?.accountId != nil {
                return 4
            } else {
                return 2
            }
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: settingsTitleReuse) as! ProfileTableViewCell
            cell.backgroundColor = color.black()
            cell.selectionStyle = .none
            let localizedSettings = NSLocalizedString("settings", comment: "")
            cell.displayNameLabel.text = localizedSettings
            
            cell.shareButton.addTarget(self, action: #selector(self.didPressShareProfileButton(_:)), for: .touchUpInside)
            
            return cell
            
        } else {
            return settingsItemReuse(indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                showFollowersOrFollowing("followers")
                break
                
            case 1:
                showFollowersOrFollowing("following")
                break
                
            case 2:
                //show fans
                break
                
            case 3:
                //show earnings page
                break
                
            default:
                break
            }
        }
    }
    
    func showFollowersOrFollowing(_ followerOrFollowingType: String) {
        if let container = self.so_containerViewController {
            container.isSideViewControllerPresented = false
            if let topView = container.topViewController as? UINavigationController {
                if let view = topView.topViewController as? ProfileViewController {
                    view.followerOrFollowing = followerOrFollowingType
                    view.performSegue(withIdentifier: "showFollowerFollowing", sender: self)
                }
            }
        }
    }
    
    func settingsItemReuse(_ indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: settingsReuse) as! ProfileTableViewCell
        cell.selectionStyle = .none
        cell.backgroundColor = color.black()
        self.tableView.separatorStyle = .none
        cell.profileImage.layer.borderColor = color.black().cgColor
        
        if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                var followerCount = 0
                if let count = self.artist?.followerCount {
                    followerCount = count
                }
                cell.displayNameLabel.text = "\(followerCount)"
                let localizedFollowing = NSLocalizedString("followers", comment: "")
                cell.username.text = localizedFollowing
                break
                
            case 1:
                var followingCount = 0
                if let count = self.artist?.followingCount {
                    followingCount = count
                }
                cell.displayNameLabel.text = "\(followingCount)"
                let localizedFollowing = NSLocalizedString("following", comment: "")
                cell.username.text = localizedFollowing
                break
                
            case 2:
                cell.displayNameLabel.text = "100"
                cell.username.text = "Fans"
                break
                
            case 3:
                //TODO: change this to earnings based off Stripe data
                if let earnings = self.artist?.earnings {
                    cell.displayNameLabel.text = self.uiElement.convertCentsToDollarsAndReturnString(earnings, currency: "$")
                } else {
                    cell.displayNameLabel.text = "$0.00"
                }
                cell.username.text = "Earnings"
                break
                
            default:
                break
            }
        }
        
        return cell
    }
    
    @objc func didPressShareProfileButton(_ sender: UIButton) {
        if let artist = Customer.shared.artist {
            self.uiElement.createDynamicLink(nil, artist: artist, playlist: nil, target: self)
        }
    }
        
    func cashout() {
        //TODO: show Earnings page
    }
    
    //data
    func loadFollowerFollowingStats() {
        if let currentUserID = PFUser.current()?.objectId {
            let query = PFQuery(className: "Stats")
            query.whereKey("userId", equalTo: currentUserID)
            query.cachePolicy = .networkElseCache
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if let object = object {
                    if let followers = object["followers"] as? Int {
                        self.artist?.followerCount = followers
                    }
                    
                    if let following = object["following"] as? Int {
                        self.artist?.followingCount = following
                    }
                }
               self.loadEarnings()
            }
        }
    }
    
    func loadEarnings() {
        if let currentUserID = PFUser.current()?.objectId {
            let query = PFQuery(className: "Payment")
            query.whereKey("userId", equalTo: currentUserID)
            query.cachePolicy = .networkElseCache
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if  let object = object {
                    if let earnings = object["tipsSinceLastPayout"] as? Int {
                        self.artist?.earnings = earnings
                    } else {
                        self.artist?.earnings = 0
                    }
                }
                self.setupBottomButtons()
            }
        }
    }
}

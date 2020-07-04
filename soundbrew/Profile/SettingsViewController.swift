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
import Alamofire
import SwiftyJSON

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
                if let tabBarHeight = self.tabBarController?.tabBar.frame.height {
                    make.bottom.equalTo(self.view).offset(-(tabBarHeight) + CGFloat(self.uiElement.bottomOffset))
                } else {
                    make.bottom.equalTo(self.view).offset(self.uiElement.bottomOffset * 2)
                }
            }
            
            self.view.addSubview(self.connectWithUsButton)
            self.connectWithUsButton.snp.makeConstraints { (make) -> Void in
                make.left.equalTo(self.provideFeedbackButton)
                make.bottom.equalTo(self.provideFeedbackButton.snp.top).offset(self.uiElement.bottomOffset)
            }
            
            self.view.addSubview(self.signOut)
            self.signOut.snp.makeConstraints { (make) -> Void in
                make.left.equalTo(self.provideFeedbackButton)
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
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 2
        }
        
        if section == 2 && self.artist?.account != nil {
            return 3
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return titleReuse()
        } else if indexPath.section == 1 {
            return followerFollowingReuse(indexPath)
        } else  {
            return accountReuse(indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            self.didSelectFollowerFollowingSection(indexPath)
        } else if indexPath.section == 2 {
            self.didSelectAccountSection(indexPath)
        }
    }
    
    //MARK: Title
    func titleReuse() -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: settingsTitleReuse) as! ProfileTableViewCell
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        let localizedSettings = NSLocalizedString("settings", comment: "")
        cell.displayNameLabel.text = localizedSettings
        cell.shareButton.addTarget(self, action: #selector(self.didPressShareProfileButton(_:)), for: .touchUpInside)
        return cell
    }
    
    //MARK: Follower/Following
    func followerFollowingReuse(_ indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: settingsReuse) as! ProfileTableViewCell
        cell.selectionStyle = .none
        cell.backgroundColor = color.black()
        self.tableView.separatorStyle = .none
        cell.profileImage.layer.borderColor = color.black().cgColor
        
        if indexPath.row == 0 {
            var followerCount = 0
            if let count = self.artist?.followerCount {
                followerCount = count
            }
            cell.displayNameLabel.text = "\(followerCount)"
            let localizedFollowing = NSLocalizedString("followers", comment: "")
            cell.username.text = localizedFollowing
        } else {
            var followingCount = 0
            if let count = self.artist?.followingCount {
                followingCount = count
            }
            cell.displayNameLabel.text = "\(followingCount)"
            let localizedFollowing = NSLocalizedString("following", comment: "")
            cell.username.text = localizedFollowing
        }
        
        return cell
    }
    
    func didSelectFollowerFollowingSection(_ indexPath: IndexPath) {
        if indexPath.row == 0 {
            showFollowersOrFollowing("followers")
        } else {
            showFollowersOrFollowing("following")
        }
    }
    
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
                    
                    if let fans = object["fans"] as? Int {
                        self.artist?.fanCount = fans
                    }
                }
                self.setupBottomButtons()
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
    
    @objc func didPressShareProfileButton(_ sender: UIButton) {
        if let artist = Customer.shared.artist {
            self.uiElement.createDynamicLink(nil, artist: artist, playlist: nil, target: self)
        }
    }
        
    //MARK: Account
    func accountReuse(_ indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: settingsReuse) as! ProfileTableViewCell
        cell.selectionStyle = .none
        if self.artist?.account == nil {
            cell.displayNameLabel.text = "Start Fan Club"
            cell.username.text = "Earn From Your Followers"
        } else {
            switch indexPath.row {
                case 0:
                    if let fanCount = self.artist?.fanCount {
                        cell.displayNameLabel.text = "\(fanCount)"
                    } else {
                        cell.displayNameLabel.text = "100"
                    }
                    
                    cell.username.text = "Fans"
                    break
                    
                case 1:
                    let balanceString = self.uiElement.convertCentsToDollarsAndReturnString(self.artist?.account?.weeklyEarnings ?? 0)
                    cell.displayNameLabel.text = balanceString
                    cell.username.text = "Weekly Earnings"
                    break
                    
                case 2:
                    cell.username.text = "Account"
                    if let requiresAttentionItems = self.artist?.account?.requiresAttentionItems, requiresAttentionItems > 0 {
                        var itemTitle = "1 item"
                        itemTitle = "\(requiresAttentionItems) items"
                        cell.displayNameLabel.text = "Requires Attention: \(itemTitle)"
                        cell.displayNameLabel.textColor = color.red()
                    } else {
                        cell.displayNameLabel.text = "In Good Standing"
                        cell.displayNameLabel.textColor = self.color.green()
                    }
                    break
                
            default:
                break
            }
        }
        
        return cell
    }
    
    func didSelectAccountSection(_ indexPath: IndexPath) {
        print(self.artist?.isVerified)
        if self.artist?.account == nil {
            if let isVerified = self.artist?.isVerified, isVerified {
              newFanClubAlert()
            } else {
                self.uiElement.showAlert("Not Publicly Available Yet", message: "Email support@soundbrew.app or message us @sound_brew to request access.", target: self)
            }
            
        } else {
            switch indexPath.row {
            case 0:
                showFollowersOrFollowing("fans")
                break
            case 1:
                if let container = self.so_containerViewController {
                    container.isSideViewControllerPresented = false
                    if let topView = container.topViewController as? UINavigationController,
                        let view = topView.topViewController as? ProfileViewController{
                        view.performSegue(withIdentifier: "showEarnings", sender: self)
                    }
                }
                break
                
            case 2:
                showRequireAccountAttention()
                break
                
            default:
                break
            }
        }
    }
    
    func showRequireAccountAttention() {
        if let container = self.so_containerViewController {
            container.isSideViewControllerPresented = false
            if let topView = container.topViewController as? UINavigationController,
                let view = topView.topViewController as? ProfileViewController {
                view.performSegue(withIdentifier: "showAccountWebView", sender: self)
            }
        }
    }
    
    func newFanClubAlert() {
        let alertController = UIAlertController (title: "Earn From Your Followers", message:
            "Earn money from your followers by starting a fan club. You'll earn $11.04 per fan per month, and you can choose which sounds are exclusive to your fan club!", preferredStyle: .actionSheet)
            
        let getStartedAction = UIAlertAction(title: "Get Started", style: .default) { (_) -> Void in
            if let container = self.so_containerViewController {
                container.isSideViewControllerPresented = false
                if let topView = container.topViewController as? UINavigationController,
                    let view = topView.topViewController as? ProfileViewController {
                    view.showNewAccount("US")
                    }
                }
            }
        alertController.addAction(getStartedAction)
            
        let cancelAction = UIAlertAction(title: "Later", style: .cancel) { (_) -> Void in
        }
        alertController.addAction(cancelAction)
            
        present(alertController, animated: true, completion: nil)
    }
    
}

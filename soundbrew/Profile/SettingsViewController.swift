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
import AppCenterAnalytics

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let uiElement = UIElement()
    let color = Color()
    
    var artist: Artist?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        artist = Customer.shared.artist
        loadFollowFollowingStats()
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
            Customer.shared.artist = nil
            self.uiElement.newRootView("NewUser", withIdentifier: "welcome")
            MSAnalytics.trackEvent("Settings View Controller", withProperties: ["Button" : "Sign out", "description": "User pressed Sign out"])
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
        
        MSAnalytics.trackEvent("Settings View Controller", withProperties: ["Button" : "Support", "description": "User pressed Support"])
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
            MSAnalytics.trackEvent("Connect With Us", withProperties: ["Button" : "Twitter", "description": "User pressed twitter"])
        }))
        menuAlert.addAction(UIAlertAction(title: "Instagram", style: .default, handler: { action in
            UIApplication.shared.open(URL(string: "https://www.instagram.com/sound_brew")!, options: [:], completionHandler: nil)
            MSAnalytics.trackEvent("Connect With Us", withProperties: ["Button" : "Instagram", "description": "User pressed instagram"])
        }))
        self.present(menuAlert, animated: true, completion: nil)
        
        MSAnalytics.trackEvent("Settings View Controller", withProperties: ["Button" : "Connect With Us", "description": "User pressed connect with us button"])
    }
    
    func setupBottomButtons() {
        self.view.addSubview(provideFeedbackButton)
        self.provideFeedbackButton.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.view).offset(-((self.tabBarController?.tabBar.frame.height)!) + CGFloat(uiElement.bottomOffset))
        }
        
        self.view.addSubview(connectWithUsButton)
        self.connectWithUsButton.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(provideFeedbackButton)
            make.right.equalTo(provideFeedbackButton)
            make.bottom.equalTo(provideFeedbackButton.snp.top).offset(uiElement.bottomOffset)
        }
        
        self.view.addSubview(signOut)
        self.signOut.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(provideFeedbackButton)
            make.right.equalTo(provideFeedbackButton)
            make.bottom.equalTo(connectWithUsButton.snp.top).offset(uiElement.bottomOffset)
        }
        
        setUpTableView()
    }
    
    //MARK: Tableview
    let tableView = UITableView()
    let settingsReuse = "settingsReuse"
    let settingsTitleReuse = "settingsTitleReuse"
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: settingsReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: settingsTitleReuse)
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = color.black()
        self.view.addSubview(tableView)
        self.tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(signOut.snp.top)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 4
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
                MSAnalytics.trackEvent("Settings View Controller", withProperties: ["Button" : "Followers", "description": "User pressed Followers"])
                break
                
            case 1:
                showFollowersOrFollowing("following")
                MSAnalytics.trackEvent("Settings View Controller", withProperties: ["Button" : "Following", "description": "User pressed Following"])
                break
                
            case 2:
                showEarningsOrPayments("earnings")
                MSAnalytics.trackEvent("Settings View Controller", withProperties: ["Button" : "Earnings", "description": "User pressed Earnings"])
                break
                
            case 3:
                showEarningsOrPayments("funds")
                MSAnalytics.trackEvent("Settings View Controller", withProperties: ["Button" : "Funds", "description": "User pressed Funds"])
                break
                
            default:
                break
            }
        }
    }
    
    func showEarningsOrPayments(_ paymentType: String) {
        if paymentType == "funds" {
            if let container = self.so_containerViewController {
                container.isSideViewControllerPresented = false
                if let topView = container.topViewController as? UINavigationController {
                    if let view = topView.topViewController as? ProfileViewController {
                        view.paymentType = paymentType
                        view.performSegue(withIdentifier: "showAddFunds", sender: self)
                    }
                }
            }
        } else {
            let localizedWeeklyEarnings = NSLocalizedString("weeklyEarnings", comment: "")
            let localizedWeeklyEarningsMessage = NSLocalizedString("weeklyEarningsMessage", comment: "")
            self.uiElement.showAlert(localizedWeeklyEarnings, message: localizedWeeklyEarningsMessage, target: self)
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
        let localizedFollowers = NSLocalizedString("followers", comment: "")
        let localizedFollowing = NSLocalizedString("following", comment: "")
        let localizedEarnings = NSLocalizedString("earnings", comment: "")
        let localizedFunds = NSLocalizedString("funds", comment: "")
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: settingsReuse) as! ProfileTableViewCell
        cell.selectionStyle = .none
        cell.backgroundColor = color.black()
        self.tableView.separatorStyle = .none
        cell.profileImage.layer.borderColor = color.black().cgColor
        switch indexPath.row {
        case 0:
            cell.displayNameLabel.text = "\(self.artist?.followerCount ?? 0)"
            cell.username.text = localizedFollowers
            break
            
        case 1:
            cell.displayNameLabel.text = "\(self.artist?.followingCount ?? 0)"
            cell.username.text = localizedFollowing
            break
            
        case 2:
            if let earnings = self.artist?.earnings {
                cell.displayNameLabel.text = self.uiElement.convertCentsToDollarsAndReturnString(earnings, currency: "$")
            } else {
                cell.displayNameLabel.text = "$0.00"
            }
            
            cell.username.text = localizedEarnings
            break
            
        case 3:
            if let funds = self.artist?.balance {
                cell.displayNameLabel.text = self.uiElement.convertCentsToDollarsAndReturnString(funds, currency: "$")
            } else {
                cell.displayNameLabel.text = "$0.00"
            }
            cell.username.text = localizedFunds
            break
            
        default:
            break
        }
        
        return cell
    }
    
    //data
    func loadFollowFollowingStats() {
        if let currentUserID = PFUser.current()?.objectId {
            let query = PFQuery(className: "Stats")
            query.whereKey("userId", equalTo: currentUserID)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if error == nil, let object = object {
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
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if error == nil, let object = object {
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

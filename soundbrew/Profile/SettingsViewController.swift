//
//  SettingsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 7/2/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import SidebarOverlay

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let uiElement = UIElement()
    let color = Color()
    
    var artist: Artist?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        artist = Customer.shared.artist
        loadFollowFollowingStats()
    }
    
    //Mark: sign out
    lazy var signOut: UIButton = {
        let button = UIButton()
        button.setTitle("Sign Out", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(self.didPressSignoutButton(_:)), for: .touchUpInside)
        return button
    }()
    
    @objc func didPressSignoutButton(_ sender: UIButton) {
        let menuAlert = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
        menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        menuAlert.addAction(UIAlertAction(title: "Sign Out", style: .default, handler: { action in
            self.tableView.removeFromSuperview()
            PFUser.logOut()
            Customer.shared.artist = nil
            self.uiElement.segueToView("NewUser", withIdentifier: "welcome", target: self)
        }))
        self.present(menuAlert, animated: true, completion: nil)
    }
    
    lazy var provideFeedbackButton: UIButton = {
        let button = UIButton()
        button.setTitle("Provide Feedback", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(self.didPressProvideFeedbackButton(_:)), for: .touchUpInside)
        return button
    }()
    
    @objc func didPressProvideFeedbackButton(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "https://www.soundbrew.app/support")!, options: [:], completionHandler: nil)
    }
    
    lazy var connectWithUsButton: UIButton = {
        let button = UIButton()
        button.setTitle("Connect With Us", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(self.didPressConnectWithUsButton(_:)), for: .touchUpInside)
        return button
    }()
    
    @objc func didPressConnectWithUsButton(_ sender: UIButton) {
        let menuAlert = UIAlertController(title: "Connect With Us", message: nil , preferredStyle: .actionSheet)
        menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        menuAlert.addAction(UIAlertAction(title: "Twitter", style: .default, handler: { action in
        UIApplication.shared.open(URL(string: "https://www.twitter.com/sound_brew")!, options: [:], completionHandler: nil)
        }))
        menuAlert.addAction(UIAlertAction(title: "Instagram", style: .default, handler: { action in
            UIApplication.shared.open(URL(string: "https://www.instagram.com/sound_brew")!, options: [:], completionHandler: nil)
        }))
        self.present(menuAlert, animated: true, completion: nil)
    }
    
    func setupBottomButtons() {
        self.view.addSubview(provideFeedbackButton)
        self.provideFeedbackButton.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.view).offset(-50 + uiElement.bottomOffset)
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
            cell.displayNameLabel.text = "Settings"
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
                showEarningsOrPayments("earnings")
                break
                
            case 3:
                showEarningsOrPayments("funds")
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
            self.uiElement.showAlert("Weekly Earnings", message: "Weekly Earnings are sent via PayPal using your Soundbrew email. Please double check that your Soundbrew email matches your PayPal email.", target: self)
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
        switch indexPath.row {
        case 0:
            cell.displayNameLabel.text = "\(self.artist!.followerCount ?? 0)"
            cell.username.text = "Followers"
            break
            
        case 1:
            cell.displayNameLabel.text = "\(self.artist!.followingCount ?? 0)"
            cell.username.text = "Following"
            break
            
        case 2:
            if let earnings = self.artist?.earnings {
                cell.displayNameLabel.text = self.uiElement.convertCentsToDollarsAndReturnString(earnings, currency: "$")
            } else {
                cell.displayNameLabel.text = "$0.00"
            }
            
            cell.username.text = "Earnings"
            break
            
        case 3:
            if let funds = self.artist?.balance {
                cell.displayNameLabel.text = self.uiElement.convertCentsToDollarsAndReturnString(funds, currency: "$")
            } else {
                cell.displayNameLabel.text = "$0.00"
            }
            cell.username.text = "Funds"
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
                if object != nil && error == nil {
                    let followers = object!["followers"] as! Int
                    let following = object!["following"] as! Int
                    
                    self.artist?.followingCount = following
                    self.artist?.followerCount = followers
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
                if object != nil && error == nil {
                    let earnings = object!["tipsSinceLastPayout"] as! Int
                    self.artist?.earnings = earnings
                }
                
                self.setupBottomButtons()
            }
        }
    }
}

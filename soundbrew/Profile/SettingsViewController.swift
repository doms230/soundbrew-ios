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

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    let uiElement = UIElement()
    let color = Color()
    
    var artist: Artist?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        artist = Customer.shared.artist
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
            Customer.shared.artist = nil
            if self.uiElement.getUserDefault("friends") != nil {
                self.uiElement.setUserDefault(nil, key: "friends")
            }
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
            return 5
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
                if #available(iOS 13.0, *) {
                    if let container = self.so_containerViewController {
                        container.isSideViewControllerPresented = false
                            if let topView = container.topViewController as? UINavigationController {
                                if let view = topView.topViewController as? ProfileViewController {
                                view.performSegue(withIdentifier: "showAddFunds", sender: self)
                                }
                            }
                        }
                } else {
                    self.uiElement.showAlert("Un-Available", message: "Adding funds to your account on iOS 12 is currently un-available. Email support@soundbrew.app for more info.", target: self)
                }
                break
                
            case 3:
                self.changeTipAmountDefault()
                break
                
            case 4:
                cashout()
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
            if let funds = self.artist?.balance {
                cell.displayNameLabel.text = self.uiElement.convertCentsToDollarsAndReturnString(funds, currency: "$")
            } else {
                cell.displayNameLabel.text = "$0.00"
            }
            cell.username.text = "Balance"
            break
            
        case 3:
            cell.username.text = "= 1 Like"
            if let userSavedTipAmount = self.uiElement.getUserDefault("tipAmount") as? Int {
                let formattedtipAmount = self.uiElement.convertCentsToDollarsAndReturnString(userSavedTipAmount, currency: "$")
                cell.displayNameLabel.text = "\(formattedtipAmount)"
                
            } else {
                cell.displayNameLabel.text = "setup $$$"
            }
            break
            
        case 4:
            cell.displayNameLabel.text = "Cash out"
            cell.username.text = ""
            break
            
        default:
            break
        }
        
        return cell
    }
    
    @objc func didPressShareProfileButton(_ sender: UIButton) {
        if let artist = Customer.shared.artist {
            self.uiElement.createDynamicLink("profile", sound: nil, artist: artist, target: self)
            
            MSAnalytics.trackEvent("Profile View Controller", withProperties: ["Button" : "Share Profile", "description": "User pressed share profile"])
        }
    }
    
    let tipAmountInCents = [5, 25, 50, 100]
    var selectedTipAmount = 5
    func changeTipAmountDefault() {
        let alertView = UIAlertController(
            title: "1 like = $$$",
            message: "How much would you like to tip artists when you like a song? \n\n\n\n\n\n\n\n",
            preferredStyle: .actionSheet)
        
        let pickerView = UIPickerView(frame:
            CGRect(x: 0, y: 45, width: UIScreen.main.bounds.width - 25, height: 160))
        pickerView.dataSource = self
        pickerView.delegate = self
        determineSelectedRowForPickerView(pickerView)
        alertView.view.addSubview(pickerView)
        
        let sendMoneyActionButton = UIAlertAction(title: "Save", style: .default) { (_) -> Void in
            self.uiElement.setUserDefault(self.selectedTipAmount, key: "tipAmount")
            self.tableView.reloadData()
        }
        alertView.addAction(sendMoneyActionButton)
        
        let localizedCancel = NSLocalizedString("cancel", comment: "")
        let cancelAction = UIAlertAction(title: localizedCancel, style: .cancel, handler: nil)
        alertView.addAction(cancelAction)
        
        present(alertView, animated: true, completion: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return tipAmountInCents.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let balanceInDollars = Double(tipAmountInCents[row]) / 100.00
        let doubleStr = String(format: "%.2f", balanceInDollars)
        return "$\(doubleStr)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedTipAmount = tipAmountInCents[row]
    }
    
    func determineSelectedRowForPickerView(_ pickerView: UIPickerView) {
        if let userSavedTipAmount = self.uiElement.getUserDefault("tipAmount") as? Int {
            var row = 0
            for i in 0..<tipAmountInCents.count {
                if tipAmountInCents[i] == userSavedTipAmount {
                    row = i
                }
            }
            pickerView.selectRow(row, inComponent: 0, animated: false)
        }
    }
        
    func cashout() {
        var currentUserBalance = 0
        if let balance = Customer.shared.artist?.balance {
            currentUserBalance = balance
        }
        
        let oneHundredDollarsInCents = 10000
        if currentUserBalance >= oneHundredDollarsInCents {
            print("TODO: set this up!")
        } else {
            let balanceInDollars = self.uiElement.convertCentsToDollarsAndReturnString(currentUserBalance, currency: "$")
            self.uiElement.showAlert("Current Balance: \(balanceInDollars)", message: "Cash out available when your balance reaches $100", target: self)
        }
    }
    
    //data
    func loadFollowerFollowingStats() {
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

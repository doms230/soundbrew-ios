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
    
    override func viewDidLoad() {
        super.viewDidLoad()
       setupLogOutButton()
    }
    
    //Mark: sign out
    lazy var signOut: UIButton = {
        let button = UIButton()
        button.setTitle("Sign Out", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        button.setTitleColor(Color().black(), for: .normal)
        button.addTarget(self, action: #selector(self.didPressSignoutButton(_:)), for: .touchUpInside)
        return button
    }()
    
    @objc func didPressSignoutButton(_ sender: UIButton) {
        let menuAlert = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
        menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        menuAlert.addAction(UIAlertAction(title: "Sign Out", style: .default, handler: { action in
            PFUser.logOut()
            if let container = self.so_containerViewController {
                container.isSideViewControllerPresented = false
                if let topView = container.topViewController {
                    topView.dismiss(animated: true, completion: nil)
                }                
            }
        }))
        self.present(menuAlert, animated: true, completion: nil)
    }
    
    func setupLogOutButton() {
        self.view.addSubview(signOut)
        self.signOut.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.view).offset(uiElement.bottomOffset + uiElement.bottomOffset)
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
        self.tableView.backgroundColor = .white
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
            return 3
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: settingsTitleReuse) as! ProfileTableViewCell
            cell.selectionStyle = .none
            if let currentUsername = PFUser.current()?.username {
                cell.displayNameLabel.text = currentUsername
                tableView.separatorStyle = .singleLine
            }
            return cell
            
        } else {
            return settingsItemReuse(indexPath)
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            showEarningsOrPayments("payments")
            break
            
        case 1:
            showEarningsOrPayments("earnings")
            break
            
        case 2:
            shareProfile()
            break
            
        default:
            break
        }
    }
    
    func shareProfile() {
        if let container = self.so_containerViewController {
            container.isSideViewControllerPresented = false
            if let topView = container.topViewController as? UINavigationController {
                if let view = topView.topViewController as? ProfileViewController {
                    view.shareProfile()
                }
            }
        }
    }
    
    func showEarningsOrPayments(_ paymentType: String) {
        if let container = self.so_containerViewController {
            container.isSideViewControllerPresented = false
            if let topView = container.topViewController as? UINavigationController {
                if let view = topView.topViewController as? ProfileViewController {
                    view.paymentType = paymentType
                    if paymentType == "payments" {
                        view.performSegue(withIdentifier: "showPayments", sender: self)
                    } else {
                        view.performSegue(withIdentifier: "showEarnings", sender: self)
                    }
                }
            }
        }
    }
    
    func settingsItemReuse(_ indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: settingsReuse) as! ProfileTableViewCell
        cell.selectionStyle = .none
        self.tableView.separatorStyle = .none
        switch indexPath.row {
        case 0:
            cell.displayNameLabel.text = "Payments"
            cell.profileImage.image = UIImage(named: "payments")
            break
            
        case 1:
            cell.displayNameLabel.text = "Earnings"
            cell.profileImage.image = UIImage(named: "earnings")
            break
            
        case 2:
            cell.displayNameLabel.text = "Share Profile"
            cell.profileImage.image = UIImage(named: "share")
            break
            
        default:
            break
        }
        
        return cell
    }
}

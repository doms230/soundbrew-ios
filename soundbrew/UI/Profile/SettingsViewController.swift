//
//  SettingsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 5/6/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var artist: Artist?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        self.navigationItem.title = "Settings"
    }
    
    //mark: tableview
    let tableView = UITableView()
    let reuse = "reuse"
    
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SettingsTableViewCell.self, forCellReuseIdentifier: reuse)
        tableView.separatorStyle = .none
        tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuse) as! SettingsTableViewCell
        cell.settingsButton.addTarget(self, action: #selector(self.didPressSettingsButton(_:)), for: .touchUpInside)
        
        switch indexPath.row {
        case 0:
            cell.settingsButton.setTitle("Streams", for: .normal)
            cell.settingsButton.tag = 0
            break
            
        case 1:
            cell.settingsButton.setTitle("Share profile", for: .normal)
            cell.settingsButton.setImage(UIImage(named: "share"), for: .normal)
            cell.settingsButton.tag = 1
            break
            
        case 2:
            cell.settingsButton.tag = 2
            cell.settingsButton.setTitle("Sign Out", for: .normal)
            break
            
        default:
            break
        }
        
        return cell 
    }
    
    @objc func didPressSettingsButton(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            //streaming
            self.performSegue(withIdentifier: "showStreams", sender: self)
            break
            
        case 1:
            //share profile
            if let artist = artist {
                UIElement().createDynamicLink("profile", sound: nil, artist: artist, target: self)
            }
            break
            
        case 2:
            PFUser.logOut()
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "welcome")
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            //show window
            appDelegate.window?.rootViewController = controller
            break
            
        default:
            break 
        }
    }
}

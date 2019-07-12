//
//  CreditPeopleViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 7/10/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import SnapKit
import Kingfisher

class CreditPeopleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
    }
    
    //MARK: Tableview
    let tableView = UITableView()
    let creditPeopleReuse = "creditPeopleReuse"
    let settingsTitleReuse = "settingsTitleReuse"
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: creditPeopleReuse)
       // tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: settingsTitleReuse)
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = .white
        self.tableView.frame = view.bounds
        self.view.addSubview(self.tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return peopleCell(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
    
    func peopleCell(indexPath: IndexPath) -> SoundInfoTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: creditPeopleReuse) as! SoundInfoTableViewCell
        cell.selectionStyle = .none
        switch indexPath.row {
        case 0:
            cell.artistTypeButton.setTitle("Facilitator", for: .normal)
            cell.artistTypeButton.isEnabled = false
            cell.soundArt.setImage(UIImage(named: "appy"), for: .normal)
            cell.soundTagLabel.text = "Soundbrew"
            cell.titleLabel.text = "15%"
            cell.progressSlider.value = 15
            cell.progressSlider.isEnabled = false
            cell.progressSlider.setThumbImage(UIImage(), for: .normal)
            break
            
        case 1:
            let artist = Customer.shared.artist
            cell.artistTypeButton.setTitle("Artist ▽", for: .normal)
            cell.artistTypeButton.isEnabled = true
            if let image = artist?.image {
                cell.soundArt.kf.setImage(with: URL(string: image), for: .normal)
            } else {
                cell.soundArt.setImage(UIImage(named: "profile_icon"), for: .normal)
            }
            cell.soundTagLabel.text = artist?.username
            cell.titleLabel.text = "85%"
            cell.progressSlider.value = 85
            cell.progressSlider.isEnabled = false
            cell.progressSlider.setThumbImage(UIImage(), for: .normal)
            break
            
        default:
            break
        }
        
        return cell
    }
    
    //mark: Search

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

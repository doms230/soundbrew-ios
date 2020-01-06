//
//  NewCreditViewController.swift
//  soundbrew
//
//  Created by Dominic Smith on 1/5/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import Kingfisher
import SnapKit

class NewCreditViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ArtistDelegate {
    //not used, but required
    func changeBio(_ value: String?) {
    }
    
    let color = Color()
    let uiElement = UIElement()
    
    var credits = [Credit]()
    var uploaderCredit: Credit!
    var creditDelegate: CreditDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Credits"
        uploaderCredit = createUploaderCredit()
       setUpTableView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearchUser" {
            let viewController = segue.destination as! PeopleViewController
            viewController.artistDelegate = self
            viewController.isAddingNewCredit = true
        }
    }
    
    //mark: tableview
    var tableView = UITableView()
    let creditReuse = "creditReuse"
    let newCreditReuse = "newCreditReuse"
    func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: creditReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: newCreditReuse)
        tableView.backgroundColor = color.black()
        tableView.separatorStyle = .none
        tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else if section == 1 {
            return credits.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section  {
        case 0:
            if indexPath.row == 0 {
                return creditRow(soundbrewCredit(), shouldHideStepper: true, indexPath: indexPath)
            } else {
                return creditRow(uploaderCredit, shouldHideStepper: true, indexPath: indexPath)
            }
            
        case 1:
            return creditRow(credits[indexPath.row], shouldHideStepper: false, indexPath: indexPath)
            
        default:
            let cell = self.tableView.dequeueReusableCell(withIdentifier: newCreditReuse) as! SoundInfoTableViewCell
            cell.backgroundColor = color.black()
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            self.performSegue(withIdentifier: "showSearchUser", sender: self)
        }
    }
    
    func creditRow(_ credit: Credit, shouldHideStepper: Bool, indexPath: IndexPath) -> SoundInfoTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: creditReuse) as! SoundInfoTableViewCell
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        
        if let artist = credit.artist {
            if let userImage = artist.image {
                cell.artistImage.kf.setImage(with: URL(string: userImage))
            }
            
            if let name = artist.name {
                cell.soundTagLabel.text = "\(artist.username!) (\(name))"
            } else {
                cell.soundTagLabel.text = artist.username!
            }
            
            cell.artistTypeButton.setTitle(credit.title!, for: .normal)
            cell.titleLabel.text = "Tip Split: \(credit.percentage!)%"
            
            cell.percentageStepper.value = 0
            cell.percentageStepper.isHidden = shouldHideStepper
            cell.percentageStepper.addTarget(self, action: #selector(didPressPercentageStepper(_:)), for: .valueChanged)
            cell.percentageStepper.tag = indexPath.row
            //cell.percentageSlider.value = Float(credit.percentage!)
            //cell.percentageSlider.isEnabled = shouldEnableSlider
            //cell.percentageSlider.addTarget(self, action: #selector(didChangeTipSplit(_:)), for: .valueChanged)
            //cell.percentageSlider.tag = indexPath.row
        }
        
        return cell
    }
    
    @objc func didPressPercentageStepper(_ sender: UIStepper) {
        let currentCreditSplit = self.credits[sender.tag].percentage!
        
        let splitsAvailable = 85
        var totalSplitPercentageAlreadyTaken = 0
        for credit in self.credits {
            totalSplitPercentageAlreadyTaken = totalSplitPercentageAlreadyTaken + credit.percentage!
        }
        
        let availableSplits = splitsAvailable - totalSplitPercentageAlreadyTaken
        
        if currentCreditSplit != availableSplits {
            if sender.value == 1 {
                self.credits[sender.tag].percentage = self.credits[sender.tag].percentage! + 5
            } else if sender.value == -1 {
                self.credits[sender.tag].percentage = self.credits[sender.tag].percentage! - 5
            }            
            let currentUploaderSplit = self.uploaderCredit.percentage!
            self.uploaderCredit.percentage = self.credits[sender.tag].percentage! - currentUploaderSplit
        }
        
        sender.value = 0
        self.tableView.reloadData()
    }
    
    /*@objc func didChangeTipSplit(_ sender: UISlider) {
        var totalTipSplits = 0
        for credit in credits {
            totalTipSplits = totalTipSplits + credit.percentage!
        }
        
        var totalTipSplitsAvailable = 85
        totalTipSplitsAvailable = totalTipSplitsAvailable - totalTipSplits
        
        let selectedSplit = Int(sender.value)
        
        if selectedSplit <= totalTipSplitsAvailable {
            self.credits[sender.tag].percentage! = selectedSplit
            //self.uploaderCredit.percentage! =
        }
        self.tableView.reloadData()
        
    }*/
        
    func soundbrewCredit() -> Credit {
        let credit = Credit(objectId: nil, artist: nil, title: "Facilitator", percentage: 15)
        let artist = Artist(objectId: "1", name: nil, city: nil, image: "https://www.soundbrew.app/images/logo.png", isVerified: false, username: "soundbrew", website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil)
        credit.artist = artist
        return credit
    }
    
    func createUploaderCredit() -> Credit {
        let credit = Credit(objectId: nil, artist: nil, title: "Artist", percentage: 85)
        if let artist = Customer.shared.artist {
            credit.artist = artist
        }
        return credit
    }
    
    func receivedArtist(_ value: Artist?) {
        if let artist = value {
            let credit = Credit(objectId: nil, artist: artist, title: "Add Credit Title", percentage: 0)
            self.credits.append(credit)
            self.tableView.reloadData()
        }
    }

}

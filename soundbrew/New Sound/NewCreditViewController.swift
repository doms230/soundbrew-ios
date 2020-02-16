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
    
    let color = Color()
    let uiElement = UIElement()
    
    var credits = [Credit]()
    var creditDelegate: CreditDelegate?
    var creditTitleCurrentlyBeingEdited: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Credits"
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(didPressDoneButton(_:)))
        self.navigationItem.rightBarButtonItem = doneButton
        setUpTableView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navigationController = segue.destination as! UINavigationController
        if segue.identifier == "showSearchUser" {
            let viewController: PeopleViewController = navigationController.topViewController as! PeopleViewController
            viewController.artistDelegate = self
            viewController.isAddingNewCredit = true
            let artists = self.credits.map {$0.artist}
            let artistObjectIds: [String] = artists.map {$0!.objectId}
            viewController.creditArtistObjectIds = artistObjectIds
            
        } else if segue.identifier == "showEditCreditTitle" {
            let viewController: EditBioViewController = navigationController.topViewController as! EditBioViewController
            viewController.totalAllowedTextLength = 25
            viewController.artistDelegate = self
            viewController.title = "Credit Title"
            if let title = self.credits[creditTitleCurrentlyBeingEdited].title {
                viewController.inputBio.text = title
            }
        }
    }
    
    @objc func didPressDoneButton(_ sender: UIBarButtonItem) {
        if let creditDelegate = self.creditDelegate {
            self.dismiss(animated: true, completion: {() in
                creditDelegate.receivedCredits(self.credits)
            })
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
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return credits.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            var shouldEnableSlider = true
            if indexPath.row == 0 {
                shouldEnableSlider = false
            }
            return creditRow(credits[indexPath.row], shouldEnableSlider: shouldEnableSlider, indexPath: indexPath)
            
        } else {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: newCreditReuse) as! SoundInfoTableViewCell
            cell.backgroundColor = color.black()
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if credits.count == 17 {
                self.uiElement.showAlert("Limit Reached", message: "You can credit up to 17 people", target: self)
            } else {
                self.performSegue(withIdentifier: "showSearchUser", sender: self)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 && indexPath.row != 0 {
            return true
        }
        return false
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.section == 0 && indexPath.row != 0 {
                if let percentage = self.credits[indexPath.row].percentage {
                    addSplitAmountBackToUploader(percentage)
                }
                self.credits.remove(at: indexPath.row)
                self.tableView.reloadData()
            }
        }
    }
    
    func creditRow(_ credit: Credit, shouldEnableSlider: Bool, indexPath: IndexPath) -> SoundInfoTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: creditReuse) as! SoundInfoTableViewCell
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
                
        if let artist = credit.artist {
            if let userImage = artist.image {
                cell.artistImage.kf.setImage(with: URL(string: userImage))
            }
            
            if let username = artist.username {
                cell.username.text = "@\(username)"
            }
            
            if let name = artist.name {
                cell.soundTagLabel.text = name
            }
            
            if let creditTitle = credit.title {
                cell.artistTypeButton.setTitle(creditTitle, for: .normal)
            } else {
                cell.artistTypeButton.setTitle("Add Credit Title", for: .normal)
            }
            
            if indexPath.row == 0 {
                cell.artistTypeButton.setTitleColor(color.blue(), for: .normal)
                cell.artistTypeButton.setTitleColor(.darkGray, for: .normal)
                
            } else {
                cell.artistTypeButton.setTitleColor(color.blue(), for: .normal)
                cell.artistTypeButton.addTarget(self, action: #selector(didPressChangeCreditTitle(_:)), for: .touchUpInside)
                cell.artistTypeButton.tag = indexPath.row
            }

            cell.titleLabel.text = "Tip Split: \(credit.percentage!)%"
            
            cell.percentageSlider.value = Float(credit.percentage!)
            cell.percentageSlider.isEnabled = shouldEnableSlider
            cell.percentageSlider.addTarget(self, action: #selector(didChangeTipSplit(_:)), for: .valueChanged)
            cell.percentageSlider.tag = indexPath.row
        }
        
        return cell
    }
    
    @objc func didPressChangeCreditTitle(_ sender: UIButton) {
        creditTitleCurrentlyBeingEdited = sender.tag
        self.performSegue(withIdentifier: "showEditCreditTitle", sender: self)
    }
    
    func changeBio(_ value: String?) {
        if let newCreditTitle = value {
            self.credits[creditTitleCurrentlyBeingEdited].title = newCreditTitle
        } else {
            self.credits[creditTitleCurrentlyBeingEdited].title = nil
        }
        self.tableView.reloadData()
    }
    
    @objc func didChangeTipSplit(_ sender: UISlider) {
        var totalAvailablePercentage = 100
        let selectedSplit = Int(sender.value)
        
        for i in 0..<self.credits.count {
            if i != sender.tag && i != 0 {
                totalAvailablePercentage = totalAvailablePercentage - self.credits[i].percentage!
            }
        }
        
        if selectedSplit <= totalAvailablePercentage {
            self.credits[sender.tag].percentage = selectedSplit
            self.credits[0].percentage = totalAvailablePercentage - selectedSplit
        }
        self.tableView.reloadData()
    }
    
    func addSplitAmountBackToUploader(_ amount: Int) {
        self.credits[0].percentage = self.credits[0].percentage! + amount
    }
    
    func receivedArtist(_ value: Artist?) {
        if let artist = value {
            let credit = Credit(objectId: nil, artist: artist, title: nil, percentage: 0)
            self.credits.append(credit)
            self.tableView.reloadData()
        }
    }

}

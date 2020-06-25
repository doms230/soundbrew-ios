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
        self.view.backgroundColor = .black
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        let topView = self.uiElement.addSubViewControllerTopView(self, action: #selector(self.didPressDoneButton(_:)), doneButtonTitle: "Done", title: "New Feature")
        setUpTableView(topView.2)
    }
    
    @objc func didPressDoneButton(_ sender: UIBarButtonItem) {
        if sender.tag == 0 {
            self.dismiss(animated: true, completion: nil)
        } else {
            if let creditDelegate = self.creditDelegate {
                self.dismiss(animated: true, completion: {() in
                    creditDelegate.receivedCredits(self.credits)
                })
            }
        }
    }
    
    //mark: tableview
    var tableView = UITableView()
    let creditReuse = "creditReuse"
    let newCreditReuse = "newCreditReuse"
    func setUpTableView(_ dividerLine: UIView) {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: creditReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: newCreditReuse)
        tableView.backgroundColor = color.black()
        tableView.separatorStyle = .none
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(dividerLine.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
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
            return creditCell(credits[indexPath.row], shouldEnableSlider: shouldEnableSlider, indexPath: indexPath)
            
        } else {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: newCreditReuse) as! SoundInfoTableViewCell
            cell.backgroundColor = color.black()
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if credits.count == 10 {
                self.uiElement.showAlert("Limit Reached", message: "You can feature up to 10 people", target: self)
            } else {
                let modal = PeopleViewController()
                modal.artistDelegate = self
                modal.isAddingNewCredit = true
                let artists = self.credits.map {$0.artist}
                let artistObjectIds: [String] = artists.map {$0!.objectId}
                modal.creditArtistObjectIds = artistObjectIds
                self.present(modal, animated: true, completion: nil)
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
                self.credits.remove(at: indexPath.row)
                self.tableView.reloadData()
            }
        }
    }
    
    func creditCell(_ credit: Credit, shouldEnableSlider: Bool, indexPath: IndexPath) -> SoundInfoTableViewCell {
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
                cell.artistTypeButton.setTitle("Add Feature Title", for: .normal)
            }
            
            cell.artistTypeButton.setTitleColor(color.blue(), for: .normal)
            cell.artistTypeButton.addTarget(self, action: #selector(didPressChangeCreditTitle(_:)), for: .touchUpInside)
            cell.artistTypeButton.tag = indexPath.row
        }
        
        return cell
    }
    
    @objc func didPressChangeCreditTitle(_ sender: UIButton) {
        creditTitleCurrentlyBeingEdited = sender.tag
        let modal = EditBioViewController()
        modal.bioTitle = "Feature Title"
        modal.totalAllowedTextLength = 25
        modal.artistDelegate = self
        if let title = self.credits[creditTitleCurrentlyBeingEdited].title {
            modal.inputBio.text = title
        }
        self.present(modal, animated: true, completion: nil)
    }
    
    func changeBio(_ value: String?) {
        if let newCreditTitle = value {
            self.credits[creditTitleCurrentlyBeingEdited].title = newCreditTitle
        } else {
            self.credits[creditTitleCurrentlyBeingEdited].title = nil
        }
        self.tableView.reloadData()
    }
    
    func receivedArtist(_ value: Artist?) {
        if let artist = value {
            let credit = Credit(objectId: nil, artist: artist, title: nil)
            self.credits.append(credit)
            self.tableView.reloadData()
        }
    }
}

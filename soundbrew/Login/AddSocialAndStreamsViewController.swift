//
//  AddSocialAndStreamsViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/10/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//
//  MARK: button actions, tableview, data, textfield

import UIKit
import Parse
import NVActivityIndicatorView
import SnapKit

class AddSocialAndStreamsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable {
    
    let uiElement = UIElement()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: uiElement.titleLabelFontSize)
        label.text = "Add Socials & Streams"
        label.numberOfLines = 0
        return label
    }()
    
    var city: String!
    var artistName: String!
    var email: String!
    var password: String!
    
    var instagramText: UITextField!
    var twitterText: UITextField!
    let socialLabels = ["Instagram username", "Twitter username"]
    let socialImages = ["ig_logo", "twitter_logo"]
    
    var appleMusicText: UITextField!
    var soundcloudText: UITextField!
    var spotifyText: UITextField!
    let streamLabels = ["Apple Music Link", "SoundCloud Link", "Spotify Link"]
    let streamImages = ["appleMusic_logo", "soundcloud_logo", "spotify_logo"]
    
    var linkText: UITextField!
    let linkLabel = ["Other Relevant Link"]
    let linkImage = ["link_logo"]

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }
    
    func setUpViews() {
        
        self.title = "Socials & Streams (4/4)"
        
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.didPressSaveButton(_:)))
        self.navigationItem.rightBarButtonItem = doneButton
        
        self.view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(StreamsAndSocialsTableViewCell.self, forCellReuseIdentifier: socialsAndStreamsReuse)
        tableView.register(StreamsAndSocialsTableViewCell.self, forCellReuseIdentifier: "reuse")
        //tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        //tableView.frame = view.bounds
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    //MARK: Button Actions
    @objc func didPressSaveButton(_ sender: UIBarButtonItem) {
        saveNewUser()
    }
    
    //MARK: TableView
    let tableView = UITableView()
    let socialsAndStreamsReuse = "socialsAndStreamsReuse"
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return socialLabels.count
            
        case 1:
            return streamLabels.count
            
        case 2:
            return 1
            
        default:
            return 6
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCell(withIdentifier: socialsAndStreamsReuse) as! StreamsAndSocialsTableViewCell
        
        cell.selectionStyle = .none
        let row = indexPath.row
        let section = indexPath.section
        
        switch section{
        case 0:
            cell.socialStreamImage.image = UIImage(named: socialImages[row])
            cell.socialStreamText.placeholder = socialLabels[row]
            break
            
        case 1:
            cell.socialStreamImage.image = UIImage(named: streamImages[row])
            cell.socialStreamText.placeholder = streamLabels[row]
            
        case 2:
            cell.socialStreamImage.image = UIImage(named: linkImage[row])
            cell.socialStreamText.placeholder = linkLabel[row]
            
        default:
            cell = self.tableView.dequeueReusableCell(withIdentifier: "reuse") as! StreamsAndSocialsTableViewCell
            cell.selectionStyle = .none
            break
        }
        
        setTextFields(cell, row: row, section: section)
        
        return cell
    }

    //MARK: Data
    func saveNewUser() {
        self.startAnimating()
        let emailLowercased = email.lowercased()
        
        if let igText = instagramText.text {
            if igText.starts(with: "@") {
                instagramText.text?.removeFirst()
            }
        }
        
        if let igText = twitterText.text {
            if igText.starts(with: "@") {
                twitterText.text?.removeFirst()
            }
        }
        
        let user = PFUser()
        user.username = emailLowercased
        user.password = password
        user.email = emailLowercased
        user["city"] = city
        user["artistName"] = artistName
        setSocialStreamUserObjectField(user, objectField: "instagramHandle", socialStreamText: instagramText.text!)
        setSocialStreamUserObjectField(user, objectField: "twitterHandle", socialStreamText: twitterText.text!)
        setSocialStreamUserObjectField(user, objectField: "appleMusicLink", socialStreamText: appleMusicText.text!)
        setSocialStreamUserObjectField(user, objectField: "soundCloudLink", socialStreamText: soundcloudText.text!)
        setSocialStreamUserObjectField(user, objectField: "spotifyLink", socialStreamText: spotifyText.text!)
        setSocialStreamUserObjectField(user, objectField: "otherLink", socialStreamText: linkText.text!)
        user.signUpInBackground{ (succeeded: Bool, error: Error?) -> Void in
            self.stopAnimating()
            if let error = error {
                UIElement().showAlert("Oops", message: error.localizedDescription, target: self)
                
            } else {
                let installation = PFInstallation.current()
                installation?["user"] = PFUser.current()
                installation?["userId"] = PFUser.current()?.objectId
                installation?.saveEventually()
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let initialViewController = storyboard.instantiateViewController(withIdentifier: "main")
                self.present(initialViewController, animated: true, completion: nil)
            }
        }
    }
    
    //Mark: TextField
    func setSocialStreamUserObjectField(_ user: PFUser, objectField: String, socialStreamText: String) {
        if !socialStreamText.isEmpty {
            user[objectField] = socialStreamText
        }
    }
    
    func setTextFields(_ cell: StreamsAndSocialsTableViewCell, row: Int, section: Int) {
        switch section {
        case 0:
            switch row {
            case 0:
                instagramText = cell.socialStreamText
                break
                
            case 1:
                twitterText = cell.socialStreamText
                
            default:
                break
            }
            break
            
        case 1:
            switch row {
            case 0:
                appleMusicText = cell.socialStreamText
                break
                
            case 1:
                soundcloudText = cell.socialStreamText
                break
                
            case 2:
                spotifyText = cell.socialStreamText
                
            default:
                break
            }
            break
            
        case 2:
            linkText = cell.socialStreamText
            break
            
        default:
            break
        }
    }
}

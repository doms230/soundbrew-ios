//
//  EarningsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 7/7/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import SnapKit

class EarningsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        loadEarnings()
    }
    
    let uiElement = UIElement()
    let color = Color()
    
    lazy var earningsLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 40)
        label.textColor = color.black()
        return label
    }()
    
    lazy var dividerLine: UIView = {
        let line = UIView()
        line.layer.borderWidth = 1
        line.layer.borderColor = color.darkGray().cgColor
        return line
    }()
    
    lazy var earningsScheduleLabel: UILabel = {
        let label = UILabel()
        label.text = "A 15% fee will be deducted from your earnings. \n Earnings are sent via PayPal on a weekly basis. \n Please insure that your profile email is up to date."
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = color.black()
        label.numberOfLines = 0
        return label
    }()
    
    lazy var yourTipsLabel: UILabel = {
        let label = UILabel()
        label.text = "Your Tips"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 20)
        label.textColor = color.black()
        return label
    }()
    
    func setUpView() {
        self.view.addSubview(earningsLabel)
        earningsLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(earningsScheduleLabel)
        earningsScheduleLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(earningsLabel.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(dividerLine)
        dividerLine.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(1)
            make.top.equalTo(earningsScheduleLabel.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(yourTipsLabel)
        yourTipsLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(dividerLine.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        LoadTipouts()
    }
    
    func loadEarnings() {
        let query = PFQuery(className: "Payment")
        query.whereKey("userId", equalTo: PFUser.current()!.objectId!)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if error != nil {
                self.earningsLabel.text = "$0.00"
                
            } else if let object = object {
                if let earningsInCents = object["tipsSinceLastPayout"] as? Int {
                    let earningsInDollars = self.uiElement.convertCentsToDollarsAndReturnString(earningsInCents, currency: "$")
                    self.earningsLabel.text = earningsInDollars
                    
                } else {
                    self.earningsLabel.text = "$0.00"
                }
                
            } else {
                self.earningsLabel.text = "$0.00"
            }
        }
    }

    //MARK: Tableview
    let tableView = UITableView()
    let earningsPaymentsReuse = "earningsPaymentsReuse"
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: earningsPaymentsReuse)
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = .white
        self.view.addSubview(tableView)
        self.tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.yourTipsLabel.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return soundIds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: earningsPaymentsReuse) as! ProfileTableViewCell
        cell.selectionStyle = .none
        tableView.separatorStyle = .none
        
        loadSound(cell, row: indexPath.row, objectId: soundIds[indexPath.row], tipAmount: tipAmount[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedArtist = artists[indexPath.row]
        self.performSegue(withIdentifier: "showProfile", sender: self)
    }
    
    var artists = [Artist]()
    var tipAmount = [Int]()
    var soundIds = [String]()
    var selectedArtist: Artist!
    var tipperUserId = [String]()
    
    func LoadTipouts() {
        let query = PFQuery(className: "Tip")
        query.whereKey("toUserId", equalTo: PFUser.current()!.objectId!)
        query.addDescendingOrder("createdAt")
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        self.soundIds.append(object["soundId"] as! String)
                        self.tipAmount.append(object["amount"] as! Int)
                        self.tipperUserId.append(object["fromUserId"] as! String)
                    }
                    self.setUpTableView()
                }
            }
        }
    }
    
    func loadSound(_ cell: ProfileTableViewCell, row: Int, objectId: String, tipAmount: Int) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                let sound = self.uiElement.newSoundObject(object)
                let tipInDollars = self.uiElement.convertCentsToDollarsAndReturnString(tipAmount, currency: "$")
                cell.bio.text = "\(tipInDollars) for \(sound.title!)"
                
                self.loadArtist(self.tipperUserId[row], cell: cell, row: row)
            }
        }
    }
    
    func loadArtist(_ userId: String, cell: ProfileTableViewCell, row: Int) {
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                let username = user["username"] as? String
                
                var email: String?
                if user.objectId! == PFUser.current()!.objectId {
                    email = user["email"] as? String
                }
                
                let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: username, website: nil, bio: nil, email: email, isFollowedByCurrentUser: nil, followerCount: nil, customerId: nil, balance: nil)
                
                if let followerCount = user["followerCount"] as? Int {
                    artist.followerCount = followerCount
                }
                
                if let name = user["artistName"] as? String {
                    artist.name = name
                }
                
                if let username = user["username"] as? String {
                    cell.displayNameLabel.text = username
                    artist.username = username
                }
                
                if let city = user["city"] as? String {
                    artist.city = city
                }
                
                if let userImageFile = user["userImage"] as? PFFileObject {
                    cell.profileImage.kf.setImage(with: URL(string: userImageFile.url!))
                    artist.image = userImageFile.url!
                }
                
                if let bio = user["bio"] as? String {
                    artist.bio = bio
                }
                
                if let artistVerification = user["artistVerification"] as? Bool {
                    artist.isVerified = artistVerification
                }
                
                if let website = user["website"] as? String {
                    artist.website = website
                }
                
                self.artists.append(artist)
                
            }
        }
    }
}

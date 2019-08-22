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
        label.text = "$1,000"
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
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    lazy var yourTipsLabel: UILabel = {
        let label = UILabel()
        label.text = "Your Tips"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 20)
        label.textColor = .white
        return label
    }()
    
    lazy var infoButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "info"), for: .normal)
        button.addTarget(self, action: #selector(didPressInfoButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressInfoButton(_ sender: UIButton) {
        let alertController = UIAlertController (title: "Info", message: "Earnings are sent via PayPal on a weekly basis. \n\n Please insure that your profile email is the email you use to receive PayPal payments. \n\n A 15% Soundbrew fee will be deducted from your earnings. ", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
        alertController.addAction(okayAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func setUpView() {
        self.view.addSubview(infoButton)
        infoButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(50)
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(earningsLabel)
        earningsLabel.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(infoButton)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(infoButton.snp.left).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(dividerLine)
        dividerLine.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(1)
            make.top.equalTo(earningsLabel.snp.bottom).offset(uiElement.topOffset)
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
                    //TODO self.earningsLabel.text = earningsInDollars
                    
                } else {
                    self.earningsLabel.text = "$0.00"
                }
                
            } else {
                self.earningsLabel.text = "$0.00"
            }
        }
    }

    //MARK: Tableview
    var testTips = ["$1.00 for RARE", "$0.50 for My Word", "$1.00 for My Word", "$0.10 for Rare", "$1.00 for Illuminated Illusions", "$0.10 for RARE", "$0.50", "$0.50 for My Word", "$0.25 for Illuminated Illusions", "$0.10 Illuminated Illusions", "$0.25 My Word", "$1.00 for RARE"]
    var testNames = ["Teaonna", "Sasha", "Jorge", "Christina", "Dominic", "Sarah", "Lauren", "Nicole", "Dave", "Janie", "", ""]
    var testImages = ["testImage", "testImage1", "testImage2", "testImage3", "testImage4", "testImage5", "testImage6", "testImage7", "testImage8", "testImage9", "testImage10", "testImage11", "testImage12"]
    
    let tableView = UITableView()
    let earningsPaymentsReuse = "earningsPaymentsReuse"
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: earningsPaymentsReuse)
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = color.black()
        self.view.addSubview(tableView)
        self.tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.yourTipsLabel.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return soundIds.count
        return testTips.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: earningsPaymentsReuse) as! ProfileTableViewCell
        cell.selectionStyle = .none
        cell.backgroundColor = color.black()
        tableView.separatorStyle = .none
        
        //loadSound(cell, row: indexPath.row, objectId: soundIds[indexPath.row], tipAmount: tipAmount[indexPath.row])
        cell.profileImage.image = UIImage(named: testImages[indexPath.row])
        cell.bio.text = testTips[indexPath.row]
        cell.displayNameLabel.text = testNames[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //selectedArtist = artists[indexPath.row]
        //self.performSegue(withIdentifier: "showProfile", sender: self)
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

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
        label.text = "Earnings are sent via PayPal on a weekly basis. \n Please insure that your profile email is up to date."
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
        return soundsThatArtistTipped.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: earningsPaymentsReuse) as! ProfileTableViewCell
        cell.selectionStyle = .none
        tableView.separatorStyle = .none
        
        let sound = soundsThatArtistTipped[indexPath.row]
        
        loadArtist(tipperUserId[indexPath.row], cell: cell)
        
        //song title
        let tipInDollars = self.uiElement.convertCentsToDollarsAndReturnString(tipAmount[indexPath.row], currency: "$")
        cell.bio.text = "\(tipInDollars) for \(sound.title!)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.uiElement.setUserDefault("receivedUserId", value: tipperUserId[indexPath.row])
        self.performSegue(withIdentifier: "showProfile", sender: self)
    }
    
    var soundsThatArtistTipped = [Sound]()
    var tipAmount = [Int]()
    var tipperUserId = [String]()
    var selectedArtist: Artist!
    
    func LoadTipouts() {
        var soundIds = [String]()
        let query = PFQuery(className: "Tip")
        query.whereKey("toUserId", equalTo: PFUser.current()!.objectId!)
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        soundIds.append((object["soundId"] as? String)!)
                        self.tipAmount.append((object["amount"] as? Int)!)
                        self.tipperUserId.append(object["fromUserId"] as! String)
                    }
                    
                    self.loadSounds(soundIds)
                }
            }
        }
    }
    
    func loadSounds(_ soundIds: [String]) {
        print(soundIds)
        let query = PFQuery(className: "Post")
        query.whereKey("objectId", containedIn: soundIds)
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let sound = self.uiElement.newSoundObject(object)
                        self.soundsThatArtistTipped.append(sound)
                    }
                    self.setUpTableView()
                }
            }
        }
    }
    
    func loadArtist(_ userId: String, cell: ProfileTableViewCell) {
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                if let username = user["username"] as? String {
                    cell.displayNameLabel.text = username
                }
                
                if let userImageFile = user["userImage"] as? PFFileObject {
                    cell.profileImage.kf.setImage(with: URL(string: userImageFile.url!))
                }
            }
        }
    }
}

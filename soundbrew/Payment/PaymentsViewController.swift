//
//  PaymentsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 7/2/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse

class PaymentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let uiElement = UIElement()
    let color = Color()
    var paymentType: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPaymentView()
        setUpNavigationView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let customer = Customer.shared
        if let balance = customer.artist?.balance {
            let balanceAsDollarString = uiElement.convertCentsToDollarsAndReturnString(balance, currency: "$")
            paymentLabel.text = "\(balanceAsDollarString)"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAddFunds" {
            let backItem = UIBarButtonItem()
            backItem.title = "Add Funds"
            navigationItem.backBarButtonItem = backItem
            
        } else if segue.identifier == "showProfile" {
            let viewController = segue.destination as! ProfileViewController
            viewController.profileArtist = selectedArtist
        }
    }
    
    //MARK: UI
    func setUpNavigationView() {
        let addFundsButton = UIBarButtonItem(title: "Add Funds", style: .plain, target: self, action: #selector(didPressPaymentButton(_:)))
        self.navigationItem.rightBarButtonItem = addFundsButton
    }
    
    lazy var paymentLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 40)
        label.textColor = color.black()
        return label
    }()
    
    lazy var paymentsSubLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 20)
        label.textColor = color.black()
        label.text = "Current Balance"
        return label
    }()
    
    lazy var dividerLine: UIView = {
        let line = UIView()
        line.layer.borderWidth = 1
        line.layer.borderColor = color.darkGray().cgColor
        return line
    }()
    
    lazy var artistsUserHasTippedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 20)
        label.textColor = color.black()
        label.text = "Artists you've tipped"
        return label
    }()
    
    func setupPaymentView() {
        self.view.addSubview(paymentsSubLabel)
        paymentsSubLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(paymentLabel)
        paymentLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(paymentsSubLabel.snp.bottom)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(dividerLine)
        dividerLine.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(1)
            make.top.equalTo(paymentLabel.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(artistsUserHasTippedLabel)
        artistsUserHasTippedLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(dividerLine.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        LoadTipouts()
    }
    
    @objc func didPressPaymentButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showAddFunds", sender: self)
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
            make.top.equalTo(self.artistsUserHasTippedLabel.snp.bottom)
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
        
        loadArtist(sound.artist!.objectId, cell: cell, row: indexPath.row)
        
        //song title
        let tipInDollars = self.uiElement.convertCentsToDollarsAndReturnString(tipAmount[indexPath.row], currency: "$")
        cell.bio.text = "\(tipInDollars) for \(sound.title!)"

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       selectedArtist = soundsThatArtistTipped[indexPath.row].artist
        self.performSegue(withIdentifier: "showProfile", sender: self)
    }
    
    var soundsThatArtistTipped = [Sound]()
    var tipAmount = [Int]()
    var selectedArtist: Artist!
    
    func LoadTipouts() {
        var soundIds = [String]()
        let query = PFQuery(className: "Tip")
        query.whereKey("fromUserId", equalTo: PFUser.current()!.objectId!)
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        soundIds.append((object["soundId"] as? String)!)
                        self.tipAmount.append((object["amount"] as? Int)!)
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
                    print(objects.count)
                    for object in objects {
                        let sound = self.uiElement.newSoundObject(object)
                        self.soundsThatArtistTipped.append(sound)
                        print(sound)
                    }
                    self.setUpTableView()
                }
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
                
                self.soundsThatArtistTipped[row].artist = artist
                
            }
        }
    }
}



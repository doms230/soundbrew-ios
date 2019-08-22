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
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
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
        label.textColor = .white
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
        label.textColor = .white
        label.text = "Artists you've tipped"
        return label
    }()
    
    func setupPaymentView() {
        self.view.addSubview(paymentLabel)
        paymentLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
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
        self.tableView.backgroundColor = color.black()
        self.view.addSubview(tableView)
        self.tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.artistsUserHasTippedLabel.snp.bottom)
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
        cell.backgroundColor = color.black()
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
    var tipBody = [String]()
    
    func LoadTipouts() {
        let query = PFQuery(className: "Tip")
        query.whereKey("fromUserId", equalTo: PFUser.current()!.objectId!)
        query.addDescendingOrder("createdAt")
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        self.soundIds.append((object["soundId"] as? String)!)
                        self.tipAmount.append((object["amount"] as? Int)!)
                        //print(object)
                    }
                    
                    //self.loadSounds(soundIds)
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
                
                self.loadArtist(sound.artist!.objectId, cell: cell, row: row)
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



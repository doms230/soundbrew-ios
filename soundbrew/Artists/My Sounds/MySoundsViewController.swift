//
//  MySoundsViewController.swift
//  soundbrew artists
//
//  Created by Dominic Smith on 10/11/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import Kingfisher

class MySoundsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let uiElement = UIElement()
    let color = Color()

    var sounds = [Song]()
    
    lazy var newSoundtitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)-bold", size: uiElement.titleLabelFontSize)
        label.text = "Welcome to Soundbrew!"
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    lazy var newSoundButton: UIButton = {
        let image = UIButton()
        image.setTitle("Get Started", for: .normal)
        image.titleLabel?.textColor = .black
        image.layer.cornerRadius = 3
        image.clipsToBounds = true
        image.backgroundColor = Color().blue()
        return image
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "My Sounds"
        self.loadSounds()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let installation = PFInstallation.current()
        installation?.badge = 0
        installation?.saveInBackground()
    }
    
    func showNewSoundUI() {
        self.view.addSubview(newSoundtitle)
        newSoundtitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset((self.view.frame.height / 2) - 50)
            make.left.equalTo(self.view).offset(self.uiElement.leftOffset)
            make.right.equalTo(self.view).offset(self.uiElement.rightOffset)
        }
        
        newSoundButton.addTarget(self, action: #selector(self.didPressUploadSoundButton(_:)), for: .touchUpInside)
        self.view.addSubview(newSoundButton)
        newSoundButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.width.equalTo(200)
            make.top.equalTo(self.newSoundtitle.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset((self.view.frame.width / 2) - CGFloat(100))
        }
    }
    
    //mark: tableview
    var tableView: UITableView!
    let reuse = "reuse"
    
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MySoundsTableViewCell.self, forCellReuseIdentifier: reuse)
        self.tableView.separatorStyle = .none
        tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! MySoundsTableViewCell
        
        cell.selectionStyle = .none
        
        let sound = sounds[indexPath.row]
        
        cell.menuButton.addTarget(self, action: #selector(self.didPressMenuButton(_:)), for: .touchUpInside)
        cell.menuButton.tag = indexPath.row
        
        cell.soundCreatedAt.text = formatDate(date: sound.createdAt)
        cell.soundArtImage.kf.setImage(with: URL(string: sound.art))
        cell.soundTitle.text = sound.title
        
        var tagString = ""
        let tagArray = sound.tags
        for tag in tagArray ?? [""] {
            if tagString.isEmpty {
                tagString = tag
                
            } else {
                tagString = "\(tagString), \(tag)"
            }
        }
        
        cell.soundTags.text = tagString
        
        if let plays = sound.plays {
            cell.soundPlays.text = "\(plays) plays"
            
        } else {
            cell.soundPlays.text = "Plays unavailable"
        }
        
        return cell
    }
    
    //mark: button actions
    @objc func didPressMenuButton(_ sender: UIButton) {
        let row = sender.tag
        
        let menuAlert = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
        menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        menuAlert.addAction(UIAlertAction(title: "Delete Song", style: .default, handler: { action in
            self.deleteSong(self.sounds[row].objectId, row: row)
        }))
        
        self.present(menuAlert, animated: true, completion: nil)
    }
    
    @objc func didPressUploadSoundButton(_ sender: UIButton) {
        tabBarController?.selectedIndex = 1
    }
    
    //mark: data
    func loadSounds() {
        let query = PFQuery(className: "Post")
        query.whereKey("userId", equalTo: PFUser.current()!.objectId!)
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let title = object["title"] as! String
                        let art = object["songArt"] as! PFFileObject
                        let audio = object["audioFile"] as! PFFileObject
                        let tags = object["tags"] as! Array<String>
                        var soundPlays: Int?
                        if let plays = object["plays"] as? Int {
                            soundPlays = plays
                        }
                        
                        let sound = Song(objectId: object.objectId, title: title, audio: audio, art: art.url!, userId: PFUser.current()!.objectId!, tags: tags, createdAt: object.createdAt, plays: soundPlays)
                        self.sounds.append(sound)
                    
                    }
                }
                
                if objects?.count == 0 {
                    self.showNewSoundUI()
                    
                } else {
                    //self.tableView.reloadData()
                    self.setUpTableView()
                    SKStoreReviewController.requestReview()
                }
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func deleteSong(_ objectId: String, row: Int) {
        let query = PFQuery(className:"Post")
        query.getObjectInBackground(withId: objectId) {
            (post: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let post = post {
                post.deleteInBackground {
                    (success: Bool, error: Error?) in
                    if (success) {
                        self.sounds.remove(at: row)
                        self.tableView.reloadData()
                        
                    } else if let error = error {
                        UIElement().showAlert("Oops", message: error.localizedDescription, target: self)
                    }
                }
            }
        }
    }
    
    //mark: date
    func formatDate(date: Date) -> String {
        //format date
        let formatter = DateFormatter()
        // initially set the format based on your datepicker date
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "hh:mm a"
            
        } else {
            formatter.dateFormat = "MM/dd/yy, hh:mm a"
        }
        
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        let myString = formatter.string(from: date)
        
        return myString
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

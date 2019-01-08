//
//  EditProfileViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/11/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit
import Parse
import NVActivityIndicatorView
import Kingfisher

class EditProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    let uiElement = UIElement()
    
    lazy var userImage: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "profile_icon"), for: .normal)
        button.backgroundColor = .lightGray
        button.layer.cornerRadius = 25
        button.clipsToBounds = true
        button.contentMode = .scaleAspectFill
        return button
    }()
    
    lazy var imageLabel: UILabel = {
        let label = UILabel()
        label.text = "+"
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 20)
        label.textColor = .black
        return label
    }()
    
    var newUserImage: PFFileObject?
    
    var instagramText: UITextField!
    var twitterText: UITextField!
    let socialLabels = ["Instagram username", "Twitter username"]
    let socialImages = ["ig_logo", "twitter_logo"]
    var socialText = [String]()
    
    var appleMusicText: UITextField!
    var soundcloudText: UITextField!
    var spotifyText: UITextField!
    let streamLabels = ["Apple Music Link", "SoundCloud Link", "Spotify Link"]
    let streamImages = ["appleMusic_logo", "soundcloud_logo", "spotify_logo"]
    var streamtext = [String]()
    
    var linkText: UITextField!
    let linkLabel = ["Other Relevant Link"]
    let linkImage = ["link_logo"]
    var otherLink = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        loadUserInfoFromCloud(PFUser.current()!.objectId!)
    }
    
    func setUpViews() {
        self.title = "Edit Profile"
        
        let saveButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(self.didPressSaveButton(_:)))
        self.navigationItem.rightBarButtonItem = saveButton
        
        self.userImage.addTarget(self, action: #selector(self.didPressEditImagebutton(_:)), for: .touchUpInside)
        self.view.addSubview(userImage)
        userImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(50)
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        self.view.addSubview(imageLabel)
        imageLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.userImage).offset(-5)
            make.left.equalTo(self.userImage).offset(7)
        }
    }
    
    //MARK: Button Actions
    @objc func didPressSaveButton(_ sender: UIBarButtonItem) {
        updateUserInfo()
    }
    
    @objc func didPressEditImagebutton(_ sender: UIButton){
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        
        let alertController = UIAlertController (title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { (_) -> Void in
            imagePicker.sourceType = .camera
            self.present(imagePicker, animated: true, completion: nil)
        }
        alertController.addAction(cameraAction)
        
        let photolibraryAction = UIAlertAction(title: "Photo Library", style: .default) { (_) -> Void in
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
        alertController.addAction(photolibraryAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) -> Void in
        }
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    //MARK: TableView
    let tableView = UITableView()
    let socialsAndStreamsReuse = "socialsAndStreamsReuse"
    let reuse = "reuse"
    
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(StreamsAndSocialsTableViewCell.self, forCellReuseIdentifier: socialsAndStreamsReuse)
        tableView.register(StreamsAndSocialsTableViewCell.self, forCellReuseIdentifier: reuse)
        //tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        //tableView.frame = view.bounds
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.userImage.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
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
            cell.socialStreamText.text = socialText[row]
            break
            
        case 1:
            cell.socialStreamImage.image = UIImage(named: streamImages[row])
            cell.socialStreamText.placeholder = streamLabels[row]
            cell.socialStreamText.text = streamtext[row]
            
        case 2:
            cell.socialStreamImage.image = UIImage(named: linkImage[row])
            cell.socialStreamText.placeholder = linkLabel[row]
            cell.socialStreamText.text = otherLink[row]
            
        default:
            cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! StreamsAndSocialsTableViewCell
            cell.selectionStyle = .none
            break
        }
        
        setTextFields(cell, row: row, section: section)
        
        return cell
    }
    
    //mark: media
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)        
        let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as! UIImage
        
        self.userImage.setImage(image, for: .normal)
        let proPic = image.jpegData(compressionQuality: 0.5)
        newUserImage = PFFileObject(name: "defaultProfile_ios.jpeg", data: proPic!)
        newUserImage?.saveInBackground()
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }
    
    //MARK: Data
    func loadUserInfoFromCloud(_ userId: String) {
        let query = PFQuery(className:"_User")
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                if let instagramHandle = user["instagramHandle"] as? String {
                    self.socialText.append(instagramHandle)
                    
                } else {
                    self.socialText.append("")
                }
                
                if let twitterHandle = user["twitterHandle"] as? String {
                    self.socialText.append(twitterHandle)
                    
                } else {
                    self.socialText.append("")
                }
                
                if let appleMusicLink = user["appleMusicLink"] as? String {
                    self.streamtext.append(appleMusicLink)
                    
                } else {
                    self.streamtext.append("")
                }
                
                if let soundCloudLink = user["soundCloudLink"] as? String {
                    self.streamtext.append(soundCloudLink)
                    
                } else {
                    self.streamtext.append("")
                }
                
                if let spotifyLink = user["spotifyLink"] as? String {
                    self.streamtext.append(spotifyLink)
                    
                } else {
                    self.streamtext.append("")
                }
                
                if let otherLink = user["otherLink"] as? String {
                    self.otherLink.append(otherLink)
                    
                } else {
                    self.otherLink.append("")
                }
                
                if let userImageFile = user["userImage"] as? PFFileObject {
                    self.userImage.kf.setImage(with: URL(string: userImageFile.url!), for: .normal)
                }
            
                //self.tableView.reloadData()
            }
            
            self.setUpTableView()
        }
    }
    
    func updateUserInfo() {
        self.startAnimating()
        
        let query = PFQuery(className:"_User")
        query.getObjectInBackground(withId: PFUser.current()!.objectId!) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                user["instagramHandle"] = self.instagramText.text!.lowercased()
                user["twitterHandle"] = self.twitterText.text!.lowercased()
                user["appleMusicLink"] = self.appleMusicText.text!.lowercased()
                user["soundCloudLink"] = self.soundcloudText.text!.lowercased()
                user["spotifyLink"] = self.spotifyText.text!.lowercased()
                user["otherLink"] = self.linkText.text!.lowercased()
                
                if let newUserImage = self.newUserImage {
                    user["userImage"] = newUserImage
                }
                
                user.saveEventually {
                    (success: Bool, error: Error?) in
                    self.stopAnimating()
                    if (success) {
                        self.uiElement.segueToView("Main", withIdentifier: "main", target: self)
                        
                    } else if let error = error {
                        UIElement().showAlert("Oops", message: error.localizedDescription, target: self)
                    }
                }
            }
        }
    }
    
    //Mark: TextField
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

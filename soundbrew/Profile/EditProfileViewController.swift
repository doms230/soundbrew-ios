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
    
    var artist: Artist?
    
    var newUserImage: PFFileObject?
    var userImage: UIImageView!
    var nameText: UITextField!
    var usernameText: UITextField!
    var websiteText: UITextField!
    var bioText: UITextField!
    var cityText: UITextField!

    var emailText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //loadUserInfoFromCloud(PFUser.current()!.objectId!)
        if artist != nil {
            setUpViews()
            setUpTableView()
            
        } else {
            //TODO: Dismiss this page
        }
    }
    
    func setUpViews() {
        self.title = "Edit Profile"
        
        let saveButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.didPressDoneButton(_:)))
        self.navigationItem.rightBarButtonItem = saveButton
    }
    
    //MARK: Button Actions
    @objc func didPressDoneButton(_ sender: UIBarButtonItem) {
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
    let editProfileImageReuse = "editProfileImageReuse"
    let editProfileInfoReuse = "editProfileInfoReuse"
    let editPrivateInfoReuse = "editPrivateInfoReuse"
    
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editProfileImageReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editProfileInfoReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editPrivateInfoReuse)
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .singleLine
        tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: ProfileTableViewCell!
                
        switch indexPath.section{
        case 0:
            cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileImageReuse) as? ProfileTableViewCell
            
            if let image = artist?.image {
                //cell.editProfileImage.kf.set
            }
            
            break
            
        case 1:
            cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileInfoReuse) as? ProfileTableViewCell
           /* if let name = artist?.name {
                cell.editNameText.text = name
            }
            
            cell.editUsernameText.text = artist!.username
            
            if let city = artist?.city {
                cell.editCityText.text = city
            }
            
            if let website = artist?.website {
                cell.editWebsiteText.text = website
            }
            
            if let bio = artist?.bio {
                cell.editBioText.text = bio
            }*/
            
            if let bio = artist?.bio {
                cell.editBioText.text = bio
            }
            
            break
            
        case 2:
            cell = self.tableView.dequeueReusableCell(withIdentifier: editPrivateInfoReuse) as? ProfileTableViewCell
            
            //cell.editEmailText.text = artist!.email
            
            break
            
        default:
            break
        }
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    //mark: media
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)        
        let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as! UIImage
        
        //self.userImage.setImage(image, for: .normal)
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
    /*func loadUserInfoFromCloud(_ userId: String) {
        let query = PFQuery(className:"_User")
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                let username = user["username"] as! String 
                let email = user["email"] as! String

                let artist = Artist(objectId: user.objectId!, name: nil, city: nil, image: nil, isVerified: nil, username: username, website: nil, bio: nil, email: email)
                if let userImageFile = user["userImage"] as? PFFileObject {
                    artist.image = userImageFile.url
                }
                
                if let name = user["artistName"] as? String {
                    artist.name = name
                }
                
                if let
                
                
            
                //self.tableView.reloadData()
            }
            
            self.setUpTableView()
        }
    }*/
    
    func updateUserInfo() {
        self.startAnimating()
        
        let query = PFQuery(className:"_User")
        query.getObjectInBackground(withId: PFUser.current()!.objectId!) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                //user["instagramHandle"] = self.instagramText.text!.lowercased()

                
                if let newUserImage = self.newUserImage {
                    user["userImage"] = newUserImage
                }
                
                user.saveEventually {
                    (success: Bool, error: Error?) in
                    self.stopAnimating()
                    if (success) {
                        //self.uiElement.segueToView("Main", withIdentifier: "main", target: self)
                        
                    } else if let error = error {
                        UIElement().showAlert("Oops", message: error.localizedDescription, target: self)
                    }
                }
            }
        }
    }
}

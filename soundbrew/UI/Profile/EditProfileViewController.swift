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

class EditProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ArtistDelegate {
    
    func newArtistInfo(_ value: Artist?) {
    }
    
    var artist: Artist?
    var artistDelegate: ArtistDelegate?
    var newProfileImageFile: PFFileObject?
    var profileImage: UIImageView!
    var nameText: UITextField!
    var usernameText: UITextField!
    var instagramText: UITextField!
    var twitterText: UITextField!
    var snapchatText: UITextField!
    var websiteText: UITextField!
    var bioLabel: UILabel!
    var cityText: UITextField!

    var emailText: UITextField!
    
    var editDetailType: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if artist != nil {
            setUpViews()
            setUpTableView()
            
            
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navigationController = segue.destination as! UINavigationController
        let viewController = navigationController.topViewController as! EditBioViewController
        viewController.bio = bioLabel.text
        viewController.artistDelegate = self
    }
    
    func setUpViews() {
        self.title = "Edit Profile"
        
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.didPressCancelButton(_:)))
        self.navigationItem.leftBarButtonItem = cancelButton
        
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.didPressDoneButton(_:)))
        self.navigationItem.rightBarButtonItem = doneButton
    }
    
    //MARK: Button Actions
    @objc func didPressCancelButton(_ sender: UIButton){
        self.dismiss(animated: true, completion: nil)
    }
    @objc func didPressDoneButton(_ sender: UIBarButtonItem) {
        if validateEmail() {
            updateUserInfo()
            
        } else {
            UIElement().showAlert("Oops", message: "Email is Required", target: self)
        }
    }
    
    //MARK: TableView
    let tableView = UITableView()
    let editProfileImageReuse = "editProfileImageReuse"
    let editProfileInfoReuse = "editProfileInfoReuse"
    let editPrivateInfoReuse = "editPrivateInfoReuse"
    let editBioReuse = "editBioReuse"
    let spaceReuse = "spaceReuse"
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editProfileImageReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editProfileInfoReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editPrivateInfoReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editBioReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: spaceReuse)
        tableView.separatorStyle = .singleLine
        tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 7
            
        } else if section == 3 {
            return 9
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: ProfileTableViewCell!
        let edgeInsets = UIEdgeInsets(top: 0, left: 85 + CGFloat(UIElement().leftOffset), bottom: 0, right: 0)
        
        switch indexPath.section{
        case 0:
            cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileImageReuse) as? ProfileTableViewCell
            cell.backgroundColor = Color().darkGray() 
            tableView.separatorStyle = .singleLine
            tableView.separatorInset = .zero
            cell.selectionStyle = .none
            
            profileImage = cell.profileImage
            if let image = artist?.image {
                cell.profileImage.kf.setImage(with: URL(string: image))
            }
            
            break
            
        case 1:
            cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileInfoReuse) as? ProfileTableViewCell
            cell.backgroundColor = .white
            cell.selectionStyle = .none
            tableView.separatorStyle = .singleLine
            tableView.separatorInset = edgeInsets
            
            var inputTitle: String!
            var inputText: String!
            
            switch indexPath.row {
            case 0:
                nameText = cell.editProfileInput
                inputTitle = "Name"
                if let name = artist?.name {
                    inputText = name
                }
                break
                
            case 1:
                usernameText = cell.editProfileInput
                inputTitle = "Username"
                inputText = artist!.username
                break
                
            case 2:
                cityText = cell.editProfileInput
                inputTitle = "City"
                if let city = artist?.city {
                    inputText = city
                }
                break
                
            case 3:
                instagramText = cell.editProfileInput
                inputTitle = "Instagram @"
                if let instagram = artist?.instagramUsername {
                    inputText = instagram
                }
                break
                
            case 4:
                twitterText = cell.editProfileInput
                inputTitle = "Twitter @"
                if let twitter = artist?.twitterUsername {
                    inputText = twitter
                }
                break
                
            case 5:
                snapchatText = cell.editProfileInput
                inputTitle = "Snapchat @"
                if let snapchat = artist?.snapchatUsername {
                    inputText = snapchat
                }
                break
                
            case 6:
                websiteText = cell.editProfileInput
                inputTitle = "Website"
                if let website = artist?.website {
                    inputText = website
                }
                
            default:
                break
            }
            
            //cell.editProfileInput.placeholder = inputTitle
            cell.editProfileTitle.text = inputTitle
            cell.editProfileInput.text = inputText
            break
            
        /*case 2:
            cell = self.tableView.dequeueReusableCell(withIdentifier: editBioReuse) as? ProfileTableViewCell
            cell.backgroundColor = .white
            cell.selectionStyle = .gray
            tableView.separatorStyle = .singleLine
            tableView.separatorInset = .zero

            bioLabel = cell.editBioText
            cell.editBioTitle.text = "Bio"
            if let bio = artist?.bio {
                cell.editBioText.text = bio
            }
            break*/
            
        case 2:
            cell = self.tableView.dequeueReusableCell(withIdentifier: editPrivateInfoReuse) as? ProfileTableViewCell
            cell.backgroundColor = .white
            cell.selectionStyle = .none
            tableView.separatorStyle = .singleLine
            tableView.separatorInset = .zero
            
            //cell.editProfileInput.placeholder = "Email"
            cell.editProfileTitle.text = "Email"
            emailText = cell.editProfileInput
            cell.editProfileInput.text = artist!.email
            break
            
        case 3:
            cell = self.tableView.dequeueReusableCell(withIdentifier: spaceReuse) as? ProfileTableViewCell
            cell.backgroundColor = .white
            cell.selectionStyle = .none
            tableView.separatorStyle = .none
            break
            
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            showChangeProfilePhotoPicker()
            
        } else if indexPath.section == 2 {
            tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
            self.performSegue(withIdentifier: "showDetailEditInfo", sender: self)
        }
    }
    
    //mark: media
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)        
        let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as! UIImage
        
        profileImage.image = image 
        
        let chosenProfileImage = image.jpegData(compressionQuality: 0.5)
        newProfileImageFile = PFFileObject(name: "profile_ios.jpeg", data: chosenProfileImage!)
        newProfileImageFile?.saveInBackground()
        
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
    
    func showChangeProfilePhotoPicker() {
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
    
    //MARK: bio
    func changeBio(_ value: String?) {
        if let newBioText = value {
            bioLabel.text = newBioText
        }
    }
    
    //MARK: Data
    func updateUserInfo() {
        self.startAnimating()
        
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: PFUser.current()!.objectId!) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                user["artistName"] = self.nameText.text
                
                if self.usernameText.text != self.artist?.username {
                    user["username"] = self.usernameText.text!.lowercased()
                }
                
                user["city"] = self.cityText.text
                
                var igText = self.instagramText.text
                if igText!.starts(with: "@") {
                    igText?.removeFirst()
                }
                user["instagramHandle"] = igText
                user["twitterHandle"] = self.twitterText.text
                user["snapchatHandle"] = self.snapchatText.text!
                user["otherLink"] = self.websiteText.text
                //user["bio"] = self.bioLabel.text
                user["email"] = self.emailText.text
                
                if let newUserImage = self.newProfileImageFile {
                    user["userImage"] = newUserImage
                }
                
                user.saveEventually {
                    (success: Bool, error: Error?) in
                    self.stopAnimating()
                    if (success) {
                        if let artistDelegate = self.artistDelegate {
                            let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: user["username"] as? String, website: nil, bio: nil, email: user["email"] as? String, instagramUsername: nil, twitterUsername: nil, snapchatUsername: nil, isFollowedByCurrentUser: nil)
                            
                            if let name =  user["artistName"] as? String {
                                artist.name = name
                            }
                            
                            if let city = user["city"] as? String {
                                artist.city = city
                            }
                            
                            if let instagramUsername = user["instagramHandle"] as? String {
                                artist.instagramUsername = instagramUsername
                            }
                            
                            if let twitterUsername = user["twitterHandle"] as? String {
                                artist.twitterUsername = twitterUsername
                            }
                            
                            if let snapchatUsername = user["snapchatHandle"] as? String {
                                artist.snapchatUsername = snapchatUsername
                            }
                            
                            if let website = user["otherLink"] as? String {
                                artist.website = website
                            }
                            
                            if let bio = user["bio"] as? String {
                                artist.bio = bio
                            }
                            
                            if let profileImage = user["userImage"] as? PFFileObject {
                                artist.image = profileImage.url
                            }
                        
                            artistDelegate.newArtistInfo(artist)
                        }
                        self.dismiss(animated: true, completion: nil)
                        
                    } else if let error = error {
                        UIElement().showAlert("Oops", message: error.localizedDescription, target: self)
                    }
                }
            }
        }
    }
    
    func validateEmail() -> Bool {
        let emailString : NSString = emailText.text! as NSString
        if emailText.text!.isEmpty || !emailString.contains("@") || !emailString.contains(".") {
            emailText.attributedPlaceholder = NSAttributedString(string: "Valid email required",
                                                                 attributes:[NSAttributedString.Key.foregroundColor: UIColor.red])
            emailText.text = ""
            return false
        }
        
        return true
    }
}

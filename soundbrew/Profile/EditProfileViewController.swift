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

class EditProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ArtistDelegate, TagDelegate {
    
    let uiElement = UIElement()
    let color = Color()
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

    var emailText: UITextField!
    var shouldUpdateEmail = false
    
    var editDetailType: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        
        setUpViews()
        
        if let CurrentArtist = Customer.shared.artist {
            self.artist = CurrentArtist
            self.setUpTableView()
        } else {
            self.uiElement.goBackToPreviousViewController(self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navigationController = segue.destination as! UINavigationController
        if segue.identifier == "showTags" {
            let viewController: ChooseTagsViewController = navigationController.topViewController as! ChooseTagsViewController
            viewController.tagDelegate = self
            viewController.tagType = "city"
            
        } else {
            let viewController = navigationController.topViewController as! EditBioViewController
            viewController.bio = self.artist!.bio
            viewController.artistDelegate = self
        }
    }
    
    func setUpViews() {        
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.didPressDoneButton(_:)))
        self.navigationItem.rightBarButtonItem = doneButton
    }
    
    //MARK: Button Actions
    @objc func didPressCancelButton(_ sender: UIButton){
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func didPressDoneButton(_ sender: UIBarButtonItem) {
        usernameText.text = self.uiElement.cleanUpText(usernameText.text!)
        emailText.text = self.uiElement.cleanUpText(emailText.text!)
        websiteText.text = self.uiElement.cleanUpText(websiteText.text!)
        
        if emailText.text != self.artist?.email {
            shouldUpdateEmail = true
        }
        
        if validateEmail() && validateUsername() && validateWebsite()  {
            updateUserInfo()
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
        tableView.backgroundColor = color.black()
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 3
            
        } else if section == 5 {
            return 9
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: ProfileTableViewCell!
        
        switch indexPath.section{
        case 0:
            cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileImageReuse) as? ProfileTableViewCell
            cell.backgroundColor = Color().darkGray() 
          //  tableView.separatorStyle = .singleLine
            tableView.separatorInset = .zero
            cell.selectionStyle = .none
           // cell.backgroundColor = color.black()
            
            profileImage = cell.profileImage
            if let image = artist?.image {
                cell.profileImage.kf.setImage(with: URL(string: image))
            }
            
            break
            
        case 1:
            cell = profileInfo(indexPath, tableView: tableView)
            break
            
        case 2:
            cell = cityCell(indexPath, tableView: tableView)
            
        case 3:
            cell = bioCell(indexPath, tableView: tableView)
            break
            
        case 4:
            cell = self.tableView.dequeueReusableCell(withIdentifier: editPrivateInfoReuse) as? ProfileTableViewCell
            //cell.backgroundColor = .white
            cell.selectionStyle = .none
            //tableView.separatorStyle = .singleLine
            tableView.separatorInset = .zero
            
            cell.editProfileTitle.text = "Email"
            emailText = cell.editProfileInput
            if let email = artist?.email {
                cell.editProfileInput.text = email
                
            } else {
                cell.editProfileInput.text = PFUser.current()?.email
                artist?.email = PFUser.current()?.email
            }
            break
            
        case 5:
            cell = self.tableView.dequeueReusableCell(withIdentifier: spaceReuse) as? ProfileTableViewCell
            //cell.backgroundColor = color.black()
            cell.selectionStyle = .none
            //tableView.separatorStyle = .none
            break
            
        default:
            break
        }
        cell.backgroundColor = color.black()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            showChangeProfilePhotoPicker()
            break
            
        case 2:
            tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
            self.performSegue(withIdentifier: "showTags", sender: self)
            break
            
        case 3:
            tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
            self.performSegue(withIdentifier: "showEditBio", sender: self)
            break
            
        default:
            break
        }
    }
    
    func profileInfo(_ indexPath: IndexPath, tableView: UITableView) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileInfoReuse) as! ProfileTableViewCell
        let edgeInsets = UIEdgeInsets(top: 0, left: 85 + CGFloat(UIElement().leftOffset), bottom: 0, right: 0)
        cell.backgroundColor = .white
        cell.selectionStyle = .none
        //tableView.separatorStyle = .singleLine
        tableView.separatorInset = edgeInsets
        
        var inputTitle: String!
        var inputText: String!
        
        switch indexPath.row {
        case 0:
            cell.editProfileInput.keyboardType = .default
            nameText = cell.editProfileInput
            inputTitle = "Name"
            if let name = artist?.name {
                inputText = name
            }
            break
            
        case 1:
            usernameText = cell.editProfileInput
            inputTitle = "Username"
            if let username = artist?.username {
                inputText = username
            } else {
                self.uiElement.showTextFieldErrorMessage(self.usernameText, text: "Username is required.")
            }
            
            break
            
        case 2:
            cell.editProfileInput.keyboardType = .URL
            websiteText = cell.editProfileInput
            inputTitle = "Website"
            if let website = artist?.website {
                inputText = website
            }
            
        case 4:
            break
            
        default:
            break
        }
        
        cell.editProfileTitle.text = inputTitle
        cell.editProfileInput.text = inputText
        
        return cell
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
    
    //MARK: city
    func cityCell(_ indexpath: IndexPath, tableView: UITableView) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: editBioReuse) as! ProfileTableViewCell
        cell.backgroundColor = .white
        cell.selectionStyle = .gray
        //tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero
        
        cell.editBioTitle.text = "City"
        if let city = artist?.city {
            if city.isEmpty {
                cell.editBioText.text = "Add City"
                
            } else {
                cell.editBioText.text = city
            }
        } else {
            cell.editBioText.text = "Add City"
        }
        
        return cell
    }
    
    func receivedTags(_ chosenTags: Array<Tag>?) {
        if let tag = chosenTags {
            artist?.city = tag[0].name
        }
        self.tableView.reloadData()
    }
    
    //MARK: bio
    func bioCell(_ indexpath: IndexPath, tableView: UITableView) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: editBioReuse) as! ProfileTableViewCell
        cell.backgroundColor = .white
        cell.selectionStyle = .gray
        //tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero
        
        cell.editBioTitle.text = "Bio"
        if let bio = artist?.bio {
            if bio.isEmpty {
                cell.editBioText.text = "Add Bio"
            } else {
                cell.editBioText.text = bio
            }
        } else {
            cell.editBioText.text = "Add Bio"
        }
        
        return cell
    }
    
    func changeBio(_ value: String?) {
        if let newBioText = value {
            if newBioText != "Add Bio" {
                artist!.bio = newBioText
                self.tableView.reloadData()
            }
        }
    }
    
    //MARK: Data
    func updateUserInfo() {
        self.startAnimating()
        let customer = Customer.shared
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: PFUser.current()!.objectId!) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                user["artistName"] = self.nameText.text
                
                if let username = self.artist?.username {
                    if self.usernameText.text != username {
                        self.usernameText.text = self.uiElement.cleanUpText(self.usernameText.text!)
                        user["username"] = self.usernameText.text!
                    }
                }
                
                if let city = self.artist?.city {
                    user["city"] = city
                }
                
                user["website"] = self.websiteText.text
                
                if let bio = self.artist?.bio {
                    user["bio"] = bio
                }
                
                if self.shouldUpdateEmail {
                    user["email"] = self.emailText.text
                }
                
                if let newUserImage = self.newProfileImageFile {
                    user["userImage"] = newUserImage
                }
                
                user.saveEventually {
                    (success: Bool, error: Error?) in
                    self.stopAnimating()
                    if (success) {
                        if let artistDelegate = self.artistDelegate {
                            customer.artist?.username = (user["username"] as! String)
                            customer.artist?.email = (user["email"] as! String)
                            
                            if let followerCount = user["followerCount"] as? Int {
                                customer.artist?.followerCount = followerCount
                            }
                            
                            if let name =  user["artistName"] as? String {
                                customer.artist?.name = name
                            }
                            
                            if let city = user["city"] as? String {
                                customer.artist?.city = city
                            }
                            
                            if let website = user["website"] as? String {
                                customer.artist?.website = website
                            }
                            
                            if let bio = user["bio"] as? String {
                                customer.artist?.bio = bio
                            }
                            
                            if let profileImage = user["userImage"] as? PFFileObject {
                                customer.artist?.image = profileImage.url
                            }
                        
                            artistDelegate.newArtistInfo(customer.artist)
                            
                            customer.update()
                        }
                        
                        self.uiElement.goBackToPreviousViewController(self)
                        
                    } else if let error = error {
                        UIElement().showAlert("Oops", message: error.localizedDescription, target: self)
                    }
                }
            }
        }
    }
    
    func validateEmail() -> Bool {
        if emailText.text!.isEmpty || !emailText.text!.contains("@") || !emailText.text!.contains(".") {
            self.uiElement.showTextFieldErrorMessage(self.emailText, text: "Valid email required.")
            return false
        }
        
        return true
    }
    
    func validateUsername() -> Bool {
        if usernameText.text!.contains("@") {
            self.uiElement.showTextFieldErrorMessage(self.usernameText, text: "Invalid username.")
            return false
            
        } else if usernameText.text!.isEmpty {
            self.uiElement.showTextFieldErrorMessage(self.usernameText, text: "Username is required.")
            return false
        }
        
        return true
    }
    
    func validateWebsite() -> Bool {
        if !websiteText.text!.isEmpty {
            if !websiteText.text!.starts(with: "https") || !websiteText.text!.starts(with: "http") {
                websiteText.text = "https://\(websiteText.text!)"
            }
            
            if !UIApplication.shared.canOpenURL(URL(string: websiteText.text!)!) {
                self.uiElement.showTextFieldErrorMessage(self.websiteText, text: "Invalid url.")
                return false
            }
        }
        
        return true
    }
}

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

class EditProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate  {
    
    var artist: Artist?
    
    var newProfileImageFile: PFFileObject?
    var profileImage: UIImageView!
    var nameText: UITextField!
    var usernameText: UITextField!
    var websiteText: UITextField!
    var bioText: String!
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
        let viewController = segue.destination as! DetailEditInfoViewController
        if editDetailType == "email" {
            viewController.email = emailText.text!
            
        } else {
            viewController.bio = bioText
        }
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
        updateUserInfo()
    }
    
    //MARK: TableView
    let tableView = UITableView()
    let editProfileImageReuse = "editProfileImageReuse"
    let editProfileInfoReuse = "editProfileInfoReuse"
    let editPrivateInfoReuse = "editPrivateInfoReuse"
    let editBioReuse = "editBioReuse"
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editProfileImageReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editProfileInfoReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editPrivateInfoReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editBioReuse)
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .singleLine
        tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 4
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: ProfileTableViewCell!
                
        switch indexPath.section{
        case 0:
            cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileImageReuse) as? ProfileTableViewCell
            cell.backgroundColor = Color().uicolorFromHex(0xe8e6df)
            tableView.separatorStyle = .singleLine
            cell.selectionStyle = .none
            
            profileImage = cell.editProfileImage
            if let image = artist?.image {
                cell.editProfileImage.kf.setImage(with: URL(string: image))
            }
            
            break
            
        case 1:
            cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileInfoReuse) as? ProfileTableViewCell
            cell.backgroundColor = .white
            cell.selectionStyle = .none
            tableView.separatorStyle = .none
            
            var inputTitle: String!
            var inputText: String!
            
            switch indexPath.row {
            case 0:
                nameText = cell.editNameText
                inputTitle = "Name"
                if let name = artist?.name {
                    inputText = name
                }
                break
                
            case 1:
                usernameText = cell.editUsernameText
                inputTitle = "Username"
                inputText = artist!.username
                break
                
            case 2:
                cityText = cell.editCityText
                inputTitle = "City"
                if let city = artist?.city {
                    inputText = city
                }
                break
                
            case 3:
                websiteText = cell.editWebsiteText
                inputTitle = "Website"
                if let website = artist?.website {
                    inputText = website
                }
                break
                
            /*case 4:
                inputTitle = "bio"
                if let bio = artist?.bio {
                    inputText = bio
                }
                break*/
                
            default:
                break
            }
            
            cell.editNameText.placeholder = inputTitle
            cell.editNameTitle.text = inputTitle
            cell.editNameText.text = inputText
            
            /*cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileInfoReuse) as? ProfileTableViewCell
            cell.backgroundColor = .white
            
            nameText = cell.editNameText
            if let name = artist?.name {
                cell.editNameText.text = name
            }
            
            usernameText = cell.editUsernameText
            cell.editUsernameText.text = artist!.username
            
            cityText = cell.editCityText
            if let city = artist?.city {
                cell.editCityText.text = city
            }
            
            websiteText = cell.editWebsiteText
            if let website = artist?.website {
                cell.editWebsiteText.text = website
            }
            
            if let bio = artist?.bio {
                cell.editBioText.text = bio
            }*/
            
            break
            
        case 2:
            cell = self.tableView.dequeueReusableCell(withIdentifier: editBioReuse) as? ProfileTableViewCell
            cell.backgroundColor = .white
            cell.selectionStyle = .gray
            tableView.separatorStyle = .singleLine
            
            if let bio = artist?.bio {
                if bio.isEmpty {
                    cell.editBioText.text = "Add Bio"
                    
                } else {
                    cell.editBioText.text = bio
                     bioText = bio
                }
            }
            break
            
        case 3:
            cell = self.tableView.dequeueReusableCell(withIdentifier: editPrivateInfoReuse) as? ProfileTableViewCell
            cell.backgroundColor = .white
            cell.selectionStyle = .none
            tableView.separatorStyle = .none
            
            emailText = cell.editEmailText
            cell.editEmailText.text = artist!.email
            cell.editEmailText.tag = 1
            
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
            editDetailType = "bio"
            /*let modal = DetailEditInfoViewController()
             modal.modalPresentationStyle = .fullScreen
             modal.bio = bioText
             present(modal, animated: true, completion: nil)*/
            tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
            self.performSegue(withIdentifier: "showDetailEditInfo", sender: self)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == 1 {
            //self.resignFirstResponder()
            editDetailType = "email"
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
    
    //MARK: Data
    func updateUserInfo() {
        self.startAnimating()
        
        let query = PFQuery(className:"_User")
        query.getObjectInBackground(withId: PFUser.current()!.objectId!) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                //user["instagramHandle"] = self.instagramText.text!.lowercased()

                
                if let newUserImage = self.newProfileImageFile {
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

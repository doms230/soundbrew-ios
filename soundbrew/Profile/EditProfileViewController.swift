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
import Kingfisher
import CropViewController
import Alamofire
import SwiftyJSON

class EditProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ArtistDelegate, TagDelegate, CropViewControllerDelegate {
    
    let uiElement = UIElement()
    let color = Color()
    func receivedArtist(_ value: Artist?) {
    }
    
    var artist: Artist?
    var artistDelegate: ArtistDelegate?
    var newProfileImageFile: PFFileObject?
    var profileImage: UIImageView!
    var nameText: UITextField!
    var usernameText: UITextField!
    var websiteText: UITextField!

    var emailText: UITextField!
    var shouldUpdateEmail = false
    
    var isOnboarding = false
    
    var tagType: String!
    var topView: (UIButton, UIButton, UIView, UIActivityIndicatorView)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        if let currentArtist = Customer.shared.artist {
            self.artist = currentArtist
            topView = self.uiElement.addSubViewControllerTopView(self, action: #selector(self.didPressTopViewButton(_:)), doneButtonTitle: "Done", title: "Edit Profile")
            self.setUpTableView(topView.2)
            
        } else {
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    var didPressDoneButton = false
    @objc func didPressTopViewButton(_ sender: UIButton) {
        if sender.tag == 0 {
            self.dismiss(animated: true, completion: {() in
                if let artistDelegate = self.artistDelegate {
                    //if user is onboarding, so received artist is called and they are taken to soundsViewController
                    artistDelegate.receivedArtist(nil)
                }
            })
            
        } else {
            usernameText.text = self.uiElement.cleanUpText(usernameText.text!, shouldLowercaseText: true)
            emailText.text = self.uiElement.cleanUpText(emailText.text!, shouldLowercaseText: true)
            websiteText.text = self.uiElement.cleanUpText(websiteText.text!, shouldLowercaseText: true)
            
            if emailText.text != self.artist?.email {
                shouldUpdateEmail = true
            }
            
            if validateEmail() && validateUsername() && validateWebsite() {
                didPressDoneButton = true
                if didFinishProcessingImage {
                    updateUserInfo()
                }
            }
        }
    }
    
    //MARK: TableView
    let tableView = UITableView()
    let editProfileImageReuse = "editProfileImageReuse"
    let editProfileInfoReuse = "editProfileInfoReuse"
    let editPrivateInfoReuse = "editPrivateInfoReuse"
    let privateInfoTitleReuse = "privateInfoTitleReuse"
    let editBioReuse = "editBioReuse"
    let spaceReuse = "spaceReuse"
    func setUpTableView(_ dividerLine: UIView) {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editProfileImageReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editProfileInfoReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editPrivateInfoReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: privateInfoTitleReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editBioReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: spaceReuse)
        tableView.backgroundColor = color.black()
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(dividerLine.snp.bottom).offset(uiElement.topOffset)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 9
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 3
        }
        
        if section == 6 {
            return 9
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: ProfileTableViewCell!
        
        switch indexPath.section{
        case 0:
            cell = profileImageCell(tableView, indexPath: indexPath)
            break
            
        case 1:
            cell = profileInfo(tableView, indexPath: indexPath)
            break
            
        case 2:
            cell = cityCell(tableView, indexPath: indexPath)
            
        case 3:
            cell = bioCell(tableView, indexPath: indexPath)
            break
            
        case 4:
            cell = self.tableView.dequeueReusableCell(withIdentifier: privateInfoTitleReuse) as? ProfileTableViewCell
            cell.selectionStyle = .none
            break
            
        case 5:
            cell = privateInfoCell(tableView, indexPath: indexPath)
            break
            
        case 6:
            cell = self.tableView.dequeueReusableCell(withIdentifier: spaceReuse) as? ProfileTableViewCell
            cell.selectionStyle = .none
            
            break
            
        default:
            cell = self.tableView.dequeueReusableCell(withIdentifier: spaceReuse) as? ProfileTableViewCell
            cell.selectionStyle = .none
            break
        }
        cell.backgroundColor = color.black()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
        artist?.website = websiteText.text
        artist?.email = emailText.text?.lowercased()
        artist?.username = usernameText.text
        artist?.name = nameText.text
        
        switch indexPath.section {
        case 0:
            showChangeProfilePhotoPicker()
            break
            
        case 2:
            let modal = ChooseTagsViewController()
            modal.tagDelegate = self
            modal.tagType = "city"
            self.present(modal, animated: true, completion: nil)
            break
            
        case 3:
            let modal = EditBioViewController()
            modal.bioTitle = "Bio"
            modal.artistDelegate = self
            modal.bio = self.artist!.bio
            self.present(modal, animated: true, completion: nil)
            break
            
        default:
            break
        }
    }
    
    func profileInfo(_ tableView: UITableView, indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileInfoReuse) as! ProfileTableViewCell
        let edgeInsets = UIEdgeInsets(top: 0, left: 85 + CGFloat(UIElement().leftOffset), bottom: 0, right: 0)
        cell.backgroundColor = .white
        cell.selectionStyle = .none
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
            let localizedusername = NSLocalizedString("username", comment: "")
            inputTitle = localizedusername
            if let username = artist?.username {
                inputText = username
            } else {
                let localizedusernameIsRequired = NSLocalizedString("usernameIsRequired", comment: "")
                self.uiElement.showTextFieldErrorMessage(self.usernameText, text: localizedusernameIsRequired)
            }
            break
            
        case 2:
            cell.editProfileInput.keyboardType = .URL
            websiteText = cell.editProfileInput
            let localizedWebsite = NSLocalizedString("website", comment: "")
            inputTitle = localizedWebsite
            if let website = artist?.website {
                inputText = website
            }
            break
            
        default:
            break
        }
        
        cell.editProfileTitle.text = inputTitle
        cell.editProfileInput.text = inputText
        
        return cell
    }
    
    func privateInfoCell(_ tableView: UITableView, indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: editPrivateInfoReuse) as! ProfileTableViewCell
        cell.selectionStyle = .none
        tableView.separatorInset = .zero
        
        var indexTitle: String!
        
        switch indexPath.row {
        case 0:
            indexTitle = "Email"
            emailText = cell.editProfileInput
            cell.editProfileInput.isEnabled = true
            cell.editProfileInput.textColor = .white
            if let email = artist?.email {
                cell.editProfileInput.text = email
                
            } else {
                cell.editProfileInput.text = PFUser.current()?.email
                artist?.email = PFUser.current()?.email
            }
            break
            
        default:
            break
        }
        
        cell.editProfileTitle.text = indexTitle

        return cell
    }
    
    //mark: media
    func profileImageCell(_ tableView: UITableView, indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileImageReuse) as! ProfileTableViewCell
        cell.backgroundColor = Color().darkGray()
        tableView.separatorInset = .zero
        cell.selectionStyle = .none
        
        profileImage = cell.profileImage
        if let image = artist?.image {
            cell.profileImage.kf.setImage(with: URL(string: image))
        }
        return cell
    }
    
    var didFinishProcessingImage = true
    func showChangeProfilePhotoPicker() {
        didFinishProcessingImage = false
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        
        let alertController = UIAlertController (title: nil, message: nil, preferredStyle: .actionSheet)
        
        let localizedCamera = NSLocalizedString("camera", comment: "")
        let cameraAction = UIAlertAction(title: localizedCamera, style: .default) { (_) -> Void in
            imagePicker.sourceType = .camera
            self.present(imagePicker, animated: true, completion: nil)
        }
        alertController.addAction(cameraAction)
        
        let localizedPhotoLibrary = NSLocalizedString("photoLibrary", comment: "")
        let photolibraryAction = UIAlertAction(title: localizedPhotoLibrary, style: .default) { (_) -> Void in
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
        alertController.addAction(photolibraryAction)
        
        let localizedCancel = NSLocalizedString("cancel", comment: "")
        let cancelAction = UIAlertAction(title: localizedCancel, style: .cancel) { (_) -> Void in
            self.didFinishProcessingImage = true
        }
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        var selectedImage: UIImage?
        if let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            selectedImage = image
        }
        
        if let image = selectedImage {
            self.presentImageCropViewController(image, picker: picker)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        didFinishProcessingImage = true
        picker.dismiss(animated: true, completion: nil)
    }
    
    func presentImageCropViewController(_ image: UIImage, picker: UIImagePickerController) {
        let cropViewController = CropViewController(croppingStyle: .default, image: image)
        cropViewController.aspectRatioLockEnabled = true
        cropViewController.aspectRatioPickerButtonHidden = true
        cropViewController.aspectRatioPreset = .presetSquare
        cropViewController.resetAspectRatioEnabled = false
        cropViewController.delegate = self
        picker.present(cropViewController, animated: false, completion: nil)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        profileImage.image = image
        self.dismiss(animated: false, completion: nil)
        
        let chosenProfileImage = image.jpegData(compressionQuality: 0.5)
        newProfileImageFile = PFFileObject(name: "profile_ios.jpeg", data: chosenProfileImage!)
        newProfileImageFile?.saveInBackground {
          (success: Bool, error: Error?) in
          if (success) {
            self.didFinishProcessingImage = true
            if self.didPressDoneButton {
                self.updateUserInfo()
            }
          } else if let error = error {
            self.uiElement.showAlert("Issue with saving Image", message: error.localizedDescription, target: self)
          }
        }
    }
    
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        if cancelled {
            cropViewController.dismiss(animated: true, completion: nil)
            self.dismiss(animated: false, completion: nil)
        }
    }
        
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }
    
    //MARK: city
    func cityCell(_ tableView: UITableView, indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: editBioReuse) as! ProfileTableViewCell
        cell.backgroundColor = .white
        cell.selectionStyle = .gray
        tableView.separatorInset = .zero
        
        let localizedCity = NSLocalizedString("city", comment: "")
        let localizedAddCity = NSLocalizedString("addCity", comment: "")
        cell.editBioTitle.text = localizedCity
        if let city = artist?.city {
            if city.isEmpty {
                cell.editBioText.text = localizedAddCity
                
            } else {
                cell.editBioText.text = city
            }
        } else {
            cell.editBioText.text = localizedAddCity
        }
        
        return cell
    }
    
    //MARK: Tag
    func receivedTags(_ chosenTags: Array<Tag>?) {
        if let tagArray = chosenTags {
            let tag = tagArray[0]
            artist?.city = tag.name
             self.tableView.reloadData()
        }
    }
    
    //MARK: bio
    func bioCell(_ tableView: UITableView, indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: editBioReuse) as! ProfileTableViewCell
        cell.backgroundColor = .white
        cell.selectionStyle = .gray
        tableView.separatorInset = .zero
        
        let localizedAdd = NSLocalizedString("add", comment: "")
        cell.editBioTitle.text = "Bio"
        if let bio = artist?.bio {
            if bio.isEmpty {
                cell.editBioText.text = "\(localizedAdd) Bio"
            } else {
                cell.editBioText.text = bio
            }
        } else {
            cell.editBioText.text = "\(localizedAdd) Bio"
        }
        
        return cell
    }
    
    func changeBio(_ value: String?) {
        if let newBioText = value {
            artist!.bio = newBioText
        } else {
            artist!.bio = nil
        }
        self.tableView.reloadData()
    }
    
    //MARK: Data
    func updateUserInfo() {
        self.uiElement.shouldAnimateActivitySpinner(true, buttonGroup: (topView.1, topView.3))
        let customer = Customer.shared
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: PFUser.current()!.objectId!) {
            (user: PFObject?, error: Error?) -> Void in
            self.uiElement.shouldAnimateActivitySpinner(false, buttonGroup: (self.topView.1, self.topView.3))
            if let user = user {
                user["artistName"] = self.nameText.text
                
                if let username = self.artist?.username {
                    if self.usernameText.text != username {
                        self.usernameText.text = self.uiElement.cleanUpText(self.usernameText.text!, shouldLowercaseText: true)
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
                    if (success) {
                        if let currentUsername = customer.artist?.username, let newUsername = self.usernameText.text, let account = customer.artist?.account {
                            if currentUsername != newUsername {
                                account.updateProductName(newUsername)
                                account.updateAccountURL(newUsername)
                            }
                        }
                        
                        if let currentEmail = customer.artist?.email, let newEmail = self.emailText.text, let account = customer.artist?.account {
                            if currentEmail != newEmail {
                                account.updateAccountEmail(newEmail)
                            }
                        }
                        
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
                        
                        customer.update()
                        
                        DispatchQueue.main.async {
                            if self.isOnboarding {
                                self.uiElement.newRootView("Main", withIdentifier: "tabBar")
                            } else {
                                //used to let give profileViewController updated profile
                                self.dismiss(animated: true, completion: {() in
                                    if let artistDelegate = self.artistDelegate {
                                        artistDelegate.receivedArtist(customer.artist)
                                    }
                                })
                            }
                        }
                        
                    } else if let error = error {
                        UIElement().showAlert("Error", message: error.localizedDescription, target: self)
                    }
                }
            }
        }
    }
    
    func validateEmail() -> Bool {
        let localizedValidEmailRequired = NSLocalizedString("validEmailRequired", comment: "")
        if emailText.text!.isEmpty || !emailText.text!.contains("@") || !emailText.text!.contains(".") {
            self.uiElement.showTextFieldErrorMessage(self.emailText, text: localizedValidEmailRequired)
            return false
        }
        
        return true
    }
    
    func validateUsername() -> Bool {
        let localizedInvalidUsername = NSLocalizedString("invalidUsername", comment: "")
        let localizedUsernameRequired = NSLocalizedString("usernameRequired", comment: "")
        if usernameText.text!.contains("@") {
            self.uiElement.showTextFieldErrorMessage(self.usernameText, text: localizedInvalidUsername)
            return false
            
        } else if usernameText.text!.isEmpty {
            self.uiElement.showTextFieldErrorMessage(self.usernameText, text: localizedUsernameRequired)
            return false
        }
        
        return true
    }
    
    func validateWebsite() -> Bool {
        var websiteText = ""
        if let text = self.websiteText.text {
            websiteText = text
            if !text.isEmpty {
                if !text.starts(with: "https") && !text.starts(with: "http") {
                    websiteText = "https://\(text)"
                    self.websiteText.text = websiteText
                }
                
                if let url = URL(string: websiteText), !UIApplication.shared.canOpenURL(url) {
                    let localizedInvalidURL = NSLocalizedString("invalidURL", comment: "")
                    self.uiElement.showTextFieldErrorMessage(self.websiteText, text: localizedInvalidURL)
                    return false
                }
            }
        }
        
        return true
    }
}

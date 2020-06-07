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
import CropViewController
import Alamofire
import SwiftyJSON

class EditProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ArtistDelegate, TagDelegate, CropViewControllerDelegate {
    
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
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationViews()
        setupView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? UINavigationController {
            if segue.identifier == "showTags" {
                let viewController: ChooseTagsViewController = navigationController.topViewController as! ChooseTagsViewController
                viewController.tagDelegate = self
                viewController.tagType = tagType
                
            } else if segue.identifier == "showEditBio" {
                let viewController = navigationController.topViewController as! EditBioViewController
                viewController.bio = self.artist!.bio
                viewController.artistDelegate = self
                viewController.title = "Edit Bio"
            }
            
        } else {
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
        }
    }
    
    func setupNavigationViews() {
        let localizedDone = NSLocalizedString("done", comment: "")
        let doneButton = UIBarButtonItem(title: localizedDone, style: .plain, target: self, action: #selector(self.didPressDoneButton(_:)))
        self.navigationItem.rightBarButtonItem = doneButton
        
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
    }
    
    func setupView() {
        if let currentArtist = Customer.shared.artist {
            self.artist = currentArtist
             self.setUpTableView()
            if let accountId = currentArtist.accountId {
                self.retreiveAccountIfo(accountId)
            }
            
        } else {
            self.uiElement.goBackToPreviousViewController(self)
        }
    }
    
    //MARK: Button Actions
    @objc func didPressCancelButton(_ sender: UIButton){
        self.dismiss(animated: true, completion: nil)
    }
    
    var didPressDoneButton = false
    @objc func didPressDoneButton(_ sender: Any) {
        self.startAnimating()
        
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
            
        } else {
            self.stopAnimating()
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
    func setUpTableView() {
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
        tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 9
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 3
        }
        
        if section == 6 && self.artist?.accountId != nil {
            return 3
        }
        
        if section == 7 {
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
            cell = subScell(indexPath, tableView: tableView)
            break
            
        case 5:
            cell = self.tableView.dequeueReusableCell(withIdentifier: privateInfoTitleReuse) as? ProfileTableViewCell
            cell.selectionStyle = .none
            break
            
        case 6:
            cell = privateInfoCell(tableView, indexPath: indexPath)
            break
            
        case 7:
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
        artist?.website = websiteText.text
        artist?.email = emailText.text?.lowercased()
        
        switch indexPath.section {
        case 0:
            showChangeProfilePhotoPicker()
            break
            
        case 2:
            tagType = "city"
            tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
            self.performSegue(withIdentifier: "showTags", sender: self)
            break
            
        case 3:
            tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
            self.performSegue(withIdentifier: "showEditBio", sender: self)
            break
            
        case 4:
            tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
            if let artist = self.artist, let accountId = artist.accountId, !accountId.isEmpty {
                //TODO: show option to change subscription price.. Have to have something where users are sent an email alerting about subscription price change.
            } else {
                let alertController = UIAlertController (title: "Earn From Your Followers", message: "Release exclusive sounds to followers who subscribe. You can choose how much you charge per month and which sounds are exclusive.", preferredStyle: .actionSheet)
                
                let getStartedAction = UIAlertAction(title: "Get Started", style: .default) { (_) -> Void in
                    self.tagType = "country"
                    self.performSegue(withIdentifier: "showTags", sender: self)
                }
                alertController.addAction(getStartedAction)
                
                let cancelAction = UIAlertAction(title: "Later", style: .default) { (_) -> Void in
                    self.didFinishProcessingImage = true
                }
                alertController.addAction(cancelAction)
                
                present(alertController, animated: true, completion: nil)
            }
            break
            
        case 6:
            if indexPath.row == 1 {
                //TODO: add bank logic
            } else if indexPath.row == 2{
                if let requiresAttentionItems = self.requiresAttentionItems, requiresAttentionItems != 0, let accountId = self.artist?.accountId {
                    let modal = AccountWebViewController()
                    modal.accountId = accountId
                    self.present(modal, animated: true, completion: nil)
                } else {
                    self.uiElement.showAlert("All Good", message: "You're account is in good standing!", target: self)
                }
            }
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
            
        case 1:
            indexTitle = "Payout Bank"
            cell.editProfileInput.textColor = .white
            cell.editProfileInput.isEnabled = false
            if let bankTitle = self.bankTitle {
                cell.editProfileInput.text = bankTitle
                cell.editProfileInput.textColor = .white
            } else {
                cell.editProfileInput.text = "Add Bank"
                cell.editProfileInput.textColor = color.red()
            }
                        
            break
            
        case 2:
            indexTitle = "Account"
            cell.editProfileInput.isEnabled = false
            if let requiresAttentionItems = self.requiresAttentionItems {
                if requiresAttentionItems > 0 {
                    var itemTitle = "1 item"
                    itemTitle = "\(self.requiresAttentionItems ?? 2) items"
                    cell.editProfileInput.text = "Requires Attention: \(itemTitle)"
                    cell.editProfileInput.textColor = color.red()
                } else {
                    cell.editProfileInput.text = "In Good Standing"
                    cell.editProfileInput.textColor = color.green()
                }

            } else {
                cell.editProfileInput.text = ""
                cell.editProfileInput.textColor = .darkGray
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
        
        picker.dismiss(animated: true, completion: {() in
            if let image = selectedImage {
                self.presentImageCropViewController(image)
            }
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        didFinishProcessingImage = true
        picker.dismiss(animated: true, completion: nil)
    }
    
    func presentImageCropViewController(_ image: UIImage) {
        let cropViewController = CropViewController(croppingStyle: .default, image: image)
        cropViewController.aspectRatioLockEnabled = true
        cropViewController.aspectRatioPickerButtonHidden = true
        cropViewController.aspectRatioPreset = .presetSquare
        cropViewController.resetAspectRatioEnabled = false
        cropViewController.delegate = self
        self.present(cropViewController, animated: false, completion: nil)
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
            if tag.type == "country",  let countryCode = tag.objectId, let email = artist?.email {
                self.createNewAccount(countryCode, email: email)
            } else if tag.type == "city" {
               artist?.city = tag.name
            }
        }
        self.tableView.reloadData()
        //TODO: if tagType == country, create Stripe custom account, save details to user profile, then show Subscription section and required info
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
    
    //MARK: Subscription
    func subScell(_ indexpath: IndexPath, tableView: UITableView) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: editBioReuse) as! ProfileTableViewCell
        cell.backgroundColor = .white
        cell.selectionStyle = .gray
        tableView.separatorInset = .zero
        
        if artist?.accountId == nil {
            cell.editBioTitle.text = "Subscription"
            cell.editBioText.text = "FREE"
        } else {
            cell.editBioTitle.text = "Subscription"
            cell.editBioText.text = "FREE"
        }
        
        return cell
    }
    
    //MARK: Data
    func updateUserInfo() {
        let customer = Customer.shared
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: PFUser.current()!.objectId!) {
            (user: PFObject?, error: Error?) -> Void in
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
                    self.stopAnimating()
                    if (success) {
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
                        
                        if let accountId = user["accountId"] as? String {
                            customer.artist?.accountId = accountId
                        }
                        
                        customer.update()
                        
                        //used to let give profileViewController updated profile
                        if let artistDelegate = self.artistDelegate {
                            artistDelegate.receivedArtist(customer.artist)
                        }
                        
                        DispatchQueue.main.async {
                            if self.isOnboarding {
                                self.uiElement.newRootView("Main", withIdentifier: "tabBar")
                            } else {
                                self.uiElement.goBackToPreviousViewController(self)
                            }
                        }
                        
                    } else if let error = error {
                        UIElement().showAlert("Oops", message: error.localizedDescription, target: self)
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
        if let websiteText = websiteText {
            if let text = websiteText.text {
                if !text.isEmpty {
                    if !text.starts(with: "https") && !text.starts(with: "http") {
                        self.websiteText.text = "https://\(text)"
                    }
            }
                
                if let url = URL(string: text), !UIApplication.shared.canOpenURL(url) {
                    let localizedInvalidURL = NSLocalizedString("invalidURL", comment: "")
                    self.uiElement.showTextFieldErrorMessage(self.websiteText, text: localizedInvalidURL)
                    return false
                }
            }
        }
        
        return true
    }
    
    //MARK: Account
    let baseURL = URL(string: "https://www.soundbrew.app/accounts/")
    var requiresAttentionItems: Int?
    var bankTitle: String?
    
    func createNewAccount(_ countryCode: String, email: String) {
        self.startAnimating()
        let url = self.baseURL!.appendingPathComponent("create")
        let parameters: Parameters = [
            "country": countryCode,
            "email": email]
        
        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString))
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    let json = JSON(json)
                    self.updateUserInfoWithAccountNumber(json["id"].stringValue)
                case .failure(let error):
                    self.uiElement.showAlert("Un-Successful", message: error.errorDescription ?? "", target: self)
                }
        }
    }
    
    func retreiveAccountIfo(_ accountId: String) {
        let url = self.baseURL!.appendingPathComponent("retrieve")
        let parameters: Parameters = [
            "accountId": accountId]
        
        AF.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString))
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    let json = JSON(json)
                    print(json)
                    if let currentlyDue = json["requirements"]["currently_due"].arrayObject as? [String], let eventuallyDue = json["requirements"]["eventually_due"].arrayObject as? [String], let pastDue = json["requirements"]["past_due"].arrayObject as? [String] {
                        if !currentlyDue.isEmpty  && !eventuallyDue.isEmpty && !pastDue.isEmpty {
                            self.requiresAttentionItems = currentlyDue.count + eventuallyDue.count + pastDue.count
                            
                            self.shouldSubstractRequiresAttentionNumber(currentlyDue)
                            self.shouldSubstractRequiresAttentionNumber(eventuallyDue)
                            self.shouldSubstractRequiresAttentionNumber(pastDue)
                        }
                    }
                    
                    if let bankName = json["external_accounts"]["data"][0]["bank_name"].string, let last4 = json["external_accounts"]["data"][0]["last4"].string {
                        self.bankTitle = "\(bankName) \(last4)"
                    }
                    
                    self.tableView.reloadData()
                case .failure(let error):
                    print(error)
                }
        }
    }
    
    func shouldSubstractRequiresAttentionNumber(_ due: [String]) {
        //Don't want user going to Stripe Account Link if they don't have to.
        if due.contains("external_account") {
            self.requiresAttentionItems = self.requiresAttentionItems! - 1
        }
    }
    
    func updateUserInfoWithAccountNumber(_ accountId: String) {
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: PFUser.current()!.objectId!) {
            (user: PFObject?, error: Error?) -> Void in
            if let user = user {
                user["accountId"] = accountId
                user.saveInBackground() {
                    (success: Bool, error: Error?) in
                    self.stopAnimating()
                    if (success) {
                        self.artist?.accountId = accountId
                        Customer.shared.artist?.accountId = accountId
                        self.tableView.reloadData()
                    } else if let error = error {
                        UIElement().showAlert("Oops", message: error.localizedDescription, target: self)
                    }
                }
            }
        }
    }
}

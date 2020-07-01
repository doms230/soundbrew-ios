//
//  NewAccountViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/30/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit
import Parse
import NVActivityIndicatorView
import Kingfisher
import CropViewController
import Alamofire
import SwiftyJSON

class NewAccountViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate, UITextFieldDelegate {

    let uiElement = UIElement()
    let color = Color()
    
    var newAccount: Account?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white

        setupStripeMessage()
        let topView = self.uiElement.addSubViewControllerTopView(self, action: #selector(self.didPressTopViewButton(_:)), doneButtonTitle: "Create", title: "New Fan Club Account")
        setUpTableView(topView.2)
    }
    
    @objc func didPressTopViewButton(_ sender: UIButton) {
        if sender.tag == 0 {
            self.dismiss(animated: true, completion: nil)
        } else {
            //TODO: Create new account
        }
    }
    
    //Stripe Message Views
    lazy var stripeMessage: UIButton = {
        let button = UIButton()
        button.setTitle("Your information is securely processed by Stripe.", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)", size: 15)
        button.setTitleColor(.darkGray, for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: #selector(didPressStripeMessage), for: .touchUpInside)
        return button
    }()

    @objc func didPressStripeMessage(_ sender: UIButton) {
        let stripeURL = URL(string: "https://stripe.com/connect")
        if UIApplication.shared.canOpenURL(stripeURL!) {
            UIApplication.shared.open(stripeURL!, options: [:], completionHandler: nil)
        }
    }
    
    func setupStripeMessage() {
        self.view.addSubview(stripeMessage)
        stripeMessage.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(self.uiElement.leftOffset)
            make.right.equalTo(self.view).offset(self.uiElement.rightOffset)
            if let tabBarController = self.tabBarController {
                make.bottom.equalTo(self.view).offset(-((tabBarController.tabBar.frame.height)) + CGFloat(uiElement.bottomOffset))
            } else {
                var bottomOffsetValue: Int!
                switch UIDevice.modelName {
                case "iPhone X", "iPhone XS", "iPhone XR", "iPhone 11", "iPhone 11 Pro", "iPhone 11 Pro Max", "iPhone XS Max", "Simulator iPhone 11 Pro Max":
                    bottomOffsetValue = uiElement.bottomOffset * 5
                    break
                    
                default:
                    bottomOffsetValue = uiElement.bottomOffset * 2
                    break
                }
                make.bottom.equalTo(self.view).offset(bottomOffsetValue)
            }
        }
    }
    
    //MARK: TableView
    let tableView = UITableView()
    let newAccountIdImageReuse = "newAccountIdImageReuse"
    let editProfileInfoReuse = "editProfileInfoReuse"
    let privateInfoTitleReuse = "privateInfoTitleReuse"
    let spaceReuse = "spaceReuse"
    func setUpTableView(_ topView: UIView) {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: newAccountIdImageReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editProfileInfoReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: privateInfoTitleReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: spaceReuse)
        tableView.backgroundColor = color.black()
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(topView.snp.bottom).offset(uiElement.topOffset)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.stripeMessage.snp.top)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 2:
            return 4
        case 4:
            return 2
        case 5:
            return 9
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: ProfileTableViewCell!
        if indexPath.section == 0 {
            cell = self.tableView.dequeueReusableCell(withIdentifier: privateInfoTitleReuse) as? ProfileTableViewCell
            cell.selectionStyle = .none
            cell.backgroundColor = color.black()
            cell.privateInformationLabel.text = "Upload a picture of your goverment issued ID (Driver's License, Passport, State ID, etc.)"
            cell.privateInformationLabel.numberOfLines = 0
            cell.privateInformationLabel.textColor = .lightGray
            return cell
            
        } else if indexPath.section == 1 {
            return idImageCell(tableView)
            
        } else if indexPath.section == 2 {
            return accountInfoCell(indexPath)
            
        } else if indexPath.section == 3 {
            cell = self.tableView.dequeueReusableCell(withIdentifier: privateInfoTitleReuse) as? ProfileTableViewCell
            cell.selectionStyle = .none
            cell.backgroundColor = color.black()
            cell.privateInformationLabel.text = "Weekly Payout Bank"
            return cell
            
        } else if indexPath.section == 4{
            return externalAccountCell(indexPath)
            
        } else {
            cell = self.tableView.dequeueReusableCell(withIdentifier: spaceReuse) as? ProfileTableViewCell
            cell.selectionStyle = .none
            cell.backgroundColor = color.black()
            return cell
        }
    }
    
    //MARK: ID Info
    var frontImageButton: UIButton!
    var backImageButton: UIButton!
    var selectedIdImage: String!
    
    func idImageCell(_ tableView: UITableView) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: newAccountIdImageReuse) as! ProfileTableViewCell
        cell.backgroundColor = color.black()
        tableView.separatorInset = .zero
        cell.selectionStyle = .none
        
        cell.frontImageButton.addTarget(self, action: #selector(self.didPressIdImageButton(_:)), for: .touchUpInside)
        cell.frontImageButton.tag = 0
        frontImageButton = cell.frontImageButton
        cell.backImageButton.addTarget(self, action: #selector(self.didPressIdImageButton(_:)), for: .touchUpInside)
        cell.backImageButton.tag = 1
        backImageButton = cell.backImageButton
        
        return cell
    }
    
    @objc func didPressIdImageButton(_ sender: UIButton) {
        if sender.tag == 0 {
            selectedIdImage = "front"
        } else {
            selectedIdImage = "back"
        }
        showUploadIdImagePicker()
    }
    
    func showUploadIdImagePicker() {
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
    
    func presentImageCropViewController(_ image: UIImage, picker: UIImagePickerController) {
        let cropViewController = CropViewController(croppingStyle: .default, image: image)
        cropViewController.aspectRatioLockEnabled = false
        cropViewController.aspectRatioPickerButtonHidden = false
        cropViewController.aspectRatioPreset = .preset16x9
        cropViewController.resetAspectRatioEnabled = true
        cropViewController.delegate = self
        picker.present(cropViewController, animated: false, completion: nil)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        if selectedIdImage == "front" {
            self.frontImageButton.setImage(image, for: .normal)
        } else {
            self.backImageButton.setImage(image, for: .normal)
        }
          //TODO: save file to Stripe and attache to File in Account object
        self.dismiss(animated: false, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }
    
    //MARK: Account Info
    var firstNameText: UITextField!
    var lastNameText: UITextField!
    var personalIdNumber: UITextField!
    var dobText: UITextField!
    
    func accountInfoCell(_ indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileInfoReuse) as! ProfileTableViewCell
        let edgeInsets = UIEdgeInsets(top: 0, left: 85 + CGFloat(UIElement().leftOffset), bottom: 0, right: 0)
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        tableView.separatorInset = edgeInsets
        
        var inputTitle: String!
        var inputText: String!
        
        switch indexPath.row {
        case 0:
            inputTitle = "First Name"
            cell.editProfileInput.keyboardType = .default
            firstNameText = cell.editProfileInput
            if let firstName = self.newAccount?.firstName {
                inputText = firstName
            }
            break
            
        case 1:
            inputTitle = "Last Name"
            cell.editProfileInput.keyboardType = .default
            lastNameText = cell.editProfileInput
            if let lastName = self.newAccount?.lastName {
                inputText = lastName
            }
            break
            
        case 2:
            inputTitle = "Date of Birth"
            cell.editProfileInput.keyboardType = .default
            cell.editProfileInput.tag = indexPath.row
            cell.editProfileInput.delegate = self
            dobText = cell.editProfileInput
            if let birthMonth = self.newAccount?.birthMonth, let birthDay = self.newAccount?.birthDay, let birthYear = self.newAccount?.birthYear {
                let dob = "\(birthMonth)/\(birthDay)/\(birthYear)"
                inputText = dob
            }
            break
            
        case 3:
            inputTitle = "SSN"
            cell.editProfileInput.keyboardType = .numberPad
            personalIdNumber = cell.editProfileInput
            if let lastName = self.newAccount?.lastName {
                inputText = lastName
            }
            break
            
        default:
            break
        }
        
        cell.editProfileTitle.text = inputTitle
        cell.editProfileInput.text = inputText
        
        return cell
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == 2 {
            self.showDatePickerForUserAge()
        }
    }
    
    var accountAge: Date?
    func showDatePickerForUserAge() {
        let birthdatePicker: UIDatePicker = UIDatePicker()
        if let date = self.accountAge {
            birthdatePicker.date = date
        }
        birthdatePicker.datePickerMode = .date
        birthdatePicker.timeZone = .current
        birthdatePicker.frame = CGRect(x: 0, y: 15, width: 270, height: 200)
        let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .alert)
        alertController.view.addSubview(birthdatePicker)
        let selectAction = UIAlertAction(title: "Okay", style: .default, handler: { _ in
            self.accountAge = birthdatePicker.date
            let components = birthdatePicker.date.get(.day, .month, .year)
            if self.ageIsValidated(birthdatePicker.date), let day = components.day, let month = components.month, let year = components.year {
                self.newAccount?.birthDay = "\(day)"
                self.newAccount?.birthMonth = "\(month)"
                self.newAccount?.birthYear = "\(year)"
                self.tableView.reloadData()
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(selectAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    func ageIsValidated(_ birthday: Date) -> Bool {
        let now = Date()
        let birthday: Date = birthday
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: now)
        if let year = ageComponents.year {
            if year < 18 {
                self.uiElement.showAlert("18 and Over Only", message: "We can only open fan club accounts for artists who are 18 or older. Alternatively, you can open a fan club account using your legal guardian's information, then use your own bank info.", target: self)
                return false
            }
            return true
        }
        return false
    }
    
    //MARK: Bank
    var routingBankNumber: UITextField!
    var accountBankNumber: UITextField!
    
    func externalAccountCell(_ indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileInfoReuse) as! ProfileTableViewCell
        let edgeInsets = UIEdgeInsets(top: 0, left: 85 + CGFloat(UIElement().leftOffset), bottom: 0, right: 0)
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        tableView.separatorInset = edgeInsets
        
        var inputTitle: String!
        var inputText: String!
        
        cell.editProfileInput.keyboardType = .default

        if indexPath.row == 0 {
            inputTitle = "Routing #"
            routingBankNumber = cell.editProfileInput
            if let routingBankNumber = self.newAccount?.routingNumber {
                inputText = routingBankNumber
            }
            
        } else if indexPath.row == 1 {
            inputTitle = "Account #"
            accountBankNumber = cell.editProfileInput
            if let bankAccountNumber = self.newAccount?.bankAccountNumber {
                inputText = bankAccountNumber
            }
        }
        
        cell.editProfileTitle.text = inputTitle
        cell.editProfileInput.text = inputText
        return cell
    }

}

extension Date {
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
}

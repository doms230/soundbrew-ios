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
import Kingfisher
import Alamofire
import SwiftyJSON

class NewAccountViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    let uiElement = UIElement()
    let color = Color()
    
    var newAccount: Account?
    var topView: (UIButton, UIButton, UIView, UIActivityIndicatorView)!
    var didDoubleCheckInfo = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        setupStripeMessage()
        topView = self.uiElement.addSubViewControllerTopView(self, action: #selector(self.didPressTopViewButton(_:)), doneButtonTitle: "Create", title: "New Fan Club Account")
        setUpTableView(topView.2)
    }
    
    @objc func didPressTopViewButton(_ sender: UIButton) {
        if sender.tag == 0 {
            self.dismiss(animated: true, completion: nil)
            //validateDocumentFront() &&
        } else if  self.validateText(self.firstNameInput) && self.validateText(self.lastNameInput) && self.validateText(self.dobText) && self.validateText(self.phoneNumberText) && self.validateText(self.personalIdNumberInput) && self.validateText(line1Input) && self.validateText(cityInput) && self.validateText(stateInput) && self.validateText(postalCodeInput) {
            //self.validateText(self.bankRoutingInput) && self.validateText(self.bankAccountNumberInput) {
            
            self.newAccount?.firstName = self.firstNameInput.text!
            self.newAccount?.lastName = self.lastNameInput.text!
            self.newAccount?.personalIdNumber = self.personalIdNumberInput.text!
            
            self.newAccount?.line1 = self.line1Input.text!
            if self.line2Input.text!.isEmpty {
                self.newAccount?.line2 = ""
            } else {
                self.newAccount?.line2 = self.line2Input.text!
            }
            self.newAccount?.city = self.cityInput.text!
            self.newAccount?.state = self.stateInput.text!
            self.newAccount?.postal_code = self.postalCodeInput.text!
            
         //   self.newAccount?.bankAccountNumber = self.bankAccountNumberInput.text!
          //  self.newAccount?.routingNumber = self.bankRoutingInput.text!
            
            if didDoubleCheckInfo {
                if let artist = Customer.shared.artist {
                    self.uiElement.shouldAnimateActivitySpinner(true, buttonGroup: (topView.1, topView.3))
                    self.newAccount?.createNewAccount(artist, target: self)
                }
            } else {
                didDoubleCheckInfo = true
                self.uiElement.showAlert("Double Check Info", message: "Double check that your info is correct to insure you get your weekly payouts on time!", target: self)
            }
        }
    }
    
   /* func validateDocumentFront() -> Bool {
        if self.newAccount?.documentFront == nil {
            self.uiElement.showAlert("Government Issued ID Required.", message: "", target: self)
            return false
        }
        return true
    }*/
    
    //Stripe Message Views
    lazy var stripeMessage: UIButton = {
        let button = UIButton()
        button.setTitle("Your information is securely processed & stored by stripe.com", for: .normal)
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
   // let newAccountIdImageReuse = "newAccountIdImageReuse"
    let editProfileInfoReuse = "editProfileInfoReuse"
    let privateInfoTitleReuse = "privateInfoTitleReuse"
    let spaceReuse = "spaceReuse"
    func setUpTableView(_ topView: UIView) {
        tableView.delegate = self
        tableView.dataSource = self
      //  tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: newAccountIdImageReuse)
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
            make.bottom.equalTo(self.stripeMessage.snp.top).offset(uiElement.bottomOffset)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1, 3:
            return 5
       // case 6:
         //   return 2
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
            cell.privateInformationLabel.textColor = .lightGray
            cell.privateInformationLabel.text = "To accept payment from fans, we need to verify your identity."
            cell.privateInformationLabel.numberOfLines = 0
            return cell
            
        } /*else if indexPath.section == 1 {
            return idImageCell(tableView)
            
        }*/ else if indexPath.section == 1 {
            return accountInfoCell(indexPath)
            
        } else if indexPath.section == 2 {
            cell = self.tableView.dequeueReusableCell(withIdentifier: privateInfoTitleReuse) as? ProfileTableViewCell
            cell.selectionStyle = .none
            cell.backgroundColor = color.black()
            cell.privateInformationLabel.text = "Address"
            return cell
            
        } else if indexPath.section == 3 {
            return addressCell(indexPath)
            
        } /*else if indexPath.section == 5 {
            cell = self.tableView.dequeueReusableCell(withIdentifier: privateInfoTitleReuse) as? ProfileTableViewCell
            cell.selectionStyle = .none
            cell.backgroundColor = color.black()
            cell.privateInformationLabel.text = "Weekly Payout Bank"
            return cell
            
        } else if indexPath.section == 6{
            return externalAccountCell(indexPath)
            
        }*/ else {
            cell = self.tableView.dequeueReusableCell(withIdentifier: spaceReuse) as? ProfileTableViewCell
            cell.selectionStyle = .none
            cell.backgroundColor = color.black()
            return cell
        }
    }
    
    //MARK: ID Info
    /*var frontImageButton: UIButton!
    var frontImageSpinner: UIActivityIndicatorView!
    var backImageButton: UIButton!
    var backImageSpinner: UIActivityIndicatorView!
    var selectedIdImage: String!*/
    
    /*func idImageCell(_ tableView: UITableView) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: newAccountIdImageReuse) as! ProfileTableViewCell
        cell.backgroundColor = color.black()
        tableView.separatorInset = .zero
        cell.selectionStyle = .none
        
        cell.frontImageButton.addTarget(self, action: #selector(self.didPressIdImageButton(_:)), for: .touchUpInside)
        cell.frontImageButton.tag = 0
        frontImageButton = cell.frontImageButton
        frontImageSpinner = cell.frontImageSpinner
        
        return cell
    }*/
    
   /* @objc func didPressIdImageButton(_ sender: UIButton) {
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
        var spinner: UIActivityIndicatorView!
        if selectedIdImage == "front" {
            self.frontImageButton.setImage(image, for: .normal)
            spinner = self.frontImageSpinner
        } else {
            self.backImageButton.setImage(image, for: .normal)
            spinner = self.backImageSpinner
        }
        self.dismiss(animated: false, completion: nil)
        if let chosenImageData = image.jpegData(compressionQuality: 0.5) {
            self.newAccount?.createNewFile(chosenImageData, spinner: spinner, target: self, documentType: self.selectedIdImage)
        }
    }
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        if cancelled {
            cropViewController.dismiss(animated: true, completion: nil)
            self.dismiss(animated: false, completion: nil)
        }
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
    }*/
    
    //MARK: Account Info
    var firstNameInput: UITextField!
    var lastNameInput: UITextField!
    var personalIdNumberInput: UITextField!
    var dobText: UITextField!
    var phoneNumberText: UITextField!
    
    func accountInfoCell(_ indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileInfoReuse) as! ProfileTableViewCell
        let edgeInsets = UIEdgeInsets(top: 0, left: 85 + CGFloat(UIElement().leftOffset), bottom: 0, right: 0)
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        tableView.separatorInset = edgeInsets
        
        var inputTitle: String!
        var inputText: String!
        cell.editProfileInput.delegate = self
        cell.editProfileInput.tag = indexPath.row
        
        switch indexPath.row {
            case 0:
                inputTitle = "First Name"
                cell.editProfileInput.keyboardType = .default
                firstNameInput = cell.editProfileInput
                if let firstName = self.newAccount?.firstName {
                    inputText = firstName
                }
                break
                
            case 1:
                inputTitle = "Last Name"
                cell.editProfileInput.keyboardType = .default
                lastNameInput = cell.editProfileInput
                if let lastName = self.newAccount?.lastName {
                    inputText = lastName
                }
                break
                
            case 2:
                inputTitle = "Date of Birth"
                cell.editProfileInput.keyboardType = .default
                dobText = cell.editProfileInput
                if let birthMonth = self.newAccount?.birthMonth, let birthDay = self.newAccount?.birthDay, let birthYear = self.newAccount?.birthYear {
                    let dob = "\(birthMonth)/\(birthDay)/\(birthYear)"
                    inputText = dob
                }
                break
            
            case 3:
                inputTitle = "Phone #"
                cell.editProfileInput.keyboardType = .numberPad
                phoneNumberText = cell.editProfileInput
                if let phoneNumber = self.newAccount?.phoneNumber {
                    inputText = phoneNumber
                }
                break
            
            case 4:
                inputTitle = "SSN (last 4)"
                cell.editProfileInput.keyboardType = .numberPad
                personalIdNumberInput = cell.editProfileInput
                if let lastName = self.newAccount?.personalIdNumber {
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
    
    var line1Input: UITextField!
    var line2Input: UITextField!
    var cityInput: UITextField!
    var stateInput: UITextField!
    var postalCodeInput: UITextField!
    
    func addressCell(_ indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileInfoReuse) as! ProfileTableViewCell
        let edgeInsets = UIEdgeInsets(top: 0, left: 85 + CGFloat(UIElement().leftOffset), bottom: 0, right: 0)
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        tableView.separatorInset = edgeInsets
        
        var inputTitle: String!
        var inputText: String!
        cell.editProfileInput.delegate = self
        
        switch indexPath.row {
            case 0:
                inputTitle = "Line 1"
                cell.editProfileInput.keyboardType = .default
                cell.editProfileInput.placeholder = "street"
                cell.editProfileInput.tag = 5
                line1Input = cell.editProfileInput
                if let line1 = self.newAccount?.line1 {
                    inputText = line1
                }
                break
            
            case 1:
                inputTitle = "Line 2"
                cell.editProfileInput.keyboardType = .default
                cell.editProfileInput.placeholder = "apartment, suite, unit, or building)"
                line2Input = cell.editProfileInput
                cell.editProfileInput.tag = 6
                if let line2 = self.newAccount?.line2 {
                    inputText = line2
                }
                break
                
            case 2:
                inputTitle = "City"
                cell.editProfileInput.keyboardType = .default
                cityInput = cell.editProfileInput
                cell.editProfileInput.tag = 7
                if let city = self.newAccount?.city {
                    inputText = city
                }
                break
                
            case 3:
                inputTitle = "State"
                cell.editProfileInput.keyboardType = .default
                stateInput = cell.editProfileInput
                cell.editProfileInput.tag = 8
                if let state = self.newAccount?.state {
                    inputText = state
                }
                break
                
            case 4:
                inputTitle = "Postal Code"
                cell.editProfileInput.keyboardType = .numberPad
                cell.editProfileInput.placeholder = "zip code"
                cell.editProfileInput.tag = 9
                postalCodeInput = cell.editProfileInput
                if let postal = self.newAccount?.postal_code {
                    inputText = postal
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
        } else if textField.tag == 8 {
            let pickerView = UIPickerView(frame: CGRect(x: 10, y: 50, width: 250, height: 150))
            pickerView.delegate = self
            pickerView.dataSource = self

            let ac = UIAlertController(title: "Choose Your State", message: "\n\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
            ac.view.addSubview(pickerView)
            ac.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
                let state = self.stateChoices[pickerView.selectedRow(inComponent: 0)]
                self.newAccount?.state = state
                self.tableView.reloadData()
            }))
            present(ac, animated: true)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField.tag {
            case 0:
                if textField.text!.isEmpty {
                    self.newAccount?.firstName = nil
                } else {
                   self.newAccount?.firstName = textField.text!
                }
                break
                
            case 1:
                if textField.text!.isEmpty {
                    self.newAccount?.lastName = nil
                } else {
                   self.newAccount?.lastName = textField.text!
                }
                break
                
            case 3:
                if textField.text!.isEmpty {
                    self.newAccount?.phoneNumber = nil
                } else {
                   self.newAccount?.phoneNumber = textField.text!
                }
                break
            
            case 4:
                if textField.text!.isEmpty {
                    self.newAccount?.personalIdNumber = nil
                } else {
                   self.newAccount?.personalIdNumber = textField.text!
                }
                break
            
            
            case 5:
                if textField.text!.isEmpty {
                    self.newAccount?.line1 = nil
                } else {
                   self.newAccount?.line1 = textField.text!
                }

                break
            
            case 6:
                if textField.text!.isEmpty {
                    self.newAccount?.line2 = nil
                } else {
                   self.newAccount?.line2 = textField.text!
                }
                break
            
            case 7:
                if textField.text!.isEmpty {
                    self.newAccount?.city = nil
                } else {
                   self.newAccount?.city = textField.text!
                }
                break
            
            case 9:
                if textField.text!.isEmpty {
                    self.newAccount?.postal_code = nil
                } else {
                   self.newAccount?.postal_code = textField.text!
                }
                break

            case 10:
                if textField.text!.isEmpty {
                    self.newAccount?.routingNumber = nil
                } else {
                   self.newAccount?.routingNumber = textField.text!
                }
                break
            
            case 11:
                if textField.text!.isEmpty {
                    self.newAccount?.bankAccountNumber = nil
                } else {
                   self.newAccount?.bankAccountNumber = textField.text!
                }
                break
            
            default:
                break
        }
    }
    
    let stateChoices = ["Alaska", "Alabama", "Arkansas", "American Samoa", "Arizona", "California", "Colorado", "Connecticut", "District of Columbia", "Delaware", "Florida", "Georgia", "Guam", "Hawaii", "Iowa", "Idaho", "Illinois", "Indiana", "Kansas", "Kentucky", "Louisiana", "Massachusetts", "Maryland", "Maine", "Michigan", "Minnesota", "Missouri", "Mississippi", "Montana", "North Carolina", "North Dakota", "Nebraska", "New Hampshire", "New Jersey", "New Mexico", "Nevada", "New York", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Puerto Rico", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Virginia", "Virgin Islands", "Vermont", "Washington", "Wisconsin", "West Virginia", "Wyoming"]
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return stateChoices.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return stateChoices[row]
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
                self.uiElement.showAlert("18+ Only", message: "We can only open fan club accounts for artists who are 18 or older. Alternatively, you can open a fan club account using your legal guardian's information, then use your own bank info.", target: self)
                return false
            }
            return true
        }
        return false
    }
    
    func validateText(_ textField: UITextField) -> Bool {
        if textField.text!.isEmpty {
            self.uiElement.showTextFieldErrorMessage(textField, text: "Required")
            return false
        }
        
        return true
    }
    
    //MARK: Bank
   // var bankRoutingInput: UITextField!
   // var bankAccountNumberInput: UITextField!
    
   /* func externalAccountCell(_ indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileInfoReuse) as! ProfileTableViewCell
        let edgeInsets = UIEdgeInsets(top: 0, left: 85 + CGFloat(UIElement().leftOffset), bottom: 0, right: 0)
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        tableView.separatorInset = edgeInsets
        
        var inputTitle: String!
        var inputText: String!
        
        cell.editProfileInput.keyboardType = .default
        cell.editProfileInput.delegate = self
        
        if indexPath.row == 0 {
            inputTitle = "Routing #"
            bankRoutingInput = cell.editProfileInput
            cell.editProfileInput.tag = 10
            if let routingBankNumber = self.newAccount?.routingNumber {
                inputText = routingBankNumber
            }
            
        } else if indexPath.row == 1 {
            inputTitle = "Account #"
            bankAccountNumberInput = cell.editProfileInput
            cell.editProfileInput.tag = 11
            if let bankAccountNumber = self.newAccount?.bankAccountNumber {
                inputText = bankAccountNumber
            }
        }
        
        cell.editProfileTitle.text = inputTitle
        cell.editProfileInput.text = inputText
        return cell
    }*/

}

extension Date {
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
}

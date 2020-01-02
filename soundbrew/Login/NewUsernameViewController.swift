//
//  NewUsernameViewController.swift
//  soundbrew
//
//  Created by Dominic Smith on 10/9/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import SnapKit
import NVActivityIndicatorView
import TwitterKit
import Kingfisher
import SwiftyJSON

class NewUsernameViewController: UIViewController, NVActivityIndicatorViewable {
    let uiElement = UIElement()
    let color = Color()
    
    var emailString: String!
    
    //twitter
    var authToken: String?
    var authTokenSecret: String?
    var twitterUsername: String?
    var twitterID: String?
    var twitterBio: String?
    var twitterImage: PFFileObject?
    
    //apple
    var appleID: String?
    var appleName: String? 
    
    lazy var usernameText: UITextField = {
        let localizedUsername = NSLocalizedString("username", comment: "")
        let textField = UITextField()
        textField.font = UIFont(name: uiElement.mainFont, size: 17)
        textField.backgroundColor = .white
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .whileEditing
        textField.keyboardType = .emailAddress
        textField.tintColor = color.black()
        textField.textColor = color.black()
        textField.attributedPlaceholder = NSAttributedString(string: localizedUsername,
        attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        return textField
    }()
    
    lazy var nextButton: UIButton = {
        let localizedNext = NSLocalizedString("next", comment: "")
        let button = UIButton()
        button.setTitle(localizedNext, for: .normal)
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 17)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.textAlignment = .right
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.setBackgroundImage(UIImage(named: "background"), for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        self.view.addSubview(usernameText)
        self.view.addSubview(nextButton)
        nextButton.addTarget(self, action: #selector(next(_:)), for: .touchUpInside)
        
        if let username = twitterUsername {
            usernameText.text = username
        }
        usernameText.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        nextButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.top.equalTo(usernameText.snp.bottom).offset(10)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        usernameText.becomeFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController = segue.destination as! NewPasswordViewController
        viewController.emailString = emailString
        viewController.usernameString = usernameText.text!
        
        let localizedPassword = NSLocalizedString("password", comment: "")
        let backItem = UIBarButtonItem()
        backItem.title = "\(localizedPassword) | 3/3"
        navigationItem.backBarButtonItem = backItem
    }
    
    @objc func next(_ sender: UIButton){
        self.usernameText.resignFirstResponder()
        usernameText.text = self.uiElement.cleanUpText(usernameText.text!, shouldLowercaseText: true)
        if validateUsername() {
            checkIfUsernameExistsThenMoveForward()
        }
    }
    
    func validateUsername() -> Bool {
        let localizedInvalidUsername = NSLocalizedString("invalidUsername", comment: "")
        let usernameString : NSString = usernameText.text! as NSString
        if usernameText.text!.isEmpty || usernameString.contains("@") {
            self.uiElement.showTextFieldErrorMessage(self.usernameText, text: localizedInvalidUsername)
            return false
        }
        
        return true
    }
    
    func checkIfUsernameExistsThenMoveForward() {
        startAnimating()
        let localizedUsernameAlreadyInUse = NSLocalizedString("usernameAlreadyInUse", comment: "")
        let query = PFQuery(className: "_User")
        query.whereKey("username", equalTo: usernameText.text!)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            self.stopAnimating()
            if object != nil && error == nil {
                self.uiElement.showTextFieldErrorMessage(self.usernameText, text: localizedUsernameAlreadyInUse)
                
            } else {
                if let twitterId = self.twitterID {
                    self.authenticateWith("twitter", userId: twitterId, auth_token: self.authToken, auth_token_secret: self.authTokenSecret!, username: self.usernameText.text!)
                    
                } else if let appleID = self.appleID {
                    self.authenticateWith("apple", userId: appleID, auth_token: nil, auth_token_secret: nil, username: self.usernameText.text!)
                } else {
                    self.performSegue(withIdentifier: "showPassword", sender: self)
                }
            }
        }
    }
    
    func authenticateWith(_ loginService: String, userId: String, auth_token: String?, auth_token_secret: String?, username: String) {
                        
        var authData: [String:String]
        if loginService == "twitter" {
            authData = ["id": userId, "auth_token": auth_token!, "consumer_key": "shY1N1YKquAcxJF9YtdFzm6N3", "consumer_secret": "dFzxXdA0IM9A7NsY3JzuPeWZhrIVnQXiWFoTgUoPVm0A2d1lU1", "auth_token_secret": auth_token_secret!]
        } else {
            print("apple userId: \(userId)")
            authData = ["id": userId]
        }
        
        PFUser.logInWithAuthType(inBackground: loginService, authData: authData).continueOnSuccessWith(block: {
            (ignored: BFTask!) -> AnyObject? in
            let parseUser = PFUser.current()
            let installation = PFInstallation.current()
            installation?["user"] = parseUser
            installation?["userId"] = parseUser?.objectId
            installation?.saveEventually()
            
            if loginService == "twitter" {
                self.getTwitterImageAndBio()
            } else {
                self.updateUserInfo()
            }
            return AnyObject.self as AnyObject
        })
    }
    
    func getTwitterImageAndBio() {
        if let userID = self.twitterID {
            let client = TWTRAPIClient(userID: userID)
            let statusesShowEndpoint = "https://api.twitter.com/1.1/users/show.json"
            let params = ["user_id": userID]
            var clientError : NSError?
            let request = client.urlRequest(withMethod: "GET", urlString: statusesShowEndpoint, parameters: params, error: &clientError)
            client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
                if let connectionError = connectionError {
                    print("Error: \(connectionError)")
                }
                do {
                    if let data = data {
                        let jsonData = try JSONSerialization.jsonObject(with: data, options: [])
                        let json = JSON(jsonData)
                        
                        if let description = json["description"].string {
                            self.twitterBio = description
                        }
                                                
                        if let twitterImageURL = json["profile_image_url_https"].string {
                            self.getTwitterImageAndUpdateUserInfo(twitterImageURL)
                        } else {
                            self.updateUserInfo()
                        }
                    }
                } catch let jsonError {
                    print("json error: \(jsonError.localizedDescription)")
                }
            }
        }
    }
    
    func getTwitterImageAndUpdateUserInfo(_ twitterImageURL: String) {
        let imageView = UIImageView()
        imageView.kf.setImage(with: URL(string: twitterImageURL)) { result in
            switch result {
            case .success(let value):
                let chosenProfileImage = value.image.jpegData(compressionQuality: 0.5)
                let newProfileImageFile = PFFileObject(name: "profile_ios.jpeg", data: chosenProfileImage!)
                newProfileImageFile?.saveInBackground {
                    (success: Bool, error: Error?) in
                    if (success) {
                        self.twitterImage = newProfileImageFile
                    }
                    self.updateUserInfo()
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    func updateUserInfo() {
        if let currentUserId = PFUser.current()?.objectId {
            let query = PFQuery(className: "_User")
            query.getObjectInBackground(withId: currentUserId) {
                (user: PFObject?, error: Error?) -> Void in
                if let error = error {
                    print(error)
                    
                } else if let user = user {
                    if let _ = user["email"] as? String {
                        Customer.shared.getCustomer(user.objectId!)
                        self.stopAnimating()
                        self.uiElement.newRootView("Main", withIdentifier: "tabBar")
                    } else {
                        
                        if let appleName = self.appleName {
                            user["artistName"] = appleName
                        } else {
                            user["artistName"] = self.usernameText.text
                        }
                        
                        user["username"] = self.usernameText.text
                        user["email"] = self.emailString
                        
                        if let appleID = self.appleID {
                            user["appleID"] = appleID
                        }
                        
                        if let twitterID = self.twitterID {
                            user["twitterID"] = twitterID
                        }
                        
                        if let twitterBio = self.twitterBio {
                            user["bio"] = twitterBio
                        }
                        
                        if let twitterImage = self.twitterImage {
                              user["userImage"] = twitterImage
                        }
                        
                        if let twitterUsername = self.twitterUsername {
                            user["website"] = "https://www.twitter.com/\(twitterUsername)"
                        }
                        user.saveEventually {
                            (success: Bool, error: Error?) in
                            if (success) {
                                Customer.shared.getCustomer(user.objectId!)
                                self.stopAnimating()
                                self.uiElement.newRootView("Main", withIdentifier: "tabBar")
                            } else if let error = error {
                                UIElement().showAlert("Oops", message: error.localizedDescription, target: self)
                            }
                        }
                    }
                }
            }
        }
    }
}

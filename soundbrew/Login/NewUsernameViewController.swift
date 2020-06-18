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
import Kingfisher
import SwiftyJSON

class NewUsernameViewController: UIViewController, NVActivityIndicatorViewable, PFUserAuthenticationDelegate {
    func restoreAuthentication(withAuthData authData: [String : String]?) -> Bool {
        return true 
    }
    
    let uiElement = UIElement()
    let color = Color()
    
    var emailString: String!
    
    //apple
    var appleID: String?
    var appleName: String? 
    var appleToken: String?
    
    var usernameText: UITextField!
    var usernameLabel: UILabel!
    var usernameDividerLine: UIView!
    
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
        button.addTarget(self, action: #selector(next(_:)), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        self.view.addSubview(nextButton)
        nextButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.centerY.equalTo(self.view)
        }

        self.usernameLabel = self.uiElement.soundbrewLabel("Username", textColor: .white, font: UIFont(name: "\(self.uiElement.mainFont)", size: 17)!, numberOfLines: 1)
        self.view.addSubview(self.usernameLabel)
        self.usernameLabel.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(100)
            make.left.equalTo(self.view).offset(self.uiElement.leftOffset)
            make.bottom.equalTo(self.nextButton.snp.top).offset(self.uiElement.bottomOffset * 2)
        }
        
        self.usernameText = self.uiElement.soundbrewTextInput(.default, isSecureTextEntry: false)
        self.view.addSubview(self.usernameText)
        self.usernameText.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.usernameLabel)
            make.left.equalTo(self.usernameLabel.snp.right)
            make.right.equalTo(self.view).offset(self.uiElement.rightOffset)
        }
        
        self.usernameDividerLine = self.uiElement.soundbrewDividerLine()
        self.view.addSubview(self.usernameDividerLine)
        self.usernameDividerLine.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(0.5)
            make.top.equalTo(self.usernameText.snp.bottom)
            make.left.equalTo(self.usernameText)
            make.right.equalTo(self.usernameText)
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
                if let appleID = self.appleID {
                    self.authenticateWith("apple", userId: appleID, auth_token: self.appleToken, auth_token_secret: nil, username: self.usernameText.text!)
                } else {
                    self.performSegue(withIdentifier: "showPassword", sender: self)
                }
            }
        }
    }
    
    func authenticateWith(_ loginService: String, userId: String, auth_token: String?, auth_token_secret: String?, username: String) {
                        
        var authData: [String:String]
        authData = ["token": auth_token!, "id": userId]
        
        PFUser.logInWithAuthType(inBackground: loginService, authData: authData).continueOnSuccessWith(block: {
            (ignored: BFTask!) -> AnyObject? in
            let parseUser = PFUser.current()
            let installation = PFInstallation.current()
            installation?["user"] = parseUser
            installation?["userId"] = parseUser?.objectId
            installation?.saveEventually()
            
            self.updateUserInfo()
            return AnyObject.self as AnyObject
        })
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
            
                        user.saveEventually {
                            (success: Bool, error: Error?) in
                            self.stopAnimating()
                            if (success) {
                                Customer.shared.getCustomer(user.objectId!)
                                if self.appleID != nil {
                                    let storyboard = UIStoryboard(name: "NewUser", bundle: nil)
                                    if let navi = storyboard.instantiateViewController(withIdentifier: "editProfile") as? UINavigationController, let editProfile = navi.topViewController as? EditProfileViewController {
                                        editProfile.artist = self.uiElement.newArtistObject(user)
                                        editProfile.title = "Complete Profile"
                                        editProfile.isOnboarding = true
                                        let appdelegate = UIApplication.shared.delegate as! AppDelegate
                                        appdelegate.window?.rootViewController = navi
                                    } else {
                                        self.uiElement.newRootView("Main", withIdentifier: "tabBar")
                                    }
                                    
                                 } else {
                                    self.uiElement.newRootView("Main", withIdentifier: "tabBar")
                                }

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

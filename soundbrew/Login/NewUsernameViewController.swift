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

class NewUsernameViewController: UIViewController, NVActivityIndicatorViewable {
    let uiElement = UIElement()
    let color = Color()
    
    var emailString: String!
    var authToken: String?
    var authTokenSecret: String?
    var twitterUsername: String?
    var twitterID: String?
    
    lazy var usernameText: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Username"
        textField.font = UIFont(name: uiElement.mainFont, size: 17)
        textField.backgroundColor = .white
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .whileEditing
        textField.keyboardType = .emailAddress
        textField.tintColor = color.black()
        return textField
    }()
    
    lazy var nextButton: UIButton = {
        let button = UIButton()
        button.setTitle("NEXT", for: .normal)
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
        
        let backItem = UIBarButtonItem()
        backItem.title = "Password | 3/3"
        navigationItem.backBarButtonItem = backItem
    }
    
    @objc func next(_ sender: UIButton){
        self.usernameText.resignFirstResponder()
        usernameText.text = self.uiElement.cleanUpText(usernameText.text!)
        if validateUsername() {
            checkIfUsernameExistsThenMoveForward()
        }
    }
    
    func validateUsername() -> Bool {
        let usernameString : NSString = usernameText.text! as NSString
        if usernameText.text!.isEmpty || usernameString.contains("@") {
            self.uiElement.showTextFieldErrorMessage(self.usernameText, text: "Invalid username.")
            return false
        }
        
        return true
    }
    
    func checkIfUsernameExistsThenMoveForward() {
        startAnimating()
        let query = PFQuery(className: "_User")
        query.whereKey("username", equalTo: usernameText.text!)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            self.stopAnimating()
            if object != nil && error == nil {
                self.uiElement.showTextFieldErrorMessage(self.usernameText, text: "Username already in use.")
                
            } else {
                if let authToken = self.authToken {
                    self.authenticateWithTwitter(self.twitterID!, auth_token: authToken, auth_token_secret: self.authTokenSecret!, username: self.usernameText.text!)
                    
                } else {
                   self.performSegue(withIdentifier: "showPassword", sender: self)
                }
            }
        }
    }
    
    func authenticateWithTwitter(_ userId: String, auth_token: String, auth_token_secret: String, username: String) {
        
        PFUser.logInWithAuthType(inBackground: "twitter", authData: ["id": userId, "auth_token": auth_token, "consumer_key": "shY1N1YKquAcxJF9YtdFzm6N3", "consumer_secret": "dFzxXdA0IM9A7NsY3JzuPeWZhrIVnQXiWFoTgUoPVm0A2d1lU1", "auth_token_secret": auth_token_secret ]).continueOnSuccessWith(block: {
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
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: PFUser.current()!.objectId!) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                if let _ = user["email"] as? String {
                    Customer.shared.getCustomer(user.objectId!)
                    self.stopAnimating()
                    self.uiElement.newRootView("Main", withIdentifier: "tabBar")
                } else {
                    user["artistName"] = self.usernameText.text
                    user["username"] = self.usernameText.text
                    user["email"] = self.emailString
                    user["twitterID"] = self.twitterID
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

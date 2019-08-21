//
//  UsernameViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 4/11/19.
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
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: uiElement.titleLabelFontSize)
        label.text = "Username"
        label.textColor = .white 
        label.numberOfLines = 0
        return label
    }()
    
    lazy var usernameText: UITextField = {
        let label = UITextField()
        label.placeholder = "Username"
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.backgroundColor = .white
        label.borderStyle = .roundedRect
        label.clearButtonMode = .whileEditing
        label.keyboardType = .emailAddress
        return label
    }()
    
    lazy var nextButton: UIButton = {
        let button = UIButton()
        button.setTitle("next", for: .normal)
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 20)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.textAlignment = .right
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.backgroundColor = color.blue()
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        
        if authToken != nil {
            self.title = "Username | 2/2"
            nextButton.setTitle("Done", for: .normal)
        } else {
            self.title = "Username | 2/3"
        }
        
        self.view.addSubview(titleLabel)
        self.view.addSubview(usernameText)
        self.view.addSubview(nextButton)
        nextButton.addTarget(self, action: #selector(next(_:)), for: .touchUpInside)
        
        titleLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        if let username = twitterUsername {
            usernameText.text = username
        }
        usernameText.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
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
            self.followSoundbrewTwitterAccount()
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
                    self.navigationController?.popToRootViewController(animated: true)
                    
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
                            self.navigationController?.popToRootViewController(animated: true)
                            
                        } else if let error = error {
                            UIElement().showAlert("Oops", message: error.localizedDescription, target: self)
                        }
                    }
                }
            }
        }
    }
    
    func followSoundbrewTwitterAccount() {
        if let userID = self.twitterID {
            let client = TWTRAPIClient(userID: userID)
            let statusesShowEndpoint = "https://api.twitter.com/1.1/friendships/create.json"
            let params = [ "Name": "Soundbrew", "screen_name": "sound_brew"]
            var clientError : NSError?
            let request = client.urlRequest(withMethod: "POST", urlString: statusesShowEndpoint, parameters: params, error: &clientError)
            client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
                if let connectionError = connectionError {
                    print("Error: \(connectionError)")
                }
                do {
                    if let data = data {
                        let json = try JSONSerialization.jsonObject(with: data, options: [])
                        print("json: \(json)")
                    }
                } catch let jsonError as NSError {
                    print("json error: \(jsonError.localizedDescription)")
                }
            }
        }
    }

}

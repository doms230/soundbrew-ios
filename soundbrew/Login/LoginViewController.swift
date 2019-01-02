//
//  LoginViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/10/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import NVActivityIndicatorView
import UserNotifications

class LoginViewController: UIViewController, NVActivityIndicatorViewable {
    var color = Color()
    let uiElement = UIElement()
    
    var image: UIImage!
    var retreivedImage: PFFileObject!
    
    var valUsername = false
    var valPassword = false
    var valEmail = false
    
    var signupHidden = true
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 30)
        label.text = "Sign in"
        label.numberOfLines = 0
        return label
    }()
    
    lazy var emailText: UITextField = {
        let label = UITextField()
        label.placeholder = "Email"
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.backgroundColor = .white
        label.borderStyle = .roundedRect
        label.clearButtonMode = .whileEditing
        label.keyboardType = .emailAddress
        return label
    }()
    
    lazy var passwordText: UITextField = {
        let label = UITextField()
        label.placeholder = "Password"
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.backgroundColor = .white
        label.borderStyle = .roundedRect
        label.clearButtonMode = .whileEditing
        label.isSecureTextEntry = true
        return label
    }()
    
    lazy var signButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 20)
        button.titleLabel?.textAlignment = .right
        button.setTitle("Sign In", for: .normal)
        button.backgroundColor = color.blue()
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let exitItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.didPressExit(_:)))
        self.navigationItem.leftBarButtonItem = exitItem
        
        let forogtPasswordItem = UIBarButtonItem(title: "Forgot Password", style: .plain, target: self, action: #selector(didPressForgotPassword(_:)))
        self.navigationItem.rightBarButtonItem = forogtPasswordItem
        
        self.view.addSubview(titleLabel)
        self.view.addSubview(emailText)
        self.view.addSubview(passwordText)
        self.view.addSubview(signButton)
        
        titleLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        emailText.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        passwordText.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(emailText.snp.bottom).offset(10)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        signButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.top.equalTo(passwordText.snp.bottom).offset(10)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        signButton.addTarget(self, action: #selector(loginAction(_:)), for: .touchUpInside)
        
        emailText.becomeFirstResponder()
        
        NVActivityIndicatorView.DEFAULT_TYPE = .ballScaleMultiple
        NVActivityIndicatorView.DEFAULT_COLOR = color.blue()
        NVActivityIndicatorView.DEFAULT_BLOCKER_SIZE = CGSize(width: 60, height: 60)
        NVActivityIndicatorView.DEFAULT_BLOCKER_BACKGROUND_COLOR = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    }
    
    @objc func loginAction(_ sender: UIButton) {
        emailText.resignFirstResponder()
        passwordText.resignFirstResponder()
        let emailString = emailText.text?.lowercased()
        if validateUsername() && validatePassword() {
            returningUser( password: passwordText.text!, username: emailString!)
        }
    }
    
    func validateUsername() -> Bool {
        if emailText.text!.isEmpty {
            
            emailText.attributedPlaceholder = NSAttributedString(string:"Field required",
                                                                 attributes:[NSAttributedString.Key.foregroundColor: UIColor.red])
            valUsername = false
            
        } else {
            valUsername = true
        }
        return valUsername
    }
    
    func validatePassword() -> Bool {
        if passwordText.text!.isEmpty {
            passwordText.attributedPlaceholder = NSAttributedString(string: "Field required",
                                                                    attributes:[NSAttributedString.Key.foregroundColor: UIColor.red])
            valPassword = false
            
        } else {
            valPassword = true
        }
        
        return valPassword
    }
    
    func returningUser(password: String, username: String) {
        startAnimating()
        
        let userJaunt = username.trimmingCharacters(
            in: NSCharacterSet.whitespacesAndNewlines
        )
        
        PFUser.logInWithUsername(inBackground: userJaunt, password:password) {
            (user: PFUser?, error: Error?) -> Void in
            if user != nil {
                //associate current user with device
                let installation = PFInstallation.current()
                installation?["user"] = PFUser.current()
                installation?["userId"] = PFUser.current()?.objectId
                installation?.saveEventually()
                
                self.determineNextScreen()
                
            } else {
                self.stopAnimating()
                UIElement().showAlert("Oops", message: "Incorrect Email/Password combo.", target: self)
            }
        }
    }
    
    func determineNextScreen() {
        let current = UNUserNotificationCenter.current()
        current.getNotificationSettings(completionHandler: { (settings) in
            if settings.authorizationStatus == .notDetermined {
                self.uiElement.segueToView("Main", withIdentifier: "notification", target: self)
                
            } else if settings.authorizationStatus == .denied ||
                settings.authorizationStatus == .authorized {
                self.uiElement.segueToView("Main", withIdentifier: "main", target: self)
            }
        })
    }
    
    @objc func didPressForgotPassword(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "showForgotPassword", sender: self)
    }
    
    @objc func didPressExit(_ sender: UIBarButtonItem) {
        emailText.resignFirstResponder()
        passwordText.resignFirstResponder()
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "welcome")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //show window
        appDelegate.window?.rootViewController = initialViewController
    }
}

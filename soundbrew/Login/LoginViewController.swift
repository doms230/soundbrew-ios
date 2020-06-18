//
//  LoginViewController.swift
//  soundbrew
//
//  Created by Dominic Smith on 10/9/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import NVActivityIndicatorView
import UserNotifications
import AppCenterAnalytics

class LoginViewController: UIViewController, NVActivityIndicatorViewable {
    var color = Color()
    let uiElement = UIElement()
    
    var image: UIImage!
    var retreivedImage: PFFileObject!
    
    var valUsername = false
    var valPassword = false
    var valEmail = false
    
    var signupHidden = true
    
    var usernameText: UITextField!
    var usernameLabel: UILabel!
    var usernameDividerLine: UIView!
    
    var passwordText: UITextField!
    var passwordLabel: UILabel!
    var passwordDividerLine: UIView!
    
    lazy var signButton: UIButton = {
        let localizedSignin = NSLocalizedString("signin", comment: "")
        let button = UIButton()
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 17)
        button.titleLabel?.textAlignment = .right
        button.setTitle(localizedSignin, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.setBackgroundImage(UIImage(named: "background"), for: .normal)
        button.addTarget(self, action: #selector(loginAction(_:)), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        let localizedForgotPassword = NSLocalizedString("forgotPassword", comment: "")
        let forogtPasswordItem = UIBarButtonItem(title: localizedForgotPassword, style: .plain, target: self, action: #selector(didPressForgotPassword(_:)))
        self.navigationItem.rightBarButtonItem = forogtPasswordItem
        
        let localizedCancel = NSLocalizedString("cancel", comment: "")
        let cancelButton = UIBarButtonItem(title: localizedCancel, style: .plain, target: self, action: #selector(self.didPressCancelButton(_:)))
        self.navigationItem.leftBarButtonItem = cancelButton
        
        self.view.addSubview(signButton)
        signButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
           // make.top.equalTo(passwordText.snp.bottom).offset(10)
            make.centerY.equalTo(self.view)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        passwordLabel = self.uiElement.soundbrewLabel("Password", textColor: .white, font: UIFont(name: "\(uiElement.mainFont)", size: 17)!, numberOfLines: 1)
        self.view.addSubview(passwordLabel)
        passwordLabel.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(100)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.bottom.equalTo(signButton.snp.top).offset(uiElement.bottomOffset * 2)
        }
        
        passwordText = self.uiElement.soundbrewTextInput(.default, isSecureTextEntry: true)
        self.view.addSubview(passwordText)
        passwordText.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(passwordLabel)
            make.left.equalTo(passwordLabel.snp.right)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        passwordDividerLine = self.uiElement.soundbrewDividerLine()
        self.view.addSubview(passwordDividerLine)
        passwordDividerLine.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(0.5)
            make.top.equalTo(passwordText.snp.bottom)
            make.left.equalTo(passwordText)
            make.right.equalTo(passwordText)
        }
        
        usernameLabel = self.uiElement.soundbrewLabel("Username", textColor: .white, font: UIFont(name: "\(uiElement.mainFont)", size: 17)!, numberOfLines: 1)
        self.view.addSubview(usernameLabel)
        usernameLabel.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(100)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.bottom.equalTo(passwordLabel.snp.top).offset(uiElement.bottomOffset * 2)
        }
        
        usernameText = self.uiElement.soundbrewTextInput(.default, isSecureTextEntry: false)
        self.view.addSubview(usernameText)
        usernameText.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(usernameLabel)
            make.left.equalTo(usernameLabel.snp.right)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        usernameText.becomeFirstResponder()
        
        usernameDividerLine = self.uiElement.soundbrewDividerLine()
        self.view.addSubview(usernameDividerLine)
        usernameDividerLine.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(0.5)
            make.top.equalTo(usernameText.snp.bottom)
            make.left.equalTo(usernameText)
            make.right.equalTo(usernameText)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let localizedForgotPassword = NSLocalizedString("forgotPassword", comment: "")
        let backItem = UIBarButtonItem()
        backItem.title = localizedForgotPassword
        navigationItem.backBarButtonItem = backItem
    }
    
    @objc func loginAction(_ sender: UIButton) {
        usernameText.resignFirstResponder()
        passwordText.resignFirstResponder()
        let usernameString = usernameText.text?.lowercased()
        if validateUsername() && validatePassword() {
            loginUser(usernameString!, password: passwordText.text!)
        }
    }
    
    func validateUsername() -> Bool {
        let localizedFieldRequired = NSLocalizedString("fieldRequired", comment: "")
        if usernameText.text!.isEmpty {
            
            usernameText.attributedPlaceholder = NSAttributedString(string: localizedFieldRequired,
                                                                 attributes:[NSAttributedString.Key.foregroundColor: UIColor.red])
            valUsername = false
            
        } else {
            valUsername = true
        }
        return valUsername
    }
    
    func validatePassword() -> Bool {
        let localizedFieldRequired = NSLocalizedString("fieldRequired", comment: "")
        if passwordText.text!.isEmpty {
            passwordText.attributedPlaceholder = NSAttributedString(string: localizedFieldRequired,
                                                                    attributes:[NSAttributedString.Key.foregroundColor: UIColor.red])
            valPassword = false
            
        } else {
            valPassword = true
        }
        
        return valPassword
    }
    
    func loginUser(_ username: String, password: String) {
        startAnimating()
        
        let trimmedUsername = username.trimmingCharacters(
            in: NSCharacterSet.whitespacesAndNewlines
        )
        
        PFUser.logInWithUsername(inBackground: trimmedUsername, password: password) {
            (user: PFUser?, error: Error?) -> Void in
            self.stopAnimating()
            if let user = user  {
                //associate current user with device
                let installation = PFInstallation.current()
                installation?["user"] = PFUser.current()
                installation?["userId"] = PFUser.current()?.objectId
                installation?.saveEventually()
                
                Customer.shared.getCustomer(user.objectId!)
                self.uiElement.newRootView("Main", withIdentifier: "tabBar")
            } else {
                let localizedStringOops = NSLocalizedString("oops", comment: "")
                let localizedStringIncorrectLogin = NSLocalizedString("incorrectLogin", comment: "")
                UIElement().showAlert(localizedStringOops, message: localizedStringIncorrectLogin, target: self)
            }
        }
    }
    
    @objc func didPressForgotPassword(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "showForgotPassword", sender: self)
        MSAnalytics.trackEvent("Login View Controller", withProperties: ["Button" : "didPressForgotPassword"])
    }
    
    @objc func didPressCancelButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
        MSAnalytics.trackEvent("Login View Controller", withProperties: ["Button" : "didPressCancelButton"])
    }
    
    @objc func didPressExit(_ sender: UIBarButtonItem) {
        usernameText.resignFirstResponder()
        passwordText.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
}

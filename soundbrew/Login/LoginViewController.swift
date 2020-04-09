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
    
    lazy var usernameText: UITextField = {
    
        let label = UITextField()
        let localizedString = NSLocalizedString("usernameOrEmail", comment: "")
        //label.placeholder = localizedString
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.backgroundColor = .white
        label.borderStyle = .roundedRect
        label.clearButtonMode = .whileEditing
        label.keyboardType = .emailAddress
        label.tintColor = color.black()
        label.textColor = color.black()
        label.attributedPlaceholder = NSAttributedString(string: localizedString,
        attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        return label
    }()
    
    lazy var passwordText: UITextField = {
        let label = UITextField()
        let localizedString = NSLocalizedString("password", comment: "")
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.backgroundColor = .white
        label.borderStyle = .roundedRect
        label.clearButtonMode = .whileEditing
        label.isSecureTextEntry = true
        label.tintColor = color.black()
        label.textColor = color.black()
        label.attributedPlaceholder = NSAttributedString(string: localizedString,
        attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        return label
    }()
    
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
        
        self.view.addSubview(usernameText)
        self.view.addSubview(passwordText)
        self.view.addSubview(signButton)
        
        usernameText.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        passwordText.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(usernameText.snp.bottom).offset(10)
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
        
        usernameText.becomeFirstResponder()
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
        let emailString = usernameText.text?.lowercased()
        if validateUsername() && validatePassword() {
            returningUser( password: passwordText.text!, username: emailString!)
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
    
    func returningUser(password: String, username: String) {
        startAnimating()
        
        let userJaunt = username.trimmingCharacters(
            in: NSCharacterSet.whitespacesAndNewlines
        )
        
        PFUser.logInWithUsername(inBackground: userJaunt, password:password) {
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

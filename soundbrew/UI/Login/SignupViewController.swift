//
//  SignupViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/10/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import NVActivityIndicatorView
import SnapKit

class SignupViewController: UIViewController, NVActivityIndicatorViewable {
    let color = Color()
    let uiElement = UIElement()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: uiElement.titleLabelFontSize)
        label.text = "Signup"
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
    
    lazy var signupButton: UIButton = {
        let button = UIButton()
        button.setTitle("Sign Up", for: .normal)
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 20)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.textAlignment = .right
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.backgroundColor = color.blue()
        return button
    }()
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        self.title = "Welcome"
        
        let exitItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(SignupViewController.exitAction(_:)))
        self.navigationItem.leftBarButtonItem = exitItem
        
        self.view.addSubview(titleLabel)
        self.view.addSubview(emailText)
        self.view.addSubview(passwordText)
        self.view.addSubview(signupButton)
        signupButton.addTarget(self, action: #selector(next(_:)), for: .touchUpInside)
        
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
        
        signupButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.top.equalTo(passwordText.snp.bottom).offset(10)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        NVActivityIndicatorView.DEFAULT_TYPE = .ballScaleMultiple
        NVActivityIndicatorView.DEFAULT_COLOR = color.blue()
        NVActivityIndicatorView.DEFAULT_BLOCKER_SIZE = CGSize(width: 60, height: 60)
        NVActivityIndicatorView.DEFAULT_BLOCKER_BACKGROUND_COLOR = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        emailText.becomeFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    @objc func next(_ sender: UIButton){
        emailText.resignFirstResponder()
        passwordText.resignFirstResponder()
        
        if validateEmail() && validatePassword(){
            startAnimating()
            signup()
        }
    }
    
    //MARK: Validate jaunts
    func signup() {
        let lowercasedEmail = emailText.text!.lowercased()
        
        let user = PFUser()
        //user.username = lowercasedEmail
        user.password = passwordText.text!
        user.email = lowercasedEmail
        user.signUpInBackground{ (succeeded: Bool, error: Error?) -> Void in
            self.stopAnimating()
            if let error = error {
                UIElement().showAlert("Oops", message: error.localizedDescription, target: self)
                
            } else {
                let installation = PFInstallation.current()
                installation?["user"] = PFUser.current()
                installation?["userId"] = PFUser.current()?.objectId
                installation?.saveEventually()
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let initialViewController = storyboard.instantiateViewController(withIdentifier: "main")
                self.present(initialViewController, animated: true, completion: nil)
            }
        }
    }
    
    func validatePassword() -> Bool {
        if passwordText.text!.isEmpty {
            passwordText.attributedPlaceholder = NSAttributedString(string: "Password required",
                                                                    attributes:[NSAttributedString.Key.foregroundColor: UIColor.red])
            return false
        }
        
        return true 
    }
    
    func validateEmail() -> Bool {
        let emailString : NSString = emailText.text! as NSString
        if emailText.text!.isEmpty || !emailString.contains("@") || !emailString.contains(".") {
            emailText.attributedPlaceholder = NSAttributedString(string: "Valid email required",
                                                                 attributes:[NSAttributedString.Key.foregroundColor: UIColor.red])
            emailText.text = ""
            return false
        }
        
        return true
    }
    
    @objc func exitAction(_ sender: UIButton) {
        emailText.resignFirstResponder()
        passwordText.resignFirstResponder()
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "welcome") as UIViewController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //show window
        appDelegate.window?.rootViewController = controller
    }
}

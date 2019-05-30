//
//  NewPasswordViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 4/15/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import NVActivityIndicatorView
import SnapKit

class NewPasswordViewController: UIViewController, NVActivityIndicatorViewable {
    let color = Color()
    let uiElement = UIElement()
    var emailString: String!
    var usernameString: String!
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: uiElement.titleLabelFontSize)
        label.text = "Choose A Password"
        label.numberOfLines = 0
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
    
    lazy var finishButton: UIButton = {
        let button = UIButton()
        button.setTitle("Finish", for: .normal)
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
        
        self.title = "Password | 3/3"
        
        self.view.addSubview(titleLabel)
        self.view.addSubview(passwordText)
        self.view.addSubview(finishButton)
        finishButton.addTarget(self, action: #selector(finish(_:)), for: .touchUpInside)

        titleLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        passwordText.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        finishButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.top.equalTo(passwordText.snp.bottom).offset(10)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        passwordText.becomeFirstResponder()
    }
    
    @objc func finish(_ sender: UIButton){
        if validatePassword() {
            signup()
        }
    }
    
    func validatePassword() -> Bool {
        if passwordText.text!.isEmpty {
            self.uiElement.showTextFieldErrorMessage(passwordText, text: "Password required.")
            return false
        }
       return true
    }
    
    func signup() {
        self.startAnimating()
        let user = PFUser()
        user.username = usernameString
        user.password = passwordText.text!
        user.email = emailString
        user["artistName"] = usernameString
        let acl = PFACL()
        acl.hasPublicWriteAccess = true
        acl.hasPublicReadAccess = true
        user.acl = acl
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
}

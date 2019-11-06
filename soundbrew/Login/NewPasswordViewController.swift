//
//  NewPasswordViewController.swift
//  soundbrew
//
//  Created by Dominic Smith on 10/9/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import NVActivityIndicatorView
import SnapKit
import AppCenterAnalytics

class NewPasswordViewController: UIViewController, NVActivityIndicatorViewable {
    let color = Color()
    let uiElement = UIElement()
    var emailString: String!
    var usernameString: String!
    
    lazy var passwordText: UITextField = {
        let localizedPassword = NSLocalizedString("password", comment: "")
        let textField = UITextField()
        textField.font = UIFont(name: uiElement.mainFont, size: 17)
        textField.backgroundColor = .white
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .whileEditing
        textField.isSecureTextEntry = true
        textField.tintColor = color.black()
        textField.textColor = color.black()
        textField.attributedPlaceholder = NSAttributedString(string: localizedPassword,
        attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        return textField
    }()
    
    lazy var finishButton: UIButton = {
        let localizedFinish = NSLocalizedString("finish", comment: "")
        let button = UIButton()
        button.setTitle(localizedFinish, for: .normal)
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
        
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        self.view.addSubview(passwordText)
        self.view.addSubview(finishButton)
        finishButton.addTarget(self, action: #selector(finish(_:)), for: .touchUpInside)
        
        passwordText.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
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
        let localizedPasswordRequired = NSLocalizedString("passwordRequired", comment: "")
        if passwordText.text!.isEmpty {
            self.uiElement.showTextFieldErrorMessage(passwordText, text: localizedPasswordRequired)
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
        user.signUpInBackground{ (succeeded: Bool, error: Error?) -> Void in
            self.stopAnimating()
            if let error = error {
                UIElement().showAlert(self.uiElement.localizedOops, message: error.localizedDescription, target: self)
                
            } else {
                let installation = PFInstallation.current()
                installation?["user"] = PFUser.current()
                installation?["userId"] = PFUser.current()?.objectId
                installation?.saveEventually()
                
                Customer.shared.getCustomer(user.objectId!)
                
                self.uiElement.newRootView("Main", withIdentifier: "tabBar")
            }
        }
    }
}

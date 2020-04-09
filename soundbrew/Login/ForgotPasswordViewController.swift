//
//  ForgotPasswordViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 11/13/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import AppCenterAnalytics

class ForgotPasswordViewController: UIViewController {

    let uiElement = UIElement()
    let color = Color()
    
    lazy var emailInput: UITextField = {
        let textField = UITextField()
        textField.font = UIFont(name: UIElement().mainFont, size: 17)
        textField.backgroundColor = .white
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .whileEditing
        textField.keyboardType = .emailAddress
        textField.placeholder = "Email"
        textField.tintColor = color.black()
        textField.textColor = color.black()
        textField.attributedPlaceholder = NSAttributedString(string: "Email",
        attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        return textField
    }()
    
    lazy var forgotPasswordButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 17)
        button.titleLabel?.textAlignment = .right
        button.setTitle("Reset Password", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.setBackgroundImage(UIImage(named: "background"), for: .normal)
        button.addTarget(self, action: #selector(didPressResetPassword(_:)), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        self.view.addSubview(emailInput)
        self.view.addSubview(forgotPasswordButton)
        
        forgotPasswordButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.centerY.equalTo(self.view)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        emailInput.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(forgotPasswordButton.snp.top).offset(uiElement.bottomOffset)
        }
        emailInput.becomeFirstResponder()
    }
    
    @objc func didPressResetPassword(_ sender: UIButton) {
        let emailText = emailInput.text?.trimmingCharacters(in: .whitespaces).lowercased()
        let blockQuery = PFQuery(className: "_User")
        blockQuery.whereKey("email", equalTo: emailText ?? "")
        blockQuery.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if objects?.count != 0 {
                PFUser.requestPasswordResetForEmail(inBackground: emailText!)
                let localizedStringTitle = NSLocalizedString("checkInboxTitle", comment: "")
                let localizedStringMessage = NSLocalizedString("checkInboxMessage", comment: "")
                let alertController = UIAlertController (title: localizedStringTitle, message: localizedStringMessage, preferredStyle: .alert)
                
                let okayAction = UIAlertAction(title: "Okay", style: .default) { (_) -> Void in
                    self.emailInput.resignFirstResponder()
                    UIElement().goBackToPreviousViewController(self)
                }
                
                alertController.addAction(okayAction)
                self.present(alertController, animated: true, completion: nil)
                
            } else {
                let localizedStringOops = NSLocalizedString("oops", comment: "")
                let localizedStringMessage = NSLocalizedString("resetEmailErrorMessage", comment: "")
                UIElement().showAlert(localizedStringOops, message: "\(localizedStringMessage) \(emailText!)", target: self)
            }
        }
        
        MSAnalytics.trackEvent("Forgot Password View Controller", withProperties: ["Button" : "didPressDoneButton"])
    }
}

//
//  ForgotPasswordViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 11/13/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse

class ForgotPasswordViewController: UIViewController {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(UIElement().mainFont)-Bold", size: 20 )
        label.text = "Enter Email"
        label.textColor = Color().black()
        label.numberOfLines = 0
        return label
    }()
    
    lazy var emailInput: UITextField = {
        let textField = UITextField()
        textField.font = UIFont(name: UIElement().mainFont, size: 17)
        textField.backgroundColor = .white
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .whileEditing
        textField.keyboardType = .emailAddress
        textField.placeholder = "Email"
        return textField
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let doneButton = UIBarButtonItem(title: "Reset Password", style: .plain, target: self, action: #selector(doneAction(_:)))
        self.navigationItem.rightBarButtonItem = doneButton
        
        self.view.addSubview(titleLabel)
        self.view.addSubview(emailInput)
        
        titleLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(100)
            make.left.equalTo(self.view).offset(UIElement().leftOffset)
            make.right.equalTo(self.view).offset(UIElement().rightOffset)
        }
        
        emailInput.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.equalTo(self.view).offset(UIElement().leftOffset)
            make.right.equalTo(self.view).offset(UIElement().rightOffset)
        }
        emailInput.becomeFirstResponder()
    }
    
    @objc func doneAction(_ sender: UIBarButtonItem) {
        let emailText = emailInput.text?.trimmingCharacters(in: .whitespaces).lowercased()
        let blockQuery = PFQuery(className: "_User")
        blockQuery.whereKey("email", equalTo: emailText ?? "")
        blockQuery.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if objects?.count != 0 {
                PFUser.requestPasswordResetForEmail(inBackground: emailText!)
                
                let alertController = UIAlertController (title: "Check Your Inbox (& Spam too)", message: "Click on the link from noreply@soundbrew.app", preferredStyle: .alert)
                
                let okayAction = UIAlertAction(title: "Okay", style: .default) { (_) -> Void in
                    self.emailInput.resignFirstResponder()
                    UIElement().goBackToPreviousViewController(self)
                }
                
                alertController.addAction(okayAction)
                self.present(alertController, animated: true, completion: nil)
                
            } else {
                UIElement().showAlert("Oops", message: "Couldn't find an account associated with \(emailText!)", target: self)
            }
        }
    }
}

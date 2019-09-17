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
        return textField
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        let doneButton = UIBarButtonItem(title: "Reset Password", style: .plain, target: self, action: #selector(doneAction(_:)))
        self.navigationItem.rightBarButtonItem = doneButton
        
        self.view.addSubview(emailInput)
        
        emailInput.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
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

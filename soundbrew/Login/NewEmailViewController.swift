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

class NewEmailViewController: UIViewController, NVActivityIndicatorViewable {
    let color = Color()
    let uiElement = UIElement()
    var authToken: String?
    var authTokenSecret: String?
    var twitterUsername: String?
    var twitterID: String?
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: uiElement.titleLabelFontSize)
        label.text = "What's Your Email?"
        label.textColor = .white 
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
    
    lazy var nextButton: UIButton = {
        let button = UIButton()
        button.setTitle("Next", for: .normal)
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
        
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.didPressCancelButton(_:)))
        self.navigationItem.leftBarButtonItem = cancelButton
        
        if authToken != nil {
            self.title = "Email | 1/2"
        } else {
            self.title = "Email | 1/3"
        }
        
        self.view.addSubview(titleLabel)
        self.view.addSubview(emailText)
        self.view.addSubview(nextButton)
        nextButton.addTarget(self, action: #selector(next(_:)), for: .touchUpInside)
        
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
        
        nextButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.top.equalTo(emailText.snp.bottom).offset(10)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        emailText.becomeFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController = segue.destination as! NewUsernameViewController
        viewController.emailString = emailText.text!
        viewController.authToken = self.authToken
        viewController.authTokenSecret = self.authTokenSecret
        viewController.twitterID = self.twitterID
        viewController.twitterUsername = self.twitterUsername
    }
    
    @objc func next(_ sender: UIButton){
        emailText.text = self.uiElement.cleanUpText(emailText.text!)
        if validateEmail() {
            checkIfEmailExistsThenMoveForward()
        }
    }
    
    //MARK: Validate jaunts
    func validateEmail() -> Bool {
        let emailString : NSString = emailText.text! as NSString
        if emailText.text!.isEmpty || !emailString.contains("@") || !emailString.contains(".") {
            self.uiElement.showTextFieldErrorMessage(self.emailText, text: "Valid email required.")
            return false
        }
        
        return true
    }
    
    func checkIfEmailExistsThenMoveForward() {
        startAnimating()
        let query = PFQuery(className: "_User")
        query.whereKey("email", equalTo: emailText.text!)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            self.stopAnimating()
            if object != nil && error == nil {
                self.uiElement.showTextFieldErrorMessage(self.emailText, text: "Email already in use.")
            
            } else if object == nil {
                self.performSegue(withIdentifier: "showUsername", sender: self)
            }
        }
    }
    
    @objc func didPressCancelButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}

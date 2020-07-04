//
//  NewUsernameViewController.swift
//  soundbrew
//
//  Created by Dominic Smith on 10/9/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import SnapKit
import Kingfisher
import SwiftyJSON

class NewUsernameViewController: UIViewController {
    
    let uiElement = UIElement()
    let color = Color()
    
    var emailString: String!
    
    var usernameText: UITextField!
    var usernameLabel: UILabel!
    var usernameDividerLine: UIView!
    
    lazy var nextButton: UIButton = {
        let localizedNext = NSLocalizedString("next", comment: "")
        let button = UIButton()
        button.setTitle(localizedNext, for: .normal)
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 17)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.textAlignment = .right
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.setBackgroundImage(UIImage(named: "background"), for: .normal)
        button.addTarget(self, action: #selector(next(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var nextSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .white
        spinner.isHidden = true
        return spinner
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        self.view.addSubview(nextButton)
        nextButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.centerY.equalTo(self.view)
        }
        
        self.view.addSubview(self.nextSpinner)
        self.nextSpinner.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(self.uiElement.buttonHeight / 2)
            make.center.equalTo(self.nextButton)
        }

        self.usernameLabel = self.uiElement.soundbrewLabel("Username", textColor: .white, font: UIFont(name: "\(self.uiElement.mainFont)", size: 17)!, numberOfLines: 1)
        self.view.addSubview(self.usernameLabel)
        self.usernameLabel.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(100)
            make.left.equalTo(self.view).offset(self.uiElement.leftOffset)
            make.bottom.equalTo(self.nextButton.snp.top).offset(self.uiElement.bottomOffset * 2)
        }
        
        self.usernameText = self.uiElement.soundbrewTextInput(.default, isSecureTextEntry: false)
        self.view.addSubview(self.usernameText)
        self.usernameText.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.usernameLabel)
            make.left.equalTo(self.usernameLabel.snp.right)
            make.right.equalTo(self.view).offset(self.uiElement.rightOffset)
        }
        
        self.usernameDividerLine = self.uiElement.soundbrewDividerLine()
        self.view.addSubview(self.usernameDividerLine)
        self.usernameDividerLine.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(0.5)
            make.top.equalTo(self.usernameText.snp.bottom)
            make.left.equalTo(self.usernameText)
            make.right.equalTo(self.usernameText)
        }
        
        usernameText.becomeFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController = segue.destination as! NewPasswordViewController
        viewController.emailString = emailString
        viewController.usernameString = usernameText.text!
        
        let localizedPassword = NSLocalizedString("password", comment: "")
        let backItem = UIBarButtonItem()
        backItem.title = "\(localizedPassword) | 3/3"
        navigationItem.backBarButtonItem = backItem
    }
    
    @objc func next(_ sender: UIButton){
        self.usernameText.resignFirstResponder()
        usernameText.text = self.uiElement.cleanUpText(usernameText.text!, shouldLowercaseText: true)
        if validateUsername() {
            checkIfUsernameExistsThenMoveForward()
        }
    }
    
    func validateUsername() -> Bool {
        let localizedInvalidUsername = NSLocalizedString("invalidUsername", comment: "")
        let usernameString : NSString = usernameText.text! as NSString
        if usernameText.text!.isEmpty || usernameString.contains("@") {
            self.uiElement.showTextFieldErrorMessage(self.usernameText, text: localizedInvalidUsername)
            return false
        }
        
        return true
    }
    
    func checkIfUsernameExistsThenMoveForward() {
        self.nextButton.setTitle("", for: .normal)
        self.nextSpinner.startAnimating()
        self.nextSpinner.isHidden = false
        
        let localizedUsernameAlreadyInUse = NSLocalizedString("usernameAlreadyInUse", comment: "")
        let query = PFQuery(className: "_User")
        query.whereKey("username", equalTo: usernameText.text!)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            self.nextSpinner.stopAnimating()
            self.nextSpinner.isHidden = true
            self.nextButton.setTitle("next", for: .normal)
            if object != nil && error == nil {
                self.uiElement.showTextFieldErrorMessage(self.usernameText, text: localizedUsernameAlreadyInUse)
            } else {
                self.performSegue(withIdentifier: "showPassword", sender: self)
            }
        }
    }
    
}

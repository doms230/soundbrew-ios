//
//  UsernameViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 4/11/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import SnapKit
import NVActivityIndicatorView

class NewUsernameViewController: UIViewController, NVActivityIndicatorViewable {
    let uiElement = UIElement()
    let color = Color()
    
    var emailString: String!
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: uiElement.titleLabelFontSize)
        label.text = "Username"
        label.numberOfLines = 0
        return label
    }()
    
    lazy var usernameText: UITextField = {
        let label = UITextField()
        label.placeholder = "Username"
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.backgroundColor = .white
        label.borderStyle = .roundedRect
        label.clearButtonMode = .whileEditing
        label.keyboardType = .emailAddress
        return label
    }()
    
    lazy var nextButton: UIButton = {
        let button = UIButton()
        button.setTitle("next", for: .normal)
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

        self.title = "Username | 2/3"
        
        self.view.addSubview(titleLabel)
        self.view.addSubview(usernameText)
        self.view.addSubview(nextButton)
        nextButton.addTarget(self, action: #selector(next(_:)), for: .touchUpInside)
        
        titleLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        usernameText.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        nextButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.top.equalTo(usernameText.snp.bottom).offset(10)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController = segue.destination as! NewPasswordViewController
        viewController.emailString = emailString
        viewController.usernameString = usernameText.text!
    }
    
    @objc func next(_ sender: UIButton){
        usernameText.text = self.uiElement.cleanUpTextField(usernameText.text!)
        if validateUsername() {
            checkIfUsernameExistsThenMoveForward()
        }
    }
    
    func validateUsername() -> Bool {
        let usernameString : NSString = usernameText.text! as NSString
        if usernameText.text!.isEmpty || usernameString.contains("@") {
            self.uiElement.showTextFieldErrorMessage(self.usernameText, text: "Invalid username.")
            return false
        }
        
        return true
    }
    
    func checkIfUsernameExistsThenMoveForward() {
        startAnimating()
        let query = PFQuery(className: "_User")
        query.whereKey("username", equalTo: usernameText.text!)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            self.stopAnimating()
            if object != nil && error == nil {
                self.uiElement.showTextFieldErrorMessage(self.usernameText, text: "Username already in use.")
                
            } else {
                self.performSegue(withIdentifier: "showPassword", sender: self)
            }
        }
    }
}

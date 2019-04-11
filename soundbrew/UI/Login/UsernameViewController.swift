//
//  UsernameViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 4/11/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit

class UsernameViewController: UIViewController {
    let uiElement = UIElement()
    let color = Color()
    
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

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(titleLabel)
        self.view.addSubview(usernameText)
        self.view.addSubview(signupButton)
        signupButton.addTarget(self, action: #selector(next(_:)), for: .touchUpInside)
        
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
        
        signupButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.top.equalTo(usernameText.snp.bottom).offset(10)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    @objc func next(_ sender: UIButton){
        usernameText.resignFirstResponder()
        /*passwordText.resignFirstResponder()
        
        if validateEmail() && validatePassword(){
            startAnimating()
            signup()
        }*/
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

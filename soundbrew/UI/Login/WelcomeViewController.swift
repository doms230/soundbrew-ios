//
//  WelcomeViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/9/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import SnapKit
//import GoogleSignIn

class WelcomeViewController: UIViewController {
    let color = Color()
    let uiElement = UIElement()
    
    var image: UIImage!
    var retreivedImage: PFFileObject!
    let screenSize: CGRect = UIScreen.main.bounds
    
    lazy var appImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "appy")
        image.layer.cornerRadius = 10
        image.clipsToBounds = true 
        return image
    }()
    
    lazy var appName: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 40)
        label.text = "Soundbrew"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = color.black()
        return label
    }()
    
    lazy var signinButton: UIButton = {
        let button = UIButton()
        button.setTitle("Sign in", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        button.setTitleColor(color.black(), for: .normal)
        button.backgroundColor = color.lightGray()
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    lazy var signupButton: UIButton = {
        let button = UIButton()
        button.setTitle("Sign up", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = color.blue()
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    /*lazy var googleButton: GIDSignInButton = {
        let button = GIDSignInButton()
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .center
        return button
    }()*/
    
    lazy var termsButton: UIButton = {
        let button = UIButton()
        button.setTitle("By continuing, you agree to our terms and privacy policy", for: .normal)
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 11)
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       // GIDSignIn.sharedInstance().uiDelegate = self
        
        self.view.addSubview(appImage)
        self.view.addSubview(appName)
        
        self.view.addSubview(signinButton)
        signinButton.addTarget(self, action: #selector(signInAction(_:)), for: .touchUpInside)
        
        self.view.addSubview(signupButton)
        signupButton.addTarget(self, action: #selector(signupAction(_:)), for: .touchUpInside)
        
       // self.view.addSubview(googleButton)
        
        self.view.addSubview(termsButton)
        termsButton.addTarget(self, action: #selector(termsAction(_:)), for: .touchUpInside)
        
        appImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(100)
            make.top.equalTo((self.view.frame.height / 2) - 200)
            make.left.equalTo((self.view.frame.width / 2) - 50)
        }
        
        appName.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.appImage.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        signinButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.signupButton.snp.top).offset(uiElement.bottomOffset)
        }
        
        signupButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.termsButton.snp.top).offset(uiElement.bottomOffset)
        }
        
        /*googleButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.termsButton.snp.top).offset(-10)
        }*/
        
        termsButton.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.view).offset(-10)
        }
    }
    
    @objc func signInAction(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showSignin", sender: self)
    }
    
    @objc func signupAction(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showSignup", sender: self)
    }
    
    @objc func termsAction(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "https://www.soundbrew.app/privacy" )!, options: [:], completionHandler: nil)
    }
}

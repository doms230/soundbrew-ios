//
//  WelcomeViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/11/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import Parse
import UIKit
import SnapKit
import AppCenterAnalytics

class WelcomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        welcomeView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSignup" {
            let navi = segue.destination as! UINavigationController
            let viewController = navi.topViewController as! NewEmailViewController
            viewController.isLoggingInWithTwitter = isLoggingInWithTwitter
            viewController.isLoggingInWithApple = isLoggingInWithApple
        }
    }
    
    let color = Color()
    let uiElement = UIElement()
    var isLoggingInWithTwitter = false
    var isLoggingInWithApple = false
    
    lazy var backgroundView: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "background")
        return image
    }()
    
    lazy var appView: UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var appImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "appIcon_white")
        image.layer.cornerRadius = 10
        image.clipsToBounds = true
        return image
    }()
    
    lazy var appLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 30)
        label.text = "Soundbrew"
        label.textAlignment = .center
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    lazy var signinWithLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        label.text = "Sign In With:"
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    lazy var signinButton: UIButton = {
        let button = UIButton()
        //button.setTitle("SIGN IN", for: .normal)
        let localizedSignin = NSLocalizedString("signin", comment: "")
        button.setTitle(localizedSignin, for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        button.setTitleColor(.white, for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(self.didPressSigninButton(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var signupButton: UIButton = {
        let button = UIButton()
        let localizedSignup = NSLocalizedString("signup", comment: "")
        button.setTitle(localizedSignup, for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        button.setTitleColor(color.black(), for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(self.didPressSignupButton(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var loginInWithTwitterButton: UIButton = {
        let button = UIButton()
        let localizedtwitter = NSLocalizedString("twitter", comment: "")
        button.setTitle(localizedtwitter, for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = color.uicolorFromHex(0x1DA1F2)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(didPressLoginWithTwitterButton(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var twitter: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "twitter")
        return image
    }()
    
    lazy var termsButton: UIButton = {
        let button = UIButton()
        let localizedTerms = NSLocalizedString("terms", comment: "")
        button.setTitle(localizedTerms, for: .normal)
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 11)
        button.titleLabel?.numberOfLines = 0
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(didPressTermsButton(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var skipButton: UIButton = {
        let button = UIButton()
        let localizedSkip = NSLocalizedString("skip", comment: "")
        button.setTitle(localizedSkip, for: .normal)
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 15)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(didPressSkipButton(_:)), for: .touchUpInside)
        return button
    }()
    
    func welcomeView() {
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        
        self.view.addSubview(backgroundView)
        backgroundView.frame = view.bounds
        
        self.view.addSubview(appImage)
        self.view.addSubview(appLabel)
        
        self.view.addSubview(signinWithLabel)
        
        self.view.addSubview(skipButton)
        self.view.addSubview(signinButton)
        self.view.addSubview(signupButton)
        self.view.addSubview(loginInWithTwitterButton)
        loginInWithTwitterButton.addSubview(twitter)
        self.view.addSubview(termsButton)
        
        appLabel.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.view).offset(uiElement.bottomOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        appImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(150)
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(appLabel.snp.top)
        }
        
        skipButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(signupButton.snp.top).offset(uiElement.bottomOffset)
        }
        
        signupButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(loginInWithTwitterButton.snp.top).offset(uiElement.bottomOffset * 2)
        }
        
        loginInWithTwitterButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(signinButton.snp.top).offset(uiElement.bottomOffset * 2)
        }
        twitter.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(50)
            make.top.equalTo(loginInWithTwitterButton)
            make.left.equalTo(loginInWithTwitterButton)
            make.bottom.equalTo(loginInWithTwitterButton)
        }
        
        signinButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(termsButton.snp.top).offset(uiElement.bottomOffset)
        }
        
        termsButton.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.view).offset(uiElement.bottomOffset)
        }
    }
    
    @objc func didPressSkipButton(_ sender: UIButton) {
        self.uiElement.newRootView("Main", withIdentifier: "tabBar")
    }
    
    @objc func didPressSigninButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showSignin", sender: self)
        MSAnalytics.trackEvent("Welcome View Controller", withProperties: ["Button" : "Sign In Button", "description": "User pressed Sign in button"])
    }
    
    @objc func didPressSignupButton(_ sender: UIButton) {
        isLoggingInWithTwitter = false
        self.performSegue(withIdentifier: "showSignup", sender: self)
        MSAnalytics.trackEvent("Welcome View Controller", withProperties: ["Button" : "Sign Up", "description": "user pressed sign up button"])
    }
    
    @objc func didPressTermsButton(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "https://www.soundbrew.app/privacy" )!, options: [:], completionHandler: nil)
        MSAnalytics.trackEvent("Welcome View Controller", withProperties: ["Button" : "Terms Button", "description": "user pressed terms button"])
    }
    
    @objc func didPressLoginWithTwitterButton(_ sender: UIButton) {
        isLoggingInWithApple = false
        isLoggingInWithTwitter = true
        self.performSegue(withIdentifier: "showSignup", sender: self)
        MSAnalytics.trackEvent("Welcome View Controller", withProperties: ["Button" : "Twitter Button", "description": "user pressed twitter button"])
    }
}

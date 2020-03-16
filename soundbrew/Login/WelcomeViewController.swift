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
import OnboardKit

class WelcomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showWelcomeView()
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
    
    func signInWithButton(_ title: String, titleColor: UIColor, backgroundColor: UIColor, imageName: String?, tag: Int, shouldShowBorderColor: Bool) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        button.setTitleColor(titleColor, for: .normal)
        button.backgroundColor = backgroundColor
        if shouldShowBorderColor {
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.white.cgColor
        }
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.tag = tag
        button.addTarget(self, action: #selector(self.didPressButton(_:)), for: .touchUpInside)
        
        if let imageName = imageName {
            let image = UIImageView()
            image.frame = CGRect(x: 10, y: 10, width: 35, height: 35)
            image.image = UIImage(named: imageName)
            button.addSubview(image)
        }
        
        return button
    }
    
    func showWelcomeView() {
        let titleFont = UIFont(name: "\(uiElement.mainFont)-bold", size: 40)!
        let descriptionFont = UIFont(name: "\(uiElement.mainFont)", size: 25)!
        
        let likePage = newOnboardPage("Support", imageName: "onboardLike", description: "Directly pay artists for their music everytime you 'like' a song.")
        
        let connectPage = newOnboardPage("Connect", imageName: "onboardConnect", description: "Keep up with your favorite artists' uploads and likes. Chat in the comments.")
        
        let discoverPage = newOnboardPage("Discover", imageName: "onboardDiscover", description: "Discover music & audio from different cities, moods, and activities.")
        
        let createPage = newOnboardPage("Create", imageName: "onboardCreate", description: "Upload and tag your music straight from the app. Credit other artists and collaborators, then choose their payment splits.")
        
        let appearance = OnboardViewController.AppearanceConfiguration(tintColor: .white, titleColor: .white, textColor: .white, backgroundColor: .black, imageContentMode: .scaleAspectFit, titleFont: titleFont, textFont: descriptionFont)
        
        let onboardingViewController = OnboardViewController(pageItems: [likePage, connectPage, discoverPage, createPage],
        appearanceConfiguration: appearance)
        
        onboardingViewController.presentFrom(self, animated: true)
    }
    
    func newOnboardPage(_ title: String, imageName: String, description: String) -> OnboardPage {
        let page = OnboardPage(title: title,
        imageName: imageName,
        description: description)
        return page
    }
    
    func signupView() {
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        
        self.view.addSubview(backgroundView)
        backgroundView.frame = view.bounds
        
        self.view.addSubview(appImage)
        self.view.addSubview(appLabel)
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
        
        let signupButton = signInWithButton("Sign Up", titleColor: .white, backgroundColor: .clear, imageName: nil, tag: 0, shouldShowBorderColor: true)
        self.view.addSubview(signupButton)
        signupButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(termsButton.snp.top).offset(uiElement.bottomOffset)
        }
        
        let twitterButton = signInWithButton("Twitter", titleColor: .white, backgroundColor: color.uicolorFromHex(0x1DA1F2), imageName: "twitter", tag: 1, shouldShowBorderColor: false)
        self.view.addSubview(twitterButton)
        twitterButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(signupButton.snp.top).offset(uiElement.bottomOffset * 2)
        }
        
        /*let appleButton = signInWithButton("Apple", titleColor: .white, backgroundColor: .black, imageName: "appleLogo", tag: 2, shouldShowBorderColor: false)
        self.view.addSubview(appleButton)
        appleButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(twitterButton.snp.top).offset(uiElement.bottomOffset * 2)
        }*/
        
        let signInButton = signInWithButton("Sign In", titleColor: .white, backgroundColor: .clear, imageName: nil, tag: 3, shouldShowBorderColor: false)
        self.view.addSubview(signInButton)
        signInButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(twitterButton.snp.top).offset(uiElement.bottomOffset)
        }
        
        termsButton.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.view).offset(uiElement.bottomOffset)
        }
    }
    
    @objc func didPressButton(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            isLoggingInWithTwitter = false
            isLoggingInWithApple = false
            self.performSegue(withIdentifier: "showSignup", sender: self)
            MSAnalytics.trackEvent("Welcome View Controller", withProperties: ["Button" : "Sign Up", "description": "user pressed sign up button"])
            break
            
        case 1:
            isLoggingInWithApple = false
            isLoggingInWithTwitter = true
            self.performSegue(withIdentifier: "showSignup", sender: self)
            MSAnalytics.trackEvent("Welcome View Controller", withProperties: ["Button" : "Twitter Button", "description": "user pressed twitter button"])
            break
            
        case 2:
            if #available(iOS 13.0, *) {
                isLoggingInWithApple = true
                isLoggingInWithTwitter = false
                self.performSegue(withIdentifier: "showSignup", sender: self)
                
            } else {
                self.uiElement.showAlert("Un-Available", message: "Sign in with Apple is only available on iOS 13 or newer.", target: self)
            }
            break
            
        case 3:
            self.performSegue(withIdentifier: "showSignin", sender: self)
            MSAnalytics.trackEvent("Welcome View Controller", withProperties: ["Button" : "Sign In Button", "description": "User pressed Sign in button"])
            break
            
        default:
            break
        }
    }
    
    @objc func didPressTermsButton(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "https://www.soundbrew.app/privacy" )!, options: [:], completionHandler: nil)
        MSAnalytics.trackEvent("Welcome View Controller", withProperties: ["Button" : "Terms Button", "description": "user pressed terms button"])
    }
    
    @objc func didPressLearnMoreButton(_ sender: UIButton) {
        showWelcomeView()
    }
}

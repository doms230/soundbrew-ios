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
import GoogleSignIn
import AuthenticationServices

class WelcomeViewController: UIViewController, GIDSignInDelegate, ASAuthorizationControllerDelegate {
    
    var loginType: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        signupView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSignup" {
            let navi = segue.destination as! UINavigationController
            let viewController = navi.topViewController as! NewEmailViewController
            viewController.loginType = self.loginType
            viewController.googleEmail = self.googleEmail
            viewController.googleName = self.googleName
            viewController.googleImage = self.googleImage
            viewController.googleAuthData = self.googleAuthData
            
            viewController.appleEmail = self.appleEmail
            viewController.appleName = self.appleName
            viewController.appleAuthData = self.appleAuthData
        }
    }
    
    let color = Color()
    let uiElement = UIElement()
    
    lazy var backgroundView: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "welcomeImage")
        image.contentMode = .scaleAspectFill
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
        let label = self.uiElement.soundbrewLabel("Soundbrew", textColor: .white, font: UIFont(name: "\(uiElement.mainFont)-bold", size: 20)!, numberOfLines: 0)
        label.textAlignment = .center
        return label
    }()
    
    lazy var appDescription: UILabel = {
        let label = self.uiElement.soundbrewLabel("Where Artists & Creators Get Paid", textColor: .white, font: UIFont(name: "\(uiElement.mainFont)", size: 17)!, numberOfLines: 0)
        label.textAlignment = .center
        return label
    }()
    
    lazy var termsButton: UIButton = {
        let localizedTerms = NSLocalizedString("terms", comment: "")
        let button = self.uiElement.soundbrewButton(localizedTerms, shouldShowBorder: false, backgroundColor: .clear, image: nil, titleFont: UIFont(name: uiElement.mainFont, size: 11), titleColor: .white, cornerRadius: nil)
        button.addTarget(self, action: #selector(didPressTermsButton(_:)), for: .touchUpInside)
        return button
    }()
    
    func signInWithButton(_ title: String, titleColor: UIColor, backgroundColor: UIColor, imageName: String?, tag: Int, shouldShowBorderColor: Bool) -> UIButton {
        let button = UIButton()
        self.view.addSubview(button)
        let label = UILabel()
        label.text = title
        label.font = UIFont(name: "system-bold", size: 20)
        label.textColor = titleColor
        button.addSubview(label)
        label.snp.makeConstraints { (make) -> Void in
            make.center.equalTo(button)
        }
        
        if let imageName = imageName {
            let image = UIImageView()
            image.image = UIImage(named: imageName)
            button.addSubview(image)
            image.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(20)
                make.centerY.equalTo(label)
                make.right.equalTo(label.snp.left).offset(uiElement.rightOffset)
            }
        }
        
        button.backgroundColor = backgroundColor
        if shouldShowBorderColor {
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.white.cgColor
        }
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        button.tag = tag
        button.addTarget(self, action: #selector(self.didPressButton(_:)), for: .touchUpInside)
        
        return button
    }
    
    func signupView() {
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
    
        self.view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.height.equalTo((self.view.frame.height / 2) - 50)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
        }
        
        self.view.addSubview(appLabel)
        appLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(backgroundView.snp.bottom).offset(uiElement.topOffset * 3)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(appDescription)
        appDescription.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(appLabel.snp.bottom)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        
        let googleButton = signInWithButton("Sign in with Google", titleColor: .white, backgroundColor: self.color.uicolorFromHex(0x4285F4), imageName: "google", tag: 3, shouldShowBorderColor: false)
        googleButton.titleLabel?.textAlignment = .center
        self.view.addSubview(googleButton)
        googleButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.top.equalTo(appDescription.snp.bottom).offset(uiElement.topOffset * 3)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
                
        let emailButton = signInWithButton("Sign in with Soundbrew", titleColor: .white, backgroundColor: .black, imageName: "appIcon_white", tag: 0, shouldShowBorderColor: true)
        emailButton.titleLabel?.textAlignment = .center
        self.view.addSubview(emailButton)
        emailButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.top.equalTo(googleButton.snp.bottom).offset(uiElement.topOffset * 2)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        if #available(iOS 13.0, *) {
            let appleButton = ASAuthorizationAppleIDButton(authorizationButtonType: .default, authorizationButtonStyle: .white)
            appleButton.addTarget(self, action: #selector(diPressAppleButton(_:)), for: .touchUpInside)
            self.view.addSubview(appleButton)
            appleButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(50)
                make.top.equalTo(emailButton.snp.bottom).offset(uiElement.topOffset * 2)
                make.left.equalTo(self.view).offset(uiElement.leftOffset)
                make.right.equalTo(self.view).offset(uiElement.rightOffset)
            }
        }
        
        self.view.addSubview(termsButton)
        termsButton.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.view).offset(uiElement.bottomOffset)
        }
    }
    
    @available(iOS 13.0, *)
    @objc func diPressAppleButton(_ sender: ASAuthorizationAppleIDButton) {
        self.loginType = "apple"
        self.loginWithApple()
    }
    
    @objc func didPressButton(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            self.performSegue(withIdentifier: "showSignin", sender: self)
            break
            
       /* case 1:
            if #available(iOS 13.0, *) {
                self.loginType = "apple"
                self.loginWithApple()
                
            } else {
                self.uiElement.showAlert("Un-Available", message: "Sign in with Apple is only available on iOS 13 or newer.", target: self)
            }
            break*/
            
        case 3:
            self.loginType = "google"
            GIDSignIn.sharedInstance()?.presentingViewController = self
            GIDSignIn.sharedInstance().delegate = self
            GIDSignIn.sharedInstance().signIn()
            break
            
        default:
            break
        }
    }
    
    @objc func didPressTermsButton(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "https://www.soundbrew.app/privacy" )!, options: [:], completionHandler: nil)
    }
    
    //Mark: Google
    var googleEmail: String!
    var googleName: String?
    var googleImage: URL?
    var googleAuthData: [String: String]!
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
      if error != nil {
     //   self.uiElement.showAlert("Error", message: error.localizedDescription, target: self)
        return
      }
        if let userId = user.userID, let idToken = user.authentication.idToken {
            let authData = ["id": "\(userId)", "id_token": "\(idToken)"]
            self.googleAuthData = authData
            self.googleName = user.profile.givenName
            self.googleEmail = user.profile.email
            self.googleImage = user.profile.imageURL(withDimension: 500)
            self.dismiss(animated: true, completion: {() in
                self.performSegue(withIdentifier: "showSignup", sender: self)
            })
        }
    }
    
    //MARK: Apple
    var appleEmail: String?
    var appleName: String?
    var appleAuthData: [String: String]!
    
    func loginWithApple() {
        if #available(iOS 13.0, *) {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
    }
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            let appleID = appleIDCredential.user
            let appleToken = String(data: appleIDCredential.identityToken!, encoding: .utf8)
            appleAuthData = ["id": "\(appleID)", "token": "\(appleToken ?? "nil")"]
            if let name = appleIDCredential.fullName?.givenName {
                self.appleName = name
            }
            
            if let email = appleIDCredential.email {
                self.appleEmail = email
                self.uiElement.setUserDefault(email, key: "appleEmail")
            } else if let appleEmail = self.uiElement.getUserDefault("appleEmail") as? String {
                self.appleEmail = appleEmail
            }
                        
            self.dismiss(animated: true, completion: {() in
                self.performSegue(withIdentifier: "showSignup", sender: self)
            })
            break
        default:
            break
        }
    }
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print(error)
        self.dismiss(animated: true, completion: nil)
    }
}

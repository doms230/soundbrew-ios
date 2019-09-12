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
import TwitterKit

class WelcomeViewController: UIViewController, PFUserAuthenticationDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        welcomeView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
            
        case "showSignup":
            let backItem = UIBarButtonItem()
            backItem.title = "Sign up"
            navigationItem.backBarButtonItem = backItem
            
           let navi = segue.destination as! UINavigationController
            let viewController = navi.topViewController as! NewEmailViewController
            
            viewController.authToken = authToken
            viewController.authTokenSecret = authTokenSecret
            viewController.twitterUsername = twitterUsername
            viewController.twitterID = twitterID
            break
            
        case "showSignin":
            let backItem = UIBarButtonItem()
            backItem.title = "Sign In"
            navigationItem.backBarButtonItem = backItem
            break
            
        default:
            break
        }
    }
    
    func restoreAuthentication(withAuthData authData: [String : String]?) -> Bool {
        return true
    }
    
    let color = Color()
    let uiElement = UIElement()
    
    var authToken: String?
    var authTokenSecret: String?
    var twitterUsername: String?
    var twitterID: String?
    
    lazy var appImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "appy")
        image.layer.cornerRadius = 10
        image.clipsToBounds = true
        return image
    }()
    
    lazy var appName: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        label.text = "Soundbrew Artists"
        label.numberOfLines = 0
        label.textColor = .white
        //label.textAlignment = .center
        return label
    }()
    
    lazy var signinButton: UIButton = {
        let button = UIButton()
        button.setTitle("Sign In", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
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
        button.setTitle("Sign Up", for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        button.setTitleColor(.white, for: .normal)
        button.setBackgroundImage(UIImage(named: "background"), for: .normal)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(self.didPressSignupButton(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var loginInWithTwitterButton: UIButton = {
        let button = UIButton()
        button.setTitle("Login with Twitter", for: .normal)
        // button.setImage(UIImage(named: "twitter"), for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = color.uicolorFromHex(0x1DA1F2)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(didPressLoginWithTwitterButton), for: .touchUpInside)
        return button
    }()
    
    lazy var twitter: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "twitter")
        return image
    }()
    
    lazy var termsButton: UIButton = {
        let button = UIButton()
        button.setTitle("By continuing, you agree to our terms and privacy policy", for: .normal)
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 11)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(didPressTermsButton(_:)), for: .touchUpInside)
        return button
    }()
    
    func welcomeView() {
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        
        self.view.addSubview(appName)
        self.view.addSubview(appImage)
        self.view.addSubview(signinButton)
        self.view.addSubview(signupButton)
        self.view.addSubview(loginInWithTwitterButton)
        loginInWithTwitterButton.addSubview(twitter)
        self.view.addSubview(termsButton)
        
        appImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(50)
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        appName.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(appImage)
            make.left.equalTo(appImage.snp.right).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        signinButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(signupButton.snp.top).offset(uiElement.bottomOffset * 2)
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
             make.bottom.equalTo(termsButton.snp.top).offset(uiElement.bottomOffset)
        }
        twitter.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(50)
            make.top.equalTo(loginInWithTwitterButton)
            make.left.equalTo(loginInWithTwitterButton)
            make.bottom.equalTo(loginInWithTwitterButton)
        }
        
        termsButton.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.view).offset(-10)
        }
    }
    
    @objc func didPressSigninButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showSignin", sender: self)
    }
    
    @objc func didPressSignupButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showSignup", sender: self)
    }
    
    @objc func didPressTermsButton(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "https://www.soundbrew.app/privacy" )!, options: [:], completionHandler: nil)
    }
    
    @objc func didPressLoginWithTwitterButton() {
        let store = TWTRTwitter.sharedInstance().sessionStore
        if let session = store.session() {
            store.logOutUserID(session.userID)
        }
        
        TWTRTwitter.sharedInstance().logIn(completion: { (session, error) in
            if let session = session {
                self.checkIfUserExists(session.userID, authToken: session.authToken, authTokenSecret: session.authTokenSecret, username: session.userName)
                
            } else if let error = error {
                print("error: \(error.localizedDescription)");
                //sender.isOn = false
            }
        })
    }
    
    func checkIfUserExists(_ userID: String, authToken: String, authTokenSecret: String, username: String?) {
        let query = PFQuery(className: "_User")
        query.whereKey("twitterID", equalTo: userID)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if object != nil && error == nil {
                self.PFauthenticateWithTwitter(userID, auth_token: authToken, auth_token_secret: authTokenSecret, username: username)
            } else {
                self.twitterID = userID
                self.authToken = authToken
                self.authTokenSecret = authTokenSecret
                self.twitterUsername = username
                self.performSegue(withIdentifier: "showSignup", sender: self)
            }
        }
    }
    
    func PFauthenticateWithTwitter(_ userId: String, auth_token: String, auth_token_secret: String, username: String?) {
        
        PFUser.logInWithAuthType(inBackground: "twitter", authData: ["id": userId, "auth_token": auth_token, "consumer_key": "shY1N1YKquAcxJF9YtdFzm6N3", "consumer_secret": "dFzxXdA0IM9A7NsY3JzuPeWZhrIVnQXiWFoTgUoPVm0A2d1lU1", "auth_token_secret": auth_token_secret ]).continueOnSuccessWith(block: {
            (ignored: BFTask!) -> AnyObject? in
            
            let parseUser = PFUser.current()
            let installation = PFInstallation.current()
            installation?["user"] = parseUser
            installation?["userId"] = parseUser?.objectId
            installation?.saveEventually()
            
            Customer.shared.getCustomer(parseUser!.objectId!)
            self.uiElement.segueToView("Main", withIdentifier: "tabBar", target: self)
            return AnyObject.self as AnyObject
        })
    }
}

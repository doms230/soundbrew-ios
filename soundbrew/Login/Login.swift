//
//  Login.swift
//  soundbrew
//
//  Created by Dominic  Smith on 8/19/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import Foundation
import Parse
import UIKit
import SnapKit
import TwitterKit

class Login: NSObject, PFUserAuthenticationDelegate {
    //see https://stackoverflow.com/questions/37255006/how-to-authenticate-a-user-in-parse-ios-sdk-using-oauth

    func restoreAuthentication(withAuthData authData: [String : String]?) -> Bool {
        return true
    }
    
    let color = Color()
    let uiElement = UIElement()
    
    var target: UIViewController!
    var authToken: String?
    var authTokenSecret: String?
    var twitterUsername: String?
    var twitterID: String?
    
    init(target: UIViewController) {
        self.target = target
    }
    
    lazy var explanationImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "home_color")
        image.layer.cornerRadius = 10
        image.clipsToBounds = true
        return image
    }()
    
    lazy var explanationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        label.text = "The latest uploads from artists you follow will appear here!"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .white
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
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    func welcomeView(explanationString: String, explanationImageString: String) {
        target.view.addSubview(explanationLabel)
        target.view.addSubview(explanationImage)
        
        target.view.addSubview(signinButton)
        
        target.view.addSubview(signupButton)
        
        target.view.addSubview(loginInWithTwitterButton)
        loginInWithTwitterButton.addSubview(twitter)
        
        target.view.addSubview(termsButton)
        
        termsButton.addTarget(target, action: #selector(termsAction(_:)), for: .touchUpInside)
        
        explanationImage.image = UIImage(named: explanationImageString)
        explanationImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(200)
            make.top.equalTo(target.view).offset(uiElement.uiViewTopOffset(target))
            make.centerX.equalTo(target.view)
        }
        
        explanationLabel.text = explanationString
        explanationLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(explanationImage.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(target.view).offset(uiElement.leftOffset)
            make.right.equalTo(target.view).offset(uiElement.rightOffset)
        }
        
        signinButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.top.equalTo(explanationLabel.snp.bottom).offset(uiElement.topOffset * 2)
            make.left.equalTo(target.view).offset(uiElement.leftOffset)
            make.right.equalTo(target.view).offset(uiElement.rightOffset)
            //make.bottom.equalTo(signupButton.snp.top).offset(uiElement.bottomOffset)
        }
        
        signupButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.top.equalTo(signinButton.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(target.view).offset(uiElement.leftOffset)
            make.right.equalTo(target.view).offset(uiElement.rightOffset)
           // make.bottom.equalTo(termsButton.snp.top).offset(uiElement.bottomOffset)
        }
        
        loginInWithTwitterButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.top.equalTo(signupButton.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(target.view).offset(uiElement.leftOffset)
            make.right.equalTo(target.view).offset(uiElement.rightOffset)
            // make.bottom.equalTo(termsButton.snp.top).offset(uiElement.bottomOffset)
        }
        twitter.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(50)
            make.top.equalTo(loginInWithTwitterButton)
            make.left.equalTo(loginInWithTwitterButton)
            make.bottom.equalTo(loginInWithTwitterButton)
        }
        
        termsButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(loginInWithTwitterButton.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(target.view).offset(uiElement.leftOffset)
            make.right.equalTo(target.view).offset(uiElement.rightOffset)
            //make.bottom.equalTo(target.view).offset(-10)
        }
    }
    
    func signInAction() {
        target.performSegue(withIdentifier: "showSignin", sender: target)
    }
    
    func signupAction() {
        target.performSegue(withIdentifier: "showSignup", sender: target)
    }
    
    func loginWithTwitterAction() {
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
                self.target.performSegue(withIdentifier: "showSignup", sender: self.target)
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
            print("asdfasdfasd")
            return AnyObject.self as AnyObject
        })
    }
    
    @objc func termsAction(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "https://www.soundbrew.app/privacy" )!, options: [:], completionHandler: nil)
    }
}

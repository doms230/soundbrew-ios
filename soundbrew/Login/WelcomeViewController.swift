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

class WelcomeViewController: UIViewController {
    func restoreAuthentication(withAuthData authData: [String : String]?) -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance()?.presentingViewController = self
        signupView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSignup" {
            let navi = segue.destination as! UINavigationController
            let viewController = navi.topViewController as! NewEmailViewController
            viewController.isLoggingInWithApple = isLoggingInWithApple
        }
    }
    
    let color = Color()
    let uiElement = UIElement()
    var isLoggingInWithApple = false
    
    lazy var backgroundView: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "welcomeImage")
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
        let label = self.uiElement.soundbrewLabel("Where Creators Get Paid", textColor: .white, font: UIFont(name: "\(uiElement.mainFont)", size: 15)!, numberOfLines: 0)
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
        
        if let imageName = imageName {
            let image = UIImageView(frame: CGRect(x: 10, y: 5, width: 40, height: 40))
            image.image = UIImage(named: imageName)
            button.addSubview(image)
        }
        
        let label = UILabel(frame: CGRect(x: 55, y: 5, width: 200, height: 40))
        label.text = title
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        label.textColor = titleColor
        button.addSubview(label)

        button.backgroundColor = backgroundColor
        if shouldShowBorderColor {
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.white.cgColor
        }
        button.layer.cornerRadius = 3
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
        backgroundView.frame = view.bounds
        
        self.view.addSubview(appImage)
        appImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(50)
            //make.centerY.equalTo(self.view)
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self) * 5)
        }
        
        self.view.addSubview(appLabel)
        appLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(appImage.snp.bottom)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(appDescription)
        appDescription.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(appLabel.snp.bottom)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(termsButton)
        termsButton.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.view).offset(uiElement.bottomOffset)
        }
        
        let signupButton = signInWithButton("Sign in with Email", titleColor: .black, backgroundColor: .white, imageName: "email", tag: 0, shouldShowBorderColor: false)
        self.view.addSubview(signupButton)
        signupButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(termsButton.snp.top).offset(uiElement.bottomOffset)
        }
        
        let googleButton = signInWithButton("Sign in with Google", titleColor: .white, backgroundColor: self.color.uicolorFromHex(0x4285F4), imageName: "google", tag: 3, shouldShowBorderColor: false)
        self.view.addSubview(googleButton)
        googleButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.bottom.equalTo(signupButton.snp.top).offset(uiElement.bottomOffset)
        }
        
        let appleButton = signInWithButton("Sign in with Apple", titleColor: .white, backgroundColor: .black, imageName: "appleLogo", tag: 1, shouldShowBorderColor: false)
        appleButton.titleLabel?.textAlignment = .left
        self.view.addSubview(appleButton)
        appleButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(googleButton.snp.top).offset(uiElement.bottomOffset)
        }
    }
    
    @objc func didPressButton(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            showSignInWithEmailOption()
            break
            
        case 1:
            if #available(iOS 13.0, *) {
                isLoggingInWithApple = true
                self.performSegue(withIdentifier: "showSignup", sender: self)
                
            } else {
                self.uiElement.showAlert("Un-Available", message: "Sign in with Apple is only available on iOS 13 or newer.", target: self)
            }
            break
            
        case 3:
            GIDSignIn.sharedInstance().signIn()
            break
            
        default:
            break
        }
    }
    
    func showSignInWithEmailOption() {
        let alertController = UIAlertController (title: "I am" , message: "", preferredStyle: .actionSheet)
        
        let newToSoundbrewAction = UIAlertAction(title: "New to Soundbrew", style: .default) { (_) -> Void in
            self.isLoggingInWithApple = false
            self.performSegue(withIdentifier: "showSignup", sender: self)
        }
        alertController.addAction(newToSoundbrewAction)
        
        let returningToSoundbrewAction = UIAlertAction(title: "Returning to Soundbrew", style: .default) { (_) -> Void in
            self.performSegue(withIdentifier: "showSignin", sender: self)
        }
        alertController.addAction(returningToSoundbrewAction)
        
        let localizedCancel = NSLocalizedString("cancel", comment: "")
        let cancelAction = UIAlertAction(title: localizedCancel, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func didPressTermsButton(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "https://www.soundbrew.app/privacy" )!, options: [:], completionHandler: nil)
    }
}

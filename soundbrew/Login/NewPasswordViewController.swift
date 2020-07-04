//
//  NewPasswordViewController.swift
//  soundbrew
//
//  Created by Dominic Smith on 10/9/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import SnapKit

class NewPasswordViewController: UIViewController, ArtistDelegate {
    let color = Color()
    let uiElement = UIElement()
    var emailString: String!
    var usernameString: String!
    
    var passwordText: UITextField!
    var passwordLabel: UILabel!
    var passwordDividerLine: UIView!
    
    lazy var finishButton: UIButton = {
        let localizedFinish = NSLocalizedString("finish", comment: "")
        let button = UIButton()
        button.setTitle(localizedFinish, for: .normal)
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 17)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.textAlignment = .right
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.setBackgroundImage(UIImage(named: "background"), for: .normal)
        button.addTarget(self, action: #selector(finish(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var finishSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .white
        spinner.isHidden = true
        return spinner
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        self.view.addSubview(finishButton)
        finishButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.centerY.equalTo(self.view)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(finishSpinner)
        finishSpinner.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(uiElement.buttonHeight / 2)
            make.center.equalTo(finishButton)
        }
        
        self.passwordLabel = self.uiElement.soundbrewLabel("Password", textColor: .white, font: UIFont(name: "\(self.uiElement.mainFont)", size: 17)!, numberOfLines: 1)
        self.view.addSubview(self.passwordLabel)
        self.passwordLabel.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(100)
            make.left.equalTo(self.view).offset(self.uiElement.leftOffset)
            make.bottom.equalTo(self.finishButton.snp.top).offset(self.uiElement.bottomOffset * 2)
        }
        
        self.passwordText = self.uiElement.soundbrewTextInput(.default, isSecureTextEntry: true)
        self.view.addSubview(self.passwordText)
        self.passwordText.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.passwordLabel)
            make.left.equalTo(self.passwordLabel.snp.right)
            make.right.equalTo(self.view).offset(self.uiElement.rightOffset)
        }
        
        self.passwordDividerLine = self.uiElement.soundbrewDividerLine()
        self.view.addSubview(self.passwordDividerLine)
        self.passwordDividerLine.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(0.5)
            make.top.equalTo(self.passwordText.snp.bottom)
            make.left.equalTo(self.passwordText)
            make.right.equalTo(self.passwordText)
        }
        
        passwordText.becomeFirstResponder()
    }
    
    @objc func finish(_ sender: UIButton){
        if validatePassword() {
            signup()
        }
    }
    
    func validatePassword() -> Bool {
        let localizedPasswordRequired = NSLocalizedString("passwordRequired", comment: "")
        if passwordText.text!.isEmpty {
            self.uiElement.showTextFieldErrorMessage(passwordText, text: localizedPasswordRequired)
            return false
        }
       return true
    }
    
    func signup() {
        self.finishButton.setTitle("", for: .normal)
        self.finishSpinner.startAnimating()
        self.finishButton.isHidden = false
        self.resignFirstResponder()
        let user = PFUser()
        user.username = usernameString
        user.password = passwordText.text!
        user.email = emailString
        user["artistName"] = usernameString
        user.signUpInBackground{ (succeeded: Bool, error: Error?) -> Void in
            self.finishSpinner.stopAnimating()
            self.finishSpinner.isHidden = true
            self.finishButton.setTitle("FINISH", for: .normal)
            if let error = error {
                UIElement().showAlert(self.uiElement.localizedOops, message: error.localizedDescription, target: self)
            } else {
                let installation = PFInstallation.current()
                installation?["user"] = PFUser.current()
                installation?["userId"] = PFUser.current()?.objectId
                installation?.saveEventually()
                let artist = self.uiElement.newArtistObject(user)
                self.saveNewArtistInfo(artist)
            }
        }
    }
    
    func saveNewArtistInfo(_ artist: Artist) {
        let locale = Locale.current
        if let currencySymbol = locale.currencySymbol, let currencyCode = locale.currencyCode {
            Customer.shared.currencySymbol = currencySymbol
            Customer.shared.currencySymbol = currencyCode.lowercased()
        } else {
            Customer.shared.currencySymbol = "$"
            Customer.shared.currencySymbol = "usd"
        }
        
        Customer.shared.artist = artist
        
        DispatchQueue.main.async {
            let modal = EditProfileViewController()
            modal.artistDelegate = self
            self.present(modal, animated: true, completion: nil)
        }
    }
    
    func changeBio(_ value: String?) {
    }
    
    func receivedArtist(_ value: Artist?) {
        PFUser.logOut()
        showAlertThenDismiss()
    }
    
    func showAlertThenDismiss() {
        let alertController = UIAlertController (title: "Email Verification Required" , message: "Your account has been created, but we need to verify your email is real and belongs to you. Check your email and tap the link from noreply@soundbrew.app. Check your spam folder too!", preferredStyle: .alert)
        
        let okayAction = UIAlertAction(title: "Okay", style: .default) { (_) -> Void in
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(okayAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}

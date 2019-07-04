//
//  DetailEditInfoViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 3/5/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit

class EditBioViewController: UIViewController, UITextViewDelegate {
    
    let uiElement = UIElement()
    var artistDelegate: ArtistDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpDoneButton()
        
        if let bio = self.bio {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardWillShow),
                name: UIResponder.keyboardWillShowNotification,
                object: nil
            )
            
            setupBioView(bio)
            
        } else if let email = self.email {
            setupEmailView(email)
        }
    }
    
    //done
    func setUpDoneButton() {
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(didPressDoneButton(_:)))
        self.navigationItem.rightBarButtonItem = doneButton
    }
    
    @objc func didPressDoneButton(_ sender: UIButton) {
        if let artistDelegate = self.artistDelegate {
            artistDelegate.changeBio(inputBio.text)
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    //bio
    var bio: String?
    
    lazy var bioCount: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = .lightGray
        return label
    }()
    
    lazy var inputBio: UITextView = {
        let label = UITextView()
        label.text = "Add Bio"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = Color().black()
        return label
    }()
    
    func setupBioView(_ text: String) {
        inputBio.text = text
        inputBio.delegate = self
        self.view.addSubview(inputBio)
        inputBio.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(self.view.frame.height / 2)
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        inputBio.becomeFirstResponder()
    }
    
    func setupBioCount(_ keyboardHeight: Int) {
        self.view.addSubview(bioCount)
        bioCount.snp.makeConstraints { (make) -> Void in
            //make.top.equalTo(self.inputBio.snp.bottom).offset(uiElement.elementOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.view).offset(-(keyboardHeight + uiElement.elementOffset))
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let textLength = textView.text.count +  (text.count - range.length)
        let remainingLength = 150 - textLength
        
        if remainingLength <= 0 {
            bioCount.text = "\(0)"
            
        } else {
            bioCount.text = "\(remainingLength)"
        }
        
        return textLength <= 150
    }
    var keyboardHeight: CGFloat!
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            setupBioCount(Int(keyboardHeight))
        }
    }
    
    //email
    var email: String?
    
    lazy var emailInput: UITextField = {
        let textField = UITextField()
        textField.font = UIFont(name: uiElement.mainFont, size: 17)
        textField.backgroundColor = .white
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .whileEditing
        textField.keyboardType = .emailAddress
        textField.placeholder = "Email"
        return textField
    }()
    
    func setupEmailView(_ email: String) {
        emailInput.text = email
        self.view.addSubview(emailInput)
        emailInput.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        emailInput.becomeFirstResponder()
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

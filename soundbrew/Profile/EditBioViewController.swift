//
//  EditBioViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 3/6/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit

class EditBioViewController: UIViewController, UITextViewDelegate {
    
    let uiElement = UIElement()
    let color = Color()
    var artistDelegate: ArtistDelegate?
    var totalAllowedTextLength = 150
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        setUpDoneButton()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        setupBioView()
    }
    
    //done
    func setUpDoneButton() {
        let localizedDone = NSLocalizedString("done", comment: "")
        let doneButton = UIBarButtonItem(title: localizedDone, style: .plain, target: self, action: #selector(didPressDoneButton(_:)))
        self.navigationItem.rightBarButtonItem = doneButton
    }
    
    @objc func didPressDoneButton(_ sender: UIButton) {
        if let artistDelegate = self.artistDelegate {
            if inputBio.text != "" {
                let newCreditTitleWithNoSpaces = inputBio.text.trimmingCharacters(
                    in: NSCharacterSet.whitespacesAndNewlines
                )
                artistDelegate.changeBio(newCreditTitleWithNoSpaces)
            }
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
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.textColor = .white
        label.backgroundColor = color.black()
        return label
    }()
    
    func setupBioView() {
        if let bioText = self.bio {
            inputBio.text = bioText
        }
        
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
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.view).offset(-(keyboardHeight + uiElement.elementOffset))
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let textLength = textView.text.count +  (text.count - range.length)
        let remainingLength = totalAllowedTextLength - textLength
        
        if remainingLength <= 0 {
            bioCount.text = "\(0)"
            
        } else {
            bioCount.text = "\(remainingLength)"
        }
        
        return textLength <= totalAllowedTextLength
    }
    
    var keyboardHeight: CGFloat!
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            setupBioCount(Int(keyboardHeight))
        }
    }
}

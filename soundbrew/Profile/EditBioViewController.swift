//
//  EditBioViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 3/6/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import NVActivityIndicatorView
class EditBioViewController: UIViewController, UITextViewDelegate, NVActivityIndicatorViewable {
    
    let uiElement = UIElement()
    let color = Color()
    var artistDelegate: ArtistDelegate?
    var playlistDelegate: PlaylistDelegate?
    var totalAllowedTextLength = 150
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        var buttonTitle = "Done"
        if playlistDelegate != nil {
            buttonTitle = "Create Playlist"
        }
        
         let dividerLine = self.uiElement.addSubViewControllerTopView(self, action: #selector(self.didPressDoneButton(_:)), doneButtonTitle: buttonTitle)
        setupBioView(dividerLine)
    }
    
    //done
    @objc func didPressDoneButton(_ sender: UIButton) {
        if sender.tag == 0 {
            self.dismiss(animated: true, completion: nil)
        } else {
            if let artistDelegate = self.artistDelegate {
                if inputBio.text == "" {
                    artistDelegate.changeBio(nil)
                } else {
                    let newCreditTitleWithNoSpaces = inputBio.text.trimmingCharacters(
                        in: NSCharacterSet.whitespacesAndNewlines
                    )
                    artistDelegate.changeBio(newCreditTitleWithNoSpaces)
                }
                self.dismiss(animated: true, completion: nil)

            } else if let playlistDelegate = self.playlistDelegate, let userId = PFUser.current()?.objectId {
                if inputBio.text.isEmpty {
                    self.uiElement.showAlert("Playlist Title Required", message: "", target: self)
                } else {
                    self.createNewPlaylist(playlistDelegate, userId: userId)
                }
            }
        }
    }
    
    func createNewPlaylist(_ playlistDelegate: PlaylistDelegate, userId: String) {
        startAnimating()
        let newPlaylist = PFObject(className: "Playlist")
        newPlaylist["userId"] = userId
        newPlaylist["title"] = inputBio.text
        newPlaylist["isRemoved"] = false
        newPlaylist.saveEventually {
            (success: Bool, error: Error?) in
            self.stopAnimating()
            if (success) {
                let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, accountId: nil, priceId: nil)
                let newPlaylist = Playlist(objectId: newPlaylist.objectId, artist: artist, title: self.inputBio.text, image: nil, type: "playlist", count: nil)
                self.dismiss(animated: true, completion: {() in
                    playlistDelegate.receivedPlaylist(newPlaylist)
                })
                
            } else if let error = error {
                self.uiElement.showAlert("Error", message: error.localizedDescription, target: self)
                self.dismiss(animated: true, completion: nil)
            }
        }
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
    
    func setupBioView(_ dividerLine: UIView) {
        if let bioText = self.bio {
            inputBio.text = bioText
        }
        
        inputBio.delegate = self
        self.view.addSubview(inputBio)
        inputBio.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(self.view.frame.height / 2)
            make.top.equalTo(dividerLine.snp.bottom).offset(uiElement.topOffset)
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

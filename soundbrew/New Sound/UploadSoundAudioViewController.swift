//
//  NewSoundViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/8/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import MobileCoreServices
import SnapKit
import NVActivityIndicatorView
//import Compression
//import Zip

class UploadSoundAudioViewController: UIViewController, UIDocumentPickerDelegate, UINavigationControllerDelegate, NVActivityIndicatorViewable {
    
    let uiElement = UIElement()
    let color = Color()
    var soundParseFile: PFFileObject!
    var soundFileName: String!
    var soundFileURL: URL!
    
    var soundThatIsBeingEdited: Sound?
    
    lazy var newSoundButton: UIButton = {
        let image = UIButton()
        image.setTitle("Upload Sound", for: .normal)
        image.titleLabel?.textColor = .black
        image.layer.cornerRadius = 3
        image.clipsToBounds = true
        image.backgroundColor = Color().blue()
        return image
    }()
    
    override func viewDidLoad() {        
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        
        if PFUser.current() == nil {
            showWelcome()
        } else {
            showUploadSoundFileUI()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSoundInfo" {
            let viewController: SoundInfoViewController = segue.destination as! SoundInfoViewController
            viewController.soundFileURL = self.soundFileURL
        }
    }
    
    //mark: login
    var login: Login!
    
    func showWelcome() {
        login = Login(target: self)
        login.signinButton.addTarget(self, action: #selector(signInAction(_:)), for: .touchUpInside)
        login.signupButton.addTarget(self, action: #selector(signupAction(_:)), for: .touchUpInside)
        login.loginInWithTwitterButton.addTarget(self, action: #selector(loginWithTwitterAction(_:)), for: .touchUpInside)
        login.welcomeView(explanationString: "From here, you'll be able to upload and tag your music!", explanationImageString: "sound")
    }
    
    @objc func signInAction(_ sender: UIButton) {
        login.signInAction()
    }
    
    @objc func signupAction(_ sender: UIButton) {
        login.signupAction()
    }
    
    @objc func loginWithTwitterAction(_ sender: UIButton) {
        login.loginWithTwitterAction()
    }
    
    func showUploadSoundButton() {
        newSoundButton.addTarget(self, action: #selector(self.didPressUploadButton(_:)), for: .touchUpInside)
        self.view.addSubview(newSoundButton)
        newSoundButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.width.equalTo(200)
            make.top.equalTo(self.view).offset((self.view.frame.height / 2) - CGFloat(uiElement.buttonHeight))
            make.left.equalTo(self.view).offset((self.view.frame.width / 2) - CGFloat(100))
        }
    }
    
    @objc func didPressUploadButton(_ sender: UIButton) {
        showUploadSoundFileUI()
    }
    
    //
    func showUploadSoundFileUI() {
        let types: NSArray = NSArray(object: kUTTypeAudio as NSString)
        let documentPicker = UIDocumentPickerViewController(documentTypes: types as! [String], in: .import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        self.present(documentPicker, animated: true, completion: {() in
            
        })
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if self.soundThatIsBeingEdited == nil {
         self.soundFileURL = urls[0]
         self.performSegue(withIdentifier: "showSoundInfo", sender: self)
         self.showUploadSoundButton()
         
         } else {
         self.processAudioForDatabase(urls[0])
         }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        self.showUploadSoundButton()
    }
        
    func processAudioForDatabase(_ url: URL) {
        do {
            self.soundFileName = "audio.\(url.pathExtension)"
            let audioFile = try Data(contentsOf: url, options: .uncached)
            self.soundParseFile = PFFileObject(name: self.soundFileName, data: audioFile)
            self.saveAudioFile()
            
        } catch {
            UIElement().showAlert("Oops", message: "There was an issue with your upload.", target: self)
        }
    }
    
    func saveAudioFile() {
        self.startAnimating()
        soundParseFile.saveInBackground({
            (succeeded: Bool, error: Error?) -> Void in
            if succeeded && error == nil {
                self.updateSound(self.soundThatIsBeingEdited!.objectId)
                
            } else if let error = error {
                print(error.localizedDescription)
                self.showUploadSoundButton()
                UIElement().showAlert("Sound Processing Failed", message: error.localizedDescription, target: self)
            }
            
        }, progressBlock: {
            (percentDone: Int32) -> Void in
            // Update your progress spinner here. percentDone will be between 0 and 100.
        })
    }
    
    func updateSound(_ objectId: String) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                object["audioFile"] = self.soundParseFile
                object.saveEventually {
                    (success: Bool, error: Error?) in
                    if (success) {
                        self.stopAnimating()
                        self.uiElement.goBackToPreviousViewController(self)
                        
                    } else if let error = error {
                        self.stopAnimating()
                        self.uiElement.showAlert("We Couldn't Update Your Sound", message: error.localizedDescription, target: self)
                        self.showUploadSoundButton()
                    }
                }
            }
        }
    }
}

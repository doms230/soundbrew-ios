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

class NewSoundViewController: UIViewController, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    
    let uiElement = UIElement()
    
    var soundParseFile: PFFileObject!
    var soundFilename: String!
    
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
        showNewSoundUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.title = "New Sound"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController: SoundInfoViewController = segue.destination as! SoundInfoViewController
        viewController.soundFileName = soundFilename
        viewController.soundParseFile = soundParseFile
    }
    
    func showNewSoundUI() {
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
        uploadFile()
    }
    
    //
    func uploadFile() {
        let types: NSArray = NSArray(object: kUTTypeAudio as NSString)
        let documentPicker = UIDocumentPickerViewController(documentTypes: types as! [String], in: .import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        do { //"audio.\(urls[0].pathExtension)" "audio.mp3"
            //print("audio.\(urls[0].pathExtension)")
            self.soundFilename = "audio.\(urls[0].pathExtension)"
            let audioFile = try Data(contentsOf: urls[0], options: .uncached)
            self.soundParseFile = PFFileObject(name: self.soundFilename, data: audioFile)
            //self.soundFilename = "\(urls[0].lastPathComponent)"
            self.title = self.soundFilename
            self.performSegue(withIdentifier: "showSoundInfo", sender: self)
            
        } catch {
            UIElement().showAlert("Oops", message: "There was an issue with your upload.", target: self)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        //showNewSoundUI()
    }
}

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
import Compression

class UploadSoundAudioViewController: UIViewController, UIDocumentPickerDelegate, UINavigationControllerDelegate, NVActivityIndicatorViewable {
    
    let uiElement = UIElement()
    
    var soundParseFile: PFFileObject!
    var soundFilename: String!
    
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
        if PFUser.current() != nil {
            showUploadSoundFileUI()
            
        } else {
            self.uiElement.segueToView("Login", withIdentifier: "welcome", target: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier != "showProfile" {
            let viewController: SoundInfoViewController = segue.destination as! SoundInfoViewController
            viewController.soundFileName = soundFilename
            viewController.soundParseFile = soundParseFile
        }
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
        //processAudioForDatabase(urls[0])
        compressAudio(urls[0])
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        self.showUploadSoundButton()
    }
    
    //mark: compression
    
    // The `Progress` instance used to calculate encode or
    // decode progress.
    let progress = Progress()
    
    func compressAudio(_ url: URL) {
        let algorithm: compression_algorithm
        let operation: compression_stream_operation
        let encodeAlgorithm = COMPRESSION_ZLIB
        
        algorithm = encodeAlgorithm
        operation = COMPRESSION_STREAM_ENCODE
        
        if
            let sourceFileHandle = try? FileHandle(forReadingFrom: url),
            let sourceLength = FileHelper.fileSize(atURL: url),
            let fileName = url.pathComponents.last,
            let fileNameDeletingPathExtension = url.deletingPathExtension().pathComponents.last,
            let destinationFileHandle = FileHandle.makeFileHandle(forWritingToFileNameInTempDirectory:
                operation == COMPRESSION_STREAM_ENCODE
                    ? fileName + encodeAlgorithm.pathExtension
                    : fileNameDeletingPathExtension)
        {
            self.progress.totalUnitCount = Int64(sourceLength)
            
            DispatchQueue.global(qos: .utility).async {
                // Observe `progress.fractionCompleted` to update UI during encode
                // or decode operation.
                let observation = self.progress.observe(\.fractionCompleted,
                                                        options: [.new]) { (progress, _) in
                                                            if progress.isFinished {
                                                                if let compressedFilename = FileHelper.urlFor(fileNameInTempDirectory: fileName + encodeAlgorithm.pathExtension) {
                                                                    self.processAudioForDatabase(compressedFilename)
                                                                    
                                                                }
                                                                
                                                            } else {
                                                               //print(progress.fractionCompleted)
                                                            }
                }
            
                defer {
                    observation.invalidate()
                }
                
                Compressor.streamingCompression(operation: operation,
                                                sourceFileHandle: sourceFileHandle,
                                                destinationFileHandle: destinationFileHandle,
                                                algorithm: algorithm) {
                                                    self.progress.completedUnitCount = $0
                }
            }
            
        } else {
            fatalError("Unable to complete operation.")
        }
    }
    
    func processAudioForDatabase(_ url: URL) {
        DispatchQueue.main.async {
            do {
                print("path extension: \(url.pathExtension)")
                self.soundFilename = "audio.\(url.pathExtension)"
                let audioFile = try Data(contentsOf: url, options: .uncached)
                self.soundParseFile = PFFileObject(name: self.soundFilename, data: audioFile)
                if self.soundThatIsBeingEdited != nil {
                    self.saveAudioFile()
                    
                } else {
                    self.performSegue(withIdentifier: "showSoundInfo", sender: self)
                    self.showUploadSoundButton()
                }
                
            } catch {
                UIElement().showAlert("Oops", message: "There was an issue with your upload.", target: self)
            }
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
                //self.errorAlert("Sound Processing Failed", message: error.localizedDescription)
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
                        //self.dismiss(animated: true, completion: nil)
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

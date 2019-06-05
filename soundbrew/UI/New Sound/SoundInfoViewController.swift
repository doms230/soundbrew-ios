//
//  SoundInfoViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/8/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//mark: tableview, audio, tags, media upload, view

import UIKit
import Parse
import NVActivityIndicatorView
import SnapKit
import Kingfisher
import AppCenterAnalytics

class SoundInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NVActivityIndicatorViewable, TagDelegate {

    let uiElement = UIElement()
    
    var currentUserCity: String?
    var artistName: String?
    
    let color = Color()
    var soundArt: PFFileObject?
    var soundArtButton: UIButton!
    var soundArtDidFinishProcessing = false
    
    var soundTitle: UITextField!

    var soundFileName: String!
    var soundParseFile: PFFileObject!
    var soundParseFileDidFinishProcessing = false
    var didPressUploadButton = false
    
    var soundThatIsBeingEdited: Sound?
    var newSoundObjectId: String!
    
    var uploadButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if soundThatIsBeingEdited == nil {
            saveAudioFile()
            soundParseFileDidFinishProcessing = true
            soundArtDidFinishProcessing = true
            if let userId = PFUser.current()?.objectId {
                loadCurrentUserCity(userId)
            }
        }
        
        setUpViews()
        setUpTableView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navigationController = segue.destination as! UINavigationController
        let viewController: NewSoundTagsViewController = navigationController.topViewController as! NewSoundTagsViewController
        viewController.tagDelegate = self
        
        if let chosenTags = self.chosenTags {
            for tag in chosenTags {
                if let type = tag.type {
                    switch type {
                    case "genre":
                        viewController.genreTag = tag
                        break
                        
                    case "mood":
                        viewController.moodTag = tag
                        break
                        
                    case "activity":
                        viewController.activityTag = tag
                        break
                        
                    case "similar artist":
                        viewController.similarArtistTag = tag
                        break
                        
                    case "city":
                        viewController.cityTag = tag
                        break
                        
                    default:
                        viewController.moreTags?.append(tag)
                        break
                    }
                    
                } else {
                    viewController.moreTags?.append(tag)
                }
            }
        }
    }
    
    //mark: views
    
    func setUpViews() {
        var title = "UPLOAD"
        if soundThatIsBeingEdited != nil {
            title = "UPDATE"
        }
        
        uploadButton = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(self.didPressUpload(_:)))
        uploadButton.isEnabled = false
        self.navigationItem.rightBarButtonItem = uploadButton
    }
    
    @objc func didPressCancelButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: tags
    var showTags = "showTags"
    var chosenTagsLabel: UILabel!
    var chosenTags: Array<Tag>?
    
    func receivedTags(_ chosenTags: Array<Tag>?) {
        if let chosenTags = chosenTags {
            self.chosenTags = chosenTags
            self.chosenTagsLabel.text = "\(self.chosenTags!.count)"
            self.chosenTagsLabel.textColor = color.blue()
        }
        
        self.tableView.reloadData()
    }
    
    //MARK: Tableview
    var tableView: UITableView!
    let soundInfoReuse = "soundInfoReuse"
    let soundTagReuse = "soundTagReuse"
    let soundProgressReuse = "soundProgressReuse"
    let soundSocialReuse = "soundSocialReuse"
    
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundInfoReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundTagReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundProgressReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundSocialReuse)
        tableView.backgroundColor = .white 
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .singleLine
        tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if soundThatIsBeingEdited == nil {
            return 4
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if soundThatIsBeingEdited == nil && section == 3 {
            return 3
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: SoundInfoTableViewCell!
        
        
        switch indexPath.section {
        case 0:
            cell = self.tableView.dequeueReusableCell(withIdentifier: soundProgressReuse) as? SoundInfoTableViewCell
            
            self.progressSliderTitle = cell.progressSliderTitle
            self.progressSliderPrecentDoneLabel = cell.chosenSoundTagLabel
            self.progressSlider = cell.progessSlider
            tableView.separatorStyle = .singleLine
            break
            
        case 1:
            cell = self.tableView.dequeueReusableCell(withIdentifier: soundInfoReuse) as? SoundInfoTableViewCell
            
            if let sound = soundThatIsBeingEdited {
                cell.soundArt.kf.setImage(with: URL(string: sound.artURL), for: .normal)
                cell.soundTitle.text = sound.title
            }
            
            soundArtButton = cell.soundArt
            cell.soundArt.addTarget(self, action: #selector(didPressUploadSongArtButton(_:)), for: .touchUpInside)
            
            soundTitle = cell.soundTitle
            tableView.separatorStyle = .singleLine
            break
            
        case 2:
            cell = self.tableView.dequeueReusableCell(withIdentifier: soundTagReuse) as? SoundInfoTableViewCell
            
            chosenTagsLabel =  cell.chosenSoundTagLabel
            
            tableView.separatorStyle = .singleLine
            break
            
        case 3:
            cell = self.tableView.dequeueReusableCell(withIdentifier: soundSocialReuse) as? SoundInfoTableViewCell
            if indexPath.row == 0 {
                cell.soundTagLabel.text = "Instagram Stories"
                
            } else if indexPath.row == 1 {
                cell.soundTagLabel.text = "Facebook"
                
            } else {
                cell.soundTagLabel.text = "Twitter"
            }
            
            tableView.separatorStyle = .none
            
            break
            
        default:
            break
        }
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            self.performSegue(withIdentifier: showTags, sender: self)
        }
    }
    
    //mark: media upload
    @objc func didPressUploadSongArtButton(_ sender: UIButton){
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as! UIImage
        
        soundArtButton.setImage(image, for: .normal)
        
        let proPic = image.jpegData(compressionQuality: 0.5)
        soundArt = PFFileObject(name: "soundArt.jpeg", data: proPic!)
        soundArt?.saveInBackground({
            (succeeded: Bool, error: Error?) -> Void in
            if succeeded {
                self.soundArtDidFinishProcessing = true
                
                if self.didPressUploadButton && self.soundParseFileDidFinishProcessing {
                    self.saveSound()
                }
                
            } else if let error = error {
                self.errorAlert("Art Processing Failed", message: error.localizedDescription)
            }
            
        }, progressBlock: {
            (percentDone: Int32) -> Void in
            // Update your progress spinner here. percentDone will be between 0 and 100.
        })
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }
    
    //
    @objc func didPressUpload(_ sender: UIBarButtonItem) {
        if soundInfoIsVerified() {
            self.startAnimating()
            
            if let sound = soundThatIsBeingEdited {
                updateSound(sound.objectId)
                
            } else {
                print("soundParseFile: \(soundParseFileDidFinishProcessing)")
                print("soundart: \(soundArtDidFinishProcessing)")
                if soundParseFileDidFinishProcessing && soundArtDidFinishProcessing {
                    saveSound()
                    
                } else {
                    didPressUploadButton = true
                }
            }
        }
    }
    
    func saveSound() {
        //let tags = getTags()
        let newSound = PFObject(className: "Post")
        newSound["userId"] = PFUser.current()!.objectId!
        newSound["title"] = soundTitle.text
        newSound["audioFile"] = soundParseFile
        newSound["songArt"] = soundArt
        if let chosenTags = self.chosenTags {
            newSound["tags"] = chosenTags.map {$0.name}
        }
        newSound.saveEventually {
            (success: Bool, error: Error?) in
            if (success) {
                self.newSoundObjectId = newSound.objectId
                self.saveTags(self.chosenTags)
                MSAnalytics.trackEvent("sound uploaded")
                
            } else if let error = error {
                self.stopAnimating()
                self.uiElement.showAlert("We Couldn't Post Your Sound", message: error.localizedDescription, target: self)
            }
        }
    }
    
    func updateSound(_ objectId: String) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                if let soundArt = self.soundArt {
                    object["songArt"] = soundArt
                }
                object["title"] = self.soundTitle.text
                object.saveEventually {
                    (success: Bool, error: Error?) in
                    if (success) {
                        self.stopAnimating()
                        self.uiElement.goBackToPreviousViewController(self)
                        
                    } else if let error = error {
                        self.stopAnimating()
                        self.uiElement.showAlert("We Couldn't Update Your Sound", message: error.localizedDescription, target: self)
                    }
                }
            }
        }
    }
    
    func saveTags(_ tags: Array<Tag>?) {
        if let tags = tags {
            for tag in tags {
                if let tagId = tag.objectId {
                    let query = PFQuery(className: "Tag")
                    query.getObjectInBackground(withId: tagId) {
                        (object: PFObject?, error: Error?) -> Void in
                        if let error = error {
                            print(error)
                            
                        } else if let object = object {
                            object.incrementKey("count")
                            object.saveEventually()
                        }
                    }
                    
                } else {
                    let newTag = PFObject(className: "Tag")
                    newTag["tag"] = tag.name
                    newTag["count"] = 1
                    if let type = tag.type {
                        newTag["type"] = type
                    }
                    newTag.saveEventually()
                }
            }
        }
        
        self.stopAnimating()
        self.uiElement.segueToView("Main", withIdentifier: "main", target: self)
    }
    
    //mark: audio
    var progressSlider: UISlider!
    var progressSliderPrecentDoneLabel: UILabel!
    var progressSliderTitle: UILabel!
    func saveAudioFile() {        
        soundParseFile.saveInBackground({
            (succeeded: Bool, error: Error?) -> Void in
            if succeeded {
                self.soundParseFileDidFinishProcessing = true
                self.uploadButton.isEnabled = true
                self.progressSliderTitle.text = "Audio Processing Complete."
                
            } else if let error = error {
                self.errorAlert("Sound Processing Failed", message: error.localizedDescription)
            }
            
        }, progressBlock: {
            (percentDone: Int32) -> Void in
            self.progressSlider.value = Float(percentDone)
            self.progressSliderPrecentDoneLabel.text = "\(percentDone)%"
        })
    }
    
    func soundInfoIsVerified() -> Bool {
        if soundTitle.text!.isEmpty {
            showAttributedPlaceholder(soundTitle, text: "Title Required")
            
        } else if soundThatIsBeingEdited == nil {
            if soundArt == nil {
                uiElement.showAlert("Sound Art is Required", message: "Tap the gray box that says 'Add Art' in the top left corner.", target: self)
                
            } else {
                return true
            }
            
        } else {
            return true
        }
        
        return false
    }
    
    func showAttributedPlaceholder(_ textField: UITextField, text: String) {
        textField.attributedPlaceholder = NSAttributedString(string:"\(text)",
                                                              attributes:[NSAttributedString.Key.foregroundColor: UIColor.red])
    }
    
    func errorAlert(_ title: String, message: String) {
        let alertController = UIAlertController (title: title, message: message, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Okay", style: .cancel) { (_) -> Void in
            self.uiElement.goBackToPreviousViewController(self)
        }
        alertController.addAction(settingsAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func loadCurrentUserCity(_ userId: String) {
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                if let city = user["city"] as? String {
                    if !city.isEmpty {
                        self.loadCityTag(city.lowercased())
                    }
                }
            }
        }
    }
    
    func loadCityTag(_ city: String) {
        let cityTag = Tag(objectId: nil, name: city, count: 0, isSelected: false, type: "city", image: nil)
        let query = PFQuery(className: "Tag")
        query.whereKey("tag", equalTo: city)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if object != nil && error == nil {
                cityTag.objectId = object?.objectId
                cityTag.name = object!["tag"] as? String
                self.chosenTags?.append(cityTag)
                
            } else {
                self.chosenTags?.append(cityTag)
            }
        }
    }
}

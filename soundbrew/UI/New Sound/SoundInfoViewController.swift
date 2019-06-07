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
import FirebaseAnalytics

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
        let navi = segue.destination as! UINavigationController
        let viewController: ChooseTagsViewController = navi.topViewController as! ChooseTagsViewController
        viewController.tagDelegate = self
        
        if let tagType = tagType {
            viewController.tagType = tagType
            
            if tagType == "more", let tags = tagsToUpdateInChooseTagsViewController {
                viewController.chosenTags = tags
            }
        }
    }
    
    //mark: views
    func setUpViews() {
        var title = "UPLOAD"
        var shouldUploadButtonBeEnabled = true
        if soundThatIsBeingEdited != nil {
            title = "UPDATE"
            
        } else {
            shouldUploadButtonBeEnabled = false
        }
        
        uploadButton = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(self.didPressUpload(_:)))
        uploadButton.isEnabled = shouldUploadButtonBeEnabled
        self.navigationItem.rightBarButtonItem = uploadButton
    }
    
    @objc func didPressCancelButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: tags
    var showTags = "showTags"
    var tagType: String?
    var genreTag: Tag?
    var moodTag: Tag?
    var activityTag: Tag?
    var moreTags: Array<Tag>?
    var cityTag: Tag?
    var similarArtistTag: Tag?
    var tagsToUpdateInChooseTagsViewController: Array<Tag>?
    
    func receivedTags(_ chosenTags: Array<Tag>?) {
        if let tagType = self.tagType {
            if let tag = chosenTags {
                switch tagType {
                case "city":
                    self.cityTag = tag[0]
                    break
                    
                case "genre":
                    self.genreTag = tag[0]
                    break
                    
                case "mood":
                    self.moodTag = tag[0]
                    break
                    
                case "activity":
                    self.activityTag = tag[0]
                    break
                    
                case "similar artist":
                    self.similarArtistTag = tag[0]
                    break
                    
                default:
                    self.moreTags = chosenTags
                    break
                }
            }
        }
        
        self.tableView.reloadData()
    }
    
    //MARK: Tableview
    var tableView: UITableView!
    let soundInfoReuse = "soundInfoReuse"
    let soundTagReuse = "soundTagReuse"
    let soundProgressReuse = "soundProgressReuse"
    
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundInfoReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundTagReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundProgressReuse)
        tableView.backgroundColor = .white
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .singleLine
        tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if soundThatIsBeingEdited == nil {
            return 3
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return 5
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: SoundInfoTableViewCell!
        
        if indexPath.section == 0 && soundThatIsBeingEdited != nil {
            cell = soundInfo()
            
        } else {
            if indexPath.section == 0 {
                cell = self.tableView.dequeueReusableCell(withIdentifier: soundProgressReuse) as? SoundInfoTableViewCell
                
                self.progressSliderTitle = cell.titleLabel
                self.progressSliderPrecentDoneLabel = cell.chosenSoundTagLabel
                self.progressSlider = cell.progessSlider
                
                tableView.separatorStyle = .none
                
            } else if indexPath.section == 1 {
                cell = soundInfo()
                
            } else {
                cell = self.tableView.dequeueReusableCell(withIdentifier: soundTagReuse) as? SoundInfoTableViewCell
                
                switch indexPath.row {
                case 0:
                    cell.soundTagLabel.text = "Genre Tag"
                    if let genreTag = self.genreTag {
                        cell.chosenSoundTagLabel.text = genreTag.name
                        cell.chosenSoundTagLabel.textColor = color.blue()
                    }
                    tableView.separatorStyle = .singleLine
                    break
                    
                case 1:
                    cell.soundTagLabel.text = "Mood Tag"
                    if let moodTag = self.moodTag {
                        cell.chosenSoundTagLabel.text = moodTag.name
                        cell.chosenSoundTagLabel.textColor = color.blue()
                    }
                    tableView.separatorStyle = .singleLine
                    break
                    
                case 2:
                    cell.soundTagLabel.text = "Activity Tag"
                    if let activityTag = self.activityTag {
                        cell.chosenSoundTagLabel.text = activityTag.name
                        cell.chosenSoundTagLabel.textColor = color.blue()
                    }
                    tableView.separatorStyle = .singleLine
                    
                case 3:
                    cell.soundTagLabel.text = "Similar Artist"
                    if let similarArtistTag = self.similarArtistTag {
                        cell.chosenSoundTagLabel.text = similarArtistTag.name
                        cell.chosenSoundTagLabel.textColor = color.blue()
                    }
                    
                case 4:
                    cell.soundTagLabel.text = "More Tags"
                    if let moreTags = self.moreTags {
                        if moreTags.count == 1 {
                            cell.chosenSoundTagLabel.text = "\(moreTags.count) tag"
                            
                        } else {
                            cell.chosenSoundTagLabel.text = "\(moreTags.count) tags"
                        }
                        
                        cell.chosenSoundTagLabel.textColor = color.blue()
                        
                    } else {
                        cell.chosenSoundTagLabel.text = "Add"
                        cell.chosenSoundTagLabel.textColor = color.red()
                    }
                    tableView.separatorStyle = .none
                    
                default:
                    break
                }
            }
        }
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            switch indexPath.row {
            case 0:
                self.tagType = "genre"
                break
                
            case 1:
                self.tagType = "mood"
                break
                
            case 2:
                self.tagType = "activity"
                break
                
            case 3:
                self.tagType = "similar artist"
                break
                
            case 4:
                self.tagType = "more"
                self.tagsToUpdateInChooseTagsViewController = moreTags
                break
                
            default:
                break
            }
            
            self.performSegue(withIdentifier: showTags, sender: self)
        }
    }
    
    func soundInfo() -> SoundInfoTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: soundInfoReuse) as! SoundInfoTableViewCell
        
        if let sound = soundThatIsBeingEdited {
            cell.soundArt.kf.setImage(with: URL(string: sound.artURL), for: .normal)
            cell.soundTitle.text = sound.title
        }
        
        soundArtButton = cell.soundArt
        cell.soundArt.addTarget(self, action: #selector(didPressUploadSongArtButton(_:)), for: .touchUpInside)
        
        soundTitle = cell.soundTitle
        tableView.separatorStyle = .singleLine
        
        return cell
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
                if soundParseFileDidFinishProcessing && soundArtDidFinishProcessing {
                    saveSound()
                    
                } else {
                    didPressUploadButton = true
                }
            }
        }
    }

    func saveSound() {
        let tags = getTags()
        let newSound = PFObject(className: "Post")
        newSound["userId"] = PFUser.current()!.objectId!
        newSound["title"] = soundTitle.text
        newSound["audioFile"] = soundParseFile
        newSound["songArt"] = soundArt
        newSound["tags"] = tags.map {$0.name}
        newSound.saveEventually {
            (success: Bool, error: Error?) in
            if (success) {
                self.saveTags(tags)
                Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                    AnalyticsParameterItemID: "id-sound upload",
                    AnalyticsParameterItemName: "sound upload",
                    AnalyticsParameterContentType: "cont"
                    ])
                
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
    
    func getTags() -> Array<Tag> {
        var tags = [Tag]()
        if let moreTags = self.moreTags {
            tags = moreTags
        }
        
        if let genreTag = self.genreTag {
            tags.append(genreTag)
        }
        
        if let activityTag = self.activityTag {
            tags.append(activityTag)
        }
        
        if let moodTag = self.moodTag {
            tags.append(moodTag)
        }
        
        if let cityTag = self.cityTag {
            tags.append(cityTag)
        }
        
        if let similarArtistTag = self.similarArtistTag {
            tags.append(similarArtistTag)
        }
        
        return tags
    }
    
    func saveTags(_ tags: Array<Tag>) {
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
                
            } else if genreTag == nil {
                uiElement.showAlert("Sound Genre is Required", message: "Tap the 'add genre tag' button to choose", target: self)
                
            } else if activityTag == nil {
                uiElement.showAlert("Sound Activity is Required", message: "Tap the 'add activity tag' button to choose", target: self)
                
            } else if moodTag == nil {
                uiElement.showAlert("Sound Mood is Required", message: "Tap the 'add mood tag' button to choose", target: self)
                
            } else if similarArtistTag == nil {
                uiElement.showAlert("Similar Artist is Required", message: "Tap the 'add Similar artist tag' button to choose", target: self)
                
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
        let query = PFQuery(className: "Tag")
        query.whereKey("tag", equalTo: city)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if object != nil && error == nil {
                self.cityTag = Tag(objectId: object?.objectId, name: object!["tag"] as? String, count: 0, isSelected: false, type: "city", image: nil)
                
            } else {
                self.cityTag = Tag(objectId: nil, name: city, count: 0, isSelected: false, type: "city", image: nil)
            }
        }
    }
}

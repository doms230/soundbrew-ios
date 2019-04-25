//
//  SoundInfoViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/8/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//TODO: Get User's cit they are in 

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if soundThatIsBeingEdited == nil {
            saveAudioFile()
            soundParseFileDidFinishProcessing = true
            soundArtDidFinishProcessing = true
        }
        
        setUpViews()
        setUpTableView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController: ChooseTagsViewController = segue.destination as! ChooseTagsViewController
        viewController.tagDelegate = self
        if let tags = tagsToUpdateInTagsViewController {
            viewController.chosenTags = tags
        }
        
        if let tagType = tagType {
            viewController.tagType = tagType
        }
    }
    
    func setUpViews() {
        var title = "UPLOAD"
        if soundThatIsBeingEdited != nil {
            title = "UPDATE"
        }
        
        let uploadButton = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(self.didPressUpload(_:)))
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
    var tagsToUpdateInTagsViewController: Array<Tag>?
    
    func changeTags(_ value: Array<Tag>?) {
        if let tagType = self.tagType {
            if let tag = value {
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

                default:
                    break
                }
            }
            
        } else {
            self.moreTags = value
        }
        
        self.tableView.reloadData()
    }
    
    //MARK: Tableview
    var tableView: UITableView!
    let soundInfoReuse = "soundInfoReuse"
    let soundTagReuse = "soundTagReuse"
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundInfoReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundTagReuse)
        tableView.backgroundColor = .white
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .singleLine
        tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if soundThatIsBeingEdited == nil {
            return 2
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 6
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: SoundInfoTableViewCell!
        
        if indexPath.section == 0 {
            cell = self.tableView.dequeueReusableCell(withIdentifier: soundInfoReuse) as? SoundInfoTableViewCell
            
            if let sound = soundThatIsBeingEdited {
                cell.soundArt.kf.setImage(with: URL(string: sound.artURL), for: .normal)
                cell.soundTitle.text = sound.title
            }
            
            soundArtButton = cell.soundArt
            cell.soundArt.addTarget(self, action: #selector(didPressUploadSongArtButton(_:)), for: .touchUpInside)
            
            soundTitle = cell.soundTitle
            tableView.separatorStyle = .singleLine
            
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
                cell.soundTagLabel.text = "City Tag"
                if let cityTag = self.cityTag {
                    cell.chosenSoundTagLabel.text = cityTag.name
                    cell.chosenSoundTagLabel.textColor = color.blue()
                }
                tableView.separatorStyle = .singleLine
                break
                
            case 2:
                cell.soundTagLabel.text = "Mood Tag"
                if let moodTag = self.moodTag {
                    cell.chosenSoundTagLabel.text = moodTag.name
                    cell.chosenSoundTagLabel.textColor = color.blue()
                }
                tableView.separatorStyle = .singleLine
                break
                
            case 3:
                cell.soundTagLabel.text = "Activity Tag"
                if let activityTag = self.activityTag {
                    cell.chosenSoundTagLabel.text = activityTag.name
                    cell.chosenSoundTagLabel.textColor = color.blue()
                }
                tableView.separatorStyle = .singleLine
                
            case 4:
                cell.soundTagLabel.text = "Similar Artist"
                if let similarArtistTag = self.similarArtistTag {
                    cell.chosenSoundTagLabel.text = similarArtistTag.name
                    cell.chosenSoundTagLabel.textColor = color.blue()
                }
                
            case 5:
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
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                self.tagType = "genre"
                tagsToUpdateInTagsViewController = [self.genreTag] as? Array<Tag>
                break
                
            case 1:
                self.tagType = "city"
                tagsToUpdateInTagsViewController = [self.cityTag] as? Array<Tag>
                break
                
            case 2:
                self.tagType = "mood"
                tagsToUpdateInTagsViewController = [self.moodTag] as? Array<Tag>
                break
                
            case 3:
                self.tagType = "activity"
                tagsToUpdateInTagsViewController = [self.activityTag] as? Array<Tag>
                break
                
            case 4:
                self.tagType = "similar artist"
                tagsToUpdateInTagsViewController = [self.similarArtistTag] as? Array<Tag>
                break
                
            case 5:
                self.tagType = nil
                tagsToUpdateInTagsViewController = moreTags
                break
                
            default:
                break
            }
            
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
        newSound["genre"] = genreTag!.name
        newSound["city"] = cityTag!.name
        newSound["tags"] = tags.map {$0.name}
        newSound.saveEventually {
            (success: Bool, error: Error?) in
            if (success) {
                self.saveTags(tags)
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
                        //self.dismiss(animated: true, completion: nil)
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
        tags.append(genreTag!)
        tags.append(activityTag!)
        tags.append(moodTag!)
        tags.append(cityTag!)
        tags.append(similarArtistTag!)
    
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
    
    func saveAudioFile() {
        soundParseFile.saveInBackground({
            (succeeded: Bool, error: Error?) -> Void in
            if succeeded {
                self.soundParseFileDidFinishProcessing = true
                
                if self.didPressUploadButton && self.soundArtDidFinishProcessing {
                    self.saveSound()
                }
                
            } else if let error = error {
                self.errorAlert("Sound Processing Failed", message: error.localizedDescription)
            }
            
        }, progressBlock: {
            (percentDone: Int32) -> Void in
            // Update your progress spinner here. percentDone will be between 0 and 100.
        })
    }
    
    @objc func didPressGenreButton(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            tagType = "genre"
            break
            
        case 1:
            tagType = "mood"
            break
            
        case 2:
            tagType = "activity"
            break
            
        default:
            break
        }
        
        self.performSegue(withIdentifier: "showChooseGenre", sender: self)
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
                
            } else if cityTag == nil {
                uiElement.showAlert("Sound City is Required", message: "Tap the 'add mood tag' button to choose", target: self)
                
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
}

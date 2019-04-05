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

class SoundInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, NVActivityIndicatorViewable, TagDelegate {

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        saveAudioFile()
        setUpViews()
        setUpTableView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController: TagsViewController = segue.destination as! TagsViewController
        viewController.isChoosingTagsForSoundUpload = true
        viewController.tagDelegate = self
        if let tags = tagsToEdit {
            viewController.chosenTags = tags
        }
        
        if let tagType = tagType {
            viewController.tagType = tagType
        }
    }
    
    func setUpViews() {
        let uploadButton = UIBarButtonItem(title: "UPLOAD", style: .plain, target: self, action: #selector(self.didPressUpload(_:)))
        self.navigationItem.rightBarButtonItem = uploadButton
    }
    
    //MARK: tags
    var showTags = "showTags"
    var tagType: String?
    //var addTagsType: String?
    let genres = ["Hip-Hop/Rap", "Electronic Dance Music(EDM)", "Pop", "Alternative Rock", "Americana", "Blues", "Christian & Gospal", "Classic Rock", "Classical", "Country", "Dance", "Hard Rock", "Indie", "Jazz", "Latino", "Metal", "Reggae", "R&B", "Soul", "Funk"]
    
    let moods = ["Happy", "Sad", "Angry", "Chill", "High-Energy", "Netflix-And-Chill"]
    
    let activities = ["Creative", "Workout", "Party", "Work", "Sleep", "Gaming"]
    var genreTag: Tag?
    var moodTag: String?
    var activityTag: String?
    var moreTags: Array<Tag>?
    var cityTag: Tag?
    var tagsToEdit: Array<Tag>?
    
    func changeTags(_ value: Array<Tag>?) {
        if let tagType = self.tagType {
            if let tag = value {
                if tagType == "city" {
                    self.cityTag = tag[0]
                    
                } else if tagType == "genre" {
                    self.genreTag = tag[0]
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
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 5
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: SoundInfoTableViewCell!
        
        if indexPath.section == 0 {
            cell = self.tableView.dequeueReusableCell(withIdentifier: soundInfoReuse) as? SoundInfoTableViewCell
            
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
                    cell.chosenSoundTagLabel.text = moodTag
                    cell.chosenSoundTagLabel.textColor = color.blue()
                }
                tableView.separatorStyle = .singleLine
                break
                
            case 3:
                cell.soundTagLabel.text = "Activity Tag"
                if let activityTag = self.activityTag {
                    cell.chosenSoundTagLabel.text = activityTag
                    cell.chosenSoundTagLabel.textColor = color.blue()
                }
                tableView.separatorStyle = .singleLine
                
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
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                //self.showPickerView("Genre")
                //self.genreTag = "Hip-Hop/Rap"
                tagType = "genre"
                if let genreTag = self.genreTag {
                    tagsToEdit?.append(genreTag)
                }
                self.performSegue(withIdentifier: "showTags", sender: self)
                
                break
                
            case 1:
                tagType = "city"
                if let cityTag = self.cityTag {
                    tagsToEdit?.append(cityTag)
                }
                self.performSegue(withIdentifier: showTags, sender: self)
                //var cityTags: Array<Tag>?
                //self.showTagsViewController(cityTags, tagType: "city")
                break
                
            case 2:
                self.showPickerView("Mood")
                self.moodTag = "Happy"
                break
                
            case 3:
                self.showPickerView("Activity")
                self.activityTag = "Creative"
                break
                
            case 4:
                tagType = nil
                tagsToEdit = moreTags
                self.performSegue(withIdentifier: showTags, sender: self)
                //self.showTagsViewController(moreTags, tagType: nil)
                break
                
            default:
                break
            }
        }
    }
    
    //MARK: PickerView
    func showPickerView(_ title: String) {
        let alert = UIAlertController(title: "Choose \(title) Tag", message: "\n\n\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: { action in
            self.tableView.reloadData()
        }))
        alert.isModalInPopover = true
        
        //  Create a frame (placeholder/wrapper) for the picker and then create the picker
        let pickerFrame = CGRect(x: 0, y: 0, width: self.view.frame.width - 20, height: self.view.frame.height * (1/3)) // CGRectMake(left), top, width, height) - left and top are like margins
        let picker = UIPickerView(frame: pickerFrame)
        
        //  set the pickers datasource and delegate
        picker.delegate = self
        picker.dataSource = self
        switch title {
        case "Genre":
            picker.tag = 0
            break
            
        case "Mood":
            picker.tag = 1
            break
            
        case "Activity":
            picker.tag = 2
            break
            
        default:
            break
        }
        
        //  Add the picker to the alert controller
        alert.view.addSubview(picker)
        
        self.present(alert, animated: true, completion: nil);
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0:
            return genres.count
            
        case 1:
            return moods.count
            
        case 2:
            return activities.count
            
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 0:
            return genres[row]
            
        case 1:
            return moods[row]
            
        case 2:
            return activities[row]
            
        default:
            return "default"
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 0:
            //self.genreTag = genres[row]
            break
            
        case 1:
            self.moodTag = self.moods[row]
            break
            
        case 2:
            self.activityTag = self.activities[row]
            break
            
        default:
            break
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
            if soundParseFileDidFinishProcessing && soundArtDidFinishProcessing {
                saveSound()
                
            } else {
                didPressUploadButton = true 
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
        newSound["genre"] = genreTag
        newSound["tags"] = tags
        newSound.saveEventually {
            (success: Bool, error: Error?) in
            if (success) {
                self.saveTags(tags)
                
            } else if let error = error {
                self.stopAnimating()
                self.uiElement.showAlert("We Couldn't Post Your Sound", message: error.localizedDescription, target: self)
            }
        }
    }
    
    func getTags() -> Array<String> {
        //var tags = soundTags.text!.split{$0 == " "}.map(String.init)
        var tags = [String]()
        if let moreTags = self.moreTags {
            let moreTagNames = moreTags.map {$0.name!}
            tags = moreTagNames
        }
        tags.append(genreTag!.name.lowercased())
        tags.append(activityTag!.lowercased())
        tags.append(moodTag!.lowercased())
        tags.append(cityTag!.name.lowercased())
    
        return tags
    }
    
    func saveTags(_ tags: Array<String>) {
        let query = PFQuery(className: "Tag")
        query.whereKey("tag", containedIn: tags)
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for tag in tags {
                        var didFindTagMatch = false
                        for object in objects {
                            if tag == object["tag"] as! String {
                                let currentTagCount = object["count"] as! Int
                                object["count"] = currentTagCount + 1
                                object.saveEventually()
                                didFindTagMatch = true
                                break
                            }
                        }
                        
                        if !didFindTagMatch {
                            let newTag = PFObject(className: "Tag")
                            newTag["tag"] = tag
                            newTag["count"] = 1
                            newTag.saveEventually()
                        }
                    }
                }
                
                self.stopAnimating()
                self.uiElement.setUserDefault("moreTags", value: [])
                self.uiElement.segueToView("Main", withIdentifier: "main", target: self)
                
            } else {
                self.stopAnimating()
                print("Error: \(error!)")
            }
        }
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
            
        } else if soundArt == nil {
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

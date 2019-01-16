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
import UserNotifications
import SnapKit

class SoundInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, NVActivityIndicatorViewable {

    let uiElement = UIElement()
    
    var currentUserCity: String?
    var artistName: String?
    
    let color = Color()
    var soundArt: PFFileObject?
    var soundArtButton: UIButton!
    var soundArtDidFinishProcessing = false
    
    var soundTitle: UITextField!
    
    let genres = ["Hip-Hop/Rap", "Electronic Dance Music(EDM)", "Pop", "Alternative Rock", "Americana", "Blues", "Christian & Gospal", "Classic Rock", "Classical", "Country", "Dance", "Hard Rock", "Indie", "Jazz", "Latino", "Metal", "Reggae", "R&B", "Soul", "Funk"]
    
    let moods = ["Happy", "Sad", "Angry", "Chill", "High-Energy", "Netflix-And-Chill"]
    
    let activities = ["Creative", "Workout", "Party", "Work", "Sleep", "Gaming"]
    var soundGenre: String?
    var soundMood: String?
    var soundActivity: String?
    var soundArtistsYouKnow: String?
    var soundMoreTags: String?
    
    var soundFileName: String!
    var soundParseFile: PFFileObject!
    var soundParseFileDidFinishProcessing = false
    
    var tagType: String!
    
    var didPressUploadButton = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if uiElement.getUserDefault("city") != nil && uiElement.getUserDefault("artistName") != nil {
            self.currentUserCity = uiElement.getUserDefault("city")
            self.artistName = uiElement.getUserDefault("artistName")
            
        } else {
            loadUserInfo()
        }
        
        saveAudioFile()
        setUpViews()
        setUpTableView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController: ChooseGenreViewController = segue.destination as! ChooseGenreViewController
        viewController.tagType = tagType
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    func setUpViews() {
        let uploadButton = UIBarButtonItem(title: "UPLOAD", style: .plain, target: self, action: #selector(self.didPressUpload(_:)))
        self.navigationItem.rightBarButtonItem = uploadButton
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
            return 6
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
                if let soundGenre = self.soundGenre {
                    cell.chosenSoundTagLabel.text = soundGenre
                }
                tableView.separatorStyle = .singleLine
                break
                
            case 1:
                cell.soundTagLabel.text = "City Tag"
                cell.chosenSoundTagLabel.textColor = color.black()
                tableView.separatorStyle = .singleLine
                break
                
            case 2:
                cell.soundTagLabel.text = "Artists You Know Tag"
                if let soundArtistsYouKnowTag = self.soundArtistsYouKnow {
                    cell.chosenSoundTagLabel.text = soundArtistsYouKnowTag
                }
                tableView.separatorStyle = .singleLine
                break
                
            case 3:
                cell.soundTagLabel.text = "Mood Tag"
                if let soundMood = self.soundMood {
                    cell.chosenSoundTagLabel.text = soundMood
                }
                tableView.separatorStyle = .singleLine
                break
                
            case 4:
                cell.soundTagLabel.text = "Activity Tag"
                if let soundActivity = self.soundActivity {
                    cell.chosenSoundTagLabel.text = soundActivity
                }
                tableView.separatorStyle = .singleLine
                
            case 5:
                cell.soundTagLabel.text = "More Tags"
                if let soundMoreTags = self.soundMoreTags {
                    cell.chosenSoundTagLabel.text = soundMoreTags
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
        switch indexPath.row {
        case 0:
            self.showPickerView("Genre")
            self.soundGenre = "Hip-Hop/Rap"
            break
            
        case 2:
            self.showPickerView("Artists You Know")
            self.soundArtistsYouKnow = "Drake"
            break
            
        case 3:
            self.showPickerView("Mood")
            self.soundMood = "Happy"
            break
            
        case 4:
            self.showPickerView("Activity")
            self.soundActivity = "Creative"
            break
            
        default:
            break
        }
    }
    
    func showPickerView(_ title: String) {
        let alert = UIAlertController(title: "Choose \(title) Tag", message: "\n\n\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: { action in
            self.tableView.reloadData()
        }))
        alert.isModalInPopover = true
        
        //  Create a frame (placeholder/wrapper) for the picker and then create the picker
        let pickerFrame = CGRect(x: 0, y: 0, width: self.view.frame.width - 20, height: self.view.frame.height * (1/3)) // CGRectMake(left), top, width, height) - left and top are like margins
        let picker = UIPickerView(frame: pickerFrame)
        
        //let picker = UIPickerView()
        /*picker.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(100)
            make.top.equalTo(alert.view).offset(uiElement.elementOffset)
            make.left.equalTo(alert.view).offset(uiElement.elementOffset)
            make.right.equalTo(alert.view).offset(-(uiElement.elementOffset))
            make.bottom.equalTo(alert.view).offset(-(uiElement.elementOffset))
        }*/
        
        //  set the pickers datasource and delegate
        picker.delegate = self
        picker.dataSource = self
        switch title {
        case "Genre":
            picker.tag = 0
            break
            
        case "Artists You Know":
            picker.tag = 1
            break
            
        case "Mood":
            picker.tag = 2
            break
            
        case "Activity":
            picker.tag = 3
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
            return 1
            
        case 2:
            return moods.count
            
        case 3:
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
            return "Artist You Know"
            
        case 2:
            return moods[row]
            
        case 3:
            return activities[row]
            
        default:
            return "default"
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 0:
            self.soundGenre = genres[row]
            break
            
        case 1:
            break
            
        case 2:
            self.soundMood = self.moods[row]
            break
            
        case 3:
            self.soundActivity = self.activities[row]
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
                self.uiElement.showAlert("Sound Processing Failed", message: error.localizedDescription, target: self)
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
        newSound["genre"] = soundGenre
        newSound["tags"] = tags
        newSound.saveEventually {
            (success: Bool, error: Error?) in
            if (success) {
                self.saveTags(tags)
                
            } else if let error = error {
                self.uiElement.showAlert("Oops", message: error.localizedDescription, target: self)
            }
        }
    }
    
    func getTags() -> Array<String> {
        //var tags = soundTags.text!.split{$0 == " "}.map(String.init)
        var tags = [String]()
        tags.append(soundGenre!)
        tags.append(soundActivity!)
        tags.append(soundMood!)
        
        if let currentUserCity = self.currentUserCity {
            tags.append(currentUserCity)
        }
        
        if let artistName = self.artistName {
            tags.append(artistName)
        }
    
        var finalTags = [String]()
        
        for i in 0..<tags.count {
            let tagLowercased = tags[i].lowercased()
            let tagNoSpace = tagLowercased.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            tags[i] = tagNoSpace
            
            if tags[i].hasPrefix("#") {
                tags[i].removeFirst()
            }
            
            if tags[i].hasSuffix(",") {
                tags[i].removeLast()
            }
            
            if !finalTags.contains(tags[i]) {
                finalTags.append(tags[i])
            }
        }
        
        return finalTags
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
                self.determineNextScreen()
                
            } else {
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
                self.uiElement.showAlert("Sound Processing Failed", message: error.localizedDescription, target: self)
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
            showAttributedPlaceholder(soundTitle, text: "Required")
            
        } /*else if soundTags.text!.isEmpty {
            //showAttributedPlaceholder(soundTags, text: "required: tag1 tag2 tag3")
            
        }*/ else if soundArt == nil {
            uiElement.showAlert("Oops", message: "Sound art is required.", target: self)
            
        } else if soundGenre == nil {
            uiElement.showAlert("Sound Genre is Required", message: "Tap the 'add genre tag' button to choose", target: self)
            
        } else if soundActivity == nil {
            uiElement.showAlert("Sound Activity is Required", message: "Tap the 'add activity tag' button to choose", target: self)
            
        } else if soundMood == nil {
            uiElement.showAlert("Sound Mood is Required", message: "Tap the 'add mood tag' button to choose", target: self)
            
        } else {
            return true
        }
        
        return false
    }
    
    func showAttributedPlaceholder(_ textField: UITextField, text: String) {
        textField.attributedPlaceholder = NSAttributedString(string:"\(text)",
                                                              attributes:[NSAttributedString.Key.foregroundColor: UIColor.red])
    }
    
    func loadUserInfo() {
        let query = PFQuery(className:"_User")
        query.getObjectInBackground(withId: PFUser.current()!.objectId!) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                if let city = user["city"] as? String {
                    self.currentUserCity = city
                    self.uiElement.setUserDefault("city", value: city)
                }
                
                if let artistName = user["artistName"] as? String {
                    self.artistName = artistName
                    self.uiElement.setUserDefault("artistName", value: artistName)
                }
            }
        }
    }
    
    func determineNextScreen() {
        let current = UNUserNotificationCenter.current()
        current.getNotificationSettings(completionHandler: { (settings) in
            if settings.authorizationStatus == .notDetermined {
                self.uiElement.segueToView("Main", withIdentifier: "notification", target: self)
                
            } else if settings.authorizationStatus == .denied ||
                settings.authorizationStatus == .authorized {
                self.uiElement.segueToView("Main", withIdentifier: "main", target: self)
            }
        })
    }
}

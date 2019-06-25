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
import TwitterKit
import FirebaseDynamicLinks
import FacebookCore
import FacebookLogin
import FacebookShare
import Zip

class SoundInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NVActivityIndicatorViewable, TagDelegate {
    
    let uiElement = UIElement()
    
    var currentUserCity: String?
    var artistName: String?
    
    let color = Color()
    var soundArt: PFFileObject?
    var soundArtButton: UIButton!
    var soundArtDidFinishProcessing = false
    
    var soundTitle: UITextField!
    
    var soundParseFile: PFFileObject!
    var soundFileURL: URL!
    var soundFileExtension: String!
    var soundParseFileDidFinishProcessing = false
    var didPressUploadButton = false
    
    var soundThatIsBeingEdited: Sound?
    
    var uploadButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if soundThatIsBeingEdited == nil {
            TWTRTwitter.sharedInstance().start(withConsumerKey: "shY1N1YKquAcxJF9YtdFzm6N3", consumerSecret: "dFzxXdA0IM9A7NsY3JzuPeWZhrIVnQXiWFoTgUoPVm0A2d1lU1")
            getTwitterUserID()
            
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
        if section == 2 {
            return 5
        } else if section == 3 {
            return 2
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: SoundInfoTableViewCell!
        
        if indexPath.section == 0 && soundThatIsBeingEdited != nil {
            cell = soundTitleImageCell()
            
        } else {
            switch indexPath.section {
            case 0:
                cell = self.tableView.dequeueReusableCell(withIdentifier: soundProgressReuse) as? SoundInfoTableViewCell
                self.progressSliderTitle = cell.titleLabel
                self.progressSlider = cell.progressSlider
                tableView.separatorStyle = .none
                if !didStartCompressingAudio {
                    compressAudio()
                }
                break
                
            case 1:
                cell = soundTitleImageCell()
                break
                
            case 2:
                cell = tagCell(indexPath, tableView: tableView)
                break
                
            case 3:
                cell = socialCell(indexPath)
                break
                
            default:
                break
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
    
    func soundTitleImageCell() -> SoundInfoTableViewCell {
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
    
    //mark: social
    func socialCell(_ indexPath: IndexPath) -> SoundInfoTableViewCell {
        var socialTitle: String!
        var tag: Int!
        let cell = self.tableView.dequeueReusableCell(withIdentifier: soundSocialReuse) as! SoundInfoTableViewCell
        
        if indexPath.row == 0 {
            if shouldPostLinkToFacebook {
                cell.socialSwitch.isOn = true
            }
            socialTitle = "Facebook"
            tag = 0
            
        } else {
            socialTitle = "Twitter"
            if shouldPostLinkToTwitter {
                cell.socialSwitch.isOn = true
            }
            tag = 1
        }
        
        cell.soundTagLabel.text = "Share To \(socialTitle!)"
        cell.socialSwitch.addTarget(self, action: #selector(self.didPressSocialSwitch(_:)), for: .valueChanged)
        cell.socialSwitch.tag = tag
        tableView.separatorStyle = .none
        return cell
    }
    
    @objc func didPressSocialSwitch(_ sender: UISwitch) {
        if sender.tag == 0 {
            checkFacebookAuth(sender)
        } else {
            checkTwitterAuth(sender)
        }
    }
    
    func createDynamicLink(_ sound: Sound) {
        let title = sound.title!
        let description = "\(sound.title!) by \(sound.artist!.name!)"
        let imageURL = sound.artURL!
        let objectId = sound.objectId!
        
        guard let link = URL(string: "https://soundbrew.app/sound/\(objectId)") else { return }
        let dynamicLinksDomainURIPrefix = "https://soundbrew.page.link"
        let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: dynamicLinksDomainURIPrefix)
        linkBuilder!.iOSParameters = DynamicLinkIOSParameters(bundleID: "com.soundbrew.soundbrew-artists")
        linkBuilder!.iOSParameters!.appStoreID = "1438851832"
        linkBuilder!.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        linkBuilder!.socialMetaTagParameters!.title = "\(title)"
        linkBuilder!.socialMetaTagParameters!.descriptionText = description
        linkBuilder!.socialMetaTagParameters!.imageURL = URL(string: imageURL)
        linkBuilder!.shorten() { url, warnings, error in
            if let error = error {
                print(error)
            } else if let url = url {
                if self.shouldPostLinkToFacebook {
                    self.postToFacebook(url, sound: sound)
                }
                if self.shouldPostLinkToTwitter {
                    self.postTweet(url, sound: sound)
                }
            }
        }
    }
    
    //mark: facebook
    var shouldPostLinkToFacebook = false
    
    func checkFacebookAuth(_ sender: UISwitch) {
        if sender.isOn {
            if AccessToken.current == nil {
                authenticateFacebook(sender)

            } else {
                shouldPostLinkToFacebook = true
            }
            
        } else {
            shouldPostLinkToFacebook = false
        }
    }
    func authenticateFacebook(_ sender: UISwitch) {
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [.publicProfile], viewController: self) { loginResult in
            switch loginResult {
            case .failed(let error):
                print(error)
            case .cancelled:
                print("User cancelled login.")
                sender.isOn = false
            case .success:
                self.shouldPostLinkToFacebook = true
            }
        }
    }
    
    func postToFacebook(_ url: URL, sound: Sound) {
        let content = LinkShareContent(url: url)
        
        let shareDialog = ShareDialog(content: content)
        shareDialog.mode = .native
        shareDialog.failsOnInvalidData = true
        shareDialog.completion = { result in
            // Handle share results
        }
        
        do {
        try shareDialog.show()
        } catch let error {
            print(error)
        }
    }
    
    //mark: twitter
    var twitterUserID: String?
    var shouldPostLinkToTwitter = false
    
    func getTwitterUserID() {
        let store = TWTRTwitter.sharedInstance().sessionStore
        if let userId = store.session()?.userID {
            self.twitterUserID = userId
        }
    }
    
    func checkTwitterAuth(_ sender: UISwitch) {
        if sender.isOn {
            if twitterUserID == nil {
                authenticateTwitter(sender)
            } else {
                shouldPostLinkToTwitter = true
            }
        } else {
            shouldPostLinkToTwitter = false
        }
    }
    
    func authenticateTwitter(_ sender: UISwitch) {
        TWTRTwitter.sharedInstance().logIn(completion: { (session, error) in
            if let session = session {
                self.twitterUserID = session.userID
                self.shouldPostLinkToTwitter = true
            } else if let error = error {
                print("error: \(error.localizedDescription)");
                sender.isOn = false
            }
        })
    }
    
    func postTweet(_ url: URL, sound: Sound) {
        if let userID = self.twitterUserID {
            let client = TWTRAPIClient(userID: userID)
            let statusesShowEndpoint = "https://api.twitter.com/1.1/statuses/update.json"
            let params = ["status": "Listen to \(sound.title!) on #soundbrew \(url)"]
            var clientError : NSError?
            let request = client.urlRequest(withMethod: "POST", urlString: statusesShowEndpoint, parameters: params, error: &clientError)
            client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
                if let connectionError = connectionError {
                    print("Error: \(connectionError)")
                }
                do {
                    if let data = data {
                        let json = try JSONSerialization.jsonObject(with: data, options: [])
                        print("json: \(json)")
                    }
                } catch let jsonError as NSError {
                    print("json error: \(jsonError.localizedDescription)")
                }
            }
        }
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
    
    func tagCell(_ indexPath: IndexPath, tableView: UITableView) -> SoundInfoTableViewCell {
       let cell = self.tableView.dequeueReusableCell(withIdentifier: soundTagReuse) as! SoundInfoTableViewCell
        
        switch indexPath.row {
        case 0:
            determineTag(cell, soundTagLabel: "Genre Tag", tag: self.genreTag)
            tableView.separatorStyle = .none
            break
        case 1:
            determineTag(cell, soundTagLabel: "Mood Tag", tag: self.moodTag)
            tableView.separatorStyle = .none
            break
        case 2:
            determineTag(cell, soundTagLabel: "Activity Tag", tag: self.activityTag)
            tableView.separatorStyle = .none
            break
        case 3:
            determineTag(cell, soundTagLabel: "Similar Tag", tag: self.similarArtistTag)
            tableView.separatorStyle = .none
            break
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
            tableView.separatorStyle = .singleLine
        default:
            break
        }
        
        
        return cell
    }
    
    func determineTag(_ cell: SoundInfoTableViewCell, soundTagLabel: String, tag: Tag?) {
        cell.soundTagLabel.text = soundTagLabel
        if let tag = tag {
            cell.chosenSoundTagLabel.text = tag.name
            cell.chosenSoundTagLabel.textColor = color.blue()
        }
    }
    
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
    var progressSliderTitle: UILabel!
    
    var didStartCompressingAudio = false
    
    func compressAudio() {
        didStartCompressingAudio = true 
        do {
            let zipFilePath = try TemporaryFile(creatingTempDirectoryForFilename: self.soundFileURL.lastPathComponent)
            try Zip.zipFiles(paths: [self.soundFileURL], zipFilePath: zipFilePath.fileURL, password: nil, progress: { (progress) -> () in
                self.progressSliderTitle.text = "Compressing Audio..."
                self.progressSlider.value = Float(progress)
                print("audio compression progress: \(progress)")
                
                if progress >= 1 {
                    self.processAudioForDatabase(zipFilePath)
                }
            })
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func processAudioForDatabase(_ zipFilePath: TemporaryFile) {
        do {
            self.soundFileExtension = "\(zipFilePath.fileURL.pathExtension)"
            let audioFile = try Data(contentsOf: zipFilePath.fileURL, options: .uncached)
            self.soundParseFile = PFFileObject(name: "audio.zip", data: audioFile)
            self.saveAudioFile()
            DispatchQueue.main.async {
                do {
                    try zipFilePath.deleteDirectory()
                    
                } catch let error {
                    print("error deleting temp file: \(error)")
                }
            }
            
        } catch {
            //UIElement().showAlert("Oops", message: "There was an issue with your upload.", target: self)
            //TODO segue back to last view so they can upload sound
        }
    }
    
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
            self.progressSliderTitle.text = "Processing Audio..."
            self.progressSlider!.value = Float(percentDone)
        })
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

    //mark: data
    func saveSound() {
        let tags = getTags()
        let newSound = PFObject(className: "Post")
        newSound["userId"] = PFUser.current()!.objectId!
        newSound["title"] = soundTitle.text
        //newSound["audioFile"] = soundParseFile
        newSound["audioFileCompressed"] = soundParseFile
        newSound["fileExtension"] = soundFileExtension
        newSound["isRemoved"] = true 
        newSound["songArt"] = soundArt
        newSound["tags"] = tags.map {$0.name}
        newSound.saveEventually {
            (success: Bool, error: Error?) in
            if (success) {
                if self.shouldPostLinkToTwitter || self.shouldPostLinkToFacebook {
                    let sound = self.newSoundObject(newSound)
                    self.createDynamicLink(sound)
                }
                self.saveTags(tags)
                Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                    AnalyticsParameterItemID: "id-soundupload",
                    AnalyticsParameterItemName: "sound upload",
                    AnalyticsParameterContentType: "soundupload"
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
    
    func newSoundObject(_ object: PFObject) -> Sound {
        let title = object["title"] as! String
        let art = object["songArt"] as! PFFileObject
        let audio = object["audioFile"] as! PFFileObject
        let tags = object["tags"] as! Array<String>
        
        let userId = object["userId"] as! String
        let artist = Artist(objectId: userId, name: PFUser.current()?.username, city: nil, image: nil, isVerified: nil, username: "", website: "", bio: "", email: "", isFollowedByCurrentUser: nil, followerCount: nil)
        
        let sound = Sound(objectId: object.objectId, title: title, artURL: art.url!, artImage: nil, artFile: art, tags: tags, createdAt: object.createdAt!, plays: 0, audio: audio, audioURL: audio.url!, relevancyScore: 0, audioData: nil, artist: artist, isLiked: nil, likes: 0, tmpFile: nil)
        
        return sound
    }
    
    
    //mark: utility
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
}

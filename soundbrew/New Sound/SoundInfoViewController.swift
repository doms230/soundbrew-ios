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
import TwitterKit
import FirebaseDynamicLinks
import AppCenterAnalytics
//import Zip

class SoundInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NVActivityIndicatorViewable, TagDelegate {
    
    let uiElement = UIElement()
    
    var currentUserCity: String?
    var artistName: String?
    
    let color = Color()
    var soundArtDidFinishProcessing = false
    var soundTitle: UITextView!
    var soundParseFileDidFinishProcessing = false
    var didPressUploadButton = false
    
    var soundThatIsBeingEdited: Sound?
    
    var uploadButton: UIBarButtonItem!
    
    let localizedAdd = NSLocalizedString("add", comment: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getTwitterUserID()
        getSelectedTags()
        setUpViews()
        setUpTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //loading city Tag, so want to get most recent data if user updated profile.
        if tableView != nil {
            self.tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTags" {
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
    }
    
    //mark: views
    let localizedCancel = NSLocalizedString("cancel", comment: "")
    func setUpViews() {
        var shouldUploadButtonBeEnabled = false
        if soundThatIsBeingEdited?.objectId != nil {
            shouldUploadButtonBeEnabled = true
            soundParseFileDidFinishProcessing = true 
        }
        let localizedRelease = NSLocalizedString("release", comment: "")
        uploadButton = UIBarButtonItem(title: localizedRelease, style: .plain, target: self, action: #selector(self.didPressUploadButton(_:)))
        uploadButton.isEnabled = shouldUploadButtonBeEnabled
        self.navigationItem.rightBarButtonItem = uploadButton
        
        self.navigationItem.hidesBackButton = true
        let backButton = UIBarButtonItem(title: localizedCancel, style: .plain, target: self, action: #selector(didPressCancelButton(_:)))
        self.navigationItem.leftBarButtonItem = backButton
    }
    
    @objc func didPressCancelButton(_ sender: UIBarButtonItem) {
        self.soundThatIsBeingEdited?.title = self.soundTitle.text
        if let sound = self.soundThatIsBeingEdited {
            if sound.isDraft! && self.soundParseFileDidFinishProcessing {
                showDraftOrDiscardMessage()
            } else {
                self.uiElement.goBackToPreviousViewController(self)
            }
        }
    }
    
    func showDraftOrDiscardMessage() {
        let localizedIfYouGobackMessage = NSLocalizedString("ifYouGoBackMessage", comment: "")
        let menuAlert = UIAlertController(title: localizedIfYouGobackMessage, message: nil , preferredStyle: .actionSheet)
        menuAlert.addAction(UIAlertAction(title: localizedCancel, style: .cancel, handler: nil))
        let localizedSaveDraft = NSLocalizedString("saveDraft", comment: "")
        menuAlert.addAction(UIAlertAction(title: localizedSaveDraft, style: .default, handler: { action in
            if let sound = self.soundThatIsBeingEdited {
                if sound.objectId == nil {
                    self.createSound(sound, isDraft: true)
                } else {
                    self.updateSound(sound, isDraft: true)
                }
            }
            
            MSAnalytics.trackEvent("SoundInfoViewController", withProperties: ["Button" : "Save Draft", "Description": "User save sound as draft"])
        }))
        let localizedDiscard = NSLocalizedString("discard", comment: "")
        menuAlert.addAction(UIAlertAction(title: localizedDiscard, style: .default, handler: { action in
            self.uiElement.goBackToPreviousViewController(self)
            
            MSAnalytics.trackEvent("SoundInfoViewController", withProperties: ["Button" : "Discard", "Description": "User discarded sound"])
        }))
        self.present(menuAlert, animated: true, completion: nil)
    }
    
    //MARK: Tableview
    var tableView: UITableView!
    let soundInfoReuse = "soundInfoReuse"
    let soundTagReuse = "soundTagReuse"
    let soundProgressReuse = "soundProgressReuse"
    let soundSocialReuse = "soundSocialReuse"
    let dividerReuse = "dividerReuse"
    
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundInfoReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundTagReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundProgressReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundSocialReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: dividerReuse)
        tableView.backgroundColor = color.black()
        tableView.keyboardDismissMode = .onDrag
        //tableView.separatorStyle = .singleLine
        tableView.frame = view.bounds
        self.view.addSubview(tableView)
        
        if soundThatIsBeingEdited?.objectId == nil {
            processAudioForDatabase(nil)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if soundThatIsBeingEdited?.objectId != nil {
            return 5
        }
        return 6
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var tagSection = 3
        var socialSection = 5
        if soundThatIsBeingEdited?.objectId != nil {
            tagSection = 2
            socialSection = 4
        }
        
        if section == tagSection {
            return 5
        } else if section == socialSection {
            return 2
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: SoundInfoTableViewCell!
    
        var soundProgress = 0
        var titleSection = 1
        var tagSection = 3
        var socialSection = 5
        
        if soundThatIsBeingEdited?.objectId != nil {
            soundProgress = -1
            titleSection = 0
            tagSection = 2
            socialSection = 4
        }
        
        switch indexPath.section {
        case soundProgress:
            cell = self.tableView.dequeueReusableCell(withIdentifier: soundProgressReuse) as? SoundInfoTableViewCell
            self.progressSliderTitle = cell.titleLabel
            self.progressSlider = cell.progressSlider
            //tableView.separatorStyle = .none
            break
            
        case titleSection:
            cell = titleImageCell()
            break
            
        case tagSection:
            cell = tagCell(indexPath, tableView: tableView)
            break
            
        case socialSection:
            cell = socialCell(indexPath)
            break
            
        default:
            cell = self.tableView.dequeueReusableCell(withIdentifier: dividerReuse) as? SoundInfoTableViewCell
            break
        }
        
        cell.selectionStyle = .none
        cell.backgroundColor = color.black()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var tagSection = 3
        if self.soundThatIsBeingEdited?.objectId != nil {
            tagSection = 2
        }
        
        if indexPath.section == tagSection {
            switch indexPath.row {
            case 0:
                self.tagType = "city"
                break
            case 1:
                self.tagType = "genre"
                break
                
            case 2:
                self.tagType = "mood"
                break
                
            case 3:
                self.tagType = "activity"
                break
                
            case 4:
                self.tagType = "more"
                self.tagsToUpdateInChooseTagsViewController = moreTags
                break
                
            default:
                break
            }
            
            if self.tagType == "city" {
                let localizedCityTagTitle = NSLocalizedString("cityTag", comment: "")
                let localizedCityTagMessage = NSLocalizedString("cityTagMessage", comment: "")
                self.uiElement.showAlert(localizedCityTagTitle, message: localizedCityTagMessage, target: self)
            } else {
                self.performSegue(withIdentifier: showTags, sender: self)
            }
        }
    }
    
    func titleImageCell() -> SoundInfoTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: soundInfoReuse) as! SoundInfoTableViewCell
        
        if let sound = soundThatIsBeingEdited {
            if let soundArtImage = sound.artImage {
                cell.soundArt.setImage(soundArtImage, for: .normal)
            } else if let soundArtURL = sound.artURL {
                cell.soundArt.kf.setImage(with: URL(string: soundArtURL), for: .normal)
                self.soundThatIsBeingEdited?.artImage = cell.soundArt.imageView?.image
            }
            
            if cell.inputTitle.text!.isEmpty, let soundTitle = sound.title {
                cell.inputTitle.text = soundTitle
            }
                        
           /* if cell.soundTitle.text!.isEmpty, let soundTitle = sound.title {
                cell.soundTitle.text = soundTitle
            }*/
        }
        
        cell.soundArt.addTarget(self, action: #selector(didPressUploadSongArtButton(_:)), for: .touchUpInside)
        
        soundTitle = cell.inputTitle
        tableView.separatorStyle = .singleLine
        
        return cell
    }
    
    //mark: social
    func socialCell(_ indexPath: IndexPath) -> SoundInfoTableViewCell {
        var socialTitle: String!
        var tag: Int!
        let cell = self.tableView.dequeueReusableCell(withIdentifier: soundSocialReuse) as! SoundInfoTableViewCell
        
        if indexPath.row == 0 {
            if shouldPostToSnapchat {
                cell.socialSwitch.isOn = true
            }
            socialTitle = "Snapchat"
            tag = 0
            
        } else {
            socialTitle = "Twitter"
            if shouldPostLinkToTwitter {
                cell.socialSwitch.isOn = true
            }
            tag = 1
        }
        let localizedShareLinkTo = NSLocalizedString("shareLinkTo", comment: "")
        cell.soundTagLabel.text = "\(localizedShareLinkTo) \(socialTitle!)"
        cell.socialSwitch.addTarget(self, action: #selector(self.didPressSocialSwitch(_:)), for: .valueChanged)
        cell.socialSwitch.tag = tag
        tableView.separatorStyle = .none
        return cell
    }
    
    @objc func didPressSocialSwitch(_ sender: UISwitch) {
        if sender.tag == 0 {
            shouldPostToSnapchat = true
        } else {
            checkTwitterAuth(sender)
        }
    }
    
    /*func createDynamicLink(_ object: PFObject) {
        let title = object["title"] as! String
        let description = "\(title) by \(PFUser.current()!.username!)"
        let art = object["songArt"] as! PFFileObject
        let imageURL = art.url!
        let objectId = object.objectId!
        
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
                /*if self.shouldPostLinkToFacebook {
                    let ya = URL(string: "https://www.instagram.com")
                    self.postToFacebook(ya!)
                }*/
                if self.shouldPostLinkToTwitter {
                    self.postTweet(url, title: title)
                }
            }
        }
    }*/
    
    //mark: Snapchat
    var shouldPostToSnapchat = false
    
    //mark: twitter
    var twitterUserID: String?
    var shouldPostLinkToTwitter = false
    
    func getTwitterUserID() {
        let store = TWTRTwitter.sharedInstance().sessionStore
        
        if let userId = store.session()?.userID {
            self.twitterUserID = userId
            shouldPostLinkToTwitter = true
            if self.tableView != nil {
                self.tableView.reloadData()
            }
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
    
    func postTweet(_ url: URL, title: String) {
        if let userID = self.twitterUserID {
            let client = TWTRAPIClient(userID: userID)
            let statusesShowEndpoint = "https://api.twitter.com/1.1/statuses/update.json"
            let params = ["status": "Listen to \(title) on @sound_brew \(url)"]
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
    var artistTag: Tag?
    var tagsToUpdateInChooseTagsViewController: Array<Tag>?
    
    func getSelectedTags() {
        if let soundTags = soundThatIsBeingEdited?.tags {
            for tag in soundTags {
                loadTag(tag, type: nil)
            }
        }
        
        if let currentUser = Customer.shared.artist {
            loadCurrentUserCity(currentUser.objectId)
            if let username = currentUser.username {
                loadTag(username, type: "artist")
            }
        }
    }
    
    func tagCell(_ indexPath: IndexPath, tableView: UITableView) -> SoundInfoTableViewCell {
       let cell = self.tableView.dequeueReusableCell(withIdentifier: soundTagReuse) as! SoundInfoTableViewCell
        let localizedTag = NSLocalizedString("tag", comment: "")
        let localizedTags = NSLocalizedString("tags", comment: "")
        
        switch indexPath.row {
        case 0:
            let localizedCityTag = NSLocalizedString("cityTag", comment: "")
            cell.soundTagLabel.text = localizedCityTag
            cell.chosenSoundTagLabel.textColor = .darkGray
            if let currentArtistCity = Customer.shared.artist?.city {
                cell.chosenSoundTagLabel.text = currentArtistCity
            } else {
                let localizedNone = NSLocalizedString("none", comment: "")
                cell.chosenSoundTagLabel.text = localizedNone
                cell.chosenSoundTagLabel.textColor = .darkGray
            }
            tableView.separatorStyle = .none
            break
        case 1:
            determineTag(cell, soundTagLabel: "Genre \(localizedTag)", tag: self.genreTag)
            tableView.separatorStyle = .none
            break
            
        case 2:
            determineTag(cell, soundTagLabel: "\(self.uiElement.localizedMood.capitalized) \(localizedTag)", tag: self.moodTag)
            tableView.separatorStyle = .none
            break
            
        case 3:
            determineTag(cell, soundTagLabel: "\(self.uiElement.localizedActivity.capitalized) \(localizedTag)", tag: self.activityTag)
            tableView.separatorStyle = .none
            break
            
        case 4:
            cell.soundTagLabel.text = "\(self.uiElement.localizedMore.capitalized) \(localizedTags)"
        if let moreTags = self.moreTags {
            if moreTags.count == 1 {
                cell.chosenSoundTagLabel.text = "\(moreTags.count) \(localizedTag)"
            } else {
                cell.chosenSoundTagLabel.text = "\(moreTags.count) \(localizedTags)"
            }
            
            cell.chosenSoundTagLabel.textColor = .white
            
        } else {
            cell.chosenSoundTagLabel.text = localizedAdd.capitalized
            cell.chosenSoundTagLabel.textColor = color.red()
        }
        tableView.separatorStyle = .singleLine
            break
            
        default:
            break
        }
        
        return cell
    }
    
    func determineTag(_ cell: SoundInfoTableViewCell, soundTagLabel: String, tag: Tag?) {
        cell.soundTagLabel.text = soundTagLabel
        if let tag = tag {
            cell.chosenSoundTagLabel.text = tag.name
            cell.chosenSoundTagLabel.textColor = .white 
            
        } else {
            cell.chosenSoundTagLabel.text = localizedAdd.capitalized
            cell.chosenSoundTagLabel.textColor = color.red()
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
                default:
                    self.moreTags = chosenTags
                    break
                }
                
            } else if tagType == "more" {
                self.moreTags = nil 
            }
        }
        
        self.tableView.reloadData()
    }
    
    func combineSelectedTags() -> Array<Tag> {
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
        
        if let artistTag = self.artistTag{
            tags.append(artistTag)
        }
        
        self.soundThatIsBeingEdited?.tags = tags.map {$0.name}
        
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
        self.finishUp(true)
    }
    
    func loadTag(_ tag: String, type: String?) {
        let query = PFQuery(className: "Tag")
        query.whereKey("tag", equalTo: tag)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            var retreivedTag: Tag!
            var retreivedType: String?
            if let object = object {
                if let type = object["type"] as? String {
                    retreivedType = type
                }
                retreivedTag = Tag(objectId: object.objectId, name: object["tag"] as? String, count: 0, isSelected: false, type: retreivedType, image: nil)
                
            } else {
                if let type = type {
                    retreivedType = type
                }
                retreivedTag = Tag(objectId: nil, name: tag, count: 0, isSelected: false, type: retreivedType, image: nil)
            }
            
            if let type = retreivedType {
                switch type {
                case "genre":
                    self.genreTag = retreivedTag
                    break
                    
                case "city":
                    self.cityTag = retreivedTag
                    break
                    
                case "mood":
                    self.moodTag = retreivedTag
                    break
                    
                case "activity":
                    self.activityTag = retreivedTag
                    break
                    
                case "artist":
                    self.artistTag = retreivedTag
                    break
                                                   
                default:
                    self.moreTags?.append(retreivedTag)
                    break
                }
            }
            if self.tableView != nil {
                self.tableView.reloadData()
            }
        }
    }
    
    //mark: audio
    var progressSlider: UISlider!
    var progressSliderTitle: UILabel!
    
    func processAudioForDatabase(_ zipFilePath: TemporaryFile?) {
        do {
            if let soundFileString = soundThatIsBeingEdited?.audioURL {
                let soundFileURL = URL(string: soundFileString)
                let audioFile = try Data(contentsOf: soundFileURL!, options: .uncached)
                self.soundThatIsBeingEdited?.audio = PFFileObject(name: "audio.\(soundFileURL!.lastPathComponent)", data: audioFile)
                self.saveAudioFile(self.soundThatIsBeingEdited!.audio!)
            }
        } catch let error {
            let localizedIssueWithUpload = NSLocalizedString("issueWithUpload", comment: "")
            self.errorAlert(self.uiElement.localizedOops, message: "\(localizedIssueWithUpload) \(error)")
        }
    }
    
    func saveAudioFile(_ soundParseFile: PFFileObject) {
        let localizedAudioProcessingComplete = NSLocalizedString("audioProcessingComplete", comment: "")
        soundParseFile.saveInBackground({
            (succeeded: Bool, error: Error?) -> Void in
            if succeeded {
                self.soundParseFileDidFinishProcessing = true
                self.uploadButton.isEnabled = true
                self.progressSliderTitle.text = localizedAudioProcessingComplete
                
            } else if let error = error {
                self.errorAlert("Sound Processing Failed", message: error.localizedDescription)
                
            }
            
        }, progressBlock: {
            (percentDone: Int32) -> Void in
            let localizedProcessingAudio = NSLocalizedString("processingAudio", comment: "")
            self.progressSliderTitle.text = localizedProcessingAudio
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
        
        self.soundThatIsBeingEdited?.artImage = image
        self.tableView.reloadData()
        
        let proPic = image.jpegData(compressionQuality: 0.5)
        self.soundThatIsBeingEdited?.artFile = PFFileObject(name: "soundArt.jpeg", data: proPic!)
        self.soundThatIsBeingEdited?.artFile!.saveInBackground({
            (succeeded: Bool, error: Error?) -> Void in
            if succeeded {
                self.soundArtDidFinishProcessing = true
                
                if self.didPressUploadButton && self.soundParseFileDidFinishProcessing {
                    self.createSound(self.soundThatIsBeingEdited!, isDraft: false)
                }
                
            } else if let error = error {
                let localizedArtProcessingFailed = NSLocalizedString("artProcessingFailded", comment: "")
                self.errorAlert(localizedArtProcessingFailed, message: error.localizedDescription)
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
    @objc func didPressUploadButton(_ sender: UIBarButtonItem) {
        self.soundThatIsBeingEdited?.title = self.soundTitle.text
        if let sound = soundThatIsBeingEdited {
            if isSoundInfoCorrect(sound) {
                if sound.objectId != nil {
                    updateSound(sound, isDraft: false)
                } else if soundParseFileDidFinishProcessing && soundArtDidFinishProcessing {
                    createSound(sound, isDraft: false)
                } else {
                    didPressUploadButton = true
                }
            }
        }
    }

    //mark: data
    func createSound(_ sound: Sound, isDraft: Bool) {
        self.startAnimating()
        let tags = combineSelectedTags()
        let newSound = PFObject(className: "Post")
        newSound["userId"] = sound.artist!.objectId
        if let title = sound.title {
            newSound["title"] = title
        }
        newSound["audioFile"] = sound.audio!
        if let artFile = sound.artFile {
            newSound["songArt"] = artFile
        }
        newSound["tags"] = sound.tags
        newSound["isDraft"] = isDraft
        newSound["isRemoved"] = isDraft
        newSound.saveEventually {
            (success: Bool, error: Error?) in
            if (success) {
                if isDraft {
                    self.finishUp(false)
                } else {
                    self.handleSocials(newSound)
                    self.saveTags(tags)
                    MSAnalytics.trackEvent("SoundInfoViewController", withProperties: ["Button" : "New Upload"])
                }
            } else if let error = error {
                self.stopAnimating()
                let localizedCouldNotPost = NSLocalizedString("couldNotPost", comment: "")
                self.uiElement.showAlert(localizedCouldNotPost, message: error.localizedDescription, target: self)
            }
        }
    }
    
    func updateSound(_ sound: Sound, isDraft: Bool) {
        self.startAnimating()
        let tags = combineSelectedTags()
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: sound.objectId!) {
            (object: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let object = object {
                if let soundArt = sound.artFile {
                    object["songArt"] = soundArt
                }
                if let title = sound.title {
                    object["title"] = title
                }
                
                object["tags"] = tags.map {$0.name}
                object["isDraft"] = isDraft
                object["isRemoved"] = isDraft
                object.saveEventually {
                    (success: Bool, error: Error?) in
                    if (success) {
                        if isDraft {
                            self.finishUp(false)
                        } else {
                            self.saveTags(tags)
                            self.handleSocials(object)
                            self.finishUp(true)
                        }
                        
                    } else if let error = error {
                        self.stopAnimating()
                        let localizedCouldNotUpdate = NSLocalizedString("couldNotUpdate", comment: "")
                        self.uiElement.showAlert(localizedCouldNotUpdate, message: error.localizedDescription, target: self)
                    }
                }
            }
        }
    }
    
    func handleSocials(_ object: PFObject) {
        if self.shouldPostLinkToTwitter {
            let title = object["title"] as! String
            let objectId = object.objectId!
            if let url = self.uiElement.getSoundbrewURL(objectId, path: "s") {
                self.postTweet(url, title: title)
            }
        }
        
        if self.shouldPostToSnapchat {
            self.uiElement.shareToSnapchat(self.soundThatIsBeingEdited!)
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
                        self.loadTag(city.lowercased(), type: "city")
                    }
                }
            }
        }
    }
    
    //mark: utility
    func isSoundInfoCorrect(_ sound: Sound) -> Bool {
        let localizedTitleRequired = NSLocalizedString("titleRequired", comment: "")
        let localizedSoundArtRequired = NSLocalizedString("soundArtRequired", comment: "")
        let localizedTapGrayBoxArt = NSLocalizedString("tapGrayBoxArt", comment: "")
        let localizedTapGrayBoxGenre = NSLocalizedString("tapGrayBoxGenre", comment: "")
        let localizedGenreRequired = NSLocalizedString("genreRequired", comment: "")
        let localizedMoodRequired = NSLocalizedString("moodRequired", comment: "")
        let localizedActivityRequired = NSLocalizedString("activityRequired", comment: "")
        let localizedTapGrayBoxMood = NSLocalizedString("tapGrayBoxMood", comment: "")
        let localizedTapGrayBoxActivity = NSLocalizedString("tapGrayBoxActivity", comment: "")
        if let sound = soundThatIsBeingEdited {
            if sound.title!.isEmpty {
                //showAttributedPlaceholder(soundTitle, text: localizedTitleRequired)
                uiElement.showAlert(localizedTitleRequired, message: "", target: self)
            } else if sound.artFile == nil && sound.artURL == nil {
                uiElement.showAlert(localizedSoundArtRequired, message: localizedTapGrayBoxArt, target: self)
            }else if genreTag == nil {
                uiElement.showAlert(localizedGenreRequired, message: localizedTapGrayBoxGenre, target: self)
            } else if moodTag == nil  {
                uiElement.showAlert(localizedMoodRequired, message: localizedTapGrayBoxMood, target: self)
            } else if activityTag == nil  {
                uiElement.showAlert(localizedActivityRequired, message: localizedTapGrayBoxActivity, target: self)
            } else {
                return true
            }
        }
        return false
    }
    
    /*func showAttributedPlaceholder(_ textField: UITextView, text: String) {
        //textField.attributedPlaceholder = NSAttributedString(string:"\(text)",
            attributes:[NSAttributedString.Key.foregroundColor: UIColor.red])
    }*/
    
    func errorAlert(_ title: String, message: String) {
        let alertController = UIAlertController (title: title, message: message, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Okay", style: .cancel) { (_) -> Void in
            self.uiElement.goBackToPreviousViewController(self)
        }
        alertController.addAction(settingsAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func finishUp(_ shouldAskForReview: Bool) {
        self.stopAnimating()
        if shouldAskForReview {
            SKStoreReviewController.requestReview()
        }
        self.uiElement.goBackToPreviousViewController(self)
    }
}

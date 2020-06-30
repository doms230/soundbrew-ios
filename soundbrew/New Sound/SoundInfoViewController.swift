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
import UICircularProgressRing
import CropViewController

class SoundInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NVActivityIndicatorViewable, TagDelegate, ArtistDelegate, CreditDelegate, UITextViewDelegate, CropViewControllerDelegate {
    
    func receivedArtist(_ value: Artist?) {
    }
    
    let color = Color()
    let uiElement = UIElement()
    
    var soundArtDidFinishProcessing = true
    var didPressUploadButton = false
    var soundParseFileDidFinishProcessing = false
    
    var soundThatIsBeingEdited: Sound?
        
    let localizedAdd = NSLocalizedString("add", comment: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getSelectedTags()
        setUpViews()
        setUpTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //loading city Tag, so want to get most recent data if user updated profile.
        self.tableView.reloadData()
    }
        
   /* override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navigationController = segue.destination as! UINavigationController
        
        switch segue.identifier {
        case "showTags":
            prepareTagView(navigationController)
            break
            
        default:
            break
        }
    }*/
    
    //mark: views
    var uploadButton: UIBarButtonItem!
    var backButton: UIBarButtonItem!
    func setUpViews() {
        var shouldUploadButtonBeEnabled = false
        if soundThatIsBeingEdited?.objectId != nil {
            shouldUploadButtonBeEnabled = true
        }
        
        uploadButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.didPressUploadButton(_:)))
        uploadButton.isEnabled = shouldUploadButtonBeEnabled
        self.navigationItem.rightBarButtonItem = uploadButton
    }
    
    @objc func didPressGoBackButton(_ sender: UIBarButtonItem) {
        self.uiElement.goBackToPreviousViewController(self)
    }
    
    func saveDraft() {
        if let sound = self.soundThatIsBeingEdited {
            if sound.objectId == nil {
                self.createSound(sound, isDraft: true)
            } else {
                self.updateSound(sound, isDraft: true)
            }
        }
    }
    
    //MARK: Tableview
    var tableView = UITableView()
    let soundInfoReuse = "soundInfoReuse"
    let soundTagReuse = "soundTagReuse"
    let soundProgressReuse = "soundProgressReuse"
    let fanClubExcluseReuse = "soundSocialReuse"
    let dividerReuse = "dividerReuse"
    let audioImageCellSection = 0
    let fanClubExclusiveSection = 2
    let creditCellSection = 4
    let tagCellSection = 6
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundInfoReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundTagReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: fanClubExcluseReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: dividerReuse)
        tableView.backgroundColor = color.black()
        tableView.keyboardDismissMode = .onDrag
        tableView.frame = view.bounds
        tableView.separatorStyle = .none
        self.view.addSubview(tableView)
        
        if soundThatIsBeingEdited?.objectId == nil {
            processAudioForDatabase()
        } else {
            self.soundParseFileDidFinishProcessing = true 
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 7
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         /*if section == tagCellSection {
            return 5
        }*/
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: SoundInfoTableViewCell!
        
        switch indexPath.section {
        case audioImageCellSection:
            cell = audioImageTitleCell()
            break
            
        case fanClubExclusiveSection:
            cell = fanClubExclusiveCell()
            break
        case creditCellSection:
            cell = creditCell(indexPath)
            break
            
        case tagCellSection:
            cell = tagCell(indexPath, tableView: tableView)
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
        switch indexPath.section {
        case audioImageCellSection:
            self.showEditTitleView()
            break
            
        case creditCellSection:
            let modal = NewCreditViewController()
            modal.creditDelegate = self
            modal.credits = credits
            self.present(modal, animated: true, completion: nil)
            break
            
        case tagCellSection:
           // didPressTagSection(indexPath)
            self.showChooseTagsView()
            break
            
        default:
            break
        }
    }

    //mark: Fan Club Exclusive
    func fanClubExclusiveCell() -> SoundInfoTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: fanClubExcluseReuse) as! SoundInfoTableViewCell
        if Customer.shared.artist?.account?.priceId != nil {
            if let isExclusive = self.soundThatIsBeingEdited?.isExclusive {
                cell.socialSwitch.isOn = isExclusive
            } else {
                cell.socialSwitch.isOn = false 
            }
        } else {
            cell.socialSwitch.isOn = false
        }
        
        cell.soundTagLabel.text = "Fan Club Exclusive 💎"
        cell.socialSwitch.addTarget(self, action: #selector(self.didPressFanClubExclusiveSwitch(_:)), for: .valueChanged)
        return cell
    }
    
    @objc func didPressFanClubExclusiveSwitch(_ sender: UISwitch) {
        if Customer.shared.artist?.account?.id == nil {
            sender.isOn = false
            self.uiElement.showAlert("Fan Club Required", message: "Earn money from your followers by starting a fan club. You can choose how much you charge per month, and which sounds are exclusive! Create your fan club on the settings panel.", target: self)
        } else {
            self.soundThatIsBeingEdited?.isExclusive = sender.isOn
        }
    }
    
    //mark: credits
    var credits = [Credit]()
    func creditCell(_ indexPath: IndexPath) -> SoundInfoTableViewCell {
        var cell: SoundInfoTableViewCell!
        cell = (self.tableView.dequeueReusableCell(withIdentifier: soundTagReuse) as! SoundInfoTableViewCell)
            
        cell.soundTagLabel.text = "Features"
                    
        cell.chosenSoundTagLabel.textColor = .white
        
        if credits.count == 0 {
            cell.chosenSoundTagLabel.text = "Add Features"
            cell.chosenSoundTagLabel.textColor = color.blue()
        } else if credits.count == 1 {
            cell.chosenSoundTagLabel.text = "\(credits.count) Feature"
        } else {
            cell.chosenSoundTagLabel.text = "\(credits.count) Features"
        }
        return cell
    }
    
    func receivedCredits(_ chosenCredits: Array<Credit>?) {
        if let credits = chosenCredits {
            self.credits = credits
            self.tableView.reloadData()
        }
    }
    
    func saveCredits(_ sound: Sound) {
        let postId = sound.objectId!
        for i in 0..<credits.count {
            let credit = credits[i]
            if i != 0 {
                newCredit(credit, postId: postId)
                self.uiElement.sendAlert("credited you on their new release '\(sound.title ?? "")'", toUserId: credit.artist!.objectId, shouldIncludeName: true)
            }
        }
    }
    
    func newCredit(_ credit: Credit, postId: String) {
        let newCredit = PFObject(className: "Credit")
        if let title = credit.title {
            newCredit["title"] = title
        } else {
            newCredit["title"] = ""
        }
        newCredit["userId"] = credit.artist!.objectId!
        newCredit["postId"] = postId
        newCredit.saveEventually()
    }

    //MARK: tags
    var soundTags: Array<Tag>?
  /*  var showTags = "showTags"
    var tagType: String?
    var genreTag: Tag?
    var moodTag: Tag?
    var activityTag: Tag?
    var moreTags: Array<Tag>?
    var cityTag: Tag?
    var artistTag: Tag?
    var tagsToUpdateInChooseTagsViewController: Array<Tag>?*/
    
    func getSelectedTags() {
        if let soundTags = soundThatIsBeingEdited?.tags {
            for tag in soundTags {
                loadTag(tag)
            }
        }
        
        if let currentUser = Customer.shared.artist {
            loadCurrentUserCity(currentUser.objectId)
            if let username = currentUser.username {
                loadTag(username)
            }
        }
    }
    
    /*func prepareTagView(_ navigationController: UINavigationController) {
        let viewController: ChooseTagsViewController = navigationController.topViewController as! ChooseTagsViewController
        viewController.tagDelegate = self
        
        if let tagType = tagType {
            viewController.tagType = tagType
            if tagType == "more", let tags = tagsToUpdateInChooseTagsViewController {
                viewController.chosenTags = tags
            }
        }
    }*/
    
    func showChooseTagsView() {
        let modal = ChooseTagsV2ViewController()
        modal.tagType = "sound"
        modal.tagDelegate = self 
        if let tags = soundTags {
            modal.chosenTagsForSound = tags
        }
        self.present(modal, animated: true, completion: nil)
    }
    
    /*func didPressTagSection(_ indexPath: IndexPath) {
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
    }*/
    
    func tagCell(_ indexPath: IndexPath, tableView: UITableView) -> SoundInfoTableViewCell {
       let cell = self.tableView.dequeueReusableCell(withIdentifier: soundTagReuse) as! SoundInfoTableViewCell
        let localizedTag = NSLocalizedString("tag", comment: "")
        let localizedTags = NSLocalizedString("tags", comment: "")
        cell.soundTagLabel.text = "Tags"
       // cell.soundTagLabel.text = "\(self.uiElement.localizedMore.capitalized) \(localizedTags)"
        if let moreTags = self.soundThatIsBeingEdited?.tags {
            if moreTags.count == 1 {
                cell.chosenSoundTagLabel.text = "\(moreTags.count) \(localizedTag)"
            } else {
                cell.chosenSoundTagLabel.text = "\(moreTags.count) \(localizedTags)"
            }
            
            cell.chosenSoundTagLabel.textColor = .white
            
        } else {
            cell.chosenSoundTagLabel.text = localizedAdd.capitalized
            cell.chosenSoundTagLabel.textColor = color.blue()
        }
        
       /* switch indexPath.row {
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
            break
        case 1:
            determineTag(cell, soundTagLabel: "Genre \(localizedTag)", tag: self.genreTag)
            break
            
        case 2:
            determineTag(cell, soundTagLabel: "\(self.uiElement.localizedMood.capitalized) \(localizedTag)", tag: self.moodTag)
            break
            
        case 3:
            determineTag(cell, soundTagLabel: "\(self.uiElement.localizedActivity.capitalized) \(localizedTag)", tag: self.activityTag)
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
            cell.chosenSoundTagLabel.textColor = color.blue()
        }
            break
            
        default:
            break
        }*/
        
        return cell
    }
    
    func determineTag(_ cell: SoundInfoTableViewCell, soundTagLabel: String, tag: Tag?) {
        cell.soundTagLabel.text = soundTagLabel
        if let tag = tag {
            cell.chosenSoundTagLabel.text = tag.name
            cell.chosenSoundTagLabel.textColor = .white 
            
        } else {
            cell.chosenSoundTagLabel.text = localizedAdd.capitalized
            cell.chosenSoundTagLabel.textColor = color.blue()
        }
    }
    
    func receivedTags(_ chosenTags: Array<Tag>?) {
        if let tags = chosenTags {
            self.soundTags = tags
            self.soundThatIsBeingEdited?.tags = tags.map {$0.name}
        } else {
            self.soundTags?.removeAll()
            self.soundThatIsBeingEdited?.tags = nil
            //self.moreTags?.removeAll()
        }
        self.tableView.reloadData()
        /*if let tagType = self.tagType {
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
        }*/
        
        self.tableView.reloadData()
    }
    
   /* func combineSelectedTags() -> Array<Tag> {
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
    }*/
    
    func saveTags(_ tags: Array<Tag>) {
        for tag in tags {
            if let tagId = tag.objectId {
                let query = PFQuery(className: "Tag")
                query.getObjectInBackground(withId: tagId) {
                    (object: PFObject?, error: Error?) -> Void in
                     if let object = object {
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
    
    func loadTag(_ tag: String) {
        let query = PFQuery(className: "Tag")
        query.whereKey("tag", equalTo: tag)
        query.cachePolicy = .networkElseCache
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if let object = object{
                let tag = Tag(objectId: object.objectId, name: object["tag"] as? String, count: 0, isSelected: false, type: object["type"] as? String, imageURL: nil, uiImage: nil)
                self.soundTags?.append(tag)
            }

            //var retreivedTag: Tag!
            //var retreivedType: String?
            /*if let object = object {
                if let type = object["type"] as? String {
                    retreivedType = type
                }
                retreivedTag = Tag(objectId: object.objectId, name: object["tag"] as? String, count: 0, isSelected: false, type: retreivedType, imageURL: nil, uiImage: nil)
                
            } else {
                if let type = type {
                    retreivedType = type
                }
                retreivedTag = Tag(objectId: nil, name: tag, count: 0, isSelected: false, type: retreivedType, imageURL: nil, uiImage: nil)
            }*/
            
            /*if let type = retreivedType {
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
            }*/
            self.tableView.reloadData()
        }
    }
    
    //mark: Title
    func showEditTitleView() {
        let modal = EditBioViewController()
        modal.bioTitle = "Sound Title"
        if let title = self.soundThatIsBeingEdited?.title {
            modal.bio = title
        }
        modal.totalAllowedTextLength = 50
        modal.artistDelegate = self
        self.present(modal, animated: true, completion: nil)
    }
    
    func audioImageTitleCell() -> SoundInfoTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: soundInfoReuse) as! SoundInfoTableViewCell
        
        self.audioProgress = cell.audioProgress
        
        cell.soundArtImageButton.addTarget(self, action: #selector(self.didPressUploadSoundArtButton(_:)), for: .touchUpInside)

        if let sound = soundThatIsBeingEdited {
            if let soundTitle = sound.title {
                cell.inputTitle.text = soundTitle
            } else {
                cell.inputTitle.text = "Add Title/Description"
            }
            
            if sound.objectId != nil {
                cell.audioProgress.value = 100
            }
                        
            if let image = sound.artImage {
                cell.soundArtImageButton.setImage(image, for: .normal)
            } else if let imageURL = sound.artFile?.url  {
                cell.soundArtImageButton.kf.setImage(with: URL(string: imageURL), for: .normal)
            }
        }
                
        return cell
    }
    
    //changed Title
    func changeBio(_ value: String?) {
        if let newtitle = value {
            self.soundThatIsBeingEdited?.title = newtitle
        } else {
            self.soundThatIsBeingEdited?.title = nil
        }
        self.tableView.reloadData()
    }
    
    //mark: audio
    var audioProgress: UICircularProgressRing!
    var progressSliderTitle: UILabel!
    
    func processAudioForDatabase() {
        if let soundFileString = soundThatIsBeingEdited?.audioURL {
            if let soundFileURL = URL(string: soundFileString) {
                if pathExtensionIsUncompressed(soundFileURL.pathExtension) {
                    self.convertAudioToM4a(soundFileURL)
                } else {
                    convertURLToDataAndSavetoDatabase(soundFileURL)
                }
                
            } else {
                let localizedIssueWithUpload = NSLocalizedString("issueWithUpload", comment: "")
                self.errorAlert(self.uiElement.localizedOops, message: "\(localizedIssueWithUpload)")
            }
        }
    }
    
    func pathExtensionIsUncompressed(_ pathExtension: String) -> Bool {
        switch pathExtension {
        case "wav", "pcm", "aiff":
            return true
        default:
            return false
        }
    }
    
    func convertURLToDataAndSavetoDatabase(_ soundfileURL: URL) {
        do {
            let audioFile = try Data(contentsOf: soundfileURL, options: .uncached)
            let name = "audio.\(soundfileURL.pathExtension)"
            self.soundThatIsBeingEdited?.audio = PFFileObject(name: name, data: audioFile)
            self.saveAudioFile(self.soundThatIsBeingEdited!.audio!)
        } catch let error {
            let localizedIssueWithUpload = NSLocalizedString("issueWithUpload", comment: "")
            self.errorAlert(self.uiElement.localizedOops, message: "\(localizedIssueWithUpload) \(error)")
        }
    }
    
    func convertAudioToM4a(_ audioURL: URL) {
        let dirPath = FileManager.default.temporaryDirectory
        let outputURL = dirPath.appendingPathComponent("audio.m4a")
        let converter = AKConverter(inputURL: audioURL, outputURL: outputURL)
        converter.start(completionHandler: { error in
            if let error = error {
                print(error)
            } else {
                self.convertURLToDataAndSavetoDatabase(outputURL)
            }
        })
    }
    
    func saveAudioFile(_ soundParseFile: PFFileObject) {
        soundParseFile.saveInBackground({
            (succeeded: Bool, error: Error?) -> Void in
            if succeeded {
                self.soundParseFileDidFinishProcessing = true
                self.uploadButton.isEnabled = true
                                
            } else if let error = error {
                let localizedProcessingAudio = NSLocalizedString("SoundProcessingFailed", comment: "")
                self.errorAlert(localizedProcessingAudio, message: error.localizedDescription)
            }
            
        }, progressBlock: {
            (percentDone: Int32) -> Void in
            self.audioProgress.value = CGFloat(percentDone)
        })
    }
    
    //mark: media upload
    @objc func didPressUploadSoundArtButton(_ sender: UIButton){
        self.soundArtDidFinishProcessing = false
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        var selectedImage: UIImage?
        if let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            selectedImage = image
        }
        
        if let image = selectedImage {
            self.presentImageCropViewController(image, picker: picker)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
        self.soundArtDidFinishProcessing = true 
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }
    
    func presentImageCropViewController(_ image: UIImage, picker: UIImagePickerController) {
        let cropViewController = CropViewController(croppingStyle: .default, image: image)
        cropViewController.aspectRatioLockEnabled = true
        cropViewController.aspectRatioPickerButtonHidden = true
        cropViewController.aspectRatioPreset = .presetSquare
        cropViewController.resetAspectRatioEnabled = false
        cropViewController.delegate = self
        picker.present(cropViewController, animated: false, completion: nil)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
                    self.soundThatIsBeingEdited?.artImage = image
        self.tableView.reloadData()
        
        let proPic = image.jpegData(compressionQuality: 0.5)
        self.soundThatIsBeingEdited?.artFile = PFFileObject(name: "soundArt.jpeg", data: proPic!)
        self.soundThatIsBeingEdited?.artFile!.saveInBackground({
            (succeeded: Bool, error: Error?) -> Void in
            if succeeded {
                self.soundArtDidFinishProcessing = true
                if self.didPressUploadButton {
                    self.releaseSound()
                }
                
            } else if let error = error {
                self.stopAnimating()
                let localizedArtProcessingFailed = NSLocalizedString("artProcessingFailded", comment: "")
                self.errorAlert(localizedArtProcessingFailed, message: error.localizedDescription)
            }
            
        }, progressBlock: {
            (percentDone: Int32) -> Void in
            // Update your progress spinner here. percentDone will be between 0 and 100.
        })
        
        dismiss(animated: true, completion: nil)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        dismiss(animated: true, completion: nil)
        self.soundArtDidFinishProcessing = true
    }
    
    //
    @objc func didPressUploadButton(_ sender: UIBarButtonItem) {
        /*var titleMessage: String!
        if self.soundThatIsBeingEdited?.objectId != nil {
            titleMessage = "Update the changes you made to this upload?"
        } else {
            titleMessage = "Save this upload for later?"
        }*/
        
        let alertController = UIAlertController (title: "", message: "", preferredStyle: .actionSheet)
        
        let yesAction = UIAlertAction(title: "Release as Single", style: .default) { (_) -> Void in
            self.releaseSound()
        }
        alertController.addAction(yesAction)
        
        let noAction = UIAlertAction(title: "Save to Drafts", style: .default) { (_) -> Void in
            self.saveDraft()
        }
        alertController.addAction(noAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) -> Void in
        }
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
       // self.didPressUploadButton = true
       // handleUploadButtonAction()
    }
    
    func releaseSound() {
        self.didPressUploadButton = true
        self.startAnimating()
        if self.soundArtDidFinishProcessing, let sound = soundThatIsBeingEdited {
            if sound.objectId != nil {
                updateSound(sound, isDraft: false)
            } else {
                createSound(sound, isDraft: false)
            }
        }
    }

    //mark: data
    func createSound(_ sound: Sound, isDraft: Bool) {
        //let tags = combineSelectedTags()
        let newSound = PFObject(className: "Post")
        newSound["userId"] = sound.artist!.objectId
        newSound["user"] = PFUser.current()
        newSound["audioFile"] = sound.audio!
        if let title = sound.title {
            newSound["title"] = title
        }
        if let artFile = sound.artFile {
            newSound["songArt"] = artFile
        }
        if let tags = sound.tags {
            newSound["tags"] = tags
        }
        
        newSound["isDraft"] = isDraft
        newSound["isRemoved"] = isDraft
        newSound["credits"] = credits.count
        if let isExclusive = sound.isExclusive {
            newSound["isExclusive"] = isExclusive
        }
        
        newSound.saveEventually {
            (success: Bool, error: Error?) in
            if (success) {
                if isDraft {
                    self.finishUp(false, object: newSound)
                } else {
                    if let tags = self.soundTags {
                        self.saveTags(tags)
                    }
                    sound.objectId = newSound.objectId
                    self.saveCredits(sound)
                    self.finishUp(true, object: newSound)
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    self.stopAnimating()
                    let localizedCouldNotPost = NSLocalizedString("couldNotPost", comment: "")
                    self.uiElement.showAlert(localizedCouldNotPost, message: error.localizedDescription, target: self)
                }
            }
        }
    }
    
    func updateSound(_ sound: Sound, isDraft: Bool) {
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
                
                if let tags = sound.tags {
                    object["tags"] = tags
                }
                
                object["isDraft"] = isDraft
                object["isRemoved"] = isDraft
                object["credits"] = self.credits.count
                if let isExclusive = sound.isExclusive {
                    object["isExclusive"] = isExclusive
                }

                object.saveEventually {
                    (success: Bool, error: Error?) in
                    if (success) {
                        if isDraft {
                            self.finishUp(false, object: object)
                        } else {
                            if let tags = self.soundTags {
                                self.saveTags(tags)
                            }
                            sound.objectId = object.objectId
                            self.saveCredits(sound)
                            self.finishUp(true, object: object)
                        }
                        
                    } else if let error = error {
                        DispatchQueue.main.async {
                            self.stopAnimating()
                            let localizedCouldNotUpdate = NSLocalizedString("couldNotUpdate", comment: "")
                            self.uiElement.showAlert(localizedCouldNotUpdate, message: error.localizedDescription, target: self)
                        }
                    }
                }
            }
        }
    }
    
    func loadCurrentUserCity(_ userId: String) {
        let query = PFQuery(className: "_User")
        query.cachePolicy = .networkElseCache
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                if let city = user["city"] as? String {
                    if !city.isEmpty {
                        self.loadTag(city.lowercased())
                    }
                }
            }
        }
    }
    
    //mark: utility
    func errorAlert(_ title: String, message: String) {
        let alertController = UIAlertController (title: title, message: message, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Okay", style: .cancel) { (_) -> Void in
            self.uiElement.goBackToPreviousViewController(self)
        }
        alertController.addAction(settingsAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func finishUp(_ shouldPlaySoundAndShowShareOptions: Bool, object: PFObject) {
        DispatchQueue.main.async {
            self.stopAnimating()
            if shouldPlaySoundAndShowShareOptions {
                let soundId = object.objectId!
                self.uiElement.setUserDefault(soundId, key: "newSoundId")
                self.uiElement.newRootView("Main", withIdentifier: "tabBar")
            } else {
                self.uiElement.goBackToPreviousViewController(self)
            }
        }
    }
}

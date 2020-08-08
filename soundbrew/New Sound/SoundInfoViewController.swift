//
//  SoundInfoViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/8/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//mark: tableview, audio, tags, media upload, view

import UIKit
import Parse
import SnapKit
import Kingfisher
import UICircularProgressRing
import CropViewController
import Firebase

class SoundInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TagDelegate, ArtistDelegate, CreditDelegate, UITextViewDelegate, CropViewControllerDelegate {
    
    func receivedArtist(_ value: Artist?) {
    }
    
    let color = Color()
    let uiElement = UIElement()
    
    var soundArtDidFinishProcessing = true
    var didPressDoneButton = false
    var isDraft = false
    var soundParseFileDidFinishProcessing = false
    
    var soundThatIsBeingEdited: Sound?
        
    let localizedAdd = NSLocalizedString("add", comment: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let miniPlayer = MiniPlayerView.sharedInstance
        miniPlayer.isHidden = true
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        if let objectId = self.soundThatIsBeingEdited?.objectId {
            self.loadCredits(objectId)
        }
        getSelectedTags()
        setupDoneButtons()
        setUpTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        saveDraftButton.removeFromSuperview()
        uploadAsSingleButton.removeFromSuperview()
    }
    
    @objc func appBecomeActive() {
        if let uploadTask = self.uploadTask {
            uploadTask.resume()
        }
    }
    
    //mark: views
    var saveDraftButton: UIButton!
    var uploadAsSingleButton: UIButton!
    lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .white
        return spinner
    }()
    
    func shouldAnimateActivitySpinner(_ buttonToAnimate: UIButton, shouldAnimate: Bool) {
        if shouldAnimate {
            buttonToAnimate.addSubview(spinner)
            spinner.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(buttonToAnimate)
                make.center.equalTo(buttonToAnimate)
            }
            saveDraftButton.isEnabled = false
            uploadAsSingleButton.isEnabled = false
            if buttonToAnimate.tag == 0 {
                buttonToAnimate.setTitle("", for: .normal)
            } else {
                buttonToAnimate.setTitle("", for: .normal)
            }
            spinner.isHidden = false
            spinner.startAnimating()
            
        } else {
            spinner.isHidden = true
            spinner.stopAnimating()
            spinner.removeFromSuperview()
            if buttonToAnimate.tag == 0 {
                buttonToAnimate.setTitle("Drafts", for: .normal)
            } else {
                buttonToAnimate.setTitle("Post", for: .normal)
            }
            saveDraftButton.isEnabled = true
            uploadAsSingleButton.isEnabled = true
        }
    }
    
    func setupDoneButtons() {
        var shouldUploadButtonBeEnabled = false
        if soundThatIsBeingEdited?.objectId != nil {
            shouldUploadButtonBeEnabled = true
        }
        
        saveDraftButton = self.uiElement.soundbrewButton("Drafts", shouldShowBorder: false, backgroundColor: .darkGray, image: nil, titleFont: UIFont(name: "\(uiElement.mainFont)", size: 17)!, titleColor: .white, cornerRadius: 5)
        saveDraftButton.addTarget(self, action: #selector(self.didPressDoneButton(_:)), for: .touchUpInside)
        saveDraftButton.tag = 0
        
        uploadAsSingleButton = self.uiElement.soundbrewButton("Post", shouldShowBorder: false, backgroundColor: color.blue(), image: nil, titleFont: UIFont(name: "\(uiElement.mainFont)", size: 17)!, titleColor: .white, cornerRadius: 5)
        uploadAsSingleButton.addTarget(self, action: #selector(self.didPressDoneButton(_:)), for: .touchUpInside)
        uploadAsSingleButton.tag = 1
        
        shouldEnableDraftAndSingButton(shouldUploadButtonBeEnabled)
        
        if let tabBarController = self.tabBarController {
            tabBarController.view.addSubview(saveDraftButton)
            saveDraftButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(self.uiElement.buttonHeight)
                make.width.equalTo(tabBarController.view.frame.width / 2 - 25)
                make.left.equalTo(tabBarController.view).offset(uiElement.leftOffset)
                make.bottom.equalTo(tabBarController.tabBar.snp.top).offset(uiElement.bottomOffset)
            }
            
            tabBarController.view.addSubview(uploadAsSingleButton)
            uploadAsSingleButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(self.uiElement.buttonHeight)
                make.width.equalTo(tabBarController.view.frame.width / 2 - 25)
                make.right.equalTo(tabBarController.view).offset(uiElement.rightOffset)
                make.bottom.equalTo(tabBarController.tabBar.snp.top).offset(uiElement.bottomOffset)
            }
            
        }
    }
    
    func shouldEnableDraftAndSingButton(_ shouldEnable: Bool) {
        saveDraftButton.isEnabled = shouldEnable
        uploadAsSingleButton.isEnabled = shouldEnable
        if shouldEnable {
            saveDraftButton.backgroundColor = .darkGray
            saveDraftButton.setTitle("Drafts", for: .normal)
            uploadAsSingleButton.backgroundColor = color.blue()
            uploadAsSingleButton.setTitle("Post", for: .normal)
        } else {
            saveDraftButton.backgroundColor = color.purpleBlack()
            uploadAsSingleButton.backgroundColor = color.purpleBlack()
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
        var tabBarControllerHeight: CGFloat = 50
        if let tabBar = self.tabBarController?.tabBar {
            tabBarControllerHeight = tabBar.frame.height
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundInfoReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundTagReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: fanClubExcluseReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: dividerReuse)
        tableView.backgroundColor = color.black()
        tableView.keyboardDismissMode = .onDrag
       // tableView.frame = view.bounds
        tableView.separatorStyle = .none
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-(50 + tabBarControllerHeight))
        }
        if soundThatIsBeingEdited?.objectId == nil {
            processFileForDatabase()
        } else {
            self.soundParseFileDidFinishProcessing = true 
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 7
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
            if let soundObjectId = self.soundThatIsBeingEdited?.objectId {
                modal.soundObjectId = soundObjectId
            }
            self.present(modal, animated: true, completion: nil)
            break
            
        case tagCellSection:
            self.showChooseTagsView()
            break
            
        default:
            break
        }
    }

    //mark: Fan Club Exclusive
    func fanClubExclusiveCell() -> SoundInfoTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: fanClubExcluseReuse) as! SoundInfoTableViewCell
        if Customer.shared.artist?.account?.id != nil {
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
            self.uiElement.showAlert("Fan Club Account Required", message: "Earn money from your followers by starting a fan club! You can get started on your profile page.", target: self)
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
    
    func loadCredits(_ postId: String) {
        let query = PFQuery(className: "Credit")
        query.whereKey("postId", equalTo: postId)
        query.addDescendingOrder("createdAt")
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                for object in objects {
                    let credit = Credit(objectId: object.objectId, username: nil, title: nil, artist: nil)
                    if let username = object["username"] as? String {
                        credit.username = username
                    }
                    
                    if let title = object["title"] as? String {
                        credit.title = title
                    }
                    if let userId = object["userId"] as? String {
                    let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, fanCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, account: nil)
                        artist.loadUserInfoFromCloud(nil, soundCell: nil, commentCell: nil, mentionCell: nil, artistUsernameLabel: nil, artistImageButton: nil)
                        credit.artist = artist
                        self.credits.append(credit)
                    }
                }
            }
        }
    }
    
    func saveCredits(_ sound: Sound) {
        for i in 0..<credits.count {
            let credit = credits[i]
            self.checkIfFeatureAlreadyExists(credit, postId: sound.objectId!, title: sound.title ?? "")
        }
    }
    
    func checkIfFeatureAlreadyExists(_ credit: Credit, postId: String, title: String) {
        let query = PFQuery(className: "Credit")
        query.whereKey("userId", equalTo: credit.artist?.objectId ?? "")
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if object == nil {
                self.newCredit(credit, postId: postId)
                self.uiElement.sendAlert("featured you on their new release '\(title)'", toUserId: credit.artist!.objectId, shouldIncludeName: true)
            }
        }
    }
    func newCredit(_ credit: Credit, postId: String){
        if let userId = credit.artist?.objectId, let username = credit.artist?.username {
            let newCredit = PFObject(className: "Credit")
            if let title = credit.title {
                newCredit["title"] = title
            } else {
                newCredit["title"] = "Featured"
            }
            
            newCredit["userId"] = userId
            newCredit["postId"] = postId
            newCredit["username"] = username
            newCredit.saveEventually()
        }
    }

    //MARK: tags
    var soundTags = [Tag]()
    var cityTag: Tag?
    func getSelectedTags() {
        if let soundTags = soundThatIsBeingEdited?.tags {
            for tag in soundTags {
                loadTag(tag, type: nil)
            }
        }
        if self.cityTag == nil, let currentUser = Customer.shared.artist{
            loadCurrentUserCity(currentUser.objectId)
        }
    }
    
    func showChooseTagsView() {
        let modal = ChooseTagsViewController()
        modal.tagType = "sound"
        modal.tagDelegate = self 
        modal.chosenTagsForSound = self.soundTags
        self.present(modal, animated: true, completion: nil)
    }
    
    func tagCell(_ indexPath: IndexPath, tableView: UITableView) -> SoundInfoTableViewCell {
       let cell = self.tableView.dequeueReusableCell(withIdentifier: soundTagReuse) as! SoundInfoTableViewCell
        let localizedTag = NSLocalizedString("tag", comment: "")
        let localizedTags = NSLocalizedString("tags", comment: "")
        cell.soundTagLabel.text = "Tags"
        cell.chosenSoundTagLabel.textColor = .white
        if self.soundTags.count == 0 {
            cell.chosenSoundTagLabel.text = localizedAdd.capitalized
            cell.chosenSoundTagLabel.textColor = color.blue()
        } else if self.soundTags.count == 1 {
            cell.chosenSoundTagLabel.text = "\(soundTags.count) \(localizedTag)"
        } else {
            cell.chosenSoundTagLabel.text = "\(soundTags.count) \(localizedTags)"
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
            cell.chosenSoundTagLabel.textColor = color.blue()
        }
    }
    
    func receivedTags(_ chosenTags: Array<Tag>?) {
        if let tags = chosenTags {
            self.soundTags = tags
            self.soundThatIsBeingEdited?.tags = tags.map {$0.name}
        } else {
            self.soundTags.removeAll()
            self.soundThatIsBeingEdited?.tags = nil
        }
        self.tableView.reloadData()
    }
    
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
    
    func loadTag(_ tag: String, type: String? ) {
        let query = PFQuery(className: "Tag")
        query.whereKey("tag", equalTo: tag)
        query.cachePolicy = .networkElseCache
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if let object = object{
                let tag = Tag(objectId: object.objectId, name: object["tag"] as? String, count: 0, isSelected: false, type: object["type"] as? String, imageURL: nil, uiImage: nil)
                if let type = tag.type {
                    if type == "city" {
                        self.cityTag = tag
                    } else {
                        self.soundTags.append(tag)
                    }
                } else {
                    self.soundTags.append(tag)
                }
                
            } else {
                let newCityTag = Tag(objectId: nil, name: tag, count: 0, isSelected: false, type: type, imageURL: nil, uiImage: nil)
                self.cityTag = newCityTag
            }
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
    
    func processFileForDatabase() {
        if let soundFileString = soundThatIsBeingEdited?.audioURL {
            if let soundFileURL = URL(string: soundFileString) {
                if pathExtensionIsUncompressed(soundFileURL.pathExtension) {
                    self.convertAudioToM4a(soundFileURL)
                } else {
                    convertURLToDataAndSavetoDatabase(soundFileURL, fileName: "audio")
                }
                
            } else {
                let localizedIssueWithUpload = NSLocalizedString("issueWithUpload", comment: "")
                self.errorAlert(self.uiElement.localizedOops, message: "\(localizedIssueWithUpload)")
            }
            
        } else if let videoFileString = soundThatIsBeingEdited?.videoURL,
            let videoFileURL = URL(string: videoFileString) {
            uploadFileToGoogleStorage(videoFileURL)
        } else {
            let localizedProcessingAudio = NSLocalizedString("SoundProcessingFailed", comment: "")
            self.errorAlert(localizedProcessingAudio, message: "Unable to access File")
        }
    }
    
    var uploadTask: StorageUploadTask?
    func uploadFileToGoogleStorage(_ videoURL: URL) {
            let localizedProcessingAudio = NSLocalizedString("SoundProcessingFailed", comment: "")
        
            let storage = Storage.storage()

            // Create a root reference
            let storageRef = storage.reference()

            // Create a reference to 'images/mountains.jpg'
            let videoVidesRef = storageRef.child("videos/video.\(videoURL.pathExtension)")
            
            // Upload the file to the path "images/rivers.jpg"
            uploadTask = videoVidesRef.putFile(from: videoURL, metadata: nil) { metadata, error in
                if let error = error {
                    self.errorAlert(localizedProcessingAudio, message: error.localizedDescription)
                }
              // You can also access to download URL after upload.
              videoVidesRef.downloadURL { (url, error) in
                if let uploadedFileURL = url {
                    self.soundThatIsBeingEdited?.videoURL = "\(uploadedFileURL)"
                    self.soundThatIsBeingEdited?.videoPathExtension = videoURL.pathExtension
                    self.soundParseFileDidFinishProcessing = true
                    self.shouldEnableDraftAndSingButton(true)
                } else if let error = error {
                    self.errorAlert(localizedProcessingAudio, message: error.localizedDescription)
                }
            }
        }
            
        if let uploadTask = self.uploadTask {
            uploadTask.observe(.progress) { snapshot in
                let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                    / Double(snapshot.progress!.totalUnitCount)
                self.audioProgress.value = CGFloat(percentComplete)
            }
        }
        
        
    }
    
    func pathExtensionIsUncompressed(_ pathExtension: String) -> Bool {
        switch pathExtension {
        case "wav", "pcm", "aiff", "mov":
            return true
        default:
            return false
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
                self.convertURLToDataAndSavetoDatabase(outputURL, fileName: "audio")
            }
        })
    }
    
    func convertURLToDataAndSavetoDatabase(_ soundfileURL: URL, fileName: String) {
        do {
            let file = try Data(contentsOf: soundfileURL, options: .uncached)
            let name = "\(fileName).\(soundfileURL.pathExtension)"
            if fileName == "audio" {
                self.soundThatIsBeingEdited?.audioFile = PFFileObject(name: name, data: file)
                self.saveParseFile(self.soundThatIsBeingEdited!.audioFile!)
            }
            
        } catch let error {
            let localizedIssueWithUpload = NSLocalizedString("issueWithUpload", comment: "")
            self.errorAlert(self.uiElement.localizedOops, message: "\(localizedIssueWithUpload) \(error)")
        }
    }
    
    func saveParseFile(_ soundParseFile: PFFileObject) {
        soundParseFile.saveInBackground({
            (succeeded: Bool, error: Error?) -> Void in
            if succeeded {
                self.soundParseFileDidFinishProcessing = true
                self.shouldEnableDraftAndSingButton(true)
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
                if self.didPressDoneButton {
                    self.doneAction(self.isDraft)
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
    
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        dismiss(animated: true, completion: nil)
        self.soundArtDidFinishProcessing = true
    }
    
    //
    @objc func didPressDoneButton(_ sender: UIButton) {
        if sender.tag == 0 {
            shouldAnimateActivitySpinner(saveDraftButton, shouldAnimate: true)
            self.doneAction(true)
        } else {
            shouldAnimateActivitySpinner(uploadAsSingleButton, shouldAnimate: true)
            self.doneAction(false)
        }
    }
    
    func doneAction(_ isDraft: Bool) {
        if let cityTag = self.cityTag {
            self.soundTags.append(cityTag)
        }
        self.soundThatIsBeingEdited?.tags = self.soundTags.map {$0.name}
        self.didPressDoneButton = true
        self.isDraft = isDraft
        if self.soundArtDidFinishProcessing, let sound = soundThatIsBeingEdited {
            if sound.objectId != nil {
                updateSound(sound, isDraft: isDraft)
            } else {
                createSound(sound, isDraft: isDraft)
            }
        }
    }

    //mark: data
    func createSound(_ sound: Sound, isDraft: Bool) {
        let newSound = PFObject(className: "Post")
        newSound["userId"] = sound.artist!.objectId
        newSound["user"] = PFUser.current()
        if let audioFile = sound.audioFile {
            newSound["audioFile"] = audioFile
        } else if let videoURL = sound.videoURL, let videoPathExtension = sound.videoPathExtension {
            newSound["videoURL"] = videoURL
            newSound["videoPathExtension"] = videoPathExtension
        }
        
        if let title = sound.title {
            newSound["title"] = title
        }
        if let artFile = sound.artFile {
            newSound["songArt"] = artFile
        }
        if let tags = sound.tags {
            newSound["tags"] = tags
        }
        
        if let productId = sound.artist?.account?.productId {
            newSound["productId"] = productId
        }
        
        if let username = sound.artist?.username {
            newSound["username"] = username
        }
        
        if let name = sound.artist?.name {
            newSound["name"] = name
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
                self.saveTags(self.soundTags)
                self.soundThatIsBeingEdited?.objectId = newSound.objectId
                self.saveCredits(sound)
                self.finishUp(isDraft)
                
            } else if let error = error {
                DispatchQueue.main.async {
                    let localizedCouldNotPost = NSLocalizedString("couldNotPost", comment: "")
                    self.uiElement.showAlert(localizedCouldNotPost, message: error.localizedDescription, target: self)
                    if isDraft {
                        self.shouldAnimateActivitySpinner(self.saveDraftButton, shouldAnimate: false)
                    } else {
                        self.shouldAnimateActivitySpinner(self.uploadAsSingleButton, shouldAnimate: false)
                    }
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
                
                if let productId = sound.artist?.account?.productId {
                    object["productId"] = productId
                }
                
                if let username = sound.artist?.username {
                    object["username"] = username
                }
                
                if let name = sound.artist?.name {
                    object["name"] = name
                }

                object.saveEventually {
                    (success: Bool, error: Error?) in
                    if (success) {
                        self.saveTags(self.soundTags)
                        self.soundThatIsBeingEdited?.objectId = object.objectId
                        self.saveCredits(sound)
                        self.finishUp(isDraft)
                        
                    } else if let error = error {
                        DispatchQueue.main.async {
                            let localizedCouldNotUpdate = NSLocalizedString("couldNotUpdate", comment: "")
                            self.uiElement.showAlert(localizedCouldNotUpdate, message: error.localizedDescription, target: self)
                            if isDraft {
                                self.shouldAnimateActivitySpinner(self.saveDraftButton, shouldAnimate: false)
                            } else {
                                self.shouldAnimateActivitySpinner(self.uploadAsSingleButton, shouldAnimate: false)
                            }
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
                        self.loadTag(city.lowercased(), type: "city")
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
    
    func finishUp(_ isDraft: Bool) {
        DispatchQueue.main.async {
            if isDraft {
                self.uiElement.goBackToPreviousViewController(self)
            } else {
                let soundId = self.soundThatIsBeingEdited?.objectId
                self.uiElement.setUserDefault(soundId, key: "newSoundId")
                self.uiElement.newRootView("Main", withIdentifier: "tabBar")
            }
        }
    }
}

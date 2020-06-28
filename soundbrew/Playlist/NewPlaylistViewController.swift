//
//  NewPlaylistViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/10/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import Parse
import CropViewController
import Kingfisher

class NewPlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate, ArtistDelegate {
    func receivedArtist(_ value: Artist?) {
    }
    
    let uiElement = UIElement()
    let color = Color()
        
    var playlistTitle: UITextField!
    var playlist: Playlist!
    var playlistDelegate: PlaylistDelegate?
    
    var soundList: SoundList!
    var playlistSounds = [Sound]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        if let userId = PFUser.current()?.objectId {
            let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, account: nil)
            playlist.artist = artist
            
            if playlist.type == "collection" {
                for i in 0..<playlistSounds.count {
                    playlistSounds[i].artFile = nil
                }
                
                let doneButton = UIBarButtonItem(title: "Release", style: .plain, target: self, action: #selector(didPressCollectionDoneButton(_:)))
                self.navigationItem.rightBarButtonItem = doneButton
                setUpTableView(nil)
                soundList = SoundList(target: self, tableView: tableView, soundType: "", userId: nil, tags: nil, searchText: nil, descendingOrder: nil, linkObjectId: nil, playlist: nil)
                soundList.sounds = playlistSounds
                soundList.updateTableView()
                
            } else {
                var doneButtonTitle = "Create Playlist"
                if playlist.objectId != nil {
                    doneButtonTitle = "Update Playlist"
                }
                let topView = self.uiElement.addSubViewControllerTopView(self, action: #selector(self.didPressPlaylistDoneButton(_:)), doneButtonTitle: doneButtonTitle, title: "New Playlist")
                setUpTableView(topView.2)
            }
            
        } else {
            self.uiElement.goBackToPreviousViewController(self)
        }
    }
    
    @objc func didPressPlaylistDoneButton(_ sender: UIButton) {
        if sender.tag == 0 {
            self.dismiss(animated: true, completion: nil)
        } else {
            if playlist.title == nil {
                self.uiElement.showAlert("Title Required", message: "", target: self)
            } else if playlist.objectId == nil {
                createNewPlaylist(self.playlist)
            } else if playlist.objectId != nil {
                updatePlaylist(self.playlist)
            }
        }
    }
    
    @objc func didPressCollectionDoneButton(_ sender: UIBarButtonItem) {
        if playlist.title == nil {
            self.uiElement.showAlert("Title Required", message: "", target: self)
        } else if playlist.image == nil {
            self.uiElement.showAlert("Collection Image Required", message: "", target: self)
        } else {
            createNewPlaylist(self.playlist)
        }
    }
    
    //MARK: TableView
    let tableView = UITableView()
    let editProfileInfoReuse = "editProfileInfoReuse"
    let editPlaylistTypeReuse = "editBioReuse"
    let soundReuse = "soundReuse"
    let soundInfoReuse = "soundInfoReuse"
    let dividerReuse = "dividerReuse"
    let selectPlaylistSoundsReuse = "selectPlaylistSoundsReuse"
    let soundSocialReuse = "soundSocialReuse"
    func setUpTableView(_ dividerLine: UIView?) {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editProfileInfoReuse)
        self.tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: selectPlaylistSoundsReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundInfoReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: dividerReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundSocialReuse)
        tableView.backgroundColor = color.black()
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        self.view.addSubview(tableView)
        if let dividerLine = dividerLine {
            self.tableView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(dividerLine.snp.bottom)
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
                make.bottom.equalTo(self.view)
            }
        } else {
            self.tableView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.view)
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
                make.bottom.equalTo(self.view).offset(-175)
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.playlist.type == "collection" {
            return 3
        }
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return soundList.sounds.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return playlistImageTitleCell()
            
        case 2:
            let cell = soundList.soundCell(indexPath, tableView: tableView, reuse: selectPlaylistSoundsReuse)
            let index = indexPath.row + 1
            cell.circleImage.text = "\(index)"
            cell.circleImage.textColor = .darkGray
            return cell
            
        default:
            let cell = self.tableView.dequeueReusableCell(withIdentifier: dividerReuse) as! SoundInfoTableViewCell
            cell.backgroundColor = color.black()
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let modal = EditBioViewController()
            modal.bioTitle = "Playlist Title"
            if let title = self.playlist.title {
                modal.bio = title
            }
            modal.totalAllowedTextLength = 50
            modal.artistDelegate = self
            self.present(modal, animated: true, completion: nil)
        }
    }
        
    //MARK: image title
    func changeBio(_ value: String?) {
        if let newPlaylistTitle = value {
            self.playlist.title = newPlaylistTitle
            self.tableView.reloadData()
        }
    }
    
    func playlistImageTitleCell() -> SoundInfoTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: soundInfoReuse) as! SoundInfoTableViewCell
        cell.selectionStyle = .none
        cell.backgroundColor = color.black()
        cell.soundArtImageButton.addTarget(self, action: #selector(self.didPressUploadSoundArtButton(_:)), for: .touchUpInside)

        cell.audioProgress.isHidden = true 
        
        if let playlist = self.playlist.title {
            cell.inputTitle.text = playlist
        } else {
            cell.inputTitle.text = "Add Title/Description"
        }
                                
        if let imageURL = self.playlist.image?.url {
            cell.soundArtImageButton.kf.setImage(with: URL(string: imageURL), for: .normal)
        }
                
        return cell
    }
    
    //mark: media upload
    @objc func didPressUploadSoundArtButton(_ sender: UIButton){
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
        picker.dismiss(animated: true, completion: nil)
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
        self.dismiss(animated: true, completion: nil)
        self.startAnimating()
        let proPic = image.jpegData(compressionQuality: 0.5)
        self.playlist.image = PFFileObject(name: "playlistArt.jpeg", data: proPic!)
        self.playlist.image?.saveInBackground({
            (succeeded: Bool, error: Error?) -> Void in
            self.stopAnimating()
            if succeeded {
                if self.soundList != nil {
                    self.updateSoundImages()
                } else {
                    self.tableView.reloadData()
                }
                
            } else if let error = error {
                self.playlist.image = nil
                if self.soundList != nil {
                    self.updateSoundImages()
                }
                let localizedArtProcessingFailed = NSLocalizedString("artProcessingFailded", comment: "")
                self.uiElement.showAlert(localizedArtProcessingFailed, message: error.localizedDescription, target: self)
            }
            
        }, progressBlock: {
            (percentDone: Int32) -> Void in
            // Update your progress spinner here. percentDone will be between 0 and 100.
        })
    }
    
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func updateSoundImages() {
        if let playlistImage = self.playlist.image {
            for i in 0..<soundList.sounds.count {
                soundList.sounds[i].artFile = playlistImage
            }
            soundList.updateTableView()
        }
    }
    
    //
    func createNewPlaylist(_ playlist: Playlist) {
        startAnimating()
        let newPlaylist = PFObject(className: "Playlist")
        newPlaylist["userId"] = playlist.artist?.objectId
        newPlaylist["user"] = PFUser.current()
        newPlaylist["title"] = playlist.title
        if let image = playlist.image {
            newPlaylist["image"] = image
        }
        newPlaylist["count"] = playlist.count
        newPlaylist["type"] = playlist.type
        newPlaylist["isRemoved"] = false
        newPlaylist.saveEventually {
            (success: Bool, error: Error?) in
            self.stopAnimating()
            if (success) {
                self.playlist.objectId = newPlaylist.objectId
                if playlist.type == "collection" {
                    for sound in self.soundList.sounds {
                        if let soundObjectId = sound.objectId, let playlistObjectId = newPlaylist.objectId {
                            self.attachSoundToPlaylist(soundObjectId, playlistId: playlistObjectId)
                            self.updateSound(soundObjectId, playlistImage: playlist.image!)
                        }
                    }
                    self.uiElement.newRootView("Main", withIdentifier: "tabBar")
                    
                } else if let playlistDelegate = self.playlistDelegate {
                    self.dismiss(animated: true, completion: {() in
                        playlistDelegate.receivedPlaylist(playlist)
                    })
                }
                
            } else if let error = error {
                self.uiElement.showAlert("Error", message: error.localizedDescription, target: self)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func updatePlaylist(_ playlist: Playlist) {
        let query = PFQuery(className: "Playlist")
        query.getObjectInBackground(withId: playlist.objectId ?? "") {
            (object: PFObject?, error: Error?) -> Void in
             if let object = object {
                object["title"] = playlist.title ?? ""
                object["image"] = playlist.image
                object.saveEventually {
                    (success: Bool, error: Error?) in
                    if (success) {
                        if let playlistDelegate = self.playlistDelegate {
                            self.dismiss(animated: true, completion: {() in
                                playlistDelegate.receivedPlaylist(playlist)
                            })
                        }
                    }
                }
            }
        }
    }
    
    func attachSoundToPlaylist(_ soundId: String, playlistId: String) {
        let newPlaylistSound = PFObject(className: "PlaylistSound")
        newPlaylistSound["playlistId"] = playlistId
        newPlaylistSound["soundId"] = soundId
        newPlaylistSound.saveEventually()
    }
    
    func updateSound(_ objectId: String, playlistImage: PFFileObject) {
        let query = PFQuery(className: "Post")
        query.getObjectInBackground(withId: objectId) {
            (object: PFObject?, error: Error?) -> Void in
             if let object = object {
                object["isDraft"] = false
                object["isRemoved"] = false
                object["songArt"] = playlistImage
                object.saveEventually()
            }
        }
    }
}

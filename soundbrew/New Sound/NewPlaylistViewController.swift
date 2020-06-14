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
    var newPlaylist = Playlist(objectId: nil, userId: nil, title: nil, image: nil)
    var playlistDelegate: PlaylistDelegate?
    
    var soundList: SoundList!
    var playlistSounds = [Sound]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let userId = PFUser.current()?.objectId {
            newPlaylist.userId = userId
            
            for i in 0..<playlistSounds.count {
                playlistSounds[i].artFile = nil
                playlistSounds[i].artURL = nil
            }
            
            setUpTableView()
            
            soundList = SoundList(target: self, tableView: tableView, soundType: "", userId: nil, tags: nil, searchText: nil, descendingOrder: nil, linkObjectId: nil)
            soundList.sounds = playlistSounds
            soundList.updateTableView()
            
            let doneButton = UIBarButtonItem(title: "Release", style: .plain, target: self, action: #selector(didPressDoneButton(_:)))
            self.navigationItem.rightBarButtonItem = doneButton
            
        } else {
            self.uiElement.goBackToPreviousViewController(self)
        }
    }
    
    @objc func didPressDoneButton(_ sender: UIBarButtonItem) {
        if newPlaylist.title == nil {
            self.uiElement.showAlert("Title Required", message: "", target: self)
        } else if newPlaylist.image == nil {
            self.uiElement.showAlert("Collection Image Required", message: "", target: self)
        } else {
            createNewPlaylist(self.newPlaylist)
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
    func setUpTableView() {
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
        self.tableView.frame = view.bounds
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
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
            if let title = self.newPlaylist.title {
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
            self.newPlaylist.title = newPlaylistTitle
            self.tableView.reloadData()
        }
    }
    
    func playlistImageTitleCell() -> SoundInfoTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: soundInfoReuse) as! SoundInfoTableViewCell
        cell.selectionStyle = .none
        cell.backgroundColor = color.black()
        cell.soundArtImageButton.addTarget(self, action: #selector(self.didPressUploadSoundArtButton(_:)), for: .touchUpInside)

        cell.audioProgress.isHidden = true 
        
        if let playlist = self.newPlaylist.title {
            cell.inputTitle.text = playlist
        } else {
            cell.inputTitle.text = "Add Title/Description"
        }
                                
        if let imageURL = self.newPlaylist.image?.url {
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
        
        dismiss(animated: true, completion: {() in
            if let image = selectedImage {
                self.presentImageCropViewController(image)
            }
        })
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
    
    func presentImageCropViewController(_ image: UIImage) {
        let cropViewController = CropViewController(croppingStyle: .default, image: image)
        cropViewController.aspectRatioLockEnabled = true
        cropViewController.aspectRatioPickerButtonHidden = true
        cropViewController.aspectRatioPreset = .presetSquare
        cropViewController.resetAspectRatioEnabled = false
        cropViewController.delegate = self
        present(cropViewController, animated: false, completion: nil)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        self.startAnimating()
        let proPic = image.jpegData(compressionQuality: 0.5)
        self.newPlaylist.image = PFFileObject(name: "playlistArt.jpeg", data: proPic!)
        self.newPlaylist.image?.saveInBackground({
            (succeeded: Bool, error: Error?) -> Void in
            self.stopAnimating()
            if succeeded {
                self.updateSoundImages()
                
            } else if let error = error {
                self.newPlaylist.image = nil
                self.updateSoundImages()
                let localizedArtProcessingFailed = NSLocalizedString("artProcessingFailded", comment: "")
                self.uiElement.showAlert(localizedArtProcessingFailed, message: error.localizedDescription, target: self)
            }
            
        }, progressBlock: {
            (percentDone: Int32) -> Void in
            // Update your progress spinner here. percentDone will be between 0 and 100.
        })
        
        dismiss(animated: true, completion: nil)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        dismiss(animated: true, completion: nil)
    }
    
    func updateSoundImages() {
        if let playlistImage = self.newPlaylist.image {
            for i in 0..<soundList.sounds.count {
                soundList.sounds[i].artURL = playlistImage.url
                soundList.sounds[i].artFile = playlistImage
            }
            soundList.updateTableView()
        }
    }
    
    //
    func createNewPlaylist(_ playlist: Playlist) {
        startAnimating()
        let newPlaylist = PFObject(className: "Playlist")
        newPlaylist["userId"] = playlist.userId
        newPlaylist["title"] = playlist.title
        newPlaylist["image"] = playlist.image
        newPlaylist["isRemoved"] = false 
        newPlaylist.saveEventually {
            (success: Bool, error: Error?) in
            self.stopAnimating()
            if (success) {
                self.newPlaylist.objectId = newPlaylist.objectId
                for sound in self.soundList.sounds {
                    if let soundObjectId = sound.objectId, let playlistObjectId = newPlaylist.objectId {
                        self.attachSoundToPlaylist(soundObjectId, playlistId: playlistObjectId)
                        self.updateSound(soundObjectId, playlistImage: playlist.image!)
                    }
                }
                self.uiElement.newRootView("Main", withIdentifier: "tabBar")
                
            } else if let error = error {
                self.uiElement.showAlert("Error", message: error.localizedDescription, target: self)
                self.dismiss(animated: true, completion: nil)
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

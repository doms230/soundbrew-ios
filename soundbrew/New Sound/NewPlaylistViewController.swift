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

class NewPlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {
    
    let uiElement = UIElement()
    let color = Color()
        
    var playlistTitle: UITextField!
    var newPlaylist = Playlist(objectId: nil, userId: nil, title: nil, image: nil)
    var playlistDelegate: PlaylistDelegate?
    
    var soundList: SoundList!
    var playlistSounds = [Sound]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        if let userId = PFUser.current()?.objectId {
            newPlaylist.userId = userId
        } else {
            self.dismiss(animated: true, completion: nil)
        }
        setupTopButtons()
        setUpTableView()
        
        soundList = SoundList(target: self, tableView: tableView, soundType: "", userId: nil, tags: nil, searchText: nil, descendingOrder: nil, linkObjectId: nil)
        soundList.sounds = playlistSounds
        soundList.updateTableView()
    }
    
    lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(self.didPressDoneButton), for: .touchUpInside)
        button.isOpaque = true
        button.tag = 0
        return button
    }()
    
    lazy var doneButton: UIButton = {
        let button = UIButton()
        button.setTitle("Create Playlist", for: .normal)
        button.addTarget(self, action: #selector(self.didPressDoneButton), for: .touchUpInside)
        button.isOpaque = true
        button.tag = 1
        return button
    }()
    
    func setupTopButtons() {
        self.view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        self.view.addSubview(doneButton)
        doneButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.topOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
    }
    
    @objc func didPressDoneButton(_ sender: UIButton) {
        if sender.tag == 0 {
            self.dismiss(animated: true, completion: nil)
        } else if let text = playlistTitle.text, playlistTitleIsValidated() {
            self.newPlaylist.title = text
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
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editProfileInfoReuse)
       // tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editPlaylistTypeReuse)
        self.tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: selectPlaylistSoundsReuse)
        //tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundInfoReuse)
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: dividerReuse)
        tableView.backgroundColor = color.black()
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        self.view.addSubview(tableView)
        self.view.addSubview(cancelButton)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.doneButton.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
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
           // self.performSegue(withIdentifier: "showEditTitle", sender: self)
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
                                
        if let image = self.selectedPlaylistImage {
            cell.soundArtImageButton.setImage(image, for: .normal)
        } else if let imageURL = self.newPlaylist.image?.url {
            cell.soundArtImageButton.kf.setImage(with: URL(string: imageURL), for: .normal)
        }
                
        return cell
    }
    
    //mark: media upload
    var soundArtDidFinishProcessing = false
    var didPressUploadButton = false
    var selectedPlaylistImage: UIImage?
    
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
        
        dismiss(animated: true, completion: {() in
            if let image = selectedImage {
                self.presentImageCropViewController(image)
            }
        })
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
        self.selectedPlaylistImage = image
        self.tableView.reloadData()
        
        let proPic = image.jpegData(compressionQuality: 0.5)
        self.newPlaylist.image = PFFileObject(name: "playlistArt.jpeg", data: proPic!)
        self.newPlaylist.image?.saveInBackground({
            (succeeded: Bool, error: Error?) -> Void in
            if succeeded {
                self.soundArtDidFinishProcessing = true
                if self.didPressUploadButton {
                    //TODO: create playlist
                }
                
            } else if let error = error {
                self.stopAnimating()
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
        self.soundArtDidFinishProcessing = true
    }
    
    //
    func createNewPlaylist(_ playlist: Playlist) {
        startAnimating()
        let newPlaylist = PFObject(className: "Playlist")
        newPlaylist["userId"] = playlist.userId
        newPlaylist["title"] = playlist.title
        newPlaylist["image"] = playlist.image
        newPlaylist.saveEventually {
            (success: Bool, error: Error?) in
            self.stopAnimating()
            if (success) {
                self.newPlaylist.objectId = newPlaylist.objectId
                if let playlistDelegate = self.playlistDelegate {
                    self.dismiss(animated: true, completion: {() in
                        playlistDelegate.receivedPlaylist(self.newPlaylist)
                    })
                }
            } else if let error = error {
                self.uiElement.showAlert("Error", message: error.localizedDescription, target: self)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func playlistTitleIsValidated() -> Bool {
        if playlistTitle.text!.isEmpty {
            self.uiElement.showTextFieldErrorMessage(playlistTitle, text: "Title Required")
            return false
        }
       return true
    }
}

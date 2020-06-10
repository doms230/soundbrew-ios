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

class NewPlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable {
    let uiElement = UIElement()
    let color = Color()
        
    var playlistTitle: UITextField!
    var newPlaylist = Playlist(objectId: nil, userId: nil, title: nil, type: "playlist")
    var playlistDelegate: PlaylistDelegate?
    
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
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editProfileInfoReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: editPlaylistTypeReuse)
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
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return titleCell()
        } else {
            return typeCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let alertController = UIAlertController (title: "Type of Playlist?", message: "", preferredStyle: .actionSheet)
            let playlistAction = UIAlertAction(title: "Playlist", style: .default) { (_) -> Void in
                self.updatePlaylistType("playlist")
            }
            alertController.addAction(playlistAction)
            
            let albumAction = UIAlertAction(title: "Album", style: .default) { (_) -> Void in
                self.updatePlaylistType("album")
            }
            alertController.addAction(albumAction)
            
            let epAction = UIAlertAction(title: "EP", style: .default) { (_) -> Void in
                self.updatePlaylistType("ep")
            }
            alertController.addAction(epAction)
            
            let mixtapeAction = UIAlertAction(title: "Mixtape", style: .default) { (_) -> Void in
                self.updatePlaylistType("mixtape")
            }
            alertController.addAction(mixtapeAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func updatePlaylistType(_ type: String) {
        self.newPlaylist.type = type
        self.tableView.reloadData()
    }
    
    func titleCell() -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: editProfileInfoReuse) as! ProfileTableViewCell
        let edgeInsets = UIEdgeInsets(top: 0, left: 85 + CGFloat(UIElement().leftOffset), bottom: 0, right: 0)
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        tableView.separatorInset = edgeInsets
        
        cell.editProfileTitle.text = "Title"
        playlistTitle = cell.editProfileInput
        playlistTitle.becomeFirstResponder()
        cell.backgroundColor = color.black()
        return cell
    }
    
    func typeCell() -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: editPlaylistTypeReuse) as! ProfileTableViewCell
        cell.backgroundColor = color.black()
        cell.selectionStyle = .none
        tableView.separatorInset = .zero
        cell.editBioTitle.text = "Type"
        if let type = self.newPlaylist.type {
            cell.editBioText.text = type.capitalized
        } else {
            cell.editBioText.text = "Playlist"
        }
        
        return cell
    }
    
    func createNewPlaylist(_ playlist: Playlist) {
        startAnimating()
        let newPlaylist = PFObject(className: "Playlist")
        newPlaylist["userId"] = playlist.userId
        newPlaylist["title"] = playlist.title
        newPlaylist["type"] = playlist.type
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

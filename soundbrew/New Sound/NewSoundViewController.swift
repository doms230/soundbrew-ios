//
//  NewSoundViewController.swift
//  soundbrew artists
//
//  Created by Dominic Smith on 10/8/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import MobileCoreServices
import SnapKit
import NVActivityIndicatorView
import AppCenterAnalytics

class NewSoundViewController: UIViewController, UIDocumentPickerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable, PlayerDelegate, TagDelegate {
    
    let uiElement = UIElement()
    let color = Color()
    var soundList: SoundList!
    var newSound: Sound!
    var wasShownNewUpload = false
    
    override func viewDidLoad() {        
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        view.backgroundColor = color.black()
        
        let uploadButton = UIBarButtonItem(image: UIImage(named: "new_nav"), style: .plain, target: self, action: #selector(self.didPressUploadButton(_:)))
        self.navigationItem.rightBarButtonItem = uploadButton
        
        self.uiElement.addTitleView("Drafts", target: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setMiniPlayer()
        if PFUser.current() != nil {
            if tableView != nil {
                showSounds()
            } else {
                setUpTableView()
            }
            
        } else {
            let localizedRegisterToUpload = NSLocalizedString("registerToUpload", comment: "")
            self.uiElement.welcomeAlert(localizedRegisterToUpload, target: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
            case "showEditSoundInfo":
                var soundToBeEdited: Sound!
                if let selectedSound = soundList.selectedSound {
                    selectedSound.isDraft = true
                    soundToBeEdited = selectedSound
                } else {
                    soundToBeEdited = newSound
                }
                let viewController: SoundInfoViewController = segue.destination as! SoundInfoViewController
                viewController.soundThatIsBeingEdited = soundToBeEdited
                break
                
            case "showTippers":
                soundList.prepareToShowTippers(segue)
                let backItem = UIBarButtonItem()
                backItem.title = self.uiElement.localizedCollectors
                navigationItem.backBarButtonItem = backItem
                break
                
            case "showProfile":
                soundList.prepareToShowSelectedArtist(segue)
                let backItem = UIBarButtonItem()
                backItem.title = ""
                navigationItem.backBarButtonItem = backItem
                break
            
            case "showSounds":
                let viewController = segue.destination as! SoundsViewController
                viewController.selectedTagForFiltering = self.selectedTagFromPlayerView
                viewController.soundType = "discover"
                
                let backItem = UIBarButtonItem()
                backItem.title = self.selectedTagFromPlayerView.name
                navigationItem.backBarButtonItem = backItem
                break
            
        default:
            break
        }
    }
    
    func showSounds() {
        soundList = SoundList(target: self, tableView: tableView, soundType: "drafts", userId: PFUser.current()?.objectId, tags: nil, searchText: nil, descendingOrder: nil, linkObjectId: nil)
    }
    
    //mark: tableview
    var tableView: UITableView!
    let soundReuse = "soundReuse"
    let noSoundsReuse = "noSoundsReuse"
    func setUpTableView() {
        self.tableView = UITableView()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: self.soundReuse)
        self.tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: self.noSoundsReuse)
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.backgroundColor = self.color.black()
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: UIControl.Event.valueChanged)
        self.tableView.refreshControl = refreshControl
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-175)
        }
        self.showSounds()
    }
    
    @objc func refresh(_ sender: UIRefreshControl) {
       showSounds()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if soundList != nil, soundList.sounds.count != 0 {
            return soundList.sounds.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if soundList.sounds.count == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
            cell.backgroundColor = color.black()
            if soundList.isUpdatingData {
                let localizedLoading = NSLocalizedString("loading", comment: "")
                cell.headerTitle.text = localizedLoading
            } else {
                let localizedNoDraftsMessage = NSLocalizedString("noDraftsMessage", comment: "")
                cell.headerTitle.text = localizedNoDraftsMessage
                if !wasShownNewUpload {
                    showNewUpload()
                }
            }

            return cell
            
        } else {
            return soundList.soundCell(indexPath, tableView: tableView, reuse: soundReuse)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRowAt(indexPath.row)
    }
    
    func didSelectRowAt(_ row: Int) {
        let player = Player.sharedInstance
        player.sounds = soundList.sounds
        player.didSelectSoundAt(row)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == soundList.sounds.count - 10 && !soundList.isUpdatingData && soundList.thereIsMoreDataToLoad {
            //soundList.loadCollection("createdAt", profileUserId: PFUser.current()!.objectId!)
        }
    }
    
    //mark: new sound upload
    @objc func didPressUploadButton(_ sender: UIBarButtonItem) {
        showNewUpload()
    }
    
    func showNewUpload() {
        let types: NSArray = NSArray(object: kUTTypeAudio as NSString)
        let documentPicker = UIDocumentPickerViewController(documentTypes: types as! [String], in: .import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .fullScreen
        self.present(documentPicker, animated: true, completion: nil)
    }
        
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else {
             return
        }
        wasShownNewUpload = true 
        let artist = Customer.shared.artist
        newSound = Sound(objectId: nil, title: nil, artURL: nil, artImage: nil, artFile: nil, tags: nil, createdAt: nil, playCount: nil, audio: nil, audioURL: "\(fileURL)", audioData: nil, artist: artist, tmpFile: nil, tipCount: nil, currentUserTipDate: nil, isDraft: true, isNextUpToPlay: false, creditCount: nil, commentCount: nil, isFeatured: nil, isExclusive: nil, artistSelectedPlaylist: nil)
        self.performSegue(withIdentifier: "showEditSoundInfo", sender: self)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        wasShownNewUpload = true
    }
    
    //mark: miniPlayer
    func setMiniPlayer() {
        let miniPlayerView = MiniPlayerView.sharedInstance
        miniPlayerView.superViewController = self
        miniPlayerView.tagDelegate = self
        miniPlayerView.playerDelegate = self
    }
    
    @objc func miniPlayerWasSwiped() {
        showPlayerViewController()
    }
    
    @objc func miniPlayerWasPressed(_ sender: UIButton) {
        showPlayerViewController()
    }
    
    func showPlayerViewController() {
        let player = Player.sharedInstance
        if player.player != nil {
            let modal = PlayerViewController()
            //modal.player = player
            modal.playerDelegate = self
            modal.tagDelegate = self
            self.present(modal, animated: true, completion: nil)
        }
    }
    
    //mark: selectedArtist
    func selectedArtist(_ artist: Artist?) {
        if let artist = artist {
            switch artist.objectId {
                case "addFunds":
                    self.performSegue(withIdentifier: "showAddFunds", sender: self)
                    break
                    
                case "signup":
                    self.performSegue(withIdentifier: "showWelcome", sender: self)
                    break
                    
                case "collectors":
                    self.performSegue(withIdentifier: "showTippers", sender: self)
                    break
                                        
                default:
                    soundList.selectedArtist(artist)
                    break
            }
        }
    }
    
    //mark: tags
    var selectedTagFromPlayerView: Tag!
    func receivedTags(_ chosenTags: Array<Tag>?) {
        if let tags = chosenTags {
            self.selectedTagFromPlayerView = tags[0]
            self.performSegue(withIdentifier: "showSounds", sender: self)
        }
    }
    
}

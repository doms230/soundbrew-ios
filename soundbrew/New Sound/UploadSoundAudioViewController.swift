//
//  NewSoundViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/8/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import MobileCoreServices
import SnapKit
import NVActivityIndicatorView
import DeckTransition

class UploadSoundAudioViewController: UIViewController, UIDocumentPickerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable, PlayerDelegate {
    
    let uiElement = UIElement()
    let color = Color()
    var soundList: SoundList!
    var newSound: Sound!
    
    //var soundThatIsBeingEdited: Sound?
    
    override func viewDidLoad() {        
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
        
        let uploadButton = UIBarButtonItem(title: "New Upload", style: .plain, target: self, action: #selector(self.didPressUploadButton(_:)))
        self.navigationItem.rightBarButtonItem = uploadButton
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showSounds()
        
        let player = Player.sharedInstance
        if player.player != nil {
            setUpMiniPlayer()
        } else if PFUser.current() != nil {
            setUpTableView(nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEditSoundInfo" {
            var soundToBeEdited: Sound!
            if let selectedSound = soundList.selectedSound {
                selectedSound.isDraft = true 
                soundToBeEdited = selectedSound
            } else {
                soundToBeEdited = newSound
            }
            let viewController: SoundInfoViewController = segue.destination as! SoundInfoViewController
            viewController.soundThatIsBeingEdited = soundToBeEdited
        } else {
            soundList.prepareToShowTippers(segue)
            let backItem = UIBarButtonItem()
            backItem.title = "Tippers"
            navigationItem.backBarButtonItem = backItem
        }
    }
    
    func showSounds() {
        if soundList != nil {
            self.soundList.sounds.removeAll()
            self.tableView.reloadData()
        }
        
        soundList = SoundList(target: self, tableView: tableView, soundType: "drafts", userId: PFUser.current()?.objectId, tags: nil, searchText: nil, descendingOrder: nil)
    }
    
    //mark: tableview
    var tableView = UITableView()
    let soundReuse = "soundReuse"
    let noSoundsReuse = "noSoundsReuse"
    func setUpTableView(_ miniPlayer: UIView?) {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        tableView.backgroundColor = color.lightGray()
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.backgroundColor = color.black()
        if let miniPlayer = miniPlayer {
            self.view.addSubview(tableView)
            self.tableView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.view)
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
                make.bottom.equalTo(miniPlayer.snp.top)
            }
            
        } else {
            self.tableView.frame = view.bounds
            self.view.addSubview(tableView)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Drafts"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if soundList.sounds.count == 0 {
            return 1
        }
        return soundList.sounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if soundList.sounds.count == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
            cell.backgroundColor = color.black()
            cell.headerTitle.text = "No drafts yet. Press the 'New Upload' button above to start releasing music to Soundbrew!"
            return cell
            
        } else {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
            cell.backgroundColor = color.black()
            return soundList.soundCell(indexPath, cell: cell)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRowAt(indexPath.row)
    }
    
    func didSelectRowAt(_ row: Int) {
        if let player = soundList.player {
            player.didSelectSoundAt(row)
            if miniPlayerView == nil {
                self.setUpMiniPlayer()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == soundList.sounds.count - 10 && !soundList.isUpdatingData && soundList.thereIsMoreDataToLoad {
            //soundList.loadCollection("createdAt", profileUserId: PFUser.current()!.objectId!)
        }
    }
    
    //mark: new sound upload
    @objc func didPressUploadButton(_ sender: UIBarButtonItem) {
        let menuAlert = UIAlertController(title: "Upload ", message: nil , preferredStyle: .actionSheet)
        menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        menuAlert.addAction(UIAlertAction(title: "From The App", style: .default, handler: { action in
            self.showUploadSoundFileUI()
        }))
        menuAlert.addAction(UIAlertAction(title: "From The Web", style: .default, handler: { action in
            UIApplication.shared.open(URL(string: "https://www.soundbrew.app/upload")!, options: [:], completionHandler: nil)
        }))
        self.present(menuAlert, animated: true, completion: nil)
    }
    
    func showUploadSoundFileUI() {
        let types: NSArray = NSArray(object: kUTTypeAudio as NSString)
        let documentPicker = UIDocumentPickerViewController(documentTypes: types as! [String], in: .import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let artist = Customer.shared.artist
        newSound = Sound(objectId: nil, title: nil, artURL: nil, artImage: nil, artFile: nil, tags: nil, createdAt: nil, plays: nil, audio: nil, audioURL: "\(urls[0])", relevancyScore: 0, audioData: nil, artist: artist, tmpFile: nil, tips: nil, tippers: nil, isDraft: true)
        self.performSegue(withIdentifier: "showSoundInfo", sender: self)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        
    }
    
    //mark: miniPlayer
    var miniPlayerView: MiniPlayerView?
    func setUpMiniPlayer() {
        miniPlayerView = MiniPlayerView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        self.view.addSubview(miniPlayerView!)
        let slide = UISwipeGestureRecognizer(target: self, action: #selector(self.miniPlayerWasSwiped))
        slide.direction = .up
        miniPlayerView!.addGestureRecognizer(slide)
        miniPlayerView!.addTarget(self, action: #selector(self.miniPlayerWasPressed(_:)), for: .touchUpInside)
        miniPlayerView!.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(50)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-49)
        }
        
        setUpTableView(miniPlayerView)
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
            let modal = PlayerV2ViewController()
            modal.player = player
            modal.playerDelegate = self
            let transitionDelegate = DeckTransitioningDelegate()
            modal.transitioningDelegate = transitionDelegate
            modal.modalPresentationStyle = .custom
            self.present(modal, animated: true, completion: nil)
        }
    }
    
    //mark: selectedArtist
    func selectedArtist(_ artist: Artist?) {
        if let artist = artist {
            if artist.objectId == "addFunds" {
                self.performSegue(withIdentifier: "showAddFunds", sender: self)
            } else if artist.objectId == "signup" {
                self.performSegue(withIdentifier: "showWelcome", sender: self)
            } else {
                soundList.selectedArtist(artist)
            }
        }
    }
}

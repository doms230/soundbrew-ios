//
//  FollowingViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 8/12/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import Kingfisher
import SnapKit
import AppCenterCrashes
import DeckTransition
import TwitterKit

class FollowingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, PlayerDelegate {
    
    var soundList: SoundList!
    let uiElement = UIElement()
    let color = Color()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        view.backgroundColor = color.black()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showSounds()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showProfile":
            soundList.prepareToShowSelectedArtist(segue)
            break
            
        case "showTippers":
            soundList.prepareToShowTippers(segue)
            let backItem = UIBarButtonItem()
            backItem.title = "Tippers"
            navigationItem.backBarButtonItem = backItem
            break
            
        default:
            break
        }
    }
    
    func showSounds() {
        if soundList != nil {
            self.soundList.sounds.removeAll()
            self.tableView.reloadData()
        }
        
        soundList = SoundList(target: self, tableView: tableView, soundType: "follow", userId: PFUser.current()?.objectId, tags: nil, searchText: nil, descendingOrder: nil)
        
        let player = Player.sharedInstance
        if player.player != nil {
            setUpMiniPlayer()
        } else if PFUser.current() != nil {
            setUpTableView(nil)
        }
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
            cell.headerTitle.text = "The latest releases from artists you follow will appear here!"
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
        
        if PFUser.current() != nil {
            setUpTableView(miniPlayerView)
        }
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

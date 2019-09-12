//
//  SearchSoundsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 1/28/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//  MARK: Data, tableview, player, tags, button actions, tableview, tags
//TODO: Automatic loading of more sounds as the user scrolls

import UIKit
import Parse
import Kingfisher
import SnapKit
import AppCenterCrashes
import DeckTransition

class SoundsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, PlayerDelegate {
    
    var soundList: SoundList!
    let uiElement = UIElement()
    let color = Color()
    var soundType: String!
    var userId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showSounds()
        
        let player = Player.sharedInstance
        if player.player != nil {
            setUpMiniPlayer()
        } else {
            setUpTableView(nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showProfile":
            soundList.prepareToShowSelectedArtist(segue)
            break
            
        case "showEditSoundInfo":
            soundList.prepareToShowSoundInfo(segue)
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
        
        var descendingOrder: String?
        if soundType == "chart" {
            if selectedTagForFiltering.name == "new" {
                descendingOrder = "createdAt"
            } else {
                //descendingOrder = "plays"
                descendingOrder = "tips"
            }
        }
        
        soundList = SoundList(target: self, tableView: tableView, soundType: soundType, userId: userId, tags: selectedTagForFiltering, searchText: nil, descendingOrder: descendingOrder)
    }
    
    //mark: tableview
    var tableView = UITableView()
    let soundReuse = "soundReuse"
    
    func setUpTableView(_ miniPlayer: UIView?) {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.backgroundColor = color.black()
        self.tableView.separatorStyle = .none
        
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
        return soundList.sounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
        cell.backgroundColor = color.black()
        return soundList.soundCell(indexPath, cell: cell)
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
            if soundType == "discover" {
                soundList.loadWorldCreatedAtSounds()
            } else {
                //soundList.loadSounds(soundList.descendingOrder, collectionIds: soundList.collectionSoundIds, userId: userId, searchText: nil, followIds: soundList.followUserIds)
            }
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
        
        setUpTableView(miniPlayerView!)
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
    
    //mark: tags
    var selectedTagForFiltering: Tag! 
}


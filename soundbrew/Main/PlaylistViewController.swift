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

class PlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TagDelegate, PlayerDelegate {
    
    var soundList: SoundList!
    var searchSounds = [Sound]()
    var searchUsers = [Artist]()
    var searchTags = [Tag]()
    let uiElement = UIElement()
    let color = Color()
    var playlistType = "discover"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showSounds()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let player = Player.sharedInstance
        if player.player != nil {
            setUpMiniPlayer()
            
        } else {
            setUpTableView(nil)
        }
        
        if soundList != nil {
            var tags: Array<Tag>?
            if selectedTagsForFiltering.count != 0 {
                tags = selectedTagsForFiltering
            }
            
            soundList = SoundList(target: self, tableView: tableView, soundType: "playlist", userId: PFUser.current()?.objectId, tags: tags, searchText: nil)
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
            
        case "showUploadSound":
            soundList.prepareToShowSoundAudioUpload(segue)
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
        
        var tags: Array<Tag>?
        if selectedTagsForFiltering.count != 0 {
            tags = selectedTagsForFiltering
        }
        
        soundList = SoundList(target: self, tableView: tableView, soundType: "playlist", userId: PFUser.current()?.objectId, tags: tags, searchText: nil)
    }
    
    //mark: tableview
    var tableView = UITableView()
    let soundReuse = "soundReuse"
    let tagsReuse = "tagsReuse"
    
    func setUpTableView(_ miniPlayer: UIView?) {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: tagsReuse)
        tableView.backgroundColor = color.lightGray()   
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
        if selectedTagsForFiltering.count != 0 {
            return 2
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var soundSection = 0
        
        if selectedTagsForFiltering.count != 0 {
            soundSection = 1
        }
        
        if section == soundSection {
            return soundList.sounds.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if selectedTagsForFiltering.count != 0 {
            if indexPath.section == 0 {
                return tagCell(indexPath)
                
            } else if indexPath.section == 1 {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
                cell.backgroundColor = .white 
                return soundList.soundCell(indexPath, cell: cell)
            }
        }
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
        return soundList.soundCell(indexPath, cell: cell)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //only one section if user decided to not choose any tags for their playlist 
        if selectedTagsForFiltering.count != 0 && indexPath.section == 1 {
            didSelectRowAt(indexPath.row)
            
        } else if selectedTagsForFiltering.count == 0 && indexPath.section == 0 {
            didSelectRowAt(indexPath.row)
        }
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
            
            soundList.loadWorldCreatedAtSounds()
            /*if PFUser.current() == nil {
                soundList.loadWorldCreatedAtSounds()
                
            } else {
                soundList.loadFollowCreatedAtSounds()
            }*/
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
            make.height.equalTo(90)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.view)
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
    var selectedTagsForFiltering = [Tag]()
    var xPositionForTags = 0
    
    func receivedTags(_ value: Array<Tag>?) {
        if let tags = value {
            selectedTagsForFiltering = tags
            soundList = SoundList(target: self, tableView: tableView, soundType: "discover", userId: nil, tags: tags, searchText: nil)
            
        } else {
            selectedTagsForFiltering.removeAll()
        }
        
        self.tableView.reloadData()
    }
    
    func tagCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: tagsReuse) as! SoundListTableViewCell
        cell.selectionStyle = .none
        cell.backgroundColor = color.lightGray()
        cell.tagsScrollview.subviews.forEach({ $0.removeFromSuperview() })
        xPositionForTags = uiElement.leftOffset
        if selectedTagsForFiltering.count != 0 {
            for i in 0..<selectedTagsForFiltering.count {
                let tag = selectedTagsForFiltering[i]
                self.addSelectedTags(cell.tagsScrollview, tag: tag, index: i)
            }
        }
        
        return cell
    }
    
    func addSelectedTags(_ scrollview: UIScrollView, tag: Tag, index: Int) {
        let name = "\(tag.name!)"
        //not using snpakit to set button frame becuase not able to get button width from button title.
        let buttonTitleWidth = uiElement.determineChosenTagButtonTitleWidth(name)
        
        let tagButton = UIButton()
        tagButton.frame = CGRect(x: xPositionForTags, y: 0, width: buttonTitleWidth, height: 30)
        tagButton.setTitle("#\(name.capitalized)", for: .normal)
        tagButton.setTitleColor(color.black(), for: .normal)
        tagButton.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 19)
        tagButton.tag = index
        scrollview.addSubview(tagButton)
        
        xPositionForTags = xPositionForTags + Int(tagButton.frame.width)
        scrollview.contentSize = CGSize(width: xPositionForTags, height: 35)
    }
}


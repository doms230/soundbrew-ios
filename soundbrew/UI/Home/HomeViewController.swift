//
//  HomeViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 3/27/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import Kingfisher
import SnapKit

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var soundList: SoundList!
    var homeSounds = [Sound]()
    
    var currentUser: PFUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*if Payment.shared.canMakePurchases() {
            Payment.shared.purchase()
        }*/
        
        /*guard SubscriptionService.shared.currentSessionId != nil,
            SubscriptionService.shared.hasReceiptData else {
                //
                return
        }*/
                
        if let currentUser = PFUser.current() {
            loadUserInfoFromCloud(currentUser.objectId!)
            self.currentUser = currentUser
            soundList = SoundList(target: self, tableView: tableView, soundType: "follows", userId: currentUser.objectId, tags: nil, searchText: nil)
            
            setUpTableView()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if soundList != nil {
            /* soundList.sounds = searchSounds
             soundList.player!.sounds = searchSounds
             soundList.target = self*/
            
            var tags: Array<Tag>?
            if let soundListTags = soundList.selectedTagsForFiltering {
                tags = soundListTags
            }
            
            if let currentUserId = self.currentUser?.objectId {
                soundList = SoundList(target: self, tableView: tableView, soundType: "follows", userId: currentUserId, tags: tags, searchText: nil)
            }
            
            //self.tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfile" {
            soundList.prepareToShowSelectedArtist(segue)
            
        } else if segue.identifier == "showTags" {
            soundList.prepareToShowTags(segue)
            
        } else if segue.identifier == "showEditSoundInfo" {
            soundList.prepareToShowSoundInfo(segue)
            
        } else if segue.identifier == "showUploadSound" {
            soundList.prepareToShowSoundAudioUpload(segue)
        }
    }
    
    //mark: tableview
    var tableView = UITableView()
    let recentPopularReuse = "recentPopularReuse"
    let soundReuse = "soundReuse"
    let filterSoundsReuse = "filterSoundsReuse"
    let noSoundsReuse = "noSoundsReuse"
    
    func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: recentPopularReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: filterSoundsReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        self.tableView.separatorStyle = .none
        //tableView.frame = view.bounds
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 && soundList.sounds.count != 0 {
            homeSounds = soundList.sounds
            return soundList.sounds.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let player = soundList.player {
            player.didSelectSoundAt(indexPath.row)
            if soundList.miniPlayerView == nil {
                soundList.setUpMiniPlayer()
            }
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: filterSoundsReuse) as! SoundListTableViewCell
            return soundList.soundFilterOptions(indexPath, cell: cell)
            
        } else if soundList.sounds.count == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
            cell.headerTitle.text = "Welcome to Soundbrew! The latest releases from artists you follow will appear here."
            return cell
            
        } else {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
            return soundList.sound(indexPath, cell: cell)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if indexPath.row == soundList.sounds.count - 10 && !soundList.isUpdatingData && soundList.thereIsNoMoreDataToLoad {
            soundList.loadSounds(soundList.descendingOrder, likeIds: nil, userId: nil, tags: soundList.selectedTagsForFiltering, followIds: soundList.followUserIds, searchText: nil)
        }
    }
    
    func loadUserInfoFromCloud(_ userId: String) {
        let query = PFQuery(className: "_User")
        query.getObjectInBackground(withId: userId) {
            (user: PFObject?, error: Error?) -> Void in
            if let error = error {
                print(error)
                
            } else if let user = user {
                let username = user["username"] as? String
                if username == nil || username!.contains("@") || username!.isEmpty {
                    self.performSegue(withIdentifier: "showEditProfile", sender: self)
                }
            }
        }
    }
}

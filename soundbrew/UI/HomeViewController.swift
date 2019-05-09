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
import AppCenterCrashes

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var soundList: SoundList!
    var homeSounds = [Sound]()
    
    var currentUser: PFUser?
    
    var receivedSoundObjectId: String? 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*if let id = receivedSoundObjectId {
            print("received id: \(id)")
        }*/
        
        /*if Payment.shared.canMakePurchases() {
            Payment.shared.purchase()
        }*/
        
        /*guard SubscriptionService.shared.currentSessionId != nil,
            SubscriptionService.shared.hasReceiptData else {
                //
                return
        }*/
        
        soundList = SoundList(target: self, tableView: tableView, soundType: "follows", userId: PFUser.current()?.objectId, tags: nil, searchText: nil)
        
        setUpTableView()
        
        if let currentUser = PFUser.current() {
            loadUserInfoFromCloud(currentUser.objectId!)
            self.currentUser = currentUser
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if soundList != nil {
            var tags: Array<Tag>?
            if let soundListTags = soundList.selectedTagsForFiltering {
                tags = soundListTags
            }
            
            if let currentUserId = self.currentUser?.objectId {
                soundList = SoundList(target: self, tableView: tableView, soundType: "follows", userId: currentUserId, tags: tags, searchText: nil)
            }            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showProfile":
            soundList.prepareToShowSelectedArtist(segue)
            break
            
        case "showTags":
            soundList.prepareToShowTags(segue)
            break
            
        case "showEditSoundInfo":
            soundList.prepareToShowSoundInfo(segue)
            break
            
        case "showUploadSound":
            soundList.prepareToShowSoundAudioUpload(segue)
            break
            
        case "showComments":
            soundList.prepareToShowComments(segue)
            break 
            
        default:
            break
        }
    }
    
    //mark: tableview
    var tableView = UITableView()
    let soundReuse = "soundReuse"
    let noSoundsReuse = "noSoundsReuse"
    
    func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
        self.tableView.separatorStyle = .none
        //tableView.frame = view.bounds
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-(soundList.miniPlayerView!.frame.height + (self.tabBarController?.tabBar.frame.height)!))
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if soundList.sounds.count == 0 {
            return 1
        }
        return soundList.sounds.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let player = soundList.player {
            player.didSelectSoundAt(indexPath.row)
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if soundList.sounds.count == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
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

//
//  SearchSoundsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 1/28/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//  MARK: Data, tableview, player, tags, button actions
//TODO: Automatic loading of more sounds as the user scrolls

import UIKit
import Parse
import Kingfisher
import SnapKit

class SoundListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        soundList = SoundList(target: self, tableView: tableView)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfile" {
            soundList.prepareToShowSelectedArtist(segue)
            
        } else if segue.identifier == "showTags" {
            soundList.prepareToShowTags(segue)
        }
    }
    
    //mark: tableview
    var tableView = UITableView()
    func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
    }
    var soundList: SoundList!
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return soundList.sounds.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let player = soundList.player {
            player.didSelectSoundAt(indexPath.row)
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return soundList.soundFilterOptions(indexPath)
            
        } else {
            return soundList.sound(indexPath)
        }        
    }
}


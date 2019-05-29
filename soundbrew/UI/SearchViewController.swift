//
//  SearchViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 5/29/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import Kingfisher
import SnapKit
import AppCenterCrashes

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    var soundList: SoundList!
    var searchSounds = [Sound]()
    var searchUsers = [Artist]()
    var searchTags = [Tag]()
    let uiElement = UIElement()
    let color = Color()
    var playlistType = "discover"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchBar()
        setUpTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        /*if soundList != nil && !searchIsActive {
            showSounds(playlistType)
        }*/
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
    let recentPopularReuse = "recentPopularReuse"
    let soundReuse = "soundReuse"
    let playlistSoundsReuse = "playlistSoundsReuse"
    let searchProfileReuse = "searchProfileReuse"
    //in this case, will be changed to Artists and Sounds ... Doing this to avoid repetion in code
    let SearchListTypeHeaderReuse = "SearchListTypeHeaderReuse"
    let searchTagViewReuse = "searchTagViewReuse"
    let tagsReuse = "tagsReuse"
    
    func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: recentPopularReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: soundReuse)
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: tagsReuse)
        //tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: playlistSoundsReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchProfileReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: SearchListTypeHeaderReuse)
        //tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchTagViewReuse)
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
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
        if section == 0 {
            return 1
            
        } else {
            switch searchType {
            case profileSearch:
                return searchUsers.count
                
            case soundSearch:
                return soundList.sounds.count
                
            default:
                return 1
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return searchTypeCell()
            
        } else {
            switch searchType {
            case profileSearch:
                return searchUsers[indexPath.row].cell(tableView, reuse: searchProfileReuse)
                
            case soundSearch:
                let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
                return soundList.sound(indexPath, cell: cell)
                
            default:
                return searchTags[indexPath.row].cell(tableView, reuse: searchTagViewReuse)
            }
        }
        
        /*let cell = self.tableView.dequeueReusableCell(withIdentifier: soundReuse) as! SoundListTableViewCell
        return soundList.sound(indexPath, cell: cell)*/
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
        exitSearch()
        
        switch searchType {
        case profileSearch:
            soundList.selectedArtist = searchUsers[indexPath.row]
            self.performSegue(withIdentifier: "showProfile", sender: self)
            break
            
        case soundSearch:
            didSelectSoundAt(indexPath.row)
            break
            
        default:
            break
        }
    }
    
    func didSelectSoundAt(_ row: Int) {
        if let player = soundList.player {
            player.didSelectSoundAt(row, soundList: soundList)
        }
    }
    
    //mark: Search
    var searchIsActive = false
    var searchType = "profile"
    let profileSearch = "profile"
    let soundSearch = "search"
    
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width - 10, height: 10))
        searchBar.placeholder = "Search"
        
        let searchTextField = searchBar.value(forKey: "_searchField") as? UITextField
        searchTextField?.backgroundColor = color.lightGray()
        searchBar.delegate = self
        return searchBar
    }()
    
    func setupSearchBar() {
        let leftNavBarButton = UIBarButtonItem(customView: searchBar)
        self.navigationItem.leftBarButtonItem = leftNavBarButton
    }
    
    func exitSearch() {
        searchBar.text = ""
        searchBar.placeholder = "Tags"
        searchTags.removeAll()
        self.searchBar.resignFirstResponder()
        searchIsActive = false
        self.tableView.reloadData()
    }
    
    @objc func didPressSearchTypeButton(_ sender: UIButton) {
        switch sender.tag {
         case 0:
         searchType = profileSearch
         break
         
         case 1:
         searchType = soundSearch
         break
         
         default:
         break
         }
        
         search()
    }
    
    func search() {
        switch searchType {
         case profileSearch:
         searchBar.placeholder = "Name, Username"
         if !searchBar.text!.isEmpty {
         searchUsers(searchBar.text!)
         
         } else {
            
         //self.tableView.reloadData()
         }
         break
         
         case soundSearch:
         searchBar.placeholder = "Sound Name"
         soundList = SoundList(target: self, tableView: tableView, soundType: "search", userId: nil, tags: nil, searchText: searchBar.text!)
         
         break
         
         default:
         break
         }
        self.tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchIsActive = true
        search()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchIsActive = true
        search()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        exitSearch()
    }
    
    func searchTypeCell() -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: SearchListTypeHeaderReuse) as! ProfileTableViewCell
        
        cell.isSearchActive = true
        
        cell.firstListType.setTitle("Accounts", for: .normal)
        cell.firstListType.addTarget(self, action: #selector(self.didPressSearchTypeButton(_:)), for: .touchUpInside)
        cell.firstListType.tag = 0
        
        cell.secondListType.setTitle("Sounds", for: .normal)
        cell.secondListType.addTarget(self, action: #selector(self.didPressSearchTypeButton(_:)), for: .touchUpInside)
        cell.secondListType.tag = 1
        
        if searchType == profileSearch {
            cell.firstListType.setTitleColor(color.black(), for: .normal)
            cell.secondListType.setTitleColor(color.darkGray(), for: .normal)
            
        } else {
            cell.secondListType.setTitleColor(color.black(), for: .normal)
            cell.firstListType.setTitleColor(color.darkGray(), for: .normal)
        }
        
        return cell
    }
    
    func searchUsers(_ text: String) {
        let nameQuery = PFQuery(className: "_User")
        nameQuery.whereKey("artistName", matchesRegex: text.lowercased())
        nameQuery.whereKey("artistName", matchesRegex: text)
        
        let usernameQuery = PFQuery(className: "_User")
        usernameQuery.whereKey("username", matchesRegex: text.lowercased())
        
        let query = PFQuery.orQuery(withSubqueries: [nameQuery, usernameQuery])
        query.limit = 50
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    var userResults = [Artist]()
                    for user in objects {
                        let username = user["username"] as? String
                        
                        var email: String?
                        
                        if let currentUser = PFUser.current() {
                            if currentUser.objectId! == user.objectId! {
                                email = user["email"] as? String
                            }
                        }
                        
                        let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: username, website: nil, bio: nil, email: email, isFollowedByCurrentUser: nil, followerCount: nil)
                        
                        if let followerCount = user["followerCount"] as? Int {
                            artist.followerCount = followerCount
                        }
                        
                        if let name = user["artistName"] as? String {
                            artist.name = name
                        }
                        
                        if let username = user["username"] as? String {
                            artist.username = username
                        }
                        
                        if let city = user["city"] as? String {
                            artist.city = city
                        }
                        
                        if let userImageFile = user["userImage"] as? PFFileObject {
                            artist.image = userImageFile.url!
                        }
                        
                        if let bio = user["bio"] as? String {
                            artist.bio = bio
                        }
                        
                        if let artistVerification = user["artistVerification"] as? Bool {
                            artist.isVerified = artistVerification
                        }
                        
                        if let website = user["website"] as? String {
                            artist.website = website
                        }
                        
                        userResults.append(artist)
                    }
                    
                    self.searchUsers = userResults
                }
                
                self.tableView.reloadData()
                
            } else {
                print("Error: \(error!)")
            }
        }
    }

}

//
//  MentionsViewController.swift
//  soundbrew
//
//  Created by Dominic Smith on 2/18/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import Kingfisher

class MentionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, PlayerDelegate, TagDelegate {
    let color = Color()
    let uiElement = UIElement()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        
        self.uiElement.addTitleView("Activity", target: self)
        self.loadMentions()
      }
    
    override func viewDidAppear(_ animated: Bool) {
      self.view.backgroundColor = color.black()
      navigationController?.navigationBar.barTintColor = color.black()
      navigationController?.navigationBar.tintColor = .white
      if PFUser.current() != nil {
          self.setMiniPlayer()
      }
    }
          
      override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
          switch segue.identifier {
              case "showProfile":
                  let viewController = segue.destination as! ProfileViewController
                  viewController.profileArtist = selectedArtist
                  
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
      
      //mark: tableview
    var tableView: UITableView!
    let mentionsReuse = "mentionsReuse"
    let noSoundsReuse = "noSoundsReuse"
    func setUpTableView() {
        let miniPlayerHeight = MiniPlayerView.sharedInstance.frame.height
        var tabBarControllerHeight: CGFloat = 50
        if let tabBar = self.tabBarController?.tabBar {
            tabBarControllerHeight = tabBar.frame.height
        }
        
        tableView = UITableView()
          tableView.dataSource = self
          tableView.delegate = self
          tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: mentionsReuse)
          tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
          tableView.separatorStyle = .none
          tableView.backgroundColor = color.black()
          let refreshControl = UIRefreshControl()
          refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
          tableView.refreshControl = refreshControl
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-(miniPlayerHeight + tabBarControllerHeight))
        }
      }
      
      @objc func refresh(_ sender: UIRefreshControl) {
         loadMentions()
      }
      
      func numberOfSections(in tableView: UITableView) -> Int {
          return 1
      }
      
      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          if mentions.count == 0 {
              return 1
          }
          return mentions.count
      }
      
      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if mentions.count == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: noSoundsReuse) as! SoundListTableViewCell
            cell.backgroundColor = color.black()
            cell.artistButton.isHidden = true
            if self.isLoadingMentions {
                cell.headerTitle.text = ""
            } else {
                cell.headerTitle.text = "Any mentions such as likes or follows will appear here!"
            }
              
              return cell
          } else {
             return mentionsCell(indexPath)
          }
      }
    
    @objc func didPressDiscoverButton(_ sender: UIButton) {
        if let tabBar = self.tabBarController {
            tabBar.selectedIndex = 2
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
       /* if indexPath.row == self.mentions.count - 10 && !self.isLoadingMentions {
            self.loadMentions()
        }*/
    }
      
      func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.mentions.indices.contains(indexPath.row) {
            let mention = self.mentions[indexPath.row]
            switch mention.type {
            case "like", "follow", "gift":
                tableView.cellForRow(at: indexPath)?.isSelected = false
                selectedArtist = mentions[indexPath.row].artist
                self.performSegue(withIdentifier: "showProfile", sender: self)
                break
                
            case "comment":
                loadAndPresentSoundWithCommentAttached(mention, tableView: tableView, indexPath: indexPath)
                break
                
            default:
                break
            }
        }
      }
    
    func loadAndPresentSoundWithCommentAttached(_ mention: Mention, tableView: UITableView, indexPath: IndexPath) {
        if let soundId = mention.soundId {
            let query = PFQuery(className: "Post")
            query.cachePolicy = .networkElseCache
            query.getObjectInBackground(withId: soundId) {
                (object: PFObject?, error: Error?) -> Void in
                if let object = object {
                    let mentionSound = self.uiElement.newSoundObject(object)
                    let commentModal = PlayerViewController()
                    commentModal.playerDelegate = self
                    if let commentId = mention.commentId {
                       commentModal.selectedCommentFromMentions = commentId
                    }
                    
                    if let commentUsername = mention.artist?.username {
                        commentModal.selectedCommentReply = commentUsername
                    }
                    
                    let player = Player.sharedInstance
                    if let currentSoundId = player.currentSound?.objectId {
                        if currentSoundId != mentionSound.objectId {
                            player.sounds = [mentionSound]
                            player.setUpNextSong(false, at: nil, shouldPlay: false, selectedSound: mentionSound)
                        }
                        
                    } else {
                        player.sounds = [mentionSound]
                        player.setUpNextSong(false, at: nil, shouldPlay: false, selectedSound: mentionSound)
                    }

                    tableView.cellForRow(at: indexPath)?.isSelected = false
                    self.present(commentModal, animated: true, completion: nil)
                }
            }
        }
    }
    
    func mentionsCell(_ indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: mentionsReuse) as! ProfileTableViewCell
        cell.backgroundColor = color.black()
        let mention = self.mentions[indexPath.row]
        
        if let name = mention.artist?.name {
            cell.username.text = name
            if let image = mention.artist?.image {
                cell.profileImage.kf.setImage(with: URL(string: image), placeholder: UIImage(named: "profile_icon"))
            }
        } else if let artist = mention.artist {
            artist.loadUserInfoFromCloud(nil, soundCell: nil, commentCell: nil, mentionCell: cell, artistUsernameLabel: nil, artistImageButton: nil)
        }
        
        if let message = mention.message {
            cell.displayNameLabel.text = message
        }
                
        //createdAt
        cell.city.text = self.uiElement.formatDateAndReturnString(mention.createdAt)
        
        return cell
    }
      
      //mark: miniPlayer
    func setMiniPlayer() {
        let miniPlayerView = MiniPlayerView.sharedInstance
        miniPlayerView.superViewController = self
        miniPlayerView.tagDelegate = self
        miniPlayerView.playerDelegate = self
    }
    
    var mentions = [Mention]()
    var isLoadingMentions = true
    func loadMentions() {
        isLoadingMentions = true
        let query = PFQuery(className: "Mention")
        query.whereKey("toUserId", equalTo: PFUser.current()!.objectId!)
        query.whereKey("fromUserId", notEqualTo: PFUser.current()!.objectId!)
        query.whereKey("objectId", notContainedIn: mentions.map {$0.objectId!})
        query.whereKeyExists("message")
        query.limit = 50
        query.addDescendingOrder("createdAt")
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                for object in objects {
                    let fromUserId = object["fromUserId"] as! String
                    let mention = Mention(object.objectId, createdAt: object.createdAt!, type: object["type"] as? String, fromUserId: fromUserId, artist: nil, soundId: nil, commentId: nil, message: nil)
                    let artist = self.getArtist(fromUserId)
                    mention.artist = artist
                    
                    mention.soundId = object["postId"] as? String
                    mention.commentId = object["commentId"] as? String
                    mention.message = object["message"] as? String
                    self.mentions.append(mention)
                }
                
                self.finishedLoading()
                
            } else {
                self.finishedLoading()
            }
        }
    }
    
    func getArtist(_ userId: String) -> Artist {
        let newArtisObjectt = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, fanCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, account: nil)
        return newArtisObjectt
    }
    
    func finishedLoading() {
        DispatchQueue.main.async {
            self.isLoadingMentions = false
            if self.tableView == nil {
                self.setUpTableView()
            } else {
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            }
            
            if self.mentions.count > 0 && PFUser.current()?.objectId != self.uiElement.d_innovatorObjectId {
                SKStoreReviewController.requestReview()
            }
        }
    }
      
      //mark: selectedArtist
      var selectedArtist: Artist!
      
      func selectedArtist(_ artist: Artist?) {
          if let artist = artist {
              switch artist.objectId {
                  case "signup":
                      self.performSegue(withIdentifier: "showWelcome", sender: self)
                      break
                      
                  case "collectors":
                      self.performSegue(withIdentifier: "showTippers", sender: self)
                      break
                      
                  default:
                      selectedArtist = artist
                      self.performSegue(withIdentifier: "showProfile", sender: self)
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

class Mention {
    var objectId: String!
    var createdAt: Date!
    var type: String?
    var fromUserId: String!
    var artist: Artist?
    var soundId: String?
    var commentId: String?
    var message: String?
    
    init(_ objectId: String!, createdAt: Date!, type: String?, fromUserId: String!, artist: Artist?, soundId: String?, commentId: String?, message: String?) {
        self.objectId = objectId
        self.createdAt = createdAt
        self.type = type
        self.fromUserId = fromUserId
        self.artist = artist
        self.soundId = soundId
        self.commentId = commentId
        self.message = message
    }
}

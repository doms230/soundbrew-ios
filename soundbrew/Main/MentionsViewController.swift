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
        
            NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSoundUpdate), name: NSNotification.Name(rawValue: "setSound"), object: nil)
        
            self.uiElement.addTitleView("Activity", target: self)
      }
    
    @objc func didReceiveSoundUpdate() {
        if PFUser.current() != nil {
            let player = Player.sharedInstance
            if player.player != nil {
                setUpMiniPlayer()
            }
        }
    }
      
      override func viewDidAppear(_ animated: Bool) {
        if PFUser.current() != nil {
            let player = Player.sharedInstance
            if player.player != nil {
                setUpMiniPlayer()
            } else if PFUser.current() != nil {
                setUpTableView(nil)
            }
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
      var tableView = UITableView()
      let mentionsReuse = "mentionsReuse"
      let noSoundsReuse = "noSoundsReuse"
      func setUpTableView(_ miniPlayer: UIView?) {
          tableView.dataSource = self
          tableView.delegate = self
          tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: mentionsReuse)
          tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: noSoundsReuse)
          tableView.separatorStyle = .none
          tableView.backgroundColor = color.black()
          let refreshControl = UIRefreshControl()
          refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
          tableView.refreshControl = refreshControl
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
        
        self.loadMentions()
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
            if self.isLoadingMentions {
                cell.headerTitle.text = ""
                cell.artistButton.isHidden = true
            } else {
                cell.headerTitle.text = "People who like your music, follow you, or mention you in a comment will appear here!"
                cell.artistButton.setTitle("Upload Sounds", for: .normal)
                cell.artistButton.addTarget(self, action: #selector(self.didPressDiscoverButton(_:)), for: .touchUpInside)
                cell.artistButton.isHidden = false
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
            tableView.cellForRow(at: indexPath)?.isSelected = false
            let mention = self.mentions[indexPath.row]
            switch mention.type {
            case "like", "follow":
                selectedArtist = mentions[indexPath.row].artist
                self.performSegue(withIdentifier: "showProfile", sender: self)
                break
                
            case "comment":
                let commentModal = CommentViewController()
                if let mentionSound = mention.sound {
                    commentModal.playerDelegate = self
                    commentModal.sound = mentionSound
                    if let commentId = mention.comment?.objectId {
                       commentModal.selectedCommentFromMentions = commentId
                    }
                    
                    let player = Player.sharedInstance
                    if let currentSound = player.currentSound, currentSound.objectId! != mentionSound.objectId! {
                        player.pause()
                    }
                }
                self.present(commentModal, animated: true, completion: nil)
                break
                
            default:
                break
            }
        }
      }
    
    func mentionsCell(_ indexPath: IndexPath) -> ProfileTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: mentionsReuse) as! ProfileTableViewCell
        cell.backgroundColor = color.black()
        let mention = self.mentions[indexPath.row]
        var name = ""
        if let username = mention.artist?.username {
            name = username
        } else if let artistName = mention.artist?.name {
            name = artistName
        }
        
        if let image = mention.artist?.image {
            cell.profileImage.kf.setImage(with: URL(string: image))
        } else {
            cell.profileImage.image = UIImage(named: "profile_icon")
        }
        
        switch mention.type {
        case "like":
            var title = ""
            if let soundTitle = mention.sound?.title {
                title = soundTitle
            }
            cell.displayNameLabel.text = "\(name) liked \(title)."
            break
            
        case "follow":
            cell.displayNameLabel.text = "\(name) followed you."
            break
            
        case "comment":
            var comment = ""
            if let commentText = mention.comment?.text {
                comment = commentText
            }
            cell.displayNameLabel.text = "\(name) commented '\(comment)'"
            cell.displayNameLabel.numberOfLines = 2
            break
            
        default:
            break
        }
        
        //createdAt
        cell.city.text = self.uiElement.formatDateAndReturnString(mention.createdAt)
        
        return cell
    }
      
      //mark: miniPlayer
      var miniPlayerView: MiniPlayerView?
      func setUpMiniPlayer() {
        DispatchQueue.main.async {
            self.miniPlayerView = MiniPlayerView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            self.miniPlayerView?.superViewController = self 
            self.view.addSubview(self.miniPlayerView!)
            let slide = UISwipeGestureRecognizer(target: self, action: #selector(self.miniPlayerWasSwiped))
            slide.direction = .up
            self.miniPlayerView!.addGestureRecognizer(slide)
            self.miniPlayerView!.addTarget(self, action: #selector(self.miniPlayerWasPressed(_:)), for: .touchUpInside)
            self.miniPlayerView!.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(75)
                make.right.equalTo(self.view)
                make.left.equalTo(self.view)
                make.bottom.equalTo(self.view).offset(-((self.tabBarController?.tabBar.frame.height)!))
            }
            
            self.setUpTableView(self.miniPlayerView!)
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
              let modal = PlayerViewController()
              modal.playerDelegate = self
              modal.tagDelegate = self
              self.present(modal, animated: true, completion: nil)
          }
      }
    
    var mentions = [Mention]()
    var isLoadingMentions = true
    func loadMentions() {
        if let refreshControl = self.tableView.refreshControl {
            refreshControl.beginRefreshing()
        }
        isLoadingMentions = true
        let query = PFQuery(className: "Mention")
        query.whereKey("toUserId", equalTo: PFUser.current()!.objectId!)
        query.whereKey("objectId", notContainedIn: mentions.map {$0.objectId!})
        query.limit = 50
        query.addDescendingOrder("createdAt")
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if let objects = objects {
                for object in objects {
                    let fromUserId = object["fromUserId"] as! String
                    let mention = Mention(object.createdAt!, artist: nil, comment: nil, sound: nil, type: nil, fromUserId: fromUserId, objectId: object.objectId!)
                    
                    if let commentId = object["commentId"] as? String {
                        mention.type = "comment"
                        self.loadComment(commentId, mention: mention)
                    } else if let postId = object["postId"] as? String {
                        mention.type = "like"
                        self.loadPost(postId, mention: mention)
                        
                    } else {
                        mention.type = "follow"
                        self.loadArtist(mention)
                    }
                }
                
                if objects.count > 0 && PFUser.current()?.objectId != self.uiElement.d_innovatorObjectId {
                    SKStoreReviewController.requestReview()
                } else {
                    self.finishedLoading()
                }
                
            } else {
                self.finishedLoading()
            }
        }
    }
    
    func loadComment(_ commentId: String, mention: Mention) {
        let query = PFQuery(className: "Comment")
        query.cachePolicy = .networkElseCache
        query.getObjectInBackground(withId: commentId) {
            (object: PFObject?, error: Error?) -> Void in
            if let object = object {
                let comment = Comment(objectId: object.objectId, artist: nil, text: "", atTime: 0, createdAt: object.createdAt)
                if let text = object["text"] as? String {
                    comment.text = text
                }
                mention.comment = comment
                let postId = object["postId"] as! String
                self.loadPost(postId, mention: mention)
            }
        }
    }
    
    func loadPost(_ soundId: String, mention: Mention) {
        let query = PFQuery(className: "Post")
        query.cachePolicy = .networkElseCache
        query.getObjectInBackground(withId: soundId) {
            (object: PFObject?, error: Error?) -> Void in
            if let object = object {
                let sound = self.uiElement.newSoundObject(object)
                mention.sound = sound
                self.loadArtist(mention)
            }
        }
    }
    
    func loadArtist(_ mention: Mention) {
        let query = PFQuery(className: "_User")
        query.cachePolicy = .networkElseCache
        query.getObjectInBackground(withId: mention.fromUserId) {
            (user: PFObject?, error: Error?) -> Void in
            if let user = user {
                let artist = self.uiElement.newArtistObject(user)
                mention.artist = artist
                self.mentions.append(mention)
               let sortedMentions =  self.mentions.sorted(by: {$0.createdAt > $1.createdAt})
                self.mentions = sortedMentions
            }
            self.finishedLoading()
        }
    }
    
    func finishedLoading() {
        DispatchQueue.main.async {
            self.isLoadingMentions = false
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
    }
      
      //mark: selectedArtist
      var selectedArtist: Artist!
      
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
    var artist: Artist?
    var comment: Comment?
    var sound: Sound?
    var type: String?
    var fromUserId: String!
    
    init(_ createdAt: Date, artist: Artist?, comment: Comment?, sound: Sound?, type: String?, fromUserId: String!, objectId: String) {
        self.createdAt = createdAt
        self.artist = artist
        self.comment = comment
        self.sound = sound
        self.type = type
        self.fromUserId = fromUserId
        self.objectId = objectId
    }
}

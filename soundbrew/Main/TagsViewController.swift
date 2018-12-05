//
//  TagsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/25/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//search Mark: view, tableView, taglist, searchbar, data

import UIKit
import TagListView
import SnapKit
import Parse
import AVFoundation
import NVActivityIndicatorView
import Alamofire

class TagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TagListViewDelegate, NVActivityIndicatorViewable {
    
    //MARK: views
    let uiElement = UIElement()
    let color = Color()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startAnimating()
        setUpSearchBar()
        loadTags()
        
        if UserDefaults.standard.stringArray(forKey: "tags") != nil {
            SKStoreReviewController.requestReview()
        }
    }
    
    /*lazy var menuButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "menu"), for: .normal)
        return button
    }()*/
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            
        } catch let error {
            print("Unable to activate audio session:  \(error.localizedDescription)")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController: PlayerViewController = segue.destination as! PlayerViewController
        viewController.tags = self.chosenTagsArray
    }
    
    lazy var brewMyPlaylistButton: UIButton = {
        let button = UIButton()
        button.setTitle("Brew My Playlist", for: .normal)
        button.setTitleColor(color.black(), for: .normal)
        button.backgroundColor = color.uicolorFromHex(0xa9c5d0)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 17)!
        button.isHidden = true
        return button
    }()
    
    func shouldHideBrewMyPlaylistButton(_ shouldHide: Bool) {
        brewMyPlaylistButton.isHidden = shouldHide
        /*if shouldEnable {
         brewMyPlaylistButton.backgroundColor = color.primary()
         brewMyPlaylistButton.setTitleColor(color.black(), for: .normal)
         
         
         } else {
         brewMyPlaylistButton.backgroundColor = backgroundColor()
         brewMyPlaylistButton.setTitleColor(.lightGray, for: .normal)
         }*/
    }
    
    func setUpBrewMyPlaylistButton() {
        self.view.backgroundColor = backgroundColor()
        
        self.brewMyPlaylistButton.addTarget(self, action: #selector(self.didPressBrewMyPlaylistButton(_:)), for: .touchUpInside)
        self.tableView.addSubview(self.brewMyPlaylistButton)
        brewMyPlaylistButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(60)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
        
        /*self.menuButton.addTarget(self, action: #selector(self.didPressMenuButton(_:)), for: .touchUpInside)
        self.view.addSubview(self.menuButton)
        menuButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(30)
            make.top.equalTo(self.brewMyPlaylistButton).offset(5)
            make.left.equalTo(self.view).offset(self.uiElement.leftOffset)
        }*/
    }
    
    //MARK: Tableview
    var tableView: UITableView!
    let tagReuse = "tagReuse"
    let featureTagReuse = "featureTagReuse"
    
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MainTableViewCell.self, forCellReuseIdentifier: tagReuse)
        tableView.register(MainTableViewCell.self, forCellReuseIdentifier: featureTagReuse)
        tableView.backgroundColor = backgroundColor()
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.chosenTagsScrollview.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
        
        setUpBrewMyPlaylistButton()
    }
    
     func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return featureTagTitles.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: MainTableViewCell!
        
        if indexPath.section == 0 {
            cell = self.tableView.dequeueReusableCell(withIdentifier: featureTagReuse) as? MainTableViewCell
            
            var tagType: String?
            
            switch indexPath.row {
            case 0:
                tagType = "mood"
                break
                
            case 1:
                tagType = "activity"
                break
                
            case 2:
                tagType = "genre"
                break
                
            case 3:
                tagType = "city"
                break
                
            case 4:
                tagType = "artist"
                break
                
            default:
                break
            }
            
            if let tagType = tagType {
                let tags: Array<Tag> = self.filteredTags.filter {$0.tagType == tagType}
                //addFeatureTagButton(tags, cell: cell)
                addFeatureTagButton(tags, cell: cell)
            }
            
        } else {
            cell = self.tableView.dequeueReusableCell(withIdentifier: tagReuse) as? MainTableViewCell
            cell.tagLabel.delegate = self
            cell.tagLabel.removeAllTags()
            let otherTags: Array<String> = self.filteredTags.filter {$0.tagType == nil}.map {$0.name}
            cell.tagLabel.addTags(otherTags)
            self.tagView = cell.tagLabel
            
            /*let tagColors = [color.primary(), color.uicolorFromHex(0xd0aba9), color.uicolorFromHex(0xd0bfa9), color.uicolorFromHex(0xaea9d0)]
            var colorI = 0
            
            for i in 0..<cell.tagLabel.tagViews.count {
                let tag = cell.tagLabel.tagViews[i]
                
                let color = tagColors[colorI]
                tag.borderColor = color
                tag.textColor = color 
                
                if tagColors.indices.contains(colorI + 1) {
                    colorI = 0
                    
                } else {
                    colorI = colorI + 1
                }
            }*/
        }

        cell.backgroundColor = backgroundColor()
        cell.selectionStyle = .none
        
        return cell
    }
    
    //MARK: button actions
    @objc func didPressBrewMyPlaylistButton(_ sender: UIButton) {
        UserDefaults.standard.set(self.chosenTagsArray, forKey: "tags")
        self.uiElement.segueToView("Main", withIdentifier: "player", target: self)
    }
    
    @objc func didPressMenuButton(_ sender: UIButton) {
        let alertController = UIAlertController (title: nil, message: nil, preferredStyle: .actionSheet)
        
        let uploadAction = UIAlertAction(title: "Upload to Soundbrew", style: .default) { (_) -> Void in
            let soundbrewArtistsLink = URL(string: "https://itunes.apple.com/us/app/soundbrew-artists/id1438851832?mt=8")!
            if UIApplication.shared.canOpenURL(soundbrewArtistsLink) {
                UIApplication.shared.open(soundbrewArtistsLink, completionHandler: nil)
            }
        }
        alertController.addAction(uploadAction)
        
        let provideFeedbackAction = UIAlertAction(title: "Provide Feedback", style: .default) { (_) -> Void in
            let soundbrewArtistsLink = URL(string: "https://www.soundbrew.app/support")!
            if UIApplication.shared.canOpenURL(soundbrewArtistsLink) {
                UIApplication.shared.open(soundbrewArtistsLink, completionHandler: nil)
            }
        }
        alertController.addAction(provideFeedbackAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func didPressRemoveSelectedTag(_ sender: UIButton) {
        self.startAnimating()
        removeChosenTag(sender)
        setFilteredTagIsSelectedAsFalse(sender)
    }
    
    func setFilteredTagIsSelectedAsFalse(_ sender: UIButton) {
        let title = sender.titleLabel!.text!.trimmingCharacters(in: .whitespaces)
        for i in 0..<self.filteredTags.count {
            if self.filteredTags[i].name! == title {
                self.filteredTags[i].isSelected = false
                break
            }
        }
        self.filteredTags.sort(by: {$0.count > $1.count!})
        self.tableView.reloadData()
        self.stopAnimating()
    }
    
    func removeChosenTag(_ sender: UIButton) {
        let title = sender.titleLabel!.text!.trimmingCharacters(in: .whitespaces)
        
        //remove tag from chosen Tags
        for i in 0..<self.chosenTagsArray.count {
            if self.chosenTagsArray[i] == title  {
                self.chosenTagsArray.remove(at: i)
                break
            }
        }
        
        //reset scrollview
        self.chosenTagsScrollview.subviews.forEach({ $0.removeFromSuperview() })
        xPositionForChosenTags = UIElement().leftOffset
        
        //add back chosen tags to chosen tag scrollview
        for title in chosenTagsArray {
            self.addChosenTagButton(title)
        }
        
        //show tags label if no more chosen tags
        if self.chosenTagsArray.count == 0 {
            addChooseTagsLabel()
            shouldHideBrewMyPlaylistButton(true)
        }
    }
    
    //MARK: tags
    var tags = [Tag]()
    var filteredTags = [Tag]()
    var tagView: TagListView!
    
    let featureTagTitles = ["Genre", "City", "Artists", "Mood", "Activity"]
    
    var genreTags = [String]()
    var moodTags = [String]()
    var activityTags = [String]()
    var cityTags = [String]()
    var artistTags = [String]()
    
    var chosenTagsArray = [String]()
    var xPositionForChosenTags = UIElement().leftOffset
    
    lazy var chooseTagsLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose Tags"
        label.textColor = color.black()
        label.textAlignment = .center
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 30)
        return label
    }()
    
    lazy var chosenTagsScrollview: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    func setUpTagListView() {
        addChooseTagsLabel()
        
        self.view.addSubview(self.chosenTagsScrollview)
        chosenTagsScrollview.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.top.equalTo(self.searchBar.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
        }
    }
    
    func addChooseTagsLabel() {
        self.chosenTagsScrollview.addSubview(chooseTagsLabel)
        chooseTagsLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.chosenTagsScrollview)
            make.left.equalTo(self.chosenTagsScrollview).offset(uiElement.leftOffset)
            make.right.equalTo(self.chosenTagsScrollview).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.chosenTagsScrollview)
        }
    }
    
    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
        if !tagView.isSelected {
            sender.removeTag(title)
            self.chosenTagsArray.append(title)
            self.addChosenTagButton(title)
            var positionToRemoveTag: Int?
            for i in 0..<self.filteredTags.count {
                if self.filteredTags[i].name == title {
                    positionToRemoveTag = i
                }
            }
            
            if let p = positionToRemoveTag {
                self.filteredTags.remove(at: p)
            }
        }
    }
    
    func addChosenTagButton(_ buttonTitle: String) {
        self.chooseTagsLabel.removeFromSuperview()
        
        let buttonTitleWithX = "\(buttonTitle)"
        let buttonImageWidth = 25
        //not using snpakit to set button frame becuase not able to get button width from button title.
        let buttonTitleWidth = determineChosenTagButtonTitleWidth(buttonTitleWithX)
        
        let chosenTagButton = UIButton()
        chosenTagButton.frame = CGRect(x: xPositionForChosenTags, y: 0, width: buttonTitleWidth + buttonImageWidth , height: 45)
        chosenTagButton.setTitle("\(buttonTitle)", for: .normal)
        chosenTagButton.setImage(UIImage(named: "chosenTag-exit"), for: .normal)
        chosenTagButton.setTitleColor(color.black(), for: .normal)
        chosenTagButton.backgroundColor = color.green()
        chosenTagButton.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        chosenTagButton.layer.cornerRadius = 22
        chosenTagButton.clipsToBounds = true
        chosenTagButton.addTarget(self, action: #selector(self.didPressRemoveSelectedTag(_:)), for: .touchUpInside)
        self.chosenTagsScrollview.addSubview(chosenTagButton)
        
        xPositionForChosenTags = xPositionForChosenTags + Int(chosenTagButton.frame.width) + uiElement.leftOffset
        chosenTagsScrollview.contentSize = CGSize(width: xPositionForChosenTags, height: uiElement.buttonHeight)
        
        shouldHideBrewMyPlaylistButton(false)
    }
    
    //MARK: featured tags
    func addFeatureTagButton(_ featuredTags: Array<Tag>, cell: MainTableViewCell) {
        var xPositionForFeaturedTag = uiElement.leftOffset
        let tagColors = [color.primary(), color.uicolorFromHex(0xa9c5d0), color.uicolorFromHex(0xd0aba9), color.uicolorFromHex(0xd0a9cb), color.uicolorFromHex(0xd0bfa9), color.uicolorFromHex(0xaea9d0)]
        var colorI = 0
        cell.featureTagsScrollview.subviews.forEach({$0.removeFromSuperview()})
        
        for tag in featuredTags {
            if !tag.isSelected {
                let color = tagColors[colorI]
                
                let buttonTitleWidth = determineChosenTagButtonTitleWidth(tag.name)
                
                let featureTagButton = UIButton()
                
                var buttonImageWidth = 0
                if let buttonImageString = self.determineFeaturedTagImage(tag.name) {
                    buttonImageWidth = 25
                    featureTagButton.setImage(UIImage(named: buttonImageString), for: .normal)
                }
                
                featureTagButton.frame = CGRect(x: xPositionForFeaturedTag, y: 0, width: buttonImageWidth + buttonTitleWidth , height: 45)
                featureTagButton.setTitle(" \(tag.name!) ", for: .normal)
                featureTagButton.setTitleColor(self.color.black(), for: .normal)
                featureTagButton.backgroundColor = color
                /*if tag.isSelected {
                 //tagWasSelectedLook(featureTagButton)
                 
                 } else {
                 featureTagButton.backgroundColor = color
                 }*/
                featureTagButton.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 17)
                featureTagButton.layer.cornerRadius = 20
                featureTagButton.clipsToBounds = true
                featureTagButton.addTarget(self, action: #selector(self.didPressFeatureTag(_:)), for: .touchUpInside)
                
                cell.featureTagsScrollview.addSubview(featureTagButton)
                
                xPositionForFeaturedTag = xPositionForFeaturedTag + Int(featureTagButton.frame.width) + uiElement.leftOffset
                cell.featureTagsScrollview.contentSize = CGSize(width: xPositionForFeaturedTag, height: uiElement.buttonHeight)
                
                //rotating through colors, so go back to zero if colors reach end of index
                if !tagColors.indices.contains(colorI + 1) {
                    colorI = 0
                    
                } else {
                    colorI = colorI + 1
                }
            }
        }
    }
    
    @objc func didPressFeatureTag(_ sender: UIButton) {
        self.startAnimating()
        let tagName = sender.titleLabel!.text!.trimmingCharacters(in: .whitespaces)
        self.chosenTagsArray.append(tagName)
        self.addChosenTagButton(tagName)
        //tagWasSelectedLook(sender)
        
        for i in 0..<self.filteredTags.count {
            if tagName == self.filteredTags[i].name {
                self.filteredTags[i].isSelected = true
                self.tableView.reloadData()
                self.stopAnimating()
                break
            }
        }
    }
    
    /*func tagWasSelectedLook(_ button: UIButton) {
        if button.backgroundColor == .white {
            button.layer.borderColor = color.black().cgColor
            button.layer.borderWidth = 1
            button.setTitleColor(color.black(), for: .normal)
            button.backgroundColor = .white
            
        } else {
            
        }
    }*/
    
    func determineFeaturedTagImage(_ tag: String) -> String? {
        let tagLowercased = tag.lowercased()
        switch tagLowercased {
        case "happy":
            return "happy"
            
        case "sad":
            return "sad"
            
        case "angry":
            return "angry"
            
        case "netflix-and-chill":
            return "love"
            
        case "creative":
            return "idea"
            
        case "workout":
            return "workout"
            
        case "party":
            return "party"
            
        case "work":
            return "money"
            
        case "sleep":
            return "bed"
            
        case "gaming":
            return "game"
            
        case "high-energy":
            return "high-energy"
            
        case "chill":
            return "chill"
            
        default:
            return nil
        }
    }
    
    func determineChosenTagButtonTitleWidth(_ buttonTitle: String) -> Int {
        let uiFont = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)!
        let buttonTitleSize = (buttonTitle as NSString).size(withAttributes:[.font: uiFont])
        let buttonTitleWidth = Int(buttonTitleSize.width)
        let buttonImageWidth = 50
        let totalButtonWidth = buttonTitleWidth + buttonImageWidth
        return totalButtonWidth
    }
    
    //MARK: SearchBar
    lazy var searchBar: UITextField = {
        let searchBar = UITextField()
        searchBar.placeholder = "🔍 genre, mood, activity, city"
        searchBar.borderStyle = .roundedRect
        searchBar.clearButtonMode = .always
        return searchBar
    }()
    
    func setUpSearchBar() {
        searchBar.addTarget(self, action: #selector(searchBarDidChange(_:)), for: .editingChanged)
        self.view.addSubview(self.searchBar)
        searchBar.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(30)
            make.top.equalTo(self.view).offset(uiElement.topOffset + 10)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
    }
    
    @objc func searchBarDidChange(_ textField: UITextField) {
        let wordPredicate = NSPredicate(format: "self BEGINSWITH[c] %@", textField.text!)
        
        if textField.text!.count == 0 {
            self.filteredTags = self.tags
            
        } else {
            //filter users on MeArchive that are in current user's phone
            var filteredTags = [Tag]()
            filteredTags = self.tags.filter {wordPredicate.evaluate(with: $0.name)}
            
            filteredTags.sort(by: {$0.count > $1.count!})
            self.filteredTags = filteredTags
        }
        
        self.tableView.reloadData()
    }
    
    //mark: Data
    func loadTags() {
        self.tags.removeAll()
        let query = PFQuery(className: "Tag")
        query.addDescendingOrder("count")
        query.limit = 1000
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let tagName = object["tag"] as! String
                        let tagCount = object["count"] as! Int
                        
                        let newTag = Tag(objectId: object.objectId, name: tagName, count: tagCount, isSelected: false, tagType: nil)
                        
                        if let tagType = object["type"] as? String {
                            if !tagType.isEmpty {
                                newTag.tagType = tagType
                            }
                        }
                        
                        self.tags.append(newTag)
                        
                        /*if let tagType = object["type"] as? String {
                            switch tagType {
                            case "genre":
                                self.genreTags.append(tagName)
                                break
                                
                            case "mood":
                                self.moodTags.append(tagName)
                                break
                                
                            case "activity":
                                self.activityTags.append(tagName)
                                break
                                
                            case "city":
                                self.cityTags.append(tagName)
                                break
                                
                            case "artist":
                                self.artistTags.append(tagName)
                                
                            default:
                                let newTag = Tag(objectId: object.objectId, name: tagName, count: tagCount, isSelected: false, tagType: nil)
                                self.tags.append(newTag)
                                break
                            }
                            
                        } else {
                            let newTag = Tag(objectId: object.objectId, name: tagName, count: tagCount)
                            self.tags.append(newTag)
                        }*/
                    }
                }
                
                self.filteredTags = self.tags
                
                if self.tableView == nil {
                    self.setUpTagListView()
                    self.setUpTableView()
                    
                } else {
                    self.tableView.reloadData()
                }
                
                self.stopAnimating()
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    func backgroundColor() -> UIColor {
        //return color.tan()
        return .white
    }
}

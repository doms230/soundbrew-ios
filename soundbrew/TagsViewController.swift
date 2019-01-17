//
//  TagsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/25/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//  search Mark: view, tableView, tags, featureTags, searchbar, data
// UserDefaults.standard.set(self.chosenTagsArray, forKey: "tags")

import UIKit
import TagListView
import SnapKit
import Parse
import AVFoundation
import Alamofire

class TagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TagListViewDelegate {
    
    //MARK: views
    let uiElement = UIElement()
    let color = Color()
    
    var isChoosingTagsForSoundUpload = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpSearchBar()
        
        if isChoosingTagsForSoundUpload {
            loadTagType(nil)
            
        } else {
            loadTagType("mood")
            loadTagType("activity")
            loadTagType("city")
            loadTagType("genre")
            loadTagType("artist")
            loadTagType(nil)
        }
    }
    
    /*override func viewDidAppear(_ animated: Bool) {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            
        } catch let error {
            print("Unable to activate audio session:  \(error.localizedDescription)")
        }
    }*/
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //let viewController: PlayerViewController = segue.destination as! PlayerViewController
        //viewController.tags = self.chosenTagsArray
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
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if isChoosingTagsForSoundUpload {
            return 1
        }
        
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isChoosingTagsForSoundUpload {
            return 1
        }
        
        if section == 0 {
            return featureTagTitles.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: MainTableViewCell!
        
        if indexPath.section == 0 && !isChoosingTagsForSoundUpload {
            cell = self.tableView.dequeueReusableCell(withIdentifier: featureTagReuse) as? MainTableViewCell
            setUpFeatureTagCellView(cell, row: indexPath.row)
            
        } else {
            cell = self.tableView.dequeueReusableCell(withIdentifier: tagReuse) as? MainTableViewCell
            setUpTagListCellView(cell)
        }
        
        cell.backgroundColor = backgroundColor()
        cell.selectionStyle = .none
        
        return cell
    }
    
    //MARK: button actions
    @objc func didPressRemoveSelectedTag(_ sender: UIButton) {
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
        }
    }
    
    //MARK: tags
    var tags = [Tag]()
    var filteredTags = [Tag]()
    
    var tagView: TagListView!
    
    let featureTagTitles = ["mood", "activity", "genre", "city", "artist"]
    
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
    
    func setUpTagListCellView(_ cell: MainTableViewCell) {
        cell.tagLabel.delegate = self
        cell.tagLabel.removeAllTags()
        let otherTags: Array<String> = self.filteredTags.filter {$0.tagType == nil}.map {$0.name}
        cell.tagLabel.addTags(otherTags)
        self.tagView = cell.tagLabel
        if isChoosingTagsForSoundUpload {
            cell.tagLabel.tagBackgroundColor = color.primary()
            
        } else {
            cell.tagLabel.tagBackgroundColor = color.uicolorFromHex(0xd0bfa9)
        }
    }
    
    func setupChooseTagsView() {
        addChooseTagsLabel()
        
        self.view.addSubview(self.chosenTagsScrollview)
        chosenTagsScrollview.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.top.equalTo(self.view).offset(uiElement.topOffset)
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
        let buttonTitleWidth = uiElement.determineChosenTagButtonTitleWidth(buttonTitleWithX)
        
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
    }
    
    //MARK: featured tags
    func setUpFeatureTagCellView(_ cell: MainTableViewCell, row: Int) {
        var tagType: String?
        
        var color: UIColor!
        
        switch row {
        case 0:
            tagType = "mood"
            color = self.color.primary()
            break
            
        case 1:
            tagType = "activity"
            color = self.color.uicolorFromHex(0xa9c5d0)
            break
            
        case 2:
            tagType = "genre"
            color = self.color.uicolorFromHex(0xaea9d0)
            break
            
        case 3:
            tagType = "city"
            color = self.color.uicolorFromHex(0xd0a9cb)
            break
            
        case 4:
            tagType = "artist"
            color = self.color.uicolorFromHex(0xd0aba9)
            break
            
        default:
            break
        }
        
        if let tagType = tagType {
            let tags: Array<Tag> = self.filteredTags.filter {$0.tagType == tagType}
            addFeatureTagButton(tags, cell: cell, color: color)
        }
        
        cell.featureTagTitle.text = featureTagTitles[row]
    }
    
    func addFeatureTagButton(_ featuredTags: Array<Tag>, cell: MainTableViewCell, color: UIColor) {
        var xPositionForFeaturedTag = uiElement.leftOffset
        
        cell.featureTagsScrollview.subviews.forEach({$0.removeFromSuperview()})
        
        for tag in featuredTags {
            if !tag.isSelected {
                
                let buttonTitleWidth = uiElement.determineChosenTagButtonTitleWidth(tag.name)
                
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
                featureTagButton.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 17)
                featureTagButton.layer.cornerRadius = 20
                featureTagButton.clipsToBounds = true
                featureTagButton.addTarget(self, action: #selector(self.didPressFeatureTag(_:)), for: .touchUpInside)
                
                cell.featureTagsScrollview.addSubview(featureTagButton)
                
                xPositionForFeaturedTag = xPositionForFeaturedTag + Int(featureTagButton.frame.width) + uiElement.leftOffset
                cell.featureTagsScrollview.contentSize = CGSize(width: xPositionForFeaturedTag, height: uiElement.buttonHeight)
            }
        }
    }
    
    @objc func didPressFeatureTag(_ sender: UIButton) {
        let tagName = sender.titleLabel!.text!.trimmingCharacters(in: .whitespaces)
        self.chosenTagsArray.append(tagName)
        self.addChosenTagButton(tagName)
        
        for i in 0..<self.filteredTags.count {
            if tagName == self.filteredTags[i].name {
                self.filteredTags[i].isSelected = true
                self.tableView.reloadData()
                break
            }
        }
    }
    
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
            
        case "girlpower":
            return "female"
            
        default:
            return nil
        }
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
        searchBar.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
        let rightNavBarButton = UIBarButtonItem(customView: searchBar)
        self.navigationItem.rightBarButtonItem = rightNavBarButton
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
    func loadTagType(_ type: String?) {
        let query = PFQuery(className: "Tag")
        if let type = type {
            query.whereKey("type", equalTo: type)
            
        } else {
            query.whereKey("type", notContainedIn: featureTagTitles)
        }
        query.addDescendingOrder("count")
        query.limit = 50
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
                    }
                }
                
                self.filteredTags = self.tags
                
                if self.tableView == nil {
                    self.setupChooseTagsView()
                    self.setUpTableView()
                    
                } else {
                    self.tableView.reloadData()
                }
                
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

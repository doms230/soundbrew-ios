//
//  TagsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/25/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//  "cmd + f" -> Mark: view, tableView, tags, featureTags, searchbar, data, done button
//

import UIKit
import TagListView
import SnapKit
import Parse
import AVFoundation
import Alamofire

class TagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TagListViewDelegate, UISearchBarDelegate {
    
    let uiElement = UIElement()
    let color = Color()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        setUpDoneButton()
        
        if isChoosingTagsForSoundUpload {
            if let tagType = tagType {
                loadTagType(tagType)
                
            } else {
                loadTagType(nil)
            }
            
        } else {
            loadTagType("mood")
            loadTagType("activity")
            loadTagType("city")
            loadTagType("genre")
            loadTagType("artist")
            loadTagType(nil)
        }
    }
    
    //MARK: done Button
    lazy var doneButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 20)
        button.setTitleColor(color.blue(), for: .normal)
        button.setTitle("Done", for: .normal)
        return button
    }()
    
    func setUpDoneButton() {
        view.addSubview(doneButton)
        doneButton.addTarget(self, action: #selector(self.didPressDoneButton(_:)), for: .touchUpInside)
        doneButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        setUpSearchBar()
    }
    @objc func didPressDoneButton(_ sender: UIButton) {
        handleTagsForDismissal()
    }
    
    //MARK: SearchBar
    var searchIsActive = false
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search"
        searchBar.barTintColor = .white
        searchBar.backgroundImage = UIImage()
        let searchTextField = searchBar.value(forKey: "_searchField") as? UITextField
        searchTextField?.backgroundColor = color.lightGray()
        searchBar.delegate = self
        return searchBar
    }()
    
    func setUpSearchBar() {
        self.view.addSubview(searchBar)
        searchBar.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(doneButton)
            make.left.equalTo(self.view).offset(uiElement.elementOffset)
            make.right.equalTo(doneButton.snp.left).offset(-(uiElement.elementOffset))
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text!.count == 0 {
            searchIsActive = false
            self.filteredTags = self.tags
            self.tableView.reloadData()
            
        } else {
            searchIsActive = true
            searchTags(searchBar.text!, type: tagType)
        }
    }
    
    func searchTags(_ text: String, type: String?) {
        self.filteredTags.removeAll()
        let query = PFQuery(className: "Tag")
        query.whereKey("tag", hasPrefix: text.lowercased())
        if let type = type {
            query.whereKey("type", equalTo: type)
            
        } else {
            if self.isChoosingTagsForSoundUpload {
                query.whereKey("type", notContainedIn: featureTagTitles)
            }
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
                        
                        let newTag = Tag(objectId: object.objectId, name: tagName, count: tagCount, isSelected: false, type: nil, image: nil)
                        
                        if let tagType = object["type"] as? String {
                            if !tagType.isEmpty {
                                newTag.type = tagType
                            }
                        }
                        self.filteredTags.append(newTag)
                    }
                    self.tableView.reloadData()
                }
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
    
    /*@objc func searchBarDidChange(_ textField: UITextField) {
        if textField.text!.count == 0 {
            self.filteredTags = self.tags
            self.tableView.reloadData()
            
        } else {
            searchTags(textField.text!, type: tagType)
        }
    }*/
    
    //MARK: Tableview
    var tableView: UITableView!
    let tagReuse = "tagReuse"
    let featureTagReuse = "featureTagReuse"
    
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TagTableViewCell.self, forCellReuseIdentifier: tagReuse)
        tableView.register(TagTableViewCell.self, forCellReuseIdentifier: featureTagReuse)
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
        /*if searchIsActive || isChoosingTagsForSoundUpload {
            return 1
        }*/
        
        if isChoosingTagsForSoundUpload {
            return 1
        }
        
        if searchIsActive {
            return 1
        }
        
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        /*if section == 0 && !searchIsActive || section == 0 &&  !isChoosingTagsForSoundUpload  {
            return featureTagTitles.count
        }*/
        
        if section == 0 && !isChoosingTagsForSoundUpload && !searchIsActive  {
            return featureTagTitles.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: TagTableViewCell!
        
        if indexPath.section == 0 {
            if !searchIsActive && !isChoosingTagsForSoundUpload {
                cell = self.tableView.dequeueReusableCell(withIdentifier: featureTagReuse) as? TagTableViewCell
                setUpFeatureTagCellView(cell, row: indexPath.row)
                
            } else {
                cell = self.tableView.dequeueReusableCell(withIdentifier: tagReuse) as? TagTableViewCell
                setUpTagListCellView(cell)
            }
            
        } else {
            cell = self.tableView.dequeueReusableCell(withIdentifier: tagReuse) as? TagTableViewCell
            setUpTagListCellView(cell)
        }
        
        /*if indexPath.section == 0 && !searchIsActive ||
            indexPath.section == 0 && !isChoosingTagsForSoundUpload {
            cell = self.tableView.dequeueReusableCell(withIdentifier: featureTagReuse) as? TagTableViewCell
            setUpFeatureTagCellView(cell, row: indexPath.row)
            
        } else {
            cell = self.tableView.dequeueReusableCell(withIdentifier: tagReuse) as? TagTableViewCell
            setUpTagListCellView(cell)
        }*/
        
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
        
        if chosenTags.count != 0 {
            //remove tag from chosen Tags
            for i in 0..<chosenTags.count {
                if chosenTags[i].name == title  {
                    self.chosenTags.remove(at: i)
                    break
                }
            }
            
            //reset scrollview
            self.chosenTagsScrollview.subviews.forEach({ $0.removeFromSuperview() })
            xPositionForChosenTags = UIElement().leftOffset
            
            //add back chosen tags to chosen tag scrollview
            for title in chosenTags {
                self.addChosenTagButton(title.name)
            }
            
            //show tags label if no more chosen tags
            if chosenTags.count == 0 {
                addChooseTagsLabel()
            }
        }
    }
    
    //MARK: tags
    var tagDelegate: TagDelegate?
    let moreTags = "moreTags"
    
    var isChoosingTagsForSoundUpload = false
    var tagType: String?
    
    var tags = [Tag]()
    var filteredTags = [Tag]()
    
    var tagView: TagListView!
    
    let featureTagTitles = ["mood", "activity", "genre", "city"]
    
    var genreTags = [String]()
    var moodTags = [String]()
    var activityTags = [String]()
    var cityTags = [String]()
    var artistTags = [String]()
    
    var chosenTags = [Tag]()
    var xPositionForChosenTags = UIElement().leftOffset
    
    lazy var chooseTagsLabel: UILabel = {
        let label = UILabel()
        label.text = "Select Tags"
        label.textColor = color.black()
        label.textAlignment = .center
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 25)
        return label
    }()
    
    lazy var chosenTagsScrollview: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    func setUpTagListCellView(_ cell: TagTableViewCell) {
        cell.tagLabel.delegate = self
        cell.tagLabel.removeAllTags()
        
        var tags: Array<String>!
        if isChoosingTagsForSoundUpload {
            var filterTags: Array<String> = self.filteredTags.map{$0.name}
            //if tag doesn't exist yet, add tag with search results so user can choose tag if they want.
            if searchIsActive {
                let searchText = searchBar.text!.lowercased()
                if !filterTags.contains(searchText) && searchText != "" {
                    filterTags.insert(searchText, at: 0)
                }
            }
            tags = filterTags
            
        } else if searchIsActive {
            tags = self.filteredTags.map {$0.name}
            
        } else {
            tags = self.filteredTags.filter {$0.type == nil}.map {$0.name}
        }
        cell.tagLabel.addTags(tags)
        
        self.tagView = cell.tagLabel
        
        if isChoosingTagsForSoundUpload {
            cell.tagLabel.tagBackgroundColor = color.primary()
            
        } else {
            cell.tagLabel.tagBackgroundColor = color.uicolorFromHex(0xd0bfa9)
        }
    }
    
    func setupChooseTagsView() {
        if self.chosenTags.count != 0 {
            for tag in chosenTags {
                addChosenTagButton(tag.name)
            }
            
        } else {
           addChooseTagsLabel()
        }
        
        self.view.addSubview(self.chosenTagsScrollview)
        chosenTagsScrollview.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.top.equalTo(self.searchBar.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
        }
        
        self.setUpTableView()
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
        if isChoosingTagsForSoundUpload && tagType != nil {
            appendTag(title)
            handleTagsForDismissal()
            
        } else if !tagView.isSelected {
            sender.removeTag(title)
            self.addChosenTagButton(title)
            appendTag(title)
        }
    }
    
    func appendTag(_ title: String) {
        var positionToRemoveTag: Int?
        for i in 0..<self.filteredTags.count {
            if self.filteredTags[i].name == title {
                positionToRemoveTag = i
                self.chosenTags.append(self.filteredTags[i])
            }
        }
        
        if let p = positionToRemoveTag {
            self.filteredTags.remove(at: p)
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
    
    func handleTagsForDismissal() {
        print("handle Tags for dismisall called")
        if let tagDelegate = self.tagDelegate {
            var chosenTags: Array<Tag>?
            if self.chosenTags.count != 0 {
                chosenTags = self.chosenTags
            }
            tagDelegate.changeTags(chosenTags)
            //print("tagsViewController: \(String(describing: chosenTags?.count))")
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: featured tags
    func setUpFeatureTagCellView(_ cell: TagTableViewCell, row: Int) {
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
            let tags: Array<Tag> = self.filteredTags.filter {$0.type == tagType}
            addFeatureTagButton(tags, cell: cell, color: color)
        }
        
        cell.featureTagTitle.text = featureTagTitles[row]
    }
    
    func addFeatureTagButton(_ featuredTags: Array<Tag>, cell: TagTableViewCell, color: UIColor) {
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
        self.addChosenTagButton(tagName)
        
        for i in 0..<self.filteredTags.count {
            if tagName == self.filteredTags[i].name {
                self.filteredTags[i].isSelected = true
                self.chosenTags.append(self.filteredTags[i])
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
                        
                        let newTag = Tag(objectId: object.objectId, name: tagName, count: tagCount, isSelected: false, type: nil, image: nil)
                        
                        if let tagType = object["type"] as? String {
                            if !tagType.isEmpty {
                                newTag.type = tagType
                            }
                        }
                        
                        if self.chosenTags.count != 0 {
                            let chosenTagObjectIds = self.chosenTags.map {$0.objectId}
                            if !chosenTagObjectIds.contains(newTag.objectId) {
                                self.tags.append(newTag)
                            }
                            
                        } else {
                            self.tags.append(newTag)
                        }
                    }
                }
                
                self.filteredTags = self.tags
                
                if self.tableView == nil {
                    self.setUpSearchBar()
                    //self.setUpSoundOrderSegment()
                    self.setupChooseTagsView()
                    
                } else {
                    self.tableView.reloadData()
                }
                
            } else {
                print("Error: \(error!)")
                self.uiElement.showAlert("Oops", message: "\(error!)", target: self)
            }
        }
    }
    
    func backgroundColor() -> UIColor {
        return .white
    }
}

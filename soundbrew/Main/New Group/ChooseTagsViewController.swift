//
//  TagsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/25/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//  "cmd + f" -> Mark: tableView, tags, searchbar, done button
//

import UIKit
import SnapKit
import Parse

class ChooseTagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    let uiElement = UIElement()
    let color = Color()
    var selectedArtist: Artist!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationBar()
        loadTags(tagType, selectedFeatureType: selectedFeatureTagTypeIndex, searchText: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveDynamicLink), name: NSNotification.Name(rawValue: "setDynamicLink"), object: nil)
        checkForProfileDynamicLink()
    }
    
    @objc func didReceiveDynamicLink() {
        let player = Player.sharedInstance
        for tag in player.sounds[0].tags {
            let newTagObject = Tag(objectId: nil, name: tag, count: 0, isSelected: false, type: nil, image: nil)
            self.chosenTags.append(newTagObject)
        }

        handleTagsForDismissal()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if chosenTags.count != 0 && self.tableView != nil {
            resetScrollviewAndAddChosenTagsBack()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPlaylist" {
            let backItem = UIBarButtonItem()
            backItem.title = "Your Playlist"
            navigationItem.backBarButtonItem = backItem
            
            let topviewController = segue.destination as! PlaylistViewController
            topviewController.selectedTagsForFiltering = self.chosenTags
        }
    }
    
    //MARK: done Button
    @objc func didPressChooseTagsDoneButton(_ sender: UIBarButtonItem) {
        handleTagsForDismissal()
    }
    
    //MARK: Profile
    @objc func didPressProfileButton(_ sender: UIBarButtonItem) {
        if PFUser.current() == nil {
            self.uiElement.signupRequired("Welcome To Soundbrew!", message: "Sign up or Sign in to view your profile and upload music to Soundbrew.", target: self)
            
        } else {
            self.performSegue(withIdentifier: "showProfile", sender: self)
        }
    }
    
    //MARK: SearchBar
    var searchIsActive = false
    
    lazy var searchBar: UISearchBar = {
        var minusWidth: CGFloat =  10
        var searchBarX: CGFloat = 0
        if self.tagType == nil {
            minusWidth = 150
            searchBarX = 50
            
        } else if self.tagType == "more" {
            minusWidth = 100
        }
        let searchBar = UISearchBar(frame: CGRect(x: searchBarX, y: 0, width: self.view.frame.width - minusWidth, height: 10))
        let searchTextField = searchBar.value(forKey: "searchField") as? UITextField
        searchBar.placeholder = "Search Tags"
        searchTextField?.backgroundColor = color.lightGray()
        searchBar.delegate = self
        return searchBar
    }()
    
    func setUpNavigationBar() {        
        if let tagType = self.tagType {
            searchBar.placeholder = "Search \(tagType.capitalized) Tags"
        } else {
            searchBar.placeholder = "Search \(featureTagTitles[selectedFeatureTagTypeIndex].capitalized) Tags"
        }
        
        let searchBarItem = UIBarButtonItem(customView: searchBar)
        if tagType == nil {
            let profileButton = UIBarButtonItem(image: UIImage(named: "profile_nav"), style: .plain, target: self, action: #selector(self.didPressProfileButton(_:)))
            self.navigationItem.leftBarButtonItems = [profileButton, searchBarItem]
            
        } else {
            self.navigationItem.leftBarButtonItem = searchBarItem
        }
        
        if tagType == nil {
            let doneButton = UIBarButtonItem(image: UIImage(named: "create"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.didPressChooseTagsDoneButton(_:)))
            self.navigationItem.rightBarButtonItem = doneButton
            
        } else if tagType == "more" {
            let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.didPressChooseTagsDoneButton(_:)))
            self.navigationItem.rightBarButtonItem = doneButton
            
        } else {
            searchBar.setShowsCancelButton(true, animated: true)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text!.isEmpty {
            searchIsActive = false
            loadTags(tagType, selectedFeatureType: selectedFeatureTagTypeIndex, searchText: nil)
            
        } else {
            searchIsActive = true
            loadTags(tagType, selectedFeatureType: selectedFeatureTagTypeIndex, searchText: searchText)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func checkIfTagSearchTextExists() {
        if searchIsActive {
            let tagNames = self.tags.map {$0.name}
            let chosenTagNames = self.chosenTags.map {$0.name!}
            let searchText = self.searchBar.text!.lowercased()
            if !tagNames.contains(searchText) && !chosenTagNames.contains(searchText)
                && !searchText.isEmpty {
                
                let cleanTag = cleanupText(searchText)
                let tag = Tag(objectId: nil, name: cleanTag, count: 0, isSelected: false, type: self.tagType, image: nil)
                self.filteredTags.append(tag)
            }
        }
    }
    
    func cleanupText(_ tag: String) -> String {
        var cleanTag = tag
        
        let textWithWhiteSpaceTrimmed = cleanTag.trimmingCharacters(
            in: NSCharacterSet.whitespacesAndNewlines
        )
        cleanTag = textWithWhiteSpaceTrimmed
        
        if cleanTag.hasPrefix("#") {
            cleanTag.removeFirst()
        }
        
        return cleanTag.lowercased()
    }
    
    //MARK: Tableview
    var tableView: UITableView!
    let searchTagViewReuse = "searchTagViewReuse"
    let tagsReuse = "tagsReuse"
    
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: tagsReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchTagViewReuse)
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
        if tagType == nil {
            return 2
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tagType == nil && section == 0 {
            return 1
        }
        return filteredTags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tagType == nil && indexPath.section == 0 {
            return featureTagCell(indexPath)
        }
        
        return filteredTags[indexPath.row].cell(tableView, reuse: searchTagViewReuse)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tagType != nil && indexPath.section == 1 {
            didSelectRowAt(indexPath.row)
            
        } else {
            didSelectRowAt(indexPath.row)
        }
    }
    
    func didSelectRowAt(_ row: Int) {
        let selectedTag = filteredTags[row]
        appendTag(selectedTag)
    }
    
    //MARK: tags
    var tagDelegate: TagDelegate?
    let moreTags = "moreTags"
    
    //if tagtype is nil, means user is creating playlist
    var tagType: String?
    
    var tags = [Tag]()
    var filteredTags = [Tag]()
    var featureTagTitles = ["genre", "mood", "activity", "artist", "city", "all"]
    var featureTagScrollview: UIScrollView!
    var xPositionForFeatureTags = UIElement().leftOffset
    var selectedFeatureTagTypeIndex = 0
    
    func checkForProfileDynamicLink() {
        if let _ = self.uiElement.getUserDefault("receivedUserId") as? String {
            self.performSegue(withIdentifier: "showProfile", sender: self)
        }
    }
    
    func featureTagCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: tagsReuse) as! SoundListTableViewCell
        cell.selectionStyle = .none
        
        if featureTagScrollview == nil {
            xPositionForFeatureTags = uiElement.leftOffset
            
            featureTagScrollview = cell.tagsScrollview
            for i in 0..<featureTagTitles.count {
                addSelectedTags(featureTagScrollview, name: featureTagTitles[i], index: i)
            }
        }

        return cell
    }
    
    func addSelectedTags(_ scrollview: UIScrollView, name: String, index: Int) {
        //not using snpakit to set button frame becuase not able to get button width from button title.
        let buttonTitleWidth = uiElement.determineChosenTagButtonTitleWidth(name)
        
        var titleColor = color.black()
        var backgroundColor = color.darkGray()
        if index == 0 {
            backgroundColor = color.blue()
            titleColor = .white
            
        } else {
            titleColor = color.black()
            backgroundColor = color.darkGray()
        }
        
        let buttonHeight = 30
        
        let tagButton = UIButton()
        tagButton.frame = CGRect(x: xPositionForFeatureTags, y: uiElement.elementOffset, width: buttonTitleWidth, height: buttonHeight)
        tagButton.setTitle( name.capitalized, for: .normal)
        tagButton.setTitleColor(titleColor, for: .normal)
        tagButton.backgroundColor = backgroundColor
        tagButton.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        tagButton.layer.cornerRadius = 3
        tagButton.tag = index
        tagButton.addTarget(self, action: #selector(self.didPressFeatureTagButton(_:)), for: .touchUpInside)
        scrollview.addSubview(tagButton)
        
        xPositionForFeatureTags = xPositionForFeatureTags + Int(tagButton.frame.width) + uiElement.leftOffset
        scrollview.contentSize = CGSize(width: xPositionForFeatureTags, height: buttonHeight)
    }
    
    @objc func didPressFeatureTagButton(_ sender: UIButton) {
        if sender.tag != selectedFeatureTagTypeIndex {
            let currentSelectedButton = featureTagScrollview.subviews[selectedFeatureTagTypeIndex] as! UIButton
            currentSelectedButton.backgroundColor = color.darkGray()
            currentSelectedButton.setTitleColor(color.black(), for: .normal)
            
            let newSelectedButton = featureTagScrollview.subviews[sender.tag] as! UIButton
            newSelectedButton.backgroundColor = color.blue()
            newSelectedButton.setTitleColor(.white, for: .normal)
            
            selectedFeatureTagTypeIndex = sender.tag
            self.searchBar.placeholder = "Search \(featureTagTitles[selectedFeatureTagTypeIndex].capitalized) Tags"
            self.searchBar.text = ""
            self.searchBar.resignFirstResponder()
            
            if sender.tag == 6 {
                self.filteredTags = self.tags
                
            } else {
                self.filteredTags.removeAll()
                loadTags(tagType, selectedFeatureType: selectedFeatureTagTypeIndex, searchText: searchBar.text)
            }
        }
    }
    
    var chosenTags = [Tag]()
    var xPositionForChosenTags = UIElement().leftOffset
    
    lazy var chooseTagsLabel: UILabel = {
        let label = UILabel()
        label.text = "Select Tags For Your Playlist"
        label.textColor = color.black()
        label.textAlignment = .center
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        return label
    }()
    
    lazy var chosenTagsScrollview: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    func setupChooseTagsView() {
        if self.chosenTags.count != 0 && tagType == "more" {
            for i in 0..<chosenTags.count {
                addChosenTagButton(self.chosenTags[i].name, tag: i)
            }
            
        } else {
           addChooseTagsLabel()
        }
        
        self.view.addSubview(self.chosenTagsScrollview)
        chosenTagsScrollview.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(40)
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
        }
        
        self.setUpTableView()
    }
    
    func addChooseTagsLabel() {
        if let type = tagType {
            self.chooseTagsLabel.text = "Select \(type.capitalized) Tag"
        }
        self.chosenTagsScrollview.addSubview(chooseTagsLabel)
        chooseTagsLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.chosenTagsScrollview)
            make.left.equalTo(self.chosenTagsScrollview).offset(uiElement.leftOffset)
            make.right.equalTo(self.chosenTagsScrollview).offset(uiElement.rightOffset)
            make.bottom.equalTo(self.chosenTagsScrollview)
        }
    }
    
    func appendTag(_ tag: Tag) {
        var positionToRemoveTag: Int?
        for i in 0..<self.filteredTags.count {
            if self.filteredTags[i].objectId == tag.objectId {
                positionToRemoveTag = i
                self.chosenTags.append(self.filteredTags[i])
                let index = self.chosenTags.count - 1
                self.addChosenTagButton(tag.name, tag: index)
            }
        }
        
        if let p = positionToRemoveTag {
            self.filteredTags.remove(at: p)
            
        } else {
            //means that user is using new tag that hasn't been created yet.
            let tag = Tag(objectId: nil, name: title, count: 0, isSelected: false, type: tagType, image: nil)
            self.chosenTags.append(tag)
        }
        
        if tagType == nil || tagType == "more" {
            self.tableView.reloadData()
            
        } else {
            handleTagsForDismissal()
        }
    }
    
    func addChosenTagButton(_ buttonTitle: String, tag: Int) {
        self.chooseTagsLabel.removeFromSuperview()
        
        let name = "X | \(buttonTitle)"
        //not using snpakit to set button frame becuase not able to get button width from button title.
        let buttonTitleWidth = uiElement.determineChosenTagButtonTitleWidth(name)
        let buttonHeight = 30
        
        let chosenTagButton = UIButton()
        chosenTagButton.frame = CGRect(x: xPositionForChosenTags, y: 0, width: buttonTitleWidth, height: buttonHeight)
        chosenTagButton.setTitle(name, for: .normal)
        chosenTagButton.setTitleColor(.white, for: .normal)
        chosenTagButton.backgroundColor = color.blue()
        chosenTagButton.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        chosenTagButton.layer.cornerRadius = 3
        chosenTagButton.clipsToBounds = true
        chosenTagButton.tag = tag
        chosenTagButton.addTarget(self, action: #selector(self.didPressRemoveSelectedTag(_:)), for: .touchUpInside)
        self.chosenTagsScrollview.addSubview(chosenTagButton)
        
        xPositionForChosenTags = xPositionForChosenTags + Int(chosenTagButton.frame.width) + uiElement.leftOffset
        chosenTagsScrollview.contentSize = CGSize(width: xPositionForChosenTags, height: buttonHeight)
    }
    
    func handleTagsForDismissal() {
        if let tagDelegate = self.tagDelegate {
            var chosenTags: Array<Tag>?
            if self.chosenTags.count != 0 {
                chosenTags = self.chosenTags
            }
            tagDelegate.receivedTags(chosenTags)
        }
        
        if tagType == nil {
            self.performSegue(withIdentifier: "showPlaylist", sender: self)
            
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
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
        if chosenTags.count != 0 {
            self.chosenTags.remove(at: sender.tag)
            resetScrollviewAndAddChosenTagsBack()
        }
    }
    
    func resetScrollviewAndAddChosenTagsBack() {
        //reset scrollview
        self.chosenTagsScrollview.subviews.forEach({ $0.removeFromSuperview() })
        xPositionForChosenTags = UIElement().leftOffset
        
        //add back chosen tags to chosen tag scrollview
        for i in 0..<chosenTags.count {
            self.addChosenTagButton(chosenTags[i].name, tag: i)
        }
        
        //show tags label if no more chosen tags
        if chosenTags.count == 0 {
            addChooseTagsLabel()
        }
    }
    
    func loadTags(_ type: String?, selectedFeatureType: Int, searchText: String?) {
        let query = PFQuery(className: "Tag")
        
        if let text = searchText {
            self.filteredTags.removeAll()
            query.whereKey("tag", matchesRegex: text.lowercased())
        }
        
        if let type = type {
            if type == "more" {
                query.whereKey("type", notContainedIn: self.featureTagTitles)
            } else {
                query.whereKey("type", equalTo: type)
            }
            
        } else if selectedFeatureType != 5 {
            query.whereKey("type", equalTo: featureTagTitles[selectedFeatureType])
        }
        
        query.addDescendingOrder("count")
        query.limit = 50
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    var loadedTags = [Tag]()
                    for object in objects {
                        let tagName = object["tag"] as! String
                        let tagCount = object["count"] as! Int
                        
                        let newTag = Tag(objectId: object.objectId, name: tagName, count: tagCount, isSelected: false, type: nil, image: nil)
                        
                        if let image = object["image"] as? PFFileObject {
                            newTag.image = image.url
                        }
                        
                        if let tagType = object["type"] as? String {
                            if !tagType.isEmpty {
                                newTag.type = tagType
                            }
                        }
                        
                        if self.chosenTags.count != 0 {
                            let chosenTagObjectIds = self.chosenTags.map {$0.objectId}
                            if !chosenTagObjectIds.contains(newTag.objectId) {
                                loadedTags.append(newTag)
                            }
                            
                        } else {
                            loadedTags.append(newTag)
                        }
                    }
                    
                    if searchText == nil {
                        self.tags = loadedTags
                        self.filteredTags = self.tags
                        
                    } else {
                        self.filteredTags = loadedTags
                    }
                }
                
                if self.tagType != nil && searchText != nil {
                    self.checkIfTagSearchTextExists()
                }
                
                if self.tableView == nil {
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
}

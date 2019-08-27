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
        self.view.backgroundColor = color.black()
        setUpNavigationBar()
        loadTags(tagType, searchText: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        navigationItem.backBarButtonItem = backItem
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSounds" {
            let backItem = UIBarButtonItem()
            backItem.title = self.chosenTags[0].name
            navigationItem.backBarButtonItem = backItem
            
            let viewController = segue.destination as! SoundsViewController
            viewController.selectedTagsForFiltering = self.chosenTags
            viewController.soundType = "discover"
        }
    }
    
    //MARK: done Button
    @objc func didPressChooseTagsDoneButton(_ sender: UIBarButtonItem) {
        handleTagsForDismissal()
    }
    
    //MARK: SearchBar
    var searchIsActive = false
    
    lazy var searchBar: UISearchBar = {
        var minusWidth: CGFloat =  10
        var searchBarX: CGFloat = 0
        if self.tagType == "more" || self.isSelectingTagsForPlaylist {
            minusWidth = 100
        }
        let searchBar = UISearchBar(frame: CGRect(x: searchBarX, y: 0, width: self.view.frame.width - minusWidth, height: 10))
        let searchTextField = searchBar.value(forKey: "searchField") as? UITextField
        searchBar.placeholder = "Search Tags"
        searchTextField?.backgroundColor = color.black()
        searchBar.delegate = self
        
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        return searchBar
    }()
    
    func setUpNavigationBar() {        
        if let tagType = self.tagType {
            searchBar.placeholder = "Search \(tagType.capitalized) Tags"
        }
        
        let searchBarItem = UIBarButtonItem(customView: searchBar)
        
        if isSelectingTagsForPlaylist {
            self.navigationItem.rightBarButtonItem = searchBarItem
            
        } else if tagType == "more" {
            let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.didPressChooseTagsDoneButton(_:)))
            self.navigationItem.rightBarButtonItem = doneButton
            self.navigationItem.leftBarButtonItem = searchBarItem
            
        } else {
            searchBar.setShowsCancelButton(true, animated: true)
            self.navigationItem.leftBarButtonItem = searchBarItem
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text!.isEmpty {
            searchIsActive = false
            loadTags(tagType, searchText: nil)
            
        } else {
            searchIsActive = true
            loadTags(tagType, searchText: searchText)
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
        tableView.backgroundColor = color.black()
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
        return filteredTags[indexPath.row].cell(tableView, reuse: searchTagViewReuse)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRowAt(indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func didSelectRowAt(_ row: Int) {
        let selectedTag = filteredTags[row]
        appendTag(selectedTag)
    }
    
    //MARK: tags
    var isSelectingTagsForPlaylist = false
    
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
    
    var chosenTags = [Tag]()
    var xPositionForChosenTags = UIElement().leftOffset
    
    lazy var chooseTagsLabel: UILabel = {
        let label = UILabel()
        label.text = "Select Tags"
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        return label
    }()
    
    lazy var chosenTagsScrollview: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = color.black()
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
            if type == "all" {
                self.chooseTagsLabel.text = "Select Tag"
            } else {
                self.chooseTagsLabel.text = "Select \(type.capitalized) Tag"
            }
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
                if !self.isSelectingTagsForPlaylist {
                    let index = self.chosenTags.count - 1
                    self.addChosenTagButton(tag.name, tag: index)
                }
            }
        }
        
        if let p = positionToRemoveTag {
            self.filteredTags.remove(at: p)
            
        } else {
            //means that user is using new tag that hasn't been created yet.
            let tag = Tag(objectId: nil, name: title, count: 0, isSelected: false, type: tagType, image: nil)
            self.chosenTags.append(tag)
        }
        
        if isSelectingTagsForPlaylist || tagType != "more" {
            handleTagsForDismissal()
            
        } else {
            self.tableView.reloadData()
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
        if self.isSelectingTagsForPlaylist {
            self.performSegue(withIdentifier: "showSounds", sender: self)
            
        } else if let tagDelegate = self.tagDelegate {
            var chosenTags: Array<Tag>?
            if self.chosenTags.count != 0 {
                chosenTags = self.chosenTags
            }
            tagDelegate.receivedTags(chosenTags)
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
    
    func loadTags(_ type: String?, searchText: String?) {
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
                
                if self.tagType != nil && searchText != nil && !self.isSelectingTagsForPlaylist {
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

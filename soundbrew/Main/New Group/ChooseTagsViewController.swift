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
    var sound: Sound?
    var isViewTagsFromSound = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barTintColor = color.black()
        setUpNavigationBar()
        loadTags(tagType, searchText: nil, tags: sound?.tags)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let localizedBack = NSLocalizedString("back", comment: "")
        let backItem = UIBarButtonItem()
        backItem.title = localizedBack
        navigationItem.backBarButtonItem = backItem
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSounds" {
            let backItem = UIBarButtonItem()
            backItem.title = self.selectedTag.name
            navigationItem.backBarButtonItem = backItem
            
            let viewController = segue.destination as! SoundsViewController
            viewController.selectedTagForFiltering = self.selectedTag
            viewController.soundType = "discover"
        }
    }
    
    //MARK: done Button
    @objc func didPressChooseTagsDoneButton(_ sender: UIBarButtonItem) {
        handleTagsForDismissal(true)
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
        let localizedSearchTags = NSLocalizedString("searchTags", comment: "")

        searchBar.placeholder = localizedSearchTags
        searchBar.delegate = self
        if #available(iOS 13.0, *) {
            let searchTextField = searchBar.searchTextField
            searchTextField.backgroundColor = color.black()
            searchTextField.textColor = .white
        } else {
            let searchTextField = searchBar.value(forKey: "_searchField") as! UITextField
            searchTextField.backgroundColor = color.black()
            searchTextField.textColor = .white
        }
       
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        return searchBar
    }()
    
    func setUpNavigationBar() {        
        if let tagType = self.tagType {
            searchBar.placeholder = "\(tagType.capitalized) Tags"
        }
        
        let searchBarItem = UIBarButtonItem(customView: searchBar)
        
        if isSelectingTagsForPlaylist {
            self.navigationItem.rightBarButtonItem = searchBarItem
            
        } else if tagType == "more" {
            let localizedDone = NSLocalizedString("done", comment: "")
            let doneButton = UIBarButtonItem(title: localizedDone, style: .plain, target: self, action: #selector(self.didPressChooseTagsDoneButton(_:)))
            self.navigationItem.rightBarButtonItem = doneButton
            self.navigationItem.leftBarButtonItem = searchBarItem
            
        } else {
            searchBar.setShowsCancelButton(true, animated: true)
            self.navigationItem.leftBarButtonItem = searchBarItem
        }
    }
    
    lazy var exitButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "dismiss"), for: .normal)
        button.addTarget(self, action: #selector(self.didPressExitButton(_:)), for: .touchUpInside)
        return button
    }()
    @objc func didPressExitButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    lazy var appTitle: UILabel = {
        let label = UILabel()
        label.text = "Tags"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 15)
        label.textAlignment = .center
        return label
    }()
    
    func setupTopView() {
        self.view.addSubview(exitButton)
        exitButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(25)
            make.top.equalTo(self.view).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        self.view.addSubview(appTitle)
        appTitle.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(exitButton)
        }
        
        self.setUpTableView()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text!.isEmpty {
            searchIsActive = false
            loadTags(tagType, searchText: nil, tags: sound?.tags)
            
        } else {
            searchIsActive = true
            loadTags(tagType, searchText: searchText, tags: sound?.tags)
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
                let tag = Tag(objectId: nil, name: cleanTag, count: 0, isSelected: false, type: self.tagType, imageURL: nil, uiImage: nil)
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
        if isViewTagsFromSound {
            tableView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.exitButton.snp.bottom)
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
                make.bottom.equalTo(self.view)
            }
        } else if tagType == "more" {
            tableView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.chosenTagsScrollview.snp.bottom)
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
                make.bottom.equalTo(self.view)
            }
            
        } else {
            tableView.frame = self.view.bounds
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
        if filteredTags.indices.contains(indexPath.row) {
            return filteredTags[indexPath.row].cell(tableView, reuse: searchTagViewReuse)
        }
        return fillerCell(tableView, reuse: searchTagViewReuse)
    }
    
    func fillerCell(_ tableView: UITableView, reuse: String) -> UITableViewCell {
        //issue where cellForRowAt is crashing... putting in filler until figured out exactly what's happening.
         let cell = tableView.dequeueReusableCell(withIdentifier: reuse) as! ProfileTableViewCell
         cell.selectionStyle = .gray
         cell.backgroundColor = Color().black()
         cell.profileImage.image = UIImage(named: "hashtag")
         cell.displayNameLabel.text = ""
         return cell
     }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if filteredTags.indices.contains(indexPath.row) {
            didSelectRowAt(indexPath.row)
        }
    }
    
    func didSelectRowAt(_ row: Int) {
        let selectedTag = filteredTags[row]
        if self.sound != nil {
            self.chosenTags.append(selectedTag)
            handleTagsForDismissal(false)
        } else if isSelectingTagsForPlaylist {
            self.selectedTag = selectedTag
            self.performSegue(withIdentifier: "showSounds", sender: self)
        } else {
            appendTag(selectedTag)
        }
    }
    
    //MARK: tags
    var isSelectingTagsForPlaylist = false
    
    var tagDelegate: TagDelegate?
    let moreTags = "moreTags"
    
    //if tagtype is nil, means user is creating playlist
    var tagType: String?
    var selectedTag: Tag!

    var tags = [Tag]()
    var filteredTags = [Tag]()
    var featureTagTitles = ["genre", "mood", "activity", "artist", "city", "all"]
    var featureTagScrollview: UIScrollView!
    var xPositionForFeatureTags = UIElement().leftOffset
    var selectedFeatureTagTypeIndex = 0
    
    var chosenTags = [Tag]()
    var xPositionForChosenTags = UIElement().leftOffset
    
    lazy var chooseTagsLabel: UILabel = {
        let localizedSelectTags = NSLocalizedString("selectTags", comment: "")
        let label = UILabel()
        label.text = localizedSelectTags
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
            
        } /*else {
           addChooseTagsLabel()
        }*/
        
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
        let localizedSelectTag = NSLocalizedString("selectTag", comment: "")
        let localizedSelect = NSLocalizedString("select", comment: "")
        let localizedTag = NSLocalizedString("tag", comment: "")
        if let type = tagType {
            if type == "all" {
                self.chooseTagsLabel.text = localizedSelectTag
            } else {
                self.chooseTagsLabel.text = "\(localizedSelect) \(type.capitalized) \(localizedTag)"
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
            let tag = Tag(objectId: nil, name: title, count: 0, isSelected: false, type: tagType, imageURL: nil, uiImage: nil)
            self.chosenTags.append(tag)
        }
        
        if tagType != "more" {
            handleTagsForDismissal(true)
        } else {
            self.searchBar.text = ""
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
    
    func handleTagsForDismissal(_ shouldAnimateDismissal: Bool) {
        if let tagDelegate = self.tagDelegate {
            var chosenTags: Array<Tag>?
            if self.chosenTags.count != 0 {
                chosenTags = self.chosenTags
            }
            self.dismiss(animated: shouldAnimateDismissal, completion: {() in
                tagDelegate.receivedTags(chosenTags)
            })
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
    
    func loadTags(_ type: String?, searchText: String?, tags: Array<String>?) {
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
        
        if let tags = tags {
            query.whereKey("tag", containedIn: tags)
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
                        
                        let newTag = Tag(objectId: object.objectId, name: tagName, count: tagCount, isSelected: false, type: nil, imageURL: nil, uiImage: nil)
                        
                        if let image = object["image"] as? PFFileObject {
                            newTag.imageURL = image.url
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
                    if self.isViewTagsFromSound {
                        self.setupTopView()
                    } else {
                        self.setupChooseTagsView()
                    }
                    
                } else {
                    self.tableView.reloadData()
                }
                
            } else {
                print("Error: \(error!)")
                let localizedOops = NSLocalizedString("oops", comment: "")
                self.uiElement.showAlert(localizedOops, message: "\(error!)", target: self)
            }
        }
    }
}

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if tagType == nil {
            setUpSearchBar()
            
        } else {
            setUpDoneButton()
        }
        
        loadTags(tagType, selectedFeatureType: selectedFeatureType, searchText: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPlaylist" {
            let viewController = segue.destination as! PlaylistViewController
            viewController.selectedTagsForFiltering = self.chosenTags
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
    
    @objc func didPressNaviDoneButton(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "showPlaylist", sender: self)
    }
    
    //MARK: SearchBar
    var searchIsActive = false
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Create or Search Tags"
        searchBar.barTintColor = .white
        searchBar.backgroundImage = UIImage()
        let searchTextField = searchBar.value(forKey: "_searchField") as? UITextField
        searchTextField?.backgroundColor = color.lightGray()
        searchBar.delegate = self
        return searchBar
    }()
    
    func setUpSearchBar() {
        if tagType == nil {
            searchBar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width - 100, height: 10)
            searchBar.placeholder = "Search Tags"
            let leftNavBarButton = UIBarButtonItem(customView: searchBar)
            self.navigationItem.leftBarButtonItem = leftNavBarButton
            
            let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(didPressNaviDoneButton(_:)))
            self.navigationItem.rightBarButtonItem = doneButton
            
        } else {
            searchBar.placeholder = "Search or Create Tags"
            self.view.addSubview(searchBar)
            searchBar.snp.makeConstraints { (make) -> Void in
                make.centerY.equalTo(doneButton)
                make.left.equalTo(self.view).offset(uiElement.elementOffset)
                make.right.equalTo(doneButton.snp.left).offset(-(uiElement.elementOffset))
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text!.count == 0 {
            searchIsActive = false
            self.filteredTags = self.tags
            self.selectedFeatureType = 0
            self.tableView.reloadData()
            
        } else {
            searchIsActive = true
            loadTags(tagType, selectedFeatureType: selectedFeatureType, searchText: searchText)
        }
    }
    
    func checkIfTagSearchTextExists() {
        if searchIsActive {
            let tagNames = self.tags.map {$0.name}
            let chosenTagNames = self.chosenTags.map {$0.name!}
            let searchText = self.searchBar.text!.lowercased()
            if !tagNames.contains(searchText) && !chosenTagNames.contains(searchText)
                && !searchText.isEmpty {
                let tag = Tag(objectId: nil, name: searchText, count: 0, isSelected: false, type: self.tagType, image: nil)
                self.filteredTags.append(tag)
            }
        }
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
        
        if tagType != nil && tagType != "more" {
            appendTag(selectedTag)
            handleTagsForDismissal()
            
        } else {
            appendTag(selectedTag)
        }
    }
    
    //MARK: tags
    var tagDelegate: TagDelegate?
    let moreTags = "moreTags"
    
    //if tagtype is nil, means user is creating playlist
    var tagType: String?
    
    var tags = [Tag]()
    var filteredTags = [Tag]()
    var featureTagTitles = ["all tags", "mood", "similar artist", "activity", "city", "genre"]
    
    var xPositionForFeatureTags = UIElement().leftOffset
    var selectedFeatureType = 0
    
    func featureTagCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: tagsReuse) as! SoundListTableViewCell
        cell.selectionStyle = .none
        xPositionForFeatureTags = uiElement.leftOffset
        
        for i in 0..<featureTagTitles.count {
            addSelectedTags(cell.tagsScrollview, name: featureTagTitles[i], index: i)
        }
        
        return cell
    }
    
    func addSelectedTags(_ scrollview: UIScrollView, name: String, index: Int) {
        //not using snpakit to set button frame becuase not able to get button width from button title.
        let buttonTitleWidth = uiElement.determineChosenTagButtonTitleWidth(name)
        
        var titleColor = color.black()
        var backgroundColor = color.darkGray()
        if selectedFeatureType == index {
            titleColor = .white
            backgroundColor = color.blue()
        }
        
        let tagButton = UIButton()
        tagButton.frame = CGRect(x: xPositionForFeatureTags, y: uiElement.elementOffset, width: buttonTitleWidth, height: 30)
        tagButton.setTitle( name.capitalized, for: .normal)
        tagButton.setTitleColor(titleColor, for: .normal)
        tagButton.backgroundColor = backgroundColor
        tagButton.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 17)
        tagButton.layer.cornerRadius = 3
        tagButton.tag = index
        tagButton.addTarget(self, action: #selector(self.didPressFeatureTagButton(_:)), for: .touchUpInside)
        scrollview.addSubview(tagButton)
        
        xPositionForFeatureTags = xPositionForFeatureTags + Int(tagButton.frame.width) + uiElement.leftOffset
        scrollview.contentSize = CGSize(width: xPositionForFeatureTags, height: 30)
    }
    
    @objc func didPressFeatureTagButton(_ sender: UIButton) {
        if sender.tag != selectedFeatureType {
            selectedFeatureType = sender.tag
            if sender.tag == 0 {
                self.filteredTags = self.tags
                
            } else {
                self.filteredTags.removeAll()
                loadTags(tagType, selectedFeatureType: selectedFeatureType, searchText: searchBar.text)
            }
            
            self.tableView.reloadData()
        }
    }
    
    var chosenTags = [Tag]()
    var xPositionForChosenTags = UIElement().leftOffset
    
    lazy var chooseTagsLabel: UILabel = {
        let label = UILabel()
        label.text = "Select Tags for Playlist"
        label.textColor = color.black()
        label.textAlignment = .center
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 25)
        return label
    }()
    
    lazy var chosenTagsScrollview: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    func setupChooseTagsView() {
        if self.chosenTags.count != 0 && tagType == nil {
            for i in 0..<chosenTags.count {
                addChosenTagButton(self.chosenTags[i].name, tag: i)
            }
            
        } else {
           addChooseTagsLabel()
        }
        
        self.view.addSubview(self.chosenTagsScrollview)
        chosenTagsScrollview.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(40)
            make.top.equalTo(self.searchBar.snp.bottom).offset(uiElement.topOffset)
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
        
        self.tableView.reloadData()
    }
    
    func addChosenTagButton(_ buttonTitle: String, tag: Int) {
        self.chooseTagsLabel.removeFromSuperview()
        
        let name = "X | \(buttonTitle)"
        //not using snpakit to set button frame becuase not able to get button width from button title.
        let buttonTitleWidth = uiElement.determineChosenTagButtonTitleWidth(name)
        let buttonHeight = 40
        
        let chosenTagButton = UIButton()
        chosenTagButton.frame = CGRect(x: xPositionForChosenTags, y: 0, width: buttonTitleWidth, height: buttonHeight)
        chosenTagButton.setTitle(name, for: .normal)
        chosenTagButton.setTitleColor(.white, for: .normal)
        chosenTagButton.setBackgroundImage(UIImage(named: "background"), for: .normal)
        chosenTagButton.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 20)
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
            tagDelegate.changeTags(chosenTags)
        }
        
        self.dismiss(animated: true, completion: nil)
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
    }
    
    func loadTags(_ type: String?, selectedFeatureType: Int, searchText: String?) {
        let query = PFQuery(className: "Tag")
        
        if let text = searchText {
            self.filteredTags.removeAll()
            query.whereKey("tag", matchesRegex: text.lowercased())
        }
        
        if let type = type {
            if type == "more" {
                query.whereKey("type", notContainedIn: featureTagTitles)
                
            } else {
                query.whereKey("type", equalTo: type)
            }
        }
        
        if selectedFeatureType != 0 {
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
                        
                    } else {
                        self.filteredTags = loadedTags
                    }
                }
                
                if searchText == nil {
                    self.filteredTags = self.tags
                    
                } else if self.tagType != nil {
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

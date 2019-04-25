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
import AVFoundation
import Alamofire

class ChooseTagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    let uiElement = UIElement()
    let color = Color()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        setUpDoneButton()
        loadTags(tagType, searchText: nil)
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
            loadTags(tagType, searchText: searchText)
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
    
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchTagViewReuse)
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return filteredTags[indexPath.row].cell(tableView, reuse: searchTagViewReuse)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTag = filteredTags[indexPath.row]
        
        if tagType != nil {
            appendTag(selectedTag)
            handleTagsForDismissal()
            
        } else {
            self.addChosenTagButton(selectedTag.name)
            appendTag(selectedTag)
        }
    }
    
    //MARK: tags
    var tagDelegate: TagDelegate?
    let moreTags = "moreTags"
    
    var tagType: String?
    
    var tags = [Tag]()
    var filteredTags = [Tag]()
    let featureTagTitles = ["mood", "activity", "city", "genre", "similar artist"]
    
    var chosenTags = [Tag]()
    var xPositionForChosenTags = UIElement().leftOffset
    
    lazy var chooseTagsLabel: UILabel = {
        let label = UILabel()
        label.text = "Select More Tags"
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
    
    func loadTags(_ type: String?, searchText: String?) {
        let query = PFQuery(className: "Tag")
        
        if let text = searchText {
            self.filteredTags.removeAll()
            query.whereKey("tag", matchesRegex: text.lowercased())
        }
        
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
                    
                } else {
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
    
    func backgroundColor() -> UIColor {
        return .white
    }
}

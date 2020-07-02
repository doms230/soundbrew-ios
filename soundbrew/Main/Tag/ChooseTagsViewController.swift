//
//  ChooseTagsV2ViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/29/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import SnapKit
import FlagKit

class ChooseTagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    let uiElement = UIElement()
    let color = Color()
    
    var tagType: String!
    var filteredTags = [Tag]()
    var tags = [Tag]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barTintColor = color.black()
        
        switch tagType {
            case "sound":
                let topView = addTopView("Done")
                setupChooseTagsView(topView.2)
                break
            
            case "country":
                let topView = self.uiElement.addSubViewControllerTopView(self, action: #selector(self.didPressUIElementTopViewButton(_:)), doneButtonTitle: "Cancel", title: "Choose Your Country")
                self.setUpTableView(topView.2)
                break
                
            case "city":
                let topView = addTopView("Cancel")
                self.setUpTableView(topView.2)
                break
            
            default:
                break
        }
    }
    
    func addTopView(_ doneButtonTitle: String) -> (UISearchBar, UIButton, UIView) {
        let doneButton = UIButton()
        doneButton.setTitle(doneButtonTitle, for: .normal)
        doneButton.addTarget(self, action: #selector(self.didPressDoneButton(_:)), for: .touchUpInside)
        doneButton.isOpaque = true
        doneButton.tag = 1
        self.view.addSubview(doneButton)
        doneButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(self.uiElement.topOffset)
            make.right.equalTo(self.view).offset(self.uiElement.rightOffset)
        }
        
        searchBar = UISearchBar()
        searchBar.placeholder = "Search \(tagType.capitalized)"
        searchBar.delegate = self
        searchBar.backgroundColor = .clear
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
        
        self.view.addSubview(searchBar)
        searchBar.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(doneButton)
            make.left.equalTo(self.view).offset(self.uiElement.leftOffset)
            make.right.equalTo(doneButton.snp.left).offset(self.uiElement.rightOffset)
        }
        searchBar.becomeFirstResponder()
        
        let dividerLine = UIView()
        dividerLine.layer.borderWidth = 1
        dividerLine.layer.borderColor = UIColor.darkGray.cgColor
        self.view.addSubview(dividerLine)
        dividerLine.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(0.5)
            make.top.equalTo(doneButton.snp.bottom).offset(self.uiElement.topOffset)
            make.left.equalTo(self.view).offset(self.uiElement.leftOffset)
            make.right.equalTo(self.view).offset(self.uiElement.rightOffset)
        }
        
        //return view so that the next view can set constraints
        return (searchBar, doneButton, dividerLine)
    }
    
    @objc func didPressDoneButton(_ sender: UIButton) {
        if tagType == "sound" {
            handleTagsForDismissal()
        } else {
             self.dismiss(animated: true, completion: nil)
        }
    }
    
    func handleTagsForDismissal() {
        if let tagDelegate = self.tagDelegate {
            var chosenTags: Array<Tag>?
            if self.chosenTagsForSound.count != 0 {
                chosenTags = self.chosenTagsForSound
            }
            self.dismiss(animated: true, completion: {() in
                tagDelegate.receivedTags(chosenTags)
            })
        }
    }
    
    @objc func didPressUIElementTopViewButton(_ sender: UIButton) {
        if sender.tag == 0 {
            
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    //MARK: Tableview
    var tableView: UITableView!
    let searchTagViewReuse = "searchTagViewReuse"
    let newPlaylistReuse = "newCreditReuse"
    func setUpTableView(_ topView: UIView) {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: newPlaylistReuse)
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: searchTagViewReuse)
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        tableView.backgroundColor = color.black()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(topView.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tagType == "sound" || tagType == "city" {
            return filteredTags.count
        } else if tagType == "country" {
            return availableCountries.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tagType == "sound" || tagType == "city" {
            return filteredTags[indexPath.row].cell(tableView, reuse: searchTagViewReuse)
        } else {
            return countryCell(tableView, row: indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch tagType {
            case "sound", "city":
                if filteredTags.indices.contains(indexPath.row) {
                    didSelectSoundTagAt(indexPath.row)
                }
                break
            
            case "country":
                let tag = Tag(objectId: self.availableCountryCodes[indexPath.row], name: self.availableCountries[indexPath.row], count: 0, isSelected: false, type: "country", imageURL: nil, uiImage: nil)
                self.chosenTagsForSound.append(tag)
                self.handleTagsForDismissal()
                break
            
            default:
                if filteredTags.indices.contains(indexPath.row) {
                    didSelectSoundTagAt(indexPath.row)
                }
                break
        }
    }
    
    func didSelectSoundTagAt(_ row: Int) {
        if chosenTagsForSound.count == 10 {
            self.uiElement.showAlert("Max Reached", message: "Up to 10 additional tags allowed.", target: self)
        } else {
           appendTagToChosenSoundTags(filteredTags[row])
        }
    }
    
    //MARK: Search
    var searchBar: UISearchBar!
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        loadTags(searchText)
    }
    
    //MARK: country
    let availableCountries = ["United States", "Canada", "United Kingdom", "Australia", "Austria", "Belgium", "Bulgaria", "Cyprus", "Czech Republic", "Denmark", "Estonia", "Finland", "France", "Germany", "Greece", "Hong Kong", "India", "Ireland", "Italy", "Japan", "Latvia", "Lithuania", "Luxembourg", "Malta", "Mexico", "Netherlands", "New Zealand", "Norway", "Poland", "Portugal", "Romania", "Singapore", "Slovakia", "Slovenia", "Spain", "Sweden", "Switzerland"]
    let availableCountryCodes = ["US", "CA", "GB", "AU", "AT", "BE", "BG", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HK", "IN", "IE", "IT", "JP", "LV", "LT", "LU", "MT", "MX", "NL", "NZ", "NO", "PL", "PT",  "RO", "SG", "SK", "SI", "ES", "SE", "CH"]
    
    
    func countryCell(_ tableView: UITableView, row: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: searchTagViewReuse) as! ProfileTableViewCell
        cell.selectionStyle = .gray
        cell.backgroundColor = Color().black()
        let country = availableCountries[row]
        let countryCode = availableCountryCodes[row]
        cell.profileImage.backgroundColor = .white
        if let flagImage = Flag(countryCode: countryCode)?.image(style: .circle) {
            cell.profileImage.image = flagImage
            cell.profileImage.contentMode = .scaleAspectFill
        } else {
            cell.profileImage.image = nil
            
        }
        cell.displayNameLabel.text = country
        
        return cell
    }
    
    //MARK: Sound
    var tagDelegate: TagDelegate?
    var chosenTagsForSound = [Tag]()
    var xPositionForChosenTags = UIElement().leftOffset
    lazy var chosenTagsScrollview: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = color.black()
        return scrollView
    }()
    
    func setupChooseTagsView(_ topView: UIView) {
        if self.chosenTagsForSound.count != 0 {
            for i in 0..<chosenTagsForSound.count {
                addChosenTagButton(self.chosenTagsForSound[i].name, tag: i)
            }
        }
        
        self.view.addSubview(self.chosenTagsScrollview)
        chosenTagsScrollview.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(40)
            make.top.equalTo(topView.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
        }
        
        self.setUpTableView(chosenTagsScrollview)
    }
    
    func addChosenTagButton(_ buttonTitle: String, tag: Int) {
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
    
    @objc func didPressRemoveSelectedTag(_ sender: UIButton) {
        removeChosenTag(sender)
        setFilteredTagIsSelectedAsFalse(sender)
    }
    
    func removeChosenTag(_ sender: UIButton) {
        if chosenTagsForSound.count != 0 {
            self.chosenTagsForSound.remove(at: sender.tag)
            resetScrollviewAndAddChosenTagsBack()
        }
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
    
    func resetScrollviewAndAddChosenTagsBack() {
        //reset scrollview
        self.chosenTagsScrollview.subviews.forEach({ $0.removeFromSuperview() })
        xPositionForChosenTags = UIElement().leftOffset
        
        //add back chosen tags to chosen tag scrollview
        for i in 0..<chosenTagsForSound.count {
            self.addChosenTagButton(chosenTagsForSound[i].name, tag: i)
        }
    }
    
    func loadTags(_ searchText: String?) {
        let query = PFQuery(className: "Tag")
        
        if let text = searchText {
            self.filteredTags.removeAll()
            query.whereKey("tag", matchesRegex: text.lowercased())
        }
        
        if self.tagType == "city" {
            query.whereKey("type", equalTo: "city")
        } else {
            query.whereKey("type", notEqualTo: "city")
        }
        
        query.whereKey("type", notEqualTo: "artist")
        query.addDescendingOrder("count")
        query.limit = 50
        query.cachePolicy = .networkElseCache
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
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
                    
                    if self.chosenTagsForSound.count != 0 {
                        let chosenTagObjectIds = self.chosenTagsForSound.map {$0.objectId}
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
            
            if searchText != nil {
                self.checkIfTagSearchTextExists()
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func checkIfTagSearchTextExists() {
        let tagNames = self.tags.map {$0.name}
        let chosenTagNames = self.chosenTagsForSound.map {$0.name!}
        let searchText = self.searchBar.text!.lowercased()
        if !tagNames.contains(searchText) && !chosenTagNames.contains(searchText)
            && !searchText.isEmpty {
            
            let cleanTag = cleanupText(searchText)
            let tag = Tag(objectId: nil, name: cleanTag, count: 0, isSelected: false, type: self.tagType, imageURL: nil, uiImage: nil)
            self.filteredTags.append(tag)
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
    
    func appendTagToChosenSoundTags(_ tag: Tag) {
        var positionToRemoveTag: Int?
        for i in 0..<self.filteredTags.count {
            if self.filteredTags[i].objectId == tag.objectId {
                positionToRemoveTag = i
                self.chosenTagsForSound.append(self.filteredTags[i])
                let index = self.chosenTagsForSound.count - 1
                self.addChosenTagButton(tag.name, tag: index)
            }
        }
        
        if let p = positionToRemoveTag {
            self.filteredTags.remove(at: p)
            
        } else {
            //means that user is using new tag that hasn't been created yet.
            let tag = Tag(objectId: nil, name: title, count: 0, isSelected: false, type: tagType, imageURL: nil, uiImage: nil)
            self.chosenTagsForSound.append(tag)
        }
        
        if self.tagType == "city" {
            self.handleTagsForDismissal()
        } else {
            self.searchBar.text = ""
            self.tableView.reloadData()
        }
    }
    
}

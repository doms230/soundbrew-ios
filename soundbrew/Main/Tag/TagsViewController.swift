//
//  TagsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 8/7/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import SnapKit
import Kingfisher

class TagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let color = Color()
    let uiElement = UIElement()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for featureTagType in featureTagTypes {
            loadTags(featureTagType)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSounds" {
            let topviewController = segue.destination as! PlaylistViewController
            topviewController.selectedTagsForFiltering.append(self.selectedTag)
        }
    }

    //mark: tableview
    var tableView: UITableView!
    let reuse = "reuse"
    func setUpTableView() {
        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TagTableViewCell.self, forCellReuseIdentifier: reuse)
        self.tableView.separatorStyle = .none
        self.tableView.frame = view.bounds
        self.view.addSubview(self.tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return featureTagTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return featureTagCell(indexPath)
    }
    
    //tags
    var featureTagTypes = ["genre", "mood", "activity", "city", "all"]
    var topGenreTags = [Tag]()
    var topMoodTags = [Tag]()
    var topActivityTags = [Tag]()
    var topCityTags = [Tag]()
    var topAllTags = [Tag]()
    var featureTagScrollview: UIScrollView!
    var selectedTag: Tag!
    
    func featureTagCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! TagTableViewCell
        cell.selectionStyle = .none
        cell.TagTypeTitle.text = featureTagTypes[indexPath.row].capitalized
        
        switch indexPath.row {
        case 0:
            //genre
            addTags(cell.tagsScrollview, tags: topGenreTags, row: 0)
            break
            
        case 1:
            //mood
            addTags(cell.tagsScrollview, tags: topMoodTags, row: 1)
            break
            
        case 2:
            //activity
            addTags(cell.tagsScrollview, tags: topActivityTags, row: 2)
            break
            
        case 3:
            //"city"
            addTags(cell.tagsScrollview, tags: topCityTags, row: 3)
            break
            
        default:
            //all
            addTags(cell.tagsScrollview, tags: topAllTags, row: 4)
            break
        }
        
        return cell
    }
    
    func addTags(_ scrollview: UIScrollView, tags: Array<Tag>, row: Int) {
        //not using snpakit to set button frame becuase not able to get button width from button title.
        let buttonHeight = 130
        let buttonWidth = 200
        var xPositionForFeatureTags = UIElement().leftOffset
        
        for tag in tags {
            let tagButton = UIButton()
            if let tagImage = tag.image {
                tagButton.kf.setBackgroundImage(with: URL(string: tagImage), for: .normal)
             } else {
             tagButton.setBackgroundImage(UIImage(named: "hashtag"), for: .normal)
             }
            tagButton.layer.cornerRadius = 5
            tagButton.clipsToBounds = true
            tagButton.tag = row
            tagButton.setTitle(tag.name, for: .normal)
            tagButton.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 20)
            tagButton.setTitleColor(.white, for: .normal)
            tagButton.contentHorizontalAlignment = .left
            tagButton.contentVerticalAlignment = .bottom
            tagButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: CGFloat(uiElement.leftOffset), bottom: CGFloat(uiElement.topOffset), right: 0)
            tagButton.addTarget(self, action: #selector(self.didPressTagButton(_:)), for: .touchUpInside)
            scrollview.addSubview(tagButton)
            tagButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(buttonHeight)
                make.width.equalTo(buttonWidth)
                make.top.equalTo(scrollview)
                make.left.equalTo(scrollview).offset(xPositionForFeatureTags)
                make.bottom.equalTo(scrollview)
            }
           // self.loadTagImage(tag.name, tagButton: tagButton)
            
            /*let tagTitleView = UIView()
            tagTitleView.backgroundColor = UIColor(white: 1, alpha: 0.5)
            tagButton.addSubview(tagTitleView)
            tagTitleView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(tagButton)
                make.left.equalTo(tagButton)
                make.right.equalTo(tagButton)
                //make.bottom.equalTo(tagButton)
            }
            
            let tagTitle = UILabel()
            tagTitle.text = tag.name
            tagTitle.textColor = .white
            tagTitleView.addSubview(tagTitle)
            tagTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(tagTitleView).offset(uiElement.elementOffset)
                make.left.equalTo(tagTitleView).offset(uiElement.elementOffset)
                make.right.equalTo(tagTitleView).offset(-(uiElement.elementOffset))
                //make.bottom.equalTo(tagTitleView).offset(-(uiElement.elementOffset))
            }*/
            
            xPositionForFeatureTags = xPositionForFeatureTags + buttonWidth + uiElement.leftOffset
            scrollview.contentSize = CGSize(width: xPositionForFeatureTags, height: buttonHeight)
        }
    }
    
    func loadTagImage(_ tag: String, tagButton: UIButton) {
        let query = PFQuery(className: "Post")
        query.whereKey("tags", contains: tag)
        query.whereKey("isRemoved", equalTo: false)
        query.addDescendingOrder("plays")
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if object != nil && error == nil {
                if let image = object?["songArt"] as? PFFileObject {
                    tagButton.kf.setBackgroundImage(with: URL(string: image.url!), for: .normal)
                }
            }
        }
    }
    
    @objc func didPressTagButton(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            determineSelectedTag(selectedTagTitle: sender.titleLabel!.text!, tags: topGenreTags)
            break
            
        case 1:
            determineSelectedTag(selectedTagTitle: sender.titleLabel!.text!, tags: topMoodTags)
            break
            
        case 2:
            determineSelectedTag(selectedTagTitle: sender.titleLabel!.text!, tags: topActivityTags)
            break
            
        case 3:
            determineSelectedTag(selectedTagTitle: sender.titleLabel!.text!, tags: topCityTags)
            break
            
        default:
            determineSelectedTag(selectedTagTitle: sender.titleLabel!.text!, tags: topAllTags)
            break
        }
    }
    
    func determineSelectedTag(selectedTagTitle: String, tags: Array<Tag>) {
        for tag in tags {
            if selectedTagTitle == tag.name {
                self.selectedTag = tag
                self.performSegue(withIdentifier: "showSounds", sender: self)
            }
        }
    }
    
    func loadTags(_ type: String) {
        let query = PFQuery(className: "Tag")
        if type != "all" {
            query.whereKey("type", equalTo: type)
        }
        query.addDescendingOrder("count")
        query.limit = 5
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
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
                        
                        switch type {
                        case "genre":
                            self.topGenreTags.append(newTag)
                            break
                            
                        case "mood":
                            self.topMoodTags.append(newTag)
                            break
                            
                        case "activity":
                            self.topActivityTags.append(newTag)
                            break
                            
                        case "city":
                            self.topCityTags.append(newTag)
                            break
                            
                        default:
                            self.topAllTags.append(newTag)
                            break
                        }
                    }
                }
                
                if self.tableView == nil {
                    self.setUpTableView()
                    
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

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

    //mark: tableview
    var tableView: UITableView!
    let reuse = "reuse"
    func setUpTableView() {
        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TagTableViewCell.self, forCellReuseIdentifier: reuse)
        tableView.backgroundColor = color.lightGray()
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
    
    func featureTagCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: reuse) as! TagTableViewCell
        cell.selectionStyle = .none
        cell.TagTypeTitle.text = featureTagTypes[indexPath.row]
        
        switch indexPath.row {
        case 0:
            //genre
            addTags(cell.tagsScrollview, tags: topGenreTags)
            break
            
        case 1:
            //mood
            addTags(cell.tagsScrollview, tags: topMoodTags)
            break
            
        case 2:
            //activity
            addTags(cell.tagsScrollview, tags: topActivityTags)
            break
            
        case 3:
            //"city"
            addTags(cell.tagsScrollview, tags: topCityTags)
            break
            
        default:
            //all
            addTags(cell.tagsScrollview, tags: topAllTags)
            break
        }
        
        return cell
    }
    
    func addTags(_ scrollview: UIScrollView, tags: Array<Tag>) {
        //not using snpakit to set button frame becuase not able to get button width from button title.
        let buttonHeight = 50
        let buttonWidth = 100
        var xPositionForFeatureTags = UIElement().leftOffset
        
        for i in 0..<tags.count {
            let tag = tags[i]
            
            let tagButton = UIButton()
            if let tagImage = tag.image {
                tagButton.kf.setImage(with: URL(string: tagImage), for: .normal)
            } else {
                tagButton.setImage(UIImage(named: "hashtag"), for: .normal)
            }
            tagButton.layer.cornerRadius = 3
            tagButton.tag = i
            tagButton.addTarget(self, action: #selector(self.didPressTagButton(_:)), for: .touchUpInside)
            scrollview.addSubview(tagButton)
            tagButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(buttonHeight)
                make.width.equalTo(buttonWidth)
                make.top.equalTo(scrollview)
                make.left.equalTo(scrollview).offset(xPositionForFeatureTags)
                make.bottom.equalTo(scrollview)
            }
            
            let tagTitle = UILabel()
            tagTitle.text = tag.name
            tagButton.addSubview(tagTitle)
            tagTitle.snp.makeConstraints { (make) -> Void in
                make.left.equalTo(tagButton)
                make.right.equalTo(tagButton)
                make.bottom.equalTo(tagButton)
            }
            
            xPositionForFeatureTags = xPositionForFeatureTags + buttonWidth + uiElement.leftOffset
            scrollview.contentSize = CGSize(width: xPositionForFeatureTags, height: buttonHeight)
        }
    }
    
    @objc func didPressTagButton(_ sender: UIButton) {

    }
    
    func loadTags(_ type: String) {
        let query = PFQuery(className: "Tag")
        if type != "all" {
            query.whereKey("type", equalTo: type)
        }
        query.addDescendingOrder("count")
        query.limit = 10
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

//
//  NewSoundTagsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/4/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit

class NewSoundTagsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TagDelegate {
    
    let color = Color()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpDoneButton()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController: ChooseTagsViewController = segue.destination as! ChooseTagsViewController
        viewController.tagDelegate = self
        
        if let tagType = tagType {
            viewController.tagType = tagType
            
        } else if let tags = tagsToUpdateInChooseTagsViewController {
            //only want to populate chosen tags if user is choosing more tags
            viewController.chosenTags = tags
        }
    }
    
    //
    //MARK: done Button
    let uiElement = UIElement()
    lazy var doneButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont(name: "\(UIElement().mainFont)-bold", size: 20)
        button.setTitleColor(color.blue(), for: .normal)
        button.setTitle("Done", for: .normal)
        return button
    }()
    
    func setUpDoneButton() {
        self.view.addSubview(doneButton)
        doneButton.addTarget(self, action: #selector(self.didPressDoneButton(_:)), for: .touchUpInside)
        doneButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        setUpTableView()
    }
    @objc func didPressDoneButton(_ sender: UIButton) {
        handleTagsForDismissal()
    }
    
    //MARK: Tableview
    var tableView: UITableView!
    let soundTagReuse = "soundTagReuse"
    
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: soundTagReuse)
        tableView.backgroundColor = .white
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .singleLine
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.doneButton.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: SoundInfoTableViewCell!
        
        cell = self.tableView.dequeueReusableCell(withIdentifier: soundTagReuse) as? SoundInfoTableViewCell
        
        switch indexPath.row {
        case 0:
            cell.soundTagLabel.text = "Genre Tag"
            if let genreTag = self.genreTag {
                cell.chosenSoundTagLabel.text = genreTag.name
                cell.chosenSoundTagLabel.textColor = color.blue()
            }
            tableView.separatorStyle = .singleLine
            break
            
        case 1:
            cell.soundTagLabel.text = "Mood Tag"
            if let moodTag = self.moodTag {
                cell.chosenSoundTagLabel.text = moodTag.name
                cell.chosenSoundTagLabel.textColor = color.blue()
            }
            tableView.separatorStyle = .singleLine
            break
            
        case 2:
            cell.soundTagLabel.text = "Activity Tag"
            if let activityTag = self.activityTag {
                cell.chosenSoundTagLabel.text = activityTag.name
                cell.chosenSoundTagLabel.textColor = color.blue()
            }
            tableView.separatorStyle = .singleLine
            
        case 3:
            cell.soundTagLabel.text = "Similar Artist"
            if let similarArtistTag = self.similarArtistTag {
                cell.chosenSoundTagLabel.text = similarArtistTag.name
                cell.chosenSoundTagLabel.textColor = color.blue()
            }
            
        case 4:
            cell.soundTagLabel.text = "More Tags"
            if let moreTags = self.moreTags {
                if moreTags.count == 1 {
                    cell.chosenSoundTagLabel.text = "\(moreTags.count) tag"
                    
                } else {
                    cell.chosenSoundTagLabel.text = "\(moreTags.count) tags"
                }
                
                cell.chosenSoundTagLabel.textColor = color.blue()
                
            } else {
                cell.chosenSoundTagLabel.text = "Add"
                cell.chosenSoundTagLabel.textColor = color.red()
            }
            tableView.separatorStyle = .none
            
        default:
            break
        }
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            self.tagType = "genre"
            break
            
        case 1:
            self.tagType = "mood"
            break
            
        case 2:
            self.tagType = "activity"
            break
            
        case 3:
            self.tagType = "similar artist"
            break
            
        case 4:
            self.tagType = "more"
            self.tagsToUpdateInChooseTagsViewController = moreTags
            break
            
        default:
            break
        }
        
        self.performSegue(withIdentifier: showChooseTags, sender: self)
    }
    
    //MARK: tags
    var tagDelegate: TagDelegate?
    var showChooseTags = "showChooseTags"
    var tagType: String?
    var genreTag: Tag?
    var moodTag: Tag?
    var activityTag: Tag?
    var moreTags: Array<Tag>?
    var cityTag: Tag?
    var similarArtistTag: Tag?
    var tagsToUpdateInChooseTagsViewController: Array<Tag>?
    
    func receivedTags(_ chosenTags: Array<Tag>?) {
        if let tagType = self.tagType {
            if let tag = chosenTags {
                switch tagType {
                case "city":
                    self.cityTag = tag[0]
                    break
                    
                case "genre":
                    self.genreTag = tag[0]
                    break
                    
                case "mood":
                    self.moodTag = tag[0]
                    break
                    
                case "activity":
                    self.activityTag = tag[0]
                    break
                    
                case "similar artist":
                    self.similarArtistTag = tag[0]
                    break
                    
                default:
                    self.moreTags = tag
                    break
                }
            }
        }
        
        self.tableView.reloadData()
    }
    
    func handleTagsForDismissal() {
        print("handle tags for dismissal")
        if let tagDelegate = self.tagDelegate {
            print("cha")
            var chosenTags: Array<Tag>?
            chosenTags = self.moreTags
            if let cityTag = self.cityTag {
                chosenTags?.append(cityTag)
            }
            if let genreTag = self.genreTag {
                chosenTags?.append(genreTag)
            }
            if let moodTag = self.moodTag {
                chosenTags?.append(moodTag)
            }
            if let activityTag = self.activityTag {
                chosenTags?.append(activityTag)
            }
            if let similarArtistTag = self.similarArtistTag {
                chosenTags?.append(similarArtistTag)
            }
            
            tagDelegate.receivedTags(chosenTags)
        }
        
        self.dismiss(animated: true, completion: nil)
    }

}

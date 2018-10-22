//
//  TagsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/25/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//search Mark: view, tableView, taglist, searchbar, data

import UIKit
import TagListView
import SnapKit
import Parse
import AVFoundation

class TagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, TagListViewDelegate {
    
    //MARK: views
    let uiElement = UIElement()
    let color = Color()
    
    var tags = [Tag]()
    var filteredTags = [Tag]()
    
    var tagView: TagListView!
    
    var brewMyPlaylistButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadTags()
        setUpViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            
        } catch let error {
            print("Unable to activate audio session:  \(error.localizedDescription)")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController: PlayerViewController = segue.destination as! PlayerViewController
        viewController.tags = self.chosenTagsArray
    }
    
    func setUpViews() {
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: color.black()]
        
        brewMyPlaylistButton = UIBarButtonItem(title: "Brew My Playlist", style: .plain, target: self, action: #selector(self.didPressNextButton(_:)))
        brewMyPlaylistButton.isEnabled = false
        
        self.navigationItem.rightBarButtonItem = brewMyPlaylistButton
    }
    
    //MARK: Tableview
    var tableView: UITableView!
    let tagReuse = "tagReuse"
    
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MainTableViewCell.self, forCellReuseIdentifier: tagReuse)
        tableView.backgroundColor = color.black()
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        //tableView.frame = view.bounds
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.chosenTagsScrollview.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
     func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: tagReuse) as! MainTableViewCell
        cell.backgroundColor = color.black()
        
        cell.selectionStyle = .none
        
        cell.tagLabel.delegate = self
        cell.tagLabel.removeAllTags()
        cell.tagLabel.addTags(filteredTags.map({$0.name}))
        self.tagView = cell.tagLabel
        
        return cell
    }
    
    //MARK: button actions
    @objc func didPressNextButton(_ sender: UIBarButtonItem) {
        UserDefaults.standard.set(self.chosenTagsArray, forKey: "tags")
        print(self.chosenTagsArray)
        let vc = PlayerViewController() //change this to your class name
        self.present(vc, animated: true, completion: nil)
        
        //self.performSegue(withIdentifier: "showPlayer", sender: self)
    }
    
    @objc func didPressRemoveSelectedTag(_ sender: UIButton) {
        let title = sender.titleLabel!.text!.trimmingCharacters(in: .whitespaces)
        for i in 0..<self.tags.count {
            if self.tags[i].name! == title {
                self.filteredTags.append(self.tags[i])
            }
        }
        
        removeTagButton(sender)
        
        self.filteredTags.sort(by: {$0.count > $1.count!})
        self.tableView.reloadData()
    }
    
    //MARK: tags
    var chosenTagsArray = [String]()
    var xPositionForChosenTags = UIElement().leftOffset
    
    lazy var chooseTagsLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose Tags"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 30)
        return label
    }()
    
    lazy var chosenTagsScrollview: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    func setUpTagListView() {
        addChooseTagsLabel()
        
        self.view.addSubview(self.chosenTagsScrollview)
        chosenTagsScrollview.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.top.equalTo(self.searchBar.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
        }
    }
    
    func addChooseTagsLabel() {
        self.chosenTagsScrollview.addSubview(chooseTagsLabel)
        chooseTagsLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.chosenTagsScrollview).offset(uiElement.topOffset)
            make.left.equalTo(self.chosenTagsScrollview).offset(uiElement.leftOffset)
            make.bottom.equalTo(self.chosenTagsScrollview)
        }
    }
    
    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
        if !tagView.isSelected {
            sender.removeTag(title)
            self.chosenTagsArray.append(title)
            self.addChosenTagButton(title)
            var positionToRemoveTag: Int?
            for i in 0..<self.filteredTags.count {
                if self.filteredTags[i].name == title {
                    positionToRemoveTag = i
                }
            }
            
            if let p = positionToRemoveTag {
                self.filteredTags.remove(at: p)
            }
        }
    }
    
    func addChosenTagButton(_ buttonTitle: String) {
        //not using snpakit to set button frame becuase not able to get button width.
        
        self.chooseTagsLabel.removeFromSuperview()
        let buttonWidth = determineChosenTagButtonTitleWidth(buttonTitle)
        
        let chosenTagButton = UIButton()
        chosenTagButton.frame = CGRect(x: xPositionForChosenTags, y: 0, width: buttonWidth , height: 45)
        chosenTagButton.setTitle(" \(buttonTitle) ", for: .normal)
        chosenTagButton.setTitleColor(color.black(), for: .normal)
        chosenTagButton.backgroundColor = color.primary()
        chosenTagButton.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 15)
        chosenTagButton.setImage(UIImage(named: "exit"), for: .normal)
        chosenTagButton.layer.cornerRadius = 22
        chosenTagButton.clipsToBounds = true
        chosenTagButton.addTarget(self, action: #selector(self.didPressRemoveSelectedTag(_:)), for: .touchUpInside)
        self.chosenTagsScrollview.addSubview(chosenTagButton)
        
        xPositionForChosenTags = xPositionForChosenTags + Int(chosenTagButton.frame.width) + uiElement.leftOffset
        chosenTagsScrollview.contentSize = CGSize(width: xPositionForChosenTags, height: uiElement.buttonHeight)
        
        brewMyPlaylistButton.isEnabled = true
    }
    
    func removeTagButton(_ button: UIButton) {
        let title = button.titleLabel!.text!.trimmingCharacters(in: .whitespaces)
        var position: Int?
        for i in 0..<self.chosenTagsArray.count {
            if self.chosenTagsArray[i] == title  {
                print("remove chosen tag")
                position = i
            }
        }
        
        if let p = position {
            self.chosenTagsArray.remove(at: p)
        }
        
        self.chosenTagsScrollview.subviews.forEach({ $0.removeFromSuperview() })
        xPositionForChosenTags = UIElement().leftOffset
        
        for title in chosenTagsArray {
            self.addChosenTagButton(title)
        }
        
        if self.chosenTagsArray.count == 0 {
            addChooseTagsLabel()
            brewMyPlaylistButton.isEnabled = false
        }
    }
    
    func determineChosenTagButtonTitleWidth(_ buttonTitle: String) -> Int {
        let uiFont = UIFont(name: "\(uiElement.mainFont)-bold", size: 15)!
        let buttonTitleSize = (buttonTitle as NSString).size(withAttributes:[.font: uiFont])
        let buttonTitleWidth = Int(buttonTitleSize.width)
        let buttonImageWidth = 50
        let totalButtonWidth = buttonTitleWidth + buttonImageWidth
        return totalButtonWidth
    }

    //MARK: SearchBar
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        //searchBar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width - 100, height: 15)
        searchBar.placeholder = "genre, mood, activity, city, anything"
        //searchBar.barStyle = .blackTranslucent
        searchBar.backgroundColor = color.black()
        searchBar.barTintColor = color.black()
        return searchBar
    }()
    
    func setUpSearchBar(){
        //searchBar.delegate = self
        //let searchBarNavItem = UIBarButtonItem(customView: searchBar)
        //self.navigationItem.rightBarButtonItems = [nextButton, searchBarNavItem]
        
        //self.navigationItem.rightBarButtonItem = nextButton
        
        searchBar.delegate = self
        self.view.addSubview(self.searchBar)
        searchBar.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self) - CGFloat(uiElement.topOffset))
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let wordPredicate = NSPredicate(format: "self BEGINSWITH[c] %@", searchText)
        if searchText.count == 0 {
            self.filteredTags = self.tags
            
        } else {
            //filter users on MeArchive that are in current user's phone
            var filteredTags = [Tag]()
            filteredTags = self.tags.filter {wordPredicate.evaluate(with: $0.name)}
            
            filteredTags.sort(by: {$0.count > $1.count!})
            self.filteredTags = filteredTags
        }
        
        self.tableView.reloadData()
    }
 
    //mark: Data
    func loadTags() {
        self.tags.removeAll()
        let query = PFQuery(className: "Tag")
        query.addDescendingOrder("count")
        query.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let tagName = object["tag"] as! String
                        let tagCount = object["count"] as! Int
                        
                        let newTag = Tag(objectId: object.objectId, name: tagName, count: tagCount)
                        self.tags.append(newTag)
                    }
                }
                
                self.filteredTags = self.tags
                
                if self.tableView == nil {
                    self.setUpSearchBar()
                    self.setUpTagListView()
                    self.setUpTableView()
                    
                } else {
                    self.tableView.reloadData()
                }
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
}

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
import NVActivityIndicatorView

class TagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TagListViewDelegate, NVActivityIndicatorViewable {
    
    //MARK: views
    let uiElement = UIElement()
    let color = Color()
    
    var tags = [Tag]()
    var filteredTags = [Tag]()
    
    var tagView: TagListView!
    
    lazy var brewMyPlaylistButton: UIButton = {
        let button = UIButton()
        button.setTitle("Brew", for: .normal)
        button.setTitleColor(.lightGray, for: .normal)
        button.isEnabled = false
        return button
    }()
    
    func shouldEnableBrewMyPlaylistButton(_ shouldEnable: Bool) {
        brewMyPlaylistButton.isEnabled = shouldEnable
        if shouldEnable {
            brewMyPlaylistButton.setTitleColor(.white, for: .normal)
            
        } else {
            brewMyPlaylistButton.setTitleColor(.lightGray, for: .normal)
        }
    }
    
    lazy var menuButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "menu"), for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startAnimating()
        setUpViews()
        setUpSearchBar()
        loadTags()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
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
        
        self.brewMyPlaylistButton.addTarget(self, action: #selector(self.didPressBrewMyPlaylistButton(_:)), for: .touchUpInside)
        self.view.addSubview(self.brewMyPlaylistButton)
        brewMyPlaylistButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(self.uiElement.topOffset + 25)
            make.right.equalTo(self.view).offset(self.uiElement.rightOffset)
        }
        
        self.menuButton.addTarget(self, action: #selector(self.didPressMenuButton(_:)), for: .touchUpInside)
        self.view.addSubview(self.menuButton)
        menuButton.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(30)
            make.top.equalTo(self.brewMyPlaylistButton).offset(5)
            make.left.equalTo(self.view).offset(self.uiElement.leftOffset)
        }
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
    @objc func didPressBrewMyPlaylistButton(_ sender: UIButton) {
        UserDefaults.standard.set(self.chosenTagsArray, forKey: "tags")
        self.uiElement.segueToView("Main", withIdentifier: "player", target: self)
    }
    
    @objc func didPressMenuButton(_ sender: UIButton) {
        let alertController = UIAlertController (title: nil, message: nil, preferredStyle: .actionSheet)
        
        let uploadAction = UIAlertAction(title: "Upload to Soundbrew", style: .default) { (_) -> Void in
            let soundbrewArtistsLink = URL(string: "https://itunes.apple.com/us/app/soundbrew-artists/id1438851832?mt=8")!
            if UIApplication.shared.canOpenURL(soundbrewArtistsLink) {
                UIApplication.shared.open(soundbrewArtistsLink, completionHandler: nil)
            }
        }
        alertController.addAction(uploadAction)
        
        let provideFeedbackAction = UIAlertAction(title: "Provide Feedback", style: .default) { (_) -> Void in
            let soundbrewArtistsLink = URL(string: "https://www.soundbrew.app/feedback")!
            if UIApplication.shared.canOpenURL(soundbrewArtistsLink) {
                UIApplication.shared.open(soundbrewArtistsLink, completionHandler: nil)
            }
        }
        alertController.addAction(provideFeedbackAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
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
        label.textAlignment = .center
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
            make.top.equalTo(self.searchBar.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
        }
    }
    
    func addChooseTagsLabel() {
        self.chosenTagsScrollview.addSubview(chooseTagsLabel)
        chooseTagsLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.chosenTagsScrollview)
            make.left.equalTo(self.chosenTagsScrollview).offset(uiElement.leftOffset)
            make.right.equalTo(self.chosenTagsScrollview).offset(uiElement.rightOffset)
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
        chosenTagButton.setTitle("\(buttonTitle) ", for: .normal)
        chosenTagButton.setTitleColor(color.black(), for: .normal)
        chosenTagButton.backgroundColor = color.primary()
        chosenTagButton.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 15)
        chosenTagButton.layer.cornerRadius = 22
        chosenTagButton.clipsToBounds = true
        chosenTagButton.addTarget(self, action: #selector(self.didPressRemoveSelectedTag(_:)), for: .touchUpInside)
        self.chosenTagsScrollview.addSubview(chosenTagButton)
        
        xPositionForChosenTags = xPositionForChosenTags + Int(chosenTagButton.frame.width) + uiElement.leftOffset
        chosenTagsScrollview.contentSize = CGSize(width: xPositionForChosenTags, height: uiElement.buttonHeight)
        
        shouldEnableBrewMyPlaylistButton(true)
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
            shouldEnableBrewMyPlaylistButton(false)
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
    
    lazy var searchBar: UITextField = {
        let searchBar = UITextField()
        searchBar.placeholder = "🔍 genre, mood, activity, city"
        searchBar.borderStyle = .roundedRect
        searchBar.clearButtonMode = .always
        return searchBar
    }()
    
    func setUpSearchBar() {
        searchBar.addTarget(self, action: #selector(searchBarDidChange(_:)), for: .editingChanged)
        self.view.addSubview(self.searchBar)
        searchBar.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(30)
            make.top.equalTo(self.view).offset(uiElement.topOffset + 30)
            make.left.equalTo(self.menuButton.snp.right).offset(uiElement.elementOffset)
            make.right.equalTo(self.brewMyPlaylistButton.snp.left).offset(-(uiElement.elementOffset))
        }
    }
    
    @objc func searchBarDidChange(_ textField: UITextField) {
        let wordPredicate = NSPredicate(format: "self BEGINSWITH[c] %@", textField.text!)
        
        if textField.text!.count == 0 {
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
                    self.setUpTagListView()
                    self.setUpTableView()
                    
                } else {
                    self.tableView.reloadData()
                }
                
                self.stopAnimating()
                
            } else {
                print("Error: \(error!)")
            }
        }
    }
}

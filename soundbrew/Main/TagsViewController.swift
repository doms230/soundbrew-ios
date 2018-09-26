//
//  TagsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/25/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import TagListView
import SnapKit

class TagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, TagListViewDelegate {
    
    var chosenTagsArray = [String]()
    
    var tableView: UITableView!
    let tagReuse = "tagReuse"
    let uiElement = UIElement()
    let color = Color()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViews()
    }
    
    func setUpViews() {
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: color.black()]
        
        let nextButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(self.didPressNextButton(_:)))
        
       self.navigationItem.rightBarButtonItem = nextButton
        
        searchBar.delegate = self
        self.view.addSubview(self.searchBar)
        searchBar.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self) - CGFloat(uiElement.topOffset))
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
        }
        
        self.view.addSubview(self.chosenTagsScrollview)
        chosenTagsScrollview.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.top.equalTo(self.searchBar.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
        }
        
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
            make.top.equalTo(self.searchBar.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    /*func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return ""
            
        } else {
            
        }
    }*/
    
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
        cell.tagLabel.addTags(["Hip-Hop/Rap", "R&B", "Alternative", "Dance", "Electronic", "Pop", "Rock","Soul/Funk", "Americana", "Blues", "Christian & Gospel", "Classical", "Country", "Experimental", "Hard Rock", "Indie", "Jazz", "K-Pop", "Latino", "Metal", "Música Mexicana", "Música Tropical", "Pop Latino", "Reggae", "Rock y Alternativo", "Singer / Songwriter", "Urbano Latino", "World"])

        
        return cell
    }
    
    //MARK: button actions
    @objc func didPressNextButton(_ sender: UIBarButtonItem) {
        
    }
    
    //MARK: taglist
    
    lazy var chosenTagsScrollview: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
        if tagView.isSelected {
            tagView.isSelected = false
            tagView.tagBackgroundColor = .white
            tagView.textColor = color.black()
            
        } else {
            tagView.isSelected = true
            tagView.tagBackgroundColor = color.red()
            tagView.textColor = color.black()
        }
       
    }

    //MARK: SearchBar
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        //searchBar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width - 100, height: 20)
        searchBar.placeholder = "genres, mood, activities, anything"
        searchBar.barStyle = .blackTranslucent
        return searchBar
    }()
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        /*let wordPredicate = NSPredicate(format: "self BEGINSWITH[c] %@", searchText)
        if searchText.count == 0 {
            self.filteredContactsOnMeArchive = self.contactsOnMeArchive
            self.filteredContactsOnPhone = self.contactsOnPhone
            
        } else {
            //filter users on MeArchive that are in current user's phone
            var meArchiveFilteredContacts = [MEAContacts]()
            meArchiveFilteredContacts = self.contactsOnMeArchive.filter {
                wordPredicate.evaluate(with: $0.username) ||
                    wordPredicate.evaluate(with: $0.displayName)
            }
            
            meArchiveFilteredContacts.sort(by: {$0.displayName! < $1.displayName!})
            self.filteredContactsOnMeArchive = meArchiveFilteredContacts
            
            
            //filter non-MeArchive users that are in current user's phone
            var phoneFilteredContacts = [MEAContacts]()
            phoneFilteredContacts = self.contactsOnPhone.filter { wordPredicate.evaluate(with: $0.displayName) }
            phoneFilteredContacts.sort(by: {$0.displayName! < $1.displayName!})
            self.filteredContactsOnPhone = phoneFilteredContacts
        }*/
        
        //self.tableView.reloadData()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

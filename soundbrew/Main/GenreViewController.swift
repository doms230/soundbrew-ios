//
//  ViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/25/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import TagListView
import SnapKit

class GenreViewControlle: UIViewController, UITableViewDelegate, UITableViewDataSource, TagListViewDelegate {
    
    var tableView: UITableView!
    let tagReuse = "tagReuse"
    let uiElement = UIElement()
    let color = Color()
    var selectedGenres = [String]()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 30)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViews()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*if let completedViewController = segue.destination as? CompletedViewController {
            completedViewController.noteObjectId = self.filteredPosts[selectedIndex].objectId
            completedViewController.isShowingCompleted = self.isShowingPeopleCompleted
        }*/

    }
    
    func setUpViews() {
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: color.black()]
        
        let nextButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(self.didPressNextButton(_:)))
        self.navigationItem.rightBarButtonItem = nextButton
        
        self.view.addSubview(self.titleLabel)
        titleLabel.text = "Choose The Genres You Like"
        titleLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
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
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
        
    }
    
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: tagReuse) as! MainTableViewCell
        cell.backgroundColor = color.black()
        cell.tagLabel.delegate = self 
        cell.tagLabel.addTags(["Hip-Hop/Rap", "R&B", "Alternative", "Dance", "Electronic", "Pop", "Rock","Soul/Funk", "Americana", "Blues", "Christian & Gospel", "Classical", "Country", "Experimental", "Hard Rock", "Indie", "Jazz", "K-Pop", "Latino", "Metal", "Música Mexicana", "Música Tropical", "Pop Latino", "Reggae", "Rock y Alternativo", "Singer / Songwriter", "Urbano Latino", "World"])
        return cell
    }
    
    //MARK: button actions
    @objc func didPressNextButton(_ sender: UIBarButtonItem) {
        
    }
    
    
    //MARK: taglist
    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
        if tagView.isSelected {
            tagView.isSelected = false
            tagView.tagBackgroundColor = .white
            tagView.textColor = color.black()
            
        } else {
            tagView.isSelected = true
            tagView.tagBackgroundColor = color.red()
            tagView.textColor = .white
        }
    }
}


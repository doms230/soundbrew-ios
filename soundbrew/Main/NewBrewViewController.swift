//
//  NewBrewViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 12/25/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//
//mark: tablview

import UIKit
import Parse

class NewBrewViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let color = Color()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       setUpTableView()
    }
    
    //MARK: Tableview
    var tableView: UITableView! 
    let newBrewReuse = "newBrewReuse"
    
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MainTableViewCell.self, forCellReuseIdentifier: newBrewReuse)
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        tableView.frame = self.view.bounds
        view.addSubview(tableView)
        
        /*tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.chosenTagsScrollview.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }*/
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: MainTableViewCell!
        cell = self.tableView.dequeueReusableCell(withIdentifier: newBrewReuse) as? MainTableViewCell
        
        switch indexPath.row {
        case 0:
            cell.featureTagButton.setTitle("Genre", for: .normal)
            cell.featureTagButton.backgroundColor = color.primary()
            break
            
        case 1:
            cell.featureTagButton.setTitle("Artists You Know", for: .normal)
            cell.featureTagButton.backgroundColor = self.color.uicolorFromHex(0xa9c5d0)
            break
            
        case 2:
            cell.featureTagButton.setTitle("City", for: .normal)
            cell.featureTagButton.backgroundColor = self.color.uicolorFromHex(0xaea9d0)
            break
            
        case 3:
            cell.featureTagButton.setTitle("Mood", for: .normal)
            cell.featureTagButton.backgroundColor = self.color.uicolorFromHex(0xd0a9cb)
            break
            
        case 4:
            cell.featureTagButton.setTitle("Activity", for: .normal)
            cell.featureTagButton.backgroundColor = self.color.uicolorFromHex(0xd0aba9)
            break
            
        case 5:
            cell.featureTagButton.setTitle("More", for: .normal)
            cell.featureTagButton.backgroundColor = self.color.uicolorFromHex(0xd0bfa9)
            break
            
        default:
            break 
        }
        
        return cell
    }
}

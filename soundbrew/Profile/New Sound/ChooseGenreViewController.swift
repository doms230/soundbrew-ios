//
//  ChooseGenreViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/8/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit

class ChooseGenreViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var tagType: String!
    
    let genres = ["Hip-Hop/Rap", "Electronic Dance Music(EDM)", "Pop", "Alternative Rock", "Americana", "Blues", "Christian & Gospal", "Classic Rock", "Classical", "Country", "Dance", "Hard Rock", "Indie", "Jazz", "Latino", "Metal", "Reggae", "R&B", "Soul", "Funk"]
    
    let moods = ["Happy", "Sad", "Angry", "Chill", "High-Energy", "Netflix-And-Chill"]
    
    let activities = ["Creative", "Workout", "Party", "Work", "Sleep", "Gaming"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        self.title = "Add \(tagType!) tag"
    }
    
    //MARK: Tableview
    var tableView: UITableView!
    let chooseGenreReuse = "chooseGenreReuse"
    
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SoundInfoTableViewCell.self, forCellReuseIdentifier: chooseGenreReuse)
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .singleLine
        tableView.frame = view.bounds
        self.view.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tagType {
        case "genre":
            return genres.count
            
        case "activity":
            return activities.count
            
        case "mood":
            return moods.count
            
        default:
            break
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: chooseGenreReuse) as! SoundInfoTableViewCell
        
        cell.selectionStyle = .default
        
        switch tagType {
        case "genre":
            cell.genreTitle.text = genres[indexPath.row]
            
        case "activity":
            cell.genreTitle.text = activities[indexPath.row]
            
        case "mood":
            cell.genreTitle.text = moods[indexPath.row]
            
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tagType {
        case "genre":
            UserDefaults.standard.set(genres[indexPath.row], forKey: tagType)
            
        case "activity":
            UserDefaults.standard.set(activities[indexPath.row], forKey: tagType)
            
        case "mood":
            UserDefaults.standard.set(moods[indexPath.row], forKey: tagType)
            
        default:
            break
        }
    }
}

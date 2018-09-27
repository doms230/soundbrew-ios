//
//  ArtistProfileViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/27/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit
class ArtistProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView()
    
    let uiElement = UIElement()
    let color = Color()
    let artistReuse = "artistReuse"
    
    lazy var userImage: UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = 25
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.image = UIImage(named: "sampleArtist")
        return image
    }()
    
    lazy var name: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: uiElement.mainFont, size: 20)
        label.textColor = .white
        label.text = "Dominic"
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MainTableViewCell.self, forCellReuseIdentifier: artistReuse)
        tableView.backgroundColor = color.black()
        self.tableView.separatorStyle = .none
        self.view.addSubview(tableView)
        
        self.view.addSubview(userImage)
        self.view.addSubview(name)
        
        userImage.snp.makeConstraints { (make) -> Void in
            make.height.width.equalTo(50)
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        name.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(userImage.snp.bottom).offset(uiElement.elementOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(name.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    //MARK: TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: artistReuse, for: indexPath) as! MainTableViewCell
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

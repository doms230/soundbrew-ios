//
//  ShareViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 4/24/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import Kingfisher

class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }    
    
    //mark: tableview
    var tableView = UITableView()
    let shareReuse = "shareReuse"
    
    func setUpTableView() {
        //tableView.dataSource = self
        //tableView.delegate = self
        tableView.register(SoundListTableViewCell.self, forCellReuseIdentifier: shareReuse)
        self.tableView.separatorStyle = .none
        //tableView.frame = view.bounds
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    
    
    /*func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        <#code#>
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        <#code#>
    }*/
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

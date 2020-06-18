//
//  PlayerV2ViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/18/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit

class PlayerV2ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let uiElement = UIElement()
    let color = Color()
    
    var player = Player.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotificationCenter()
        setupTopView()
        setUpTableView()
    }
    
    func setupNotificationCenter(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveSoundUpdate), name: NSNotification.Name(rawValue: "setSound"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector:#selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    lazy var dismissButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "dismiss"), for: .normal)
        button.addTarget(self, action: #selector(self.didPressDismissbutton(_:)), for: .touchUpInside)
        button.isOpaque = true
        return button
    }()
    @objc func didPressDismissbutton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    lazy var appTitle: UILabel = {
        let label = UILabel()
        label.text = "Soundbrew"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 15)
        label.textAlignment = .center
        label.isOpaque = true
        return label
    }()
    
    func setupTopView() {
        self.view.addSubview(self.dismissButton)
        self.dismissButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
        }
        
        self.view.addSubview(self.appTitle)
        self.dismissButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(dismissButton)
            make.centerX.equalTo(self.view)
        }
    }
    
    //MARK: Tableview
    var tableView: UITableView!
    let playerReuse = "playerReuse"
    func setUpTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PlayerTableViewCell.self, forCellReuseIdentifier: playerReuse)
        tableView.separatorStyle = .none
        tableView.backgroundColor = color.black()
        tableView.frame = self.view.bounds
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.dismissButton.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
        
        let player = Player.sharedInstance
        player.tableView = tableView
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        //section 0: player view
        //section 1: like count and play count
        //section 2: comments
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return playerCell()
    }
        
    //mark: sound
    @objc func didReceiveSoundUpdate(){
        //setSound()
    }
    
    @objc func didBecomeActive() {
        if self.viewIfLoaded?.window != nil {
            player.target = self
        }
    }
    
    //mark: player view
    func playerCell() -> PlayerTableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: playerReuse) as! PlayerTableViewCell
        cell.backgroundColor = .black
        cell.selectionStyle = .none
        return cell
    }
    

}

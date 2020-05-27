//
//  ContainerViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 7/2/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import SidebarOverlay

class ContainerViewController: SOContainerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.menuSide = .right
        self.topViewController = self.storyboard?.instantiateViewController(withIdentifier: "topScreen")
        self.sideViewController = self.storyboard?.instantiateViewController(withIdentifier: "rightScreen")
    }
    
    override var isSideViewControllerPresented: Bool {
        didSet {
            //doing this because miniPlayerView shows on top of sideViewController causing bottom views to be blocked
            let miniPlayer = MiniPlayerView.sharedInstance
            miniPlayer.isHidden = isSideViewControllerPresented
        }
    }

}

//
//  ContainerViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 5/6/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import SidebarOverlay

class ContainerViewController: SOContainerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.menuSide = .right
        self.topViewController = self.storyboard?.instantiateViewController(withIdentifier: "topScreen")
        self.sideViewController = self.storyboard?.instantiateViewController(withIdentifier: "sideScreen")
    }

}

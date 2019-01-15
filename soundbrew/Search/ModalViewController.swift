//
//  ModalViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 1/15/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit

final class ModalViewController: UIViewController {
    
    var tapCloseButtonActionHandler : (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let effect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: effect)
        blurView.frame = self.view.bounds
        self.view.addSubview(blurView)
        //self.view.sendSubview(toBack: blurView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ModalViewController viewWillAppear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("ModalViewController viewWillDisappear")
    }
}

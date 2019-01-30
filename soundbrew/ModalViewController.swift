//
//  ModalViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 1/29/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import DeckTransition

class ModalViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.viewWasTapped))
        view.addGestureRecognizer(tap)
        
        view.backgroundColor = .red 
    }
    

    @objc func viewWasTapped() {
        let modal = ModalViewController()
        let transitionDelegate = DeckTransitioningDelegate()
        modal.transitioningDelegate = transitionDelegate
        modal.modalPresentationStyle = .custom
        present(modal, animated: true, completion: nil)
    }

}

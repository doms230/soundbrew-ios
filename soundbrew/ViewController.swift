//
//  ViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 1/29/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import DeckTransition

class ViewController: UIViewController {

    @IBOutlet weak var button: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        //let tap = UITapGestureRecognizer(target: self, action: #selector(self.viewWasTapped))
       // button.addGestureRecognizer(tap)
        //view.addGestureRecognizer(tap)
        
        let slide = UISwipeGestureRecognizer(target: self, action: #selector(self.viewWasTapped))
        slide.direction = .up
        button.addGestureRecognizer(slide)
    }
    
    @objc func viewWasTapped() {
        let modal = ModalViewController()
        let transitionDelegate = DeckTransitioningDelegate()
        modal.transitioningDelegate = transitionDelegate
        modal.modalPresentationStyle = .custom
        present(modal, animated: true, completion: nil)
    }
    
    @IBAction func buttonAction(_ sender: UIButton) {
        let modal = ModalViewController()
        let transitionDelegate = DeckTransitioningDelegate()
        modal.transitioningDelegate = transitionDelegate
        modal.modalPresentationStyle = .custom
        present(modal, animated: true, completion: nil)
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

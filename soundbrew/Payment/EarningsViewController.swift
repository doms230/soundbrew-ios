//
//  EarningsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 7/7/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import SnapKit

class EarningsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
    }
    
    let uiElement = UIElement()
    let color = Color()
    
    lazy var thisWeekLabel: UILabel = {
        let label = UILabel()
        label.text = "1/8-1/17"
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 20)
        label.textAlignment = .center
        label.textColor = color.black()
        return label
    }()
    
    lazy var earningsLabel: UILabel = {
        let label = UILabel()
        label.text = "$0.00"
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 40)
        label.textAlignment = .center
        label.textColor = color.black()
        return label
    }()
    
    lazy var earningsScheduleLabel: UILabel = {
        let label = UILabel()
        label.text = "Earnings are sent via PayPal on a weekly basis."
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 15)
        label.textAlignment = .center
        label.textColor = color.black()
        label.numberOfLines = 0
        return label
    }()
    
    lazy var editPaypalEmailButton: UIButton = {
        let button = UIButton()
        button.setTitle("Edit PayPal Email", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = color.blue()
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 20)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()
    
    func setUpView() {
        self.view.addSubview(thisWeekLabel)
        thisWeekLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(earningsLabel)
        earningsLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(thisWeekLabel.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(earningsScheduleLabel)
        earningsScheduleLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(earningsLabel.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        self.view.addSubview(editPaypalEmailButton)
        editPaypalEmailButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(earningsScheduleLabel.snp.bottom).offset(uiElement.topOffset)
            make.width.equalTo(200)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
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

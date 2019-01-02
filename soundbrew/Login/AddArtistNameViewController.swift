//
//  AddArtistNameViewController.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/10/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit

class AddArtistNameViewController: UIViewController {
    let color = Color()
    let uiElement = UIElement()
    
    var email: String!
    var password: String! 
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: uiElement.titleLabelFontSize)
        label.text = "What's Your Artist Name?"
        label.numberOfLines = 0
        return label
    }()
    
    lazy var artistNameText: UITextField = {
        let label = UITextField()
        label.placeholder = "Artist Name"
        label.font = UIFont(name: uiElement.mainFont, size: 17)
        label.backgroundColor = .white
        label.borderStyle = .roundedRect
        label.clearButtonMode = .whileEditing
        label.keyboardType = .emailAddress
        return label
    }()
    
    lazy var saveButton: UIButton = {
        let button = UIButton()
        button.setTitle("Save", for: .normal)
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 20)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.textAlignment = .right
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.backgroundColor = color.blue()
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Artist Name (2/4)"
        
        self.view.addSubview(titleLabel)
        self.view.addSubview(artistNameText)
        self.view.addSubview(saveButton)
        saveButton.addTarget(self, action: #selector(next(_:)), for: .touchUpInside)
        
        titleLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        artistNameText.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        saveButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.top.equalTo(artistNameText.snp.bottom).offset(10)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController: AddCityViewController = segue.destination as! AddCityViewController
        viewController.artistName = artistNameText.text!
        viewController.email = email
        viewController.password = password
    }
    
    @objc func next(_ sender: UIButton) {
        if validateArtistName() {
            self.performSegue(withIdentifier: "showAddCity", sender: self)
        }
    }
    
    func validateArtistName() -> Bool {
        if artistNameText.text!.isEmpty {
            artistNameText.attributedPlaceholder = NSAttributedString(string: "Field required",
                                                                    attributes:[NSAttributedString.Key.foregroundColor: UIColor.red])
            return false
        }
        
        return true        
    }
}

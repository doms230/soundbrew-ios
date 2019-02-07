//
//  MiniPlayerView.swift
//  soundbrew
//
//  Created by Dominic  Smith on 2/6/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class MiniPlayerView: UIButton {
    let color = Color()
    let uiElement = UIElement()
    var shouldSetupConstraints = true
    
    lazy var songTitle: UILabel = {
        let label = UILabel()
        label.text = "Sound Title"
        label.textColor = color.black()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 15)
        label.textAlignment = .center
        return label
    }()
    
    lazy var artistName: UIButton = {
        let button = UIButton()
        button.setTitle("Artist Name", for: .normal)
        button.setTitleColor(color.black(), for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 10)
        return button
    }()
    
    lazy var playBackButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "pause"), for: .normal)
        button.isEnabled = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .white
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func updateConstraints() {
        if(shouldSetupConstraints) {
            self.addSubview(playBackButton)
            playBackButton.snp.makeConstraints { (make) -> Void in
                make.width.height.equalTo(30)
                make.top.equalTo(self).offset(uiElement.elementOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                //make.bottom.equalTo(self).offset(-(uiElement.elementOffset))
            }
            
            self.addSubview(songTitle)
            songTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.elementOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(playBackButton.snp.left).offset(uiElement.rightOffset)
            }
            
            self.addSubview(artistName)
            artistName.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.songTitle.snp.bottom)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(songTitle)
            }
            
            shouldSetupConstraints = false
        }
        super.updateConstraints()
    }
}

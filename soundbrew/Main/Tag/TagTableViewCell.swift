//
//  TagTableViewCell.swift
//  soundbrew
//
//  Created by Dominic  Smith on 8/7/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit

class TagTableViewCell: UITableViewCell {
    let color = Color()
    let uiElement = UIElement()
    
    lazy var TagTypeTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        label.textColor = .white
        return label
    }()
    
    lazy var tagsScrollview: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    lazy var tagTypeButton: UIButton = {
        let button = UIButton()
        return button
    }()
    
    lazy var viewAllLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.text = "View All"
        label.textColor = .white
        return label
    }()
    
    lazy var newChartsButton: UIButton = {
        let button = UIButton()
        button.setTitle("New", for: .normal)
        button.setBackgroundImage(UIImage(named: "background"), for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        return button
    }()
    
    lazy var topChartsButton: UIButton = {
        let button = UIButton()
        button.setTitle("Top", for: .normal)
        button.setBackgroundImage(UIImage(named: "background"), for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        return button
    }()
    
    lazy var followButton: UIButton = {
        let button = UIButton()
        button.setTitle("Following", for: .normal)
        button.setBackgroundImage(UIImage(named: "background"), for: .normal)
        button.titleLabel?.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        if reuseIdentifier == "reuse" {
            self.addSubview(TagTypeTitle)
            self.addSubview(tagsScrollview)
            
            TagTypeTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            tagsScrollview.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(115)
                make.top.equalTo(TagTypeTitle.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self)
                make.right.equalTo(self)
                make.bottom.equalTo(self)
            }
            
            
        } else if reuseIdentifier == "profileSoundReuse" {
            self.addSubview(tagTypeButton)
            self.tagTypeButton.addSubview(TagTypeTitle)
            self.tagTypeButton.addSubview(viewAllLabel)
            self.addSubview(tagsScrollview)
            
            tagTypeButton.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            viewAllLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(tagTypeButton)
                make.right.equalTo(tagTypeButton)
                make.bottom.equalTo(tagTypeButton)
            }
            
            TagTypeTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(tagTypeButton)
                make.left.equalTo(tagTypeButton)
                make.right.equalTo(viewAllLabel.snp.left).offset(uiElement.rightOffset)
                make.bottom.equalTo(tagTypeButton)
            }
            
            tagsScrollview.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(210)
                make.top.equalTo(tagTypeButton.snp.bottom)
                make.left.equalTo(self)
                make.right.equalTo(self)
                make.bottom.equalTo(self)
            }
            
        } else {
            self.addSubview(newChartsButton)
            self.addSubview(topChartsButton)
            self.addSubview(followButton)
            self.addSubview(TagTypeTitle)
            
            TagTypeTitle.text = "Releases"
            TagTypeTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            newChartsButton.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(100)
                make.height.equalTo(50)
                make.top.equalTo(TagTypeTitle.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            topChartsButton.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(100)
                make.height.equalTo(50)
                make.top.equalTo(newChartsButton)
                make.left.equalTo(newChartsButton.snp.right).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            followButton.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(100)
                make.height.equalTo(50)
                make.top.equalTo(newChartsButton)
                make.left.equalTo(topChartsButton.snp.right).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
        }
    }
    
    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

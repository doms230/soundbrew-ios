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
        return label
    }()
    
    lazy var viewAllLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.text = "View All"
        return label
    }()
    
    lazy var tagTypeButton: UIButton = {
        let button = UIButton()
        return button
    }()
    
    lazy var tagsScrollview: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
   /* lazy var tagButton: UIButton = {
        let button = UIButton()
        return button
    }()
    
    lazy var tagLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        return label
    }()*/
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
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
            make.height.equalTo(130)
            make.top.equalTo(tagTypeButton.snp.bottom)
            make.left.equalTo(self)
            make.right.equalTo(self)
            make.bottom.equalTo(self)
        }
    }
    
    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

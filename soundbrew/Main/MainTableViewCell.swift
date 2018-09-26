//
//  MainTableViewCell.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/25/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit
import TagListView

class MainTableViewCell: UITableViewCell {
    
    let color = Color()
    let uiElement = UIElement()
    
    //mark: Tags
    lazy var chosenTags: TagListView = {
        let tag = TagListView()
        tag.tagBackgroundColor = color.red()
        tag.cornerRadius = 3
        tag.textColor = color.black()
        tag.marginX = CGFloat(uiElement.leftOffset)
        tag.marginY = CGFloat(uiElement.topOffset)
        tag.paddingX = CGFloat(uiElement.leftOffset)
        tag.paddingY = CGFloat(uiElement.topOffset)
        tag.textFont = UIFont(name: uiElement.mainFont, size: 17)!
        return tag
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 30)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    lazy var tagLabel: TagListView = {
        let tag = TagListView()
        tag.tagBackgroundColor = .white
        tag.cornerRadius = 3
        tag.textColor = color.black()
        tag.marginX = CGFloat(uiElement.leftOffset)
        tag.marginY = CGFloat(uiElement.topOffset)
        tag.paddingX = CGFloat(uiElement.leftOffset)
        tag.paddingY = CGFloat(uiElement.topOffset)
        tag.textFont = UIFont(name: uiElement.mainFont, size: 17)!
        return tag
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        switch reuseIdentifier {
        case "tagReuse":
            self.addSubview(self.tagLabel)
            tagLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            break
            
        case "playerReuse":
            break
            
            
        default:
            break
            
            
        }
    }

    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

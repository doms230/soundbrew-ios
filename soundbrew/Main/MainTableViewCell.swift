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
    
    
    lazy var featureTagTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)-Bold", size: 20)
        label.textColor = color.black()
        label.numberOfLines = 0
        return label
    }()
    
    lazy var featureTagsScrollview: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    lazy var tagLabel: TagListView = {
        let tag = TagListView()
        tag.tagBackgroundColor = color.primary()
        tag.cornerRadius = 22
        tag.textColor = color.black()
        //tag.borderWidth = 1
        //tag.borderColor = color.black()
        tag.marginX = CGFloat(uiElement.leftOffset)
        tag.marginY = CGFloat(uiElement.topOffset)
        tag.paddingX = CGFloat(uiElement.leftOffset)
        tag.paddingY = CGFloat(uiElement.topOffset)
        tag.textFont = UIFont(name: "\(uiElement.mainFont)-Bold", size: 17)!
        return tag
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        switch reuseIdentifier {
        case "featureTagReuse":
            self.addSubview(featureTagsScrollview)
            self.addSubview(featureTagTitle)
            
            featureTagTitle.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.elementOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            featureTagsScrollview.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(uiElement.buttonHeight)
                make.top.equalTo(self.featureTagTitle.snp.bottom).offset(uiElement.elementOffset)
                make.left.equalTo(self)
                make.right.equalTo(self)
                make.bottom.equalTo(self).offset(-(uiElement.elementOffset))
            }
            break 
            
        case "tagReuse":
            self.addSubview(self.tagLabel)
            tagLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(-(uiElement.elementOffset))
            }
            
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

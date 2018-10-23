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
    
    //mark: Artist profile
    lazy var itemImage: UIImageView = {
        let image = UIImageView()
        return image
    }()
    
    lazy var itemLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: UIElement().mainFont, size: 17)
        label.textColor = color.black()
        return label
    }()
    
    //mark: Tags
    lazy var tagLabel: TagListView = {
        let tag = TagListView()
        tag.tagBackgroundColor = color.tan()
        tag.cornerRadius = 22
        tag.textColor = color.black()
        tag.borderWidth = 1
        tag.borderColor = color.black()
        tag.marginX = CGFloat(uiElement.leftOffset)
        tag.marginY = CGFloat(uiElement.topOffset)
        tag.paddingX = CGFloat(uiElement.leftOffset)
        tag.paddingY = CGFloat(uiElement.topOffset)
        tag.textFont = UIFont(name: uiElement.mainFont, size: 15)!
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
            
        case "artistProfileReuse":
            self.addSubview(itemImage)
            self.addSubview(itemLabel)
            
            itemImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(25)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            itemLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self.itemImage.snp.right).offset(5)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
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

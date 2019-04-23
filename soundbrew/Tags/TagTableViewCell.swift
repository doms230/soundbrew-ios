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

class TagTableViewCell: UITableViewCell {
    
    let color = Color()
    let uiElement = UIElement()
    
    lazy var tagLabel: TagListView = {
        let tag = TagListView()
        tag.cornerRadius = 5
        tag.textColor = color.black()
        tag.tagBackgroundColor = .white
        tag.borderWidth = 1
        tag.borderColor = color.lightGray()
        tag.marginX = CGFloat(uiElement.leftOffset)
        tag.marginY = CGFloat(uiElement.topOffset)
        tag.paddingX = CGFloat(uiElement.leftOffset)
        tag.paddingY = CGFloat(uiElement.topOffset)
        tag.textFont = UIFont(name: "\(uiElement.mainFont)-Bold", size: 20)!
        return tag
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.addSubview(self.tagLabel)
        tagLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self).offset(uiElement.topOffset)
            make.left.equalTo(self).offset(uiElement.leftOffset)
            make.right.equalTo(self).offset(uiElement.rightOffset)
            make.bottom.equalTo(self).offset(-(uiElement.elementOffset))
        }
    }

    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

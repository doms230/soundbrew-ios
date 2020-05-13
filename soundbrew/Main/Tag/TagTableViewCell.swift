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
    
    var TagTypeTitle: UILabel!
    var tagTypeButton: UIButton!
    var viewAllLabel: UILabel!
    
    lazy var tagsScrollview: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let uiElement = UIElement()
        
        tagTypeButton = uiElement.soundbrewButton(nil, shouldShowBorder: false, backgroundColor: .clear, image: nil, titleFont: nil, titleColor: .white, cornerRadius: nil)
        self.addSubview(tagTypeButton)
        tagTypeButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self).offset(uiElement.topOffset)
            make.left.equalTo(self).offset(uiElement.leftOffset)
            make.right.equalTo(self).offset(uiElement.rightOffset)
        }
        
        let localizedViewAll = NSLocalizedString("viewAll", comment: "")
        viewAllLabel = uiElement.soundbrewLabel(localizedViewAll, textColor: .white, font: UIFont(name: "\(uiElement.mainFont)", size: 17)!, numberOfLines: 0)
        self.tagTypeButton.addSubview(viewAllLabel)
        viewAllLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(tagTypeButton)
            make.right.equalTo(tagTypeButton)
            make.bottom.equalTo(tagTypeButton)
        }
        
        TagTypeTitle = uiElement.soundbrewLabel(nil, textColor: .white, font: UIFont(name: "\(uiElement.mainFont)-bold", size: 20)!, numberOfLines: 0)
        self.tagTypeButton.addSubview(TagTypeTitle)
        TagTypeTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(tagTypeButton)
            make.left.equalTo(tagTypeButton)
            make.bottom.equalTo(tagTypeButton)
        }
        
        self.addSubview(tagsScrollview)
        tagsScrollview.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(210)
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

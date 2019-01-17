//
//  StreamsAndSocialsTableViewCell.swift
//  soundbrew artists
//
//  Created by Dominic  Smith on 10/10/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import SnapKit

class StreamsAndSocialsTableViewCell: UITableViewCell {

    let uiElement = UIElement()
    let color = Color()
    
    //
    lazy var socialStreamImage: UIImageView = {
        let image = UIImageView()
        return image
    }()
    
    lazy var socialStreamText: UITextField = {
        let textField = UITextField()
        textField.placeholder = ""
        textField.borderStyle = .roundedRect
        textField.font = UIFont(name: "\(UIElement().mainFont)", size: 17)
        return textField
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        if reuseIdentifier == "socialsAndStreamsReuse" {
            self.addSubview(socialStreamImage)
            self.addSubview(socialStreamText)
            
            socialStreamImage.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(30)
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            
            socialStreamText.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self.socialStreamImage.snp.right).offset(5)
                make.right.equalTo(self).offset(uiElement.rightOffset)
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

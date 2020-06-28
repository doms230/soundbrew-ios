//
//  EarningsTableViewCell.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/27/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit

class EarningsTableViewCell: UITableViewCell {
    let uiElement = UIElement()
    let color = Color()
    
    lazy var titleLabel: UILabel = {
        return self.uiElement.soundbrewLabel("", textColor: .white, font: UIFont(name: "\(self.uiElement.mainFont)-bold", size: 17)!, numberOfLines: 1)
    }()
    
    lazy var subTitleLabel: UILabel = {
        return self.uiElement.soundbrewLabel("", textColor: .white, font: UIFont(name: "\(self.uiElement.mainFont)", size: 17)!, numberOfLines: 1)
    }()
    
    lazy var dateLabel: UILabel = {
        return self.uiElement.soundbrewLabel("", textColor: .darkGray, font: UIFont(name: "\(self.uiElement.mainFont)", size: 17)!, numberOfLines: 1)
    }()
    
    lazy var downArrow: UIImageView = {
        return uiElement.soundbrewImageView(UIImage(named: "dismiss"), cornerRadius: nil, backgroundColor: nil)
    }()
    
    lazy var dividerLine: UIView = {
        let line = UIView()
        line.layer.borderWidth = 1
        line.layer.borderColor = UIColor.darkGray.cgColor
        return line
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        switch reuseIdentifier {
        case "earningsReuse", "payoutBankReuse":
            self.addSubview(downArrow)
            downArrow.snp.makeConstraints { (make) -> Void in
                make.width.height.equalTo(25)
                make.centerY.equalTo(self)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(titleLabel)
            var titleSize: CGFloat!
            if reuseIdentifier == "earningsReuse" {
                titleSize = 25
            } else {
                titleSize = 17
            }
            titleLabel.font = UIFont(name: "\(self.uiElement.mainFont)-bold", size: titleSize)
            titleLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(downArrow.snp.left).offset(uiElement.rightOffset)
            }
            
            self.addSubview(dateLabel)
            dateLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(titleLabel.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(titleLabel)
            }
            
            self.addSubview(dividerLine)
            dividerLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(dateLabel.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            break
            
        case "payoutReuse":
            self.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(subTitleLabel)
            subTitleLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(titleLabel.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(dateLabel)
            dateLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(subTitleLabel.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
            }
            
            self.addSubview(dividerLine)
            dividerLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(dateLabel.snp.bottom).offset(uiElement.topOffset)
                make.left.equalTo(self).offset(uiElement.leftOffset)
                make.right.equalTo(self).offset(uiElement.rightOffset)
                make.bottom.equalTo(self).offset(uiElement.bottomOffset)
            }
            break
            
        case "transactionsReuse":
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

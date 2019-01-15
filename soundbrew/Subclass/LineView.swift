//
//  LineView.swift
//  soundbrew
//
//  Created by Dominic  Smith on 1/15/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit

final class LineView: UIView {
    override func draw(_ rect: CGRect) {
        let topLine = UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.frame.size.width, height: 0.5))
        UIColor.gray.setStroke()
        topLine.lineWidth = 0.2
        topLine.stroke()
        
        let bottomLine = UIBezierPath(rect: CGRect(x: 0, y: self.frame.size.height - 0.5, width: self.frame.size.width, height: 0.5))
        UIColor.lightGray.setStroke()
        bottomLine.lineWidth = 0.2
        bottomLine.stroke()
    }
}

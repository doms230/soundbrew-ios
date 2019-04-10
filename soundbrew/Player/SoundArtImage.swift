//
//  SoundArtImage.swift
//  soundbrew
//
//  Created by Dominic  Smith on 4/9/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class SoundArtImage: UIView {
    
    let color = Color()
    let uiElement = UIElement()
    
    lazy var soundbrewTitle: UILabel = {
        let label = UILabel()
        label.text = "Listen on Soundbrew"
        label.textColor = color.black()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 25)
        label.textAlignment = .center
        return label
    }()
    
    lazy var songArt: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.backgroundColor = .white
        return image
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .white
        self.layer.borderWidth = 1
        self.layer.borderColor = color.darkGray().cgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func updateConstraints() {
        songArt.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height - 50)
        self.addSubview(songArt)
        
        soundbrewTitle.frame = CGRect(x: 10, y: self.frame.height - 30, width: self.frame.width - 10, height: 30)
        self.addSubview(soundbrewTitle)
        
        super.updateConstraints()
    }
}

extension UIView {
    
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        if #available(iOS 10.0, *) {
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            return renderer.image { rendererContext in
                layer.render(in: rendererContext.cgContext)
            }
        } else {
            UIGraphicsBeginImageContext(self.frame.size)
            self.layer.render(in:UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return UIImage(cgImage: image!.cgImage!)
        }
    }
}

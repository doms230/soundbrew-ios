//
//  SnapchatStoriesArtImage.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/11/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import Foundation
import UIKit

class SnapchatStoriesArtImage: UIView {
    
    let color = Color()
    let uiElement = UIElement()
    
    lazy var soundTitle: UILabel = {
        let label = UILabel()
        label.text = "Sound Title"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 30)
        //label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    lazy var artistName: UILabel = {
        let label = UILabel()
        label.text = "Artist Name"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 25)
        //label.textAlignment = .center
        return label
    }()
    
    lazy var appName: UILabel = {
        let label = UILabel()
        label.text = "Listen on @sound_brew"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        //label.textAlignment = .center
        return label
    }()
    
    lazy var soundArt: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.backgroundColor = color.black()
        return image
    }()
    
    lazy var artView: UIView = {
        let view = UIView()
        view.backgroundColor = color.black()
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = color.black()
        //self.layer.borderWidth = 1
        //self.layer.borderColor = color.darkGray().cgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func updateConstraints() {
        artView.frame = CGRect(x: 0, y: 0, width: 500, height: 150)
        self.addSubview(artView)
        
        soundArt.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
        self.artView.addSubview(soundArt)
        
        soundTitle.frame = CGRect(x: 175, y: 15, width: 325, height: 30)
        self.artView.addSubview(soundTitle)
        
        artistName.frame = CGRect(x: 175, y: 60, width: 325, height: 30)
        self.artView.addSubview(artistName)
        
        appName.frame = CGRect(x: 175, y: 105, width: 325, height: 30)
        self.artView.addSubview(appName)
        
        
        /*artView.frame = CGRect(x: 0, y: 0, width: 500, height: 250)
        self.addSubview(artView)
        
        soundArt.frame = CGRect(x: 0, y: 0, width: 250, height: 250)
        self.artView.addSubview(soundArt)
        
        soundTitle.frame = CGRect(x: 265, y: 15, width: 240, height: 30)
        self.artView.addSubview(soundTitle)
        
        artistName.frame = CGRect(x: 265, y: 65, width: 240, height: 30)
        self.artView.addSubview(artistName)
        
        appName.frame = CGRect(x: 265, y: 115, width: 240, height: 30)
        self.artView.addSubview(appName)*/
        
        super.updateConstraints()
    }
}

extension UIView {
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    /*func asImage() -> UIImage {
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
    }*/
}

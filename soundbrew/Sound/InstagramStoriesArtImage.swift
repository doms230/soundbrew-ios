//
//  InstagramStoriesArtImage.Swift
//  soundbrew
//
//  Created by Dominic  Smith on 4/9/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import Foundation
import UIKit

class InstagramStoriesArtImage: UIView {
    
    let color = Color()
    let uiElement = UIElement()
    
    lazy var soundTitle: UILabel = {
        let label = UILabel()
        label.text = "Sound Title"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 30)
        label.textAlignment = .center
        return label
    }()
    
    lazy var artistName: UILabel = {
        let label = UILabel()
        label.text = "Artist Name"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 25)
        label.textAlignment = .center
        return label
    }()
    
    lazy var appName: UILabel = {
        let label = UILabel()
        label.text = "Listen on \(self.uiElement.soundbrewSocialHandle)"
        label.textColor = .white
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 17)
        label.textAlignment = .center
        return label
    }()
    
    lazy var soundArt: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.backgroundColor = color.black()
        return image
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func updateConstraints() {
        soundArt.frame = CGRect(x: 0, y: 0, width: 500, height: 500)
        self.addSubview(soundArt)
        
        soundTitle.frame = CGRect(x: 10, y: 515, width: 500, height: 30)
        self.addSubview(soundTitle)
        
        artistName.frame = CGRect(x: 10, y: 545, width: 500, height: 30)
        self.addSubview(artistName)
        
        appName.frame = CGRect(x: 10, y: 570, width: 500, height: 30)
        self.addSubview(appName)
        
        super.updateConstraints()
    }
}

extension UIView {
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

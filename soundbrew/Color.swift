//
//  Color.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/25/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit

class Color {
    func darkGray() -> UIColor {
        return uicolorFromHex(0xcccccc)
    }
    
    func lightGray() -> UIColor {
        return uicolorFromHex(0xececec)
    }
    
    func red() -> UIColor {
        return uicolorFromHex(0xff5757)
    }
    
    func black() -> UIColor {
        //return uicolorFromHex(0x180d22)
        return uicolorFromHex(0x393939)
        //return uicolorFromHex(0x353435)
    }
    
    func tan() -> UIColor {
        //return uicolorFromHex(0xf9f5f1)
        return uicolorFromHex(0xf9fbef)
    }
    
    func primary() -> UIColor {
        return uicolorFromHex(0xa9d0b4)
        
        //return uicolorFromHex(0xee1848)
        //return uicolorFromHex(0x00ff99)
        //return uicolorFromHex(0x378869)
    }
    
    func blue() -> UIColor { 
        return uicolorFromHex(0x1243b5)
       // return uicolorFromHex(0x0066ff)
    }
    
    func green() -> UIColor {
        return uicolorFromHex(0x70b784)
    }
    
    func uicolorFromHex(_ rgbValue:UInt32) -> UIColor {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        
        return UIColor(red:red, green:green, blue:blue, alpha:1.0)
    }
}

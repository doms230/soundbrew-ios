//
//  UIElement.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/25/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import Foundation

class UIElement {
    let topOffset = 15
    let leftOffset = 15
    let rightOffset = -15
    let bottomOffset = -15
    let arrowHeightWidth = 10
    let buttonHeight = 50
    let userImageHeightWidth = 40
    let elementOffset = 5
    let titleLabelFontSize: CGFloat = 25
    
    let mainFont = "HelveticaNeue"
    
    func determineChosenTagButtonTitleWidth(_ buttonTitle: String) -> Int {
        let uiFont = UIFont(name: "\(mainFont)-bold", size: 17)!
        let buttonTitleSize = (buttonTitle as NSString).size(withAttributes:[.font: uiFont])
        let buttonTitleWidth = Int(buttonTitleSize.width)
        let buttonImageWidth = 50
        let totalButtonWidth = buttonTitleWidth + buttonImageWidth
        return totalButtonWidth
    }
    
    //This is used to make sure that top offset is below navigation bar
    func uiViewTopOffset(_ target: UIViewController ) -> CGFloat {
        return UIApplication.shared.statusBarFrame.size.height +
            (target.navigationController?.navigationBar.frame.height ?? 0.0) + CGFloat(topOffset)
    }
    
    func segueToView(_ storyBoard: String, withIdentifier: String, target: UIViewController) {
        let storyboard = UIStoryboard(name: storyBoard, bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: withIdentifier)
        target.present(controller, animated: true, completion: nil)
    }
    
    func showAlert(_ title: String, message: String, target: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        target.present(alert, animated: true, completion: nil)
    }
    
    func permissionDenied(_ title: String, message: String, target: UIViewController) {
        let alertController = UIAlertController (title: title, message: message, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Go to Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: nil)
            }
        }
        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        target.present(alertController, animated: true, completion: nil)
    }
    
    func setUserDefault(_ key: String, value: String) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    func getUserDefault(_ key: String) -> String? {
        if let name = UserDefaults.standard.string(forKey: key) {
            return name
        }
        
        return nil
    }    
}

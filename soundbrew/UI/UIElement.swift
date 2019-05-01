//
//  UIElement.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/25/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import Foundation
import Parse
import FirebaseDynamicLinks
import SCSDKCreativeKit
import ShareInstagram

class UIElement {
    let topOffset = 10
    let leftOffset = 15
    let rightOffset = -15
    let bottomOffset = -10
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
        let buttonImageWidth = 35
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
    
    func setUserDefault(_ key: String, value: Any) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    func getUserDefault(_ key: String) -> Any? {
        if let value = UserDefaults.standard.object(forKey: key) {
            return value
        }
        
        return nil
    }
    
    func goBackToPreviousViewController(_ target: UIViewController) {
        target.navigationController?.popViewController(animated: true)
    }
    
    func showTextFieldErrorMessage(_ UITextField: UITextField, text: String) {
        UITextField.attributedPlaceholder = NSAttributedString(string: text,
                                                             attributes:[NSAttributedString.Key.foregroundColor: UIColor.red])
        UITextField.text = ""
    }
    
    func cleanUpText(_ text: String) -> String {
        let cleanText = text.trimmingCharacters(
            in: NSCharacterSet.whitespacesAndNewlines
        )
                
        return cleanText.lowercased()
    }
    
    func formatTime(_ durationInSeconds: Double ) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        let formattedString = formatter.string(from: durationInSeconds)!
        return formattedString
    }
    
    func createDynamicLink(_ linkType: String, sound: Sound?, artist: Artist?, target: UIViewController) {
        var objectId = ""
        var title = ""
        var description: String!
        var imageURL = ""
        if let sound = sound {
            title = sound.title
            description = "\(sound.title!) by \(sound.artist!.name!)"
            imageURL = sound.artURL
            objectId = sound.objectId
            
        } else if let artist = artist {
            objectId = artist.objectId
            description = "Check out my Soundbrew page!"
            if let username = artist.username {
                if !username.contains("@") {
                    title = username
                    
                } else if let name = artist.name {
                    title = name
                    
                } else {
                    title = "Soundbrew Artist"
                }
            }
            
            if let image = artist.image {
                imageURL = image
                
            } else {
                imageURL = "https://www.soundbrew.app/images/logo_green.jpg"
            }
        }
        guard let link = URL(string: "https://soundbrew.app/\(linkType)/\(objectId)") else { return }
        let dynamicLinksDomainURIPrefix = "https://soundbrew.page.link"
        let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: dynamicLinksDomainURIPrefix)
        linkBuilder!.iOSParameters = DynamicLinkIOSParameters(bundleID: "com.soundbrew.soundbrew-artists")
        linkBuilder!.iOSParameters!.appStoreID = "1438851832"
        linkBuilder!.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        linkBuilder!.socialMetaTagParameters!.title = "\(title)"
        linkBuilder!.socialMetaTagParameters!.descriptionText = description
        linkBuilder!.socialMetaTagParameters!.imageURL = URL(string: imageURL)
        linkBuilder!.shorten() { url, warnings, error in
            if let error = error {
                print(error)
                
            } else if let url = url {
                let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = target.view
                target.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    //mark: share
    let shareAppURL = "https://www.soundbrew.app/ios"
    
    func imageForSharing(_ sound: Sound) -> UIImage {
        let soundArtImage = SoundArtImage(frame: CGRect(x: 0, y: 0, width: 500, height: 610))
        soundArtImage.soundArt.image = sound.artImage
        soundArtImage.soundTitle.text = sound.title
        soundArtImage.artistName.text = sound.artist!.name
        soundArtImage.updateConstraints()
        return soundArtImage.asImage()
    }
    
    func shareToSnapchat(_ sound: Sound) {
        let snapchatImage = imageForSharing(sound)
        let snap = SCSDKNoSnapContent()
        snap.sticker = SCSDKSnapSticker(stickerImage: snapchatImage)
        snap.attachmentUrl = shareAppURL
        let api = SCSDKSnapAPI(content: snap)
        api.startSnapping(completionHandler: { (error: Error?) in
            if let error = error {
                print("Snapchat error: \(error)")
            }
        })
    }
    
    func shareToInstagram(_ sound: Sound) {
        let share = ShareImageInstagram()
        let igImage = imageForSharing(sound)
        share.postToInstagramStories(image: igImage, backgroundTopColorHex: "0x393939" , backgroundBottomColorHex: "0x393939", deepLink: shareAppURL)
    }
    
    func showShareOptions(_ target: UIViewController, sound: Sound) {
        let alertController = UIAlertController (title: "Share this Sound" , message: "To:", preferredStyle: .actionSheet)
        
        let snapchatAction = UIAlertAction(title: "Snapchat", style: .default) { (_) -> Void in
            self.shareToSnapchat(sound)
        }
        alertController.addAction(snapchatAction)
        
        let instagramAction = UIAlertAction(title: "Instagram Stories", style: .default) { (_) -> Void in
            self.shareToInstagram(sound)
        }
        alertController.addAction(instagramAction)
        
        let moreAction = UIAlertAction(title: "Share Link", style: .default) { (_) -> Void in
            self.createDynamicLink("sound", sound: sound, artist: nil, target: target)
        }
        alertController.addAction(moreAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        target.present(alertController, animated: true, completion: nil)
    }
}

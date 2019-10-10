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
import Alamofire
import Kingfisher
import AppCenterAnalytics

class UIElement {
    let topOffset = 10
    let leftOffset = 15
    let rightOffset = -15
    let bottomOffset = -10
    let arrowHeightWidth = 10
    let buttonHeight = 40
    let userImageHeightWidth = 40
    let elementOffset = 5
    let titleLabelFontSize: CGFloat = 25
    let color = Color()
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
    
    func newRootView(_ storyBoard: String, withIdentifier: String) {
        let storyboard = UIStoryboard(name: storyBoard, bundle: nil)
        let initialViewController = storyboard.instantiateViewController(withIdentifier: withIdentifier)
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        appdelegate.window?.rootViewController = initialViewController
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
    
    func signupRequired(_ title: String, message: String, target: UIViewController) {
        let alertController = UIAlertController (title: title, message: message, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Sign Up", style: .default) { (_) -> Void in
            target.performSegue(withIdentifier: "showWelcome", sender: self)
        }
        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Later", style: .cancel, handler: nil)
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
        var textWithNoSpaces = ""
        let textArray = text.components(separatedBy: " ")
        for text in textArray {
            textWithNoSpaces = textWithNoSpaces + text
        }
        
        let textWithWhiteSpaceTrimmed = textWithNoSpaces.trimmingCharacters(
            in: NSCharacterSet.whitespacesAndNewlines
        )
                
        return textWithWhiteSpaceTrimmed.lowercased()
    }
    
    //mark: date and time
    func formatDateAndReturnString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd,yyyy"
        return dateFormatter.string(from: date)
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
            title = sound.title!
            description = "\(sound.title!) by \(sound.artist!.name!)"
            imageURL = sound.artURL!
            objectId = sound.objectId!
            
        } else if let artist = artist {
            objectId = artist.objectId
            description = "Check out my @sound_brew page!"
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
                target.present(activityViewController, animated: true, completion: { () -> Void in
                })
            }
        }
    }
    
    //mark: share
    let shareAppURL = "https://www.soundbrew.app/ios"
    
    func snapchatImageForSharing(_ sound: Sound) -> UIImage {
        let soundArtImage = SnapchatStoriesArtImage(frame: CGRect(x: 0, y: 0, width: 500, height: 150))
        soundArtImage.soundArt.image = sound.artImage
        soundArtImage.soundTitle.text = sound.title
        soundArtImage.artistName.text = sound.artist!.name
        soundArtImage.updateConstraints()
        return soundArtImage.asImage()
    }
    
    func shareToSnapchat(_ sound: Sound) {
        let snapchatImage = snapchatImageForSharing(sound)
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
    
    func instagramImageForSharing(_ sound: Sound) -> UIImage {
        let soundArtImage = InstagramStoriesArtImage(frame: CGRect(x: 0, y: 0, width: 500, height: 610))
        soundArtImage.soundArt.image = sound.artImage
        soundArtImage.soundTitle.text = sound.title
        soundArtImage.artistName.text = sound.artist!.name
        soundArtImage.updateConstraints()
        return soundArtImage.asImage()
    }
    
    func shareToInstagram(_ sound: Sound) {
        let share = ShareImageInstagram()
        let igImage = instagramImageForSharing(sound)
        share.postToInstagramStories(image: igImage, backgroundTopColorHex: "\(color.black())", backgroundBottomColorHex: "\(color.black())", deepLink: shareAppURL)
    }
    
    func showShareOptions(_ target: UIViewController, sound: Sound) {
        let alertController = UIAlertController (title: "Share this Sound" , message: "To:", preferredStyle: .actionSheet)
        
        let snapchatAction = UIAlertAction(title: "Snapchat", style: .default) { (_) -> Void in
            self.shareToSnapchat(sound)
            MSAnalytics.trackEvent("Share", withProperties: ["Button" : "Snapchat", "Description": "User Pressed Share to Snapchat."])
        }
        alertController.addAction(snapchatAction)
        
        let instagramAction = UIAlertAction(title: "Instagram Stories", style: .default) { (_) -> Void in
            self.shareToInstagram(sound)
            MSAnalytics.trackEvent("Share", withProperties: ["Button" : "Instagram Stories", "Description": "User Pressed Share to Instagram."])
        }
        alertController.addAction(instagramAction)
        
        let moreAction = UIAlertAction(title: "Share Link", style: .default) { (_) -> Void in
            self.createDynamicLink("sound", sound: sound, artist: nil, target: target)
            MSAnalytics.trackEvent("Share", withProperties: ["Button" : "More", "Description": "User Pressed More."])
        }
        alertController.addAction(moreAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        target.present(alertController, animated: true, completion: nil)
    }
    
    func sendAlert(_ message: String, toUserId: String) {
        Alamofire.request("https://soundbrew.herokuapp.com/notifications/pXLmtBKxGzgzdnDU", method: .get, parameters: ["message": message, "userId": toUserId], encoding: URLEncoding.default).validate().response{response in
            //print(response.response as Any)
        }
    }
    
    func newArtistObject(_ user: PFObject) -> Artist {
        let username = user["username"] as? String
        
        var email: String?
        if user.objectId! == PFUser.current()!.objectId {
            email = user["email"] as? String
        }
        
        let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: username, website: nil, bio: nil, email: email, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil)
        
        if let name = user["artistName"] as? String {
            artist.name = name
        }
        
        if let username = user["username"] as? String {
            artist.username = username
        }
        
        if let city = user["city"] as? String {
            artist.city = city
        }
        
        if let userImageFile = user["userImage"] as? PFFileObject {
            artist.image = userImageFile.url!
        }
        
        if let bio = user["bio"] as? String {
            artist.bio = bio
        }
        
        if let website = user["website"] as? String {
            artist.website = website
        }
        
        return artist 
    }
    
    func newSoundObject(_ object: PFObject) -> Sound {
        let sound = Sound(objectId: nil, title: nil, artURL: nil, artImage: nil, artFile: nil, tags: nil, createdAt: nil, plays: nil, audio: nil, audioURL: nil, relevancyScore: 0, audioData: nil, artist: nil, tmpFile: nil, tips: nil, tippers: nil, isDraft: nil)
        
        if let createdAt = object.createdAt {
            sound.createdAt = createdAt
        }
        
        if let objectId = object.objectId {
            sound.objectId = objectId
        }
        
        let audio = object["audioFile"] as! PFFileObject
        sound.audio = audio
        sound.audioURL = audio.url!
        
        if let title = object["title"] as? String {
            if title == "" {
                sound.title = "Untitled"
            } else {
               sound.title = title
            }
        } else {
            sound.title = "Untitled"
        }
        
        if let art = object["songArt"] as? PFFileObject {
            sound.artURL = art.url
            sound.artFile = art 
        }
        
        if let tags = object["tags"] as? Array<String> {
            sound.tags = tags
        }
        
        if let plays = object["plays"] as? Int {
            sound.plays = plays
        }
        
        if let tips = object["tips"] as? Int {
            sound.tips = tips
        }
        
        if let tippers = object["tippers"] as? Int {
            sound.tippers = tippers 
        }
        
        let userId = object["userId"] as! String
        let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: "", website: "", bio: "", email: "", isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil)
        
        sound.artist = artist
        return sound
    }
    
    func convertCentsToDollarsAndReturnString(_ cents: Int, currency: String) -> String {
        let centsToDollars = Double(cents) / 100.00
        let dollarsProperlyFormattedAsString = String(format: "%.2f", centsToDollars)
        return "\(currency)\(dollarsProperlyFormattedAsString)"
    }
}

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
import SCSDKCreativeKit
import ShareInstagram
import Alamofire
import Kingfisher
import LinkPresentation

class UIElement {
    let topOffset = 10
    let leftOffset = 15
    let rightOffset = -15
    let bottomOffset = -10
    
    let bottomButtonOffset = -20
    let topButtonOffset = 20
    
    let arrowHeightWidth = 10
    let buttonHeight = 40
    let userImageHeightWidth = 40
    let elementOffset = 5
    let titleLabelFontSize: CGFloat = 25
    let color = Color()
    let mainFont = "HelveticaNeue"
    let d_innovatorObjectId = "AWKPPDI4CB"
    let localizedCollectors = NSLocalizedString("collectos", comment: "")
    let localizedMood = NSLocalizedString("mood", comment: "")
    let localizedActivity = NSLocalizedString("activity", comment: "")
    let localizedMore = NSLocalizedString("more", comment: "")
    let localizedOops = NSLocalizedString("oops", comment: "")
    
    let soundbrewSocialHandle = "@sound_brew"
    
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
        return(target.navigationController?.navigationBar.frame.height ?? 0.0) + CGFloat(topOffset)
    }
    
    func newRootView(_ storyBoard: String, withIdentifier: String) {
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: storyBoard, bundle: nil)
            let initialViewController = storyboard.instantiateViewController(withIdentifier: withIdentifier)
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            appdelegate.window?.rootViewController = initialViewController
        }
    }
    
    func showAlert(_ title: String, message: String, target: UIViewController) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            target.present(alert, animated: true, completion: nil)
        }
    }
    
    func permissionDenied(_ title: String, message: String, target: UIViewController) {
        let alertController = UIAlertController (title: title, message: message, preferredStyle: .alert)
        let localizedGoToSettings = NSLocalizedString("goToSettings", comment: "")
        let settingsAction = UIAlertAction(title: localizedGoToSettings, style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: nil)
            }
        }
        alertController.addAction(settingsAction)
        let localizedCancel = NSLocalizedString("cancel", comment: "")
        let cancelAction = UIAlertAction(title: localizedCancel, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        target.present(alertController, animated: true, completion: nil)
    }
    
    func signupRequired(_ title: String, message: String, target: UIViewController) {
        let alertController = UIAlertController (title: title, message: message, preferredStyle: .actionSheet)
        
        let localizedSignup = NSLocalizedString("signup", comment: "")
        let settingsAction = UIAlertAction(title: localizedSignup, style: .default) { (_) -> Void in
            self.newRootView("NewUser", withIdentifier: "welcome")
        }
        alertController.addAction(settingsAction)
        let localizedLater = NSLocalizedString("later", comment: "")
        let cancelAction = UIAlertAction(title: localizedLater, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        target.present(alertController, animated: true, completion: nil)
    }
    
    func welcomeAlert(_ message: String, target: UIViewController) {
        let localizedWelcomeToSoundbrew = NSLocalizedString("welcomeToSoundbrew", comment: "")
        let alertController = UIAlertController (title: localizedWelcomeToSoundbrew, message: message, preferredStyle: .actionSheet)
        
        let localizedSignup = NSLocalizedString("signup", comment: "")
        let settingsAction = UIAlertAction(title: localizedSignup, style: .default) { (_) -> Void in
            self.newRootView("NewUser", withIdentifier: "welcome")
        }
        alertController.addAction(settingsAction)
        
        let localizedLater = NSLocalizedString("later", comment: "")
        let cancelAction = UIAlertAction(title: localizedLater, style: .cancel) { (_) -> Void in
            self.newRootView("Main", withIdentifier: "tabBar")
        }
        alertController.addAction(cancelAction)
        
        target.present(alertController, animated: true, completion: nil)
    }
    
    func setUserDefault(_ value: Any?, key: String) {
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
        DispatchQueue.main.async {
            UITextField.attributedPlaceholder = NSAttributedString(string: text,
                                                                   attributes:[NSAttributedString.Key.foregroundColor: self.color.red()])
            UITextField.text = ""
        }
    }
    
    func cleanUpText(_ text: String, shouldLowercaseText: Bool) -> String {
        var textWithNoSpaces = ""
        let textArray = text.components(separatedBy: " ")
        for text in textArray {
            textWithNoSpaces = textWithNoSpaces + text
        }
        
        let textWithWhiteSpaceTrimmed = textWithNoSpaces.trimmingCharacters(
            in: NSCharacterSet.whitespacesAndNewlines
        )
        
        if shouldLowercaseText {
            return textWithWhiteSpaceTrimmed.lowercased()
        }
                
        return textWithWhiteSpaceTrimmed
    }
    
    //mark: date and time
    func formatDateAndReturnString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        return dateFormatter.string(from: date)
    }
    
    func formatTime(_ durationInSeconds: Double ) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        let formattedString = formatter.string(from: durationInSeconds)!
        return formattedString
    }
    
    func getSoundbrewURL(_ objectId: String, path: String) -> URL? {
        let url = URL(string: "https://www.soundbrew.app/\(path)/\(objectId)")
        if url != nil {
           return url
        }
        return nil
    }
    
    func createDynamicLink(_ sound: Sound?, artist: Artist?, playlist: Playlist?, target: UIViewController) {
        var url: URL?
        
        if let sound = sound {
            url = self.getSoundbrewURL(sound.objectId!, path: "s")
        } else if let artist = artist {
            url = URL(string: "https://www.soundbrew.app/\(artist.username!)")
        } else if let playlist = playlist {
            url = self.getSoundbrewURL("\(playlist.objectId ?? "")", path: "p")
        }
                
        if let url = url {
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = target.view
            target.present(activityViewController, animated: true, completion: { () -> Void in
            })
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
        DispatchQueue.main.async {
            let localizedShareThisSound = NSLocalizedString("shareThisSound", comment: "")
            let localizedTo = NSLocalizedString("to", comment: "")
            let alertController = UIAlertController (title: localizedShareThisSound , message: "\(localizedTo):", preferredStyle: .actionSheet)
            
            let snapchatAction = UIAlertAction(title: "Snapchat", style: .default) { (_) -> Void in
                self.shareToSnapchat(sound)
            }
            alertController.addAction(snapchatAction)
            
            let instagramAction = UIAlertAction(title: "Instagram Stories", style: .default) { (_) -> Void in
                self.shareToInstagram(sound)
            }
            alertController.addAction(instagramAction)
            
            let addToPlaylistAction = UIAlertAction(title: "Add To Playlist", style: .default) { (_) -> Void in
                let modal = PlaylistViewController()
                modal.sound = sound
                target.present(modal, animated: true, completion: nil)
            }
            alertController.addAction(addToPlaylistAction)
            
            let localizedMoreOptions = NSLocalizedString("moreOptions", comment: "")
            let moreAction = UIAlertAction(title: localizedMoreOptions, style: .default) { (_) -> Void in
                self.createDynamicLink(sound, artist: nil, playlist: nil, target: target)
            }
            alertController.addAction(moreAction)
            
            let localizedCancel = NSLocalizedString("cancel", comment: "")
            let cancelAction = UIAlertAction(title: localizedCancel, style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            target.present(alertController, animated: true, completion: nil)
        }
    }
    
    func sendAlert(_ message: String, toUserId: String, shouldIncludeName: Bool) {
        let artist = Customer.shared.artist
        var name = ""
        if shouldIncludeName {
            if let username = artist?.username {
                name = username
            } else if let displayName = artist?.name {
                name = displayName
            }
        }

        let alertMessage = "\(name) \(message)"
        AF.request("https://soundbrew.herokuapp.com/notifications/pXLmtBKxGzgzdnDU", method: .get, parameters: ["message": alertMessage, "userId": toUserId], encoding: URLEncoding.default).validate().response{response in
        }
    }
    
    func newArtistObject(_ user: PFObject) -> Artist {
        let artist = Artist(objectId: user.objectId, name: nil, city: nil, image: nil, isVerified: nil, username: nil, website: nil, bio: nil, email: nil, isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, account: nil)
        
        if PFUser.current() != nil {
            if user.objectId! == PFUser.current()!.objectId {
                artist.email = user["email"] as? String
            }
        }
        
        if let name = user["artistName"] as? String {
            artist.name = name
        }
        
        if let username = user["username"] as? String {
            if !username.contains("@") {
                artist.username = "\(username)"
            }
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
        
        var account: Account?
        
        if let accountId = user["accountId"] as? String, !accountId.isEmpty {
            account = Account(id: accountId, priceId: nil)
        }
        
        if let priceId = user["priceId"] as? String, !priceId.isEmpty {
            account?.priceId = priceId
        }
        
        artist.account = account
        
        return artist 
    }
    
    func newSoundObject(_ object: PFObject) -> Sound {
        let sound = Sound(objectId: nil, title: nil, artImage: nil, artFile: nil, tags: nil, createdAt: nil, playCount: nil, audio: nil, audioURL: nil, audioData: nil, artist: nil, tmpFile: nil, tipCount: nil, currentUserDidLikeSong: nil, isDraft: nil, isNextUpToPlay: nil, creditCount: nil, commentCount: nil, isFeatured: nil, isExclusive: nil)
        
        if let createdAt = object.createdAt {
            sound.createdAt = createdAt
        }
        
        if let objectId = object.objectId {
            sound.objectId = objectId
        }
        
        if let audio = object["audioFile"] as? PFFileObject {
            sound.audio = audio
            sound.audioURL = audio.url!
        }
        
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
            sound.artFile = art 
        }
        
        sound.tags = object["tags"] as? Array<String>
        sound.playCount = object["plays"] as? Int
        sound.tipCount = object["tippers"] as? Int
        sound.commentCount = object["comments"] as? Int
        sound.creditCount = object["credits"] as? Int
        sound.isDraft = object["isDraft"] as? Bool
        sound.isFeatured = object["isFeatured"] as? Bool
        sound.isExclusive = object["isExclusive"] as? Bool
        
        let userId = object["userId"] as! String
        let artist = Artist(objectId: userId, name: nil, city: nil, image: nil, isVerified: nil, username: "", website: "", bio: "", email: "", isFollowedByCurrentUser: nil, followerCount: nil, followingCount: nil, customerId: nil, balance: nil, earnings: nil, friendObjectIds: nil, account: nil)
        
        sound.artist = artist
        return sound
    }
    
    func convertCentsToDollarsAndReturnString(_ cents: Int, currency: String) -> String {
        let centsToDollars = Double(cents) / 100.00
        let dollarsProperlyFormattedAsString = String(format: "%.2f", centsToDollars)
        return "\(currency)\(dollarsProperlyFormattedAsString)"
    }
    
    func addTitleView(_ title: String, target: UIViewController) {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 50))
        label.text = title
        label.textColor = .white
        label.font = UIFont(name: "\(self.mainFont)-bold", size: 30)
        target.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: label)
    }
    
    //mark: tableView Cell UI components
    func soundbrewImageView(_ image: UIImage?, cornerRadius: CGFloat?, backgroundColor: UIColor?) -> UIImageView {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFill
        if let image = image {
            imageView.image = image
        }
        
        if let cornerRadius = cornerRadius {
            imageView.layer.cornerRadius = cornerRadius
            imageView.clipsToBounds = true
        }
        
        if let backgroundColor = backgroundColor {
            imageView.backgroundColor = backgroundColor
        }
        
        return imageView
    }
    
    func soundbrewButton(_ title: String?, shouldShowBorder: Bool, backgroundColor: UIColor, image: UIImage?, titleFont: UIFont?, titleColor: UIColor, cornerRadius: CGFloat?) -> UIButton {
        let button = UIButton()
        button.setTitleColor(titleColor, for: .normal)
        button.backgroundColor = backgroundColor
        button.contentMode = .scaleAspectFill
        button.isOpaque = true
        
        if let title = title {
            button.setTitle(title, for: .normal)
        }
        
        if shouldShowBorder {
            button.layer.borderWidth = 1
        }
        
        if let cornerRadius = cornerRadius {
            button.layer.cornerRadius = cornerRadius
        }
        
        button.clipsToBounds = true

        if let image = image {
            button.setImage(image, for: .normal)
        }
        
        if let titleFont = titleFont {
            button.titleLabel?.font = titleFont
        }
    
        return button
    }
    
    func soundbrewLabel(_ text: String?, textColor: UIColor, font: UIFont, numberOfLines: Int) -> UILabel {
        let label = UILabel()
        if let text = text {
            label.text = text
        }
        label.font = font
        label.numberOfLines = numberOfLines
        label.textColor = textColor
        label.isOpaque = true
        return label
    }
    
    func soundbrewTextInput(_ keyboardType: UIKeyboardType, isSecureTextEntry: Bool) -> UITextField{
        let textField = UITextField()
        textField.borderStyle = .none
        textField.font = UIFont(name: "\(self.mainFont)", size: 17)
        textField.textColor = .white
        textField.clearButtonMode = .whileEditing
        textField.tintColor = .white
        textField.keyboardType = keyboardType
        textField.isSecureTextEntry = isSecureTextEntry
        return textField
    }
    
    func soundbrewDividerLine() -> UIView {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderColor = UIColor.darkGray.cgColor
        view.layer.borderWidth = 0.5
        view.clipsToBounds = true
        return view
    }
        
    func addSubViewControllerTopView(_ target: UIViewController, action: Selector, doneButtonTitle: String, title: String) -> (UIButton, UIButton, UIView) {
        let cancelButton = UIButton()
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(target, action: action, for: .touchUpInside)
        cancelButton.isOpaque = true
        cancelButton.tag = 0
        target.view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(target.view).offset(self.topOffset)
            make.left.equalTo(target.view).offset(self.leftOffset)
        }
        
        let titleLabel = UILabel()
        titleLabel.textColor = .white
        titleLabel.text = title
        titleLabel.font = UIFont(name: "\(self.mainFont)-Bold", size: 15)
        titleLabel.textAlignment = .center
        titleLabel.isOpaque = true
        target.view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(target.view)
            make.centerY.equalTo(cancelButton)
        }
        
        let doneButton = UIButton()
        doneButton.setTitle(doneButtonTitle, for: .normal)
        doneButton.addTarget(target, action: action, for: .touchUpInside)
        doneButton.isOpaque = true
        doneButton.tag = 1
        target.view.addSubview(doneButton)
        doneButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(target.view).offset(self.topOffset)
            make.right.equalTo(target.view).offset(self.rightOffset)
        }
        
        let dividerLine = UIView()
        dividerLine.layer.borderWidth = 1
        dividerLine.layer.borderColor = UIColor.darkGray.cgColor
        target.view.addSubview(dividerLine)
        dividerLine.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(0.5)
            make.top.equalTo(cancelButton.snp.bottom).offset(self.topOffset)
            make.left.equalTo(target.view).offset(self.leftOffset)
            make.right.equalTo(target.view).offset(self.rightOffset)
        }
        
        //return view so that the next view can set constraints 
        return (cancelButton, doneButton, dividerLine)
    }
}

public extension UIDevice {
static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                 return "iPod touch (5th generation)"
            case "iPod7,1":                                 return "iPod touch (6th generation)"
            case "iPod9,1":                                 return "iPod touch (7th generation)"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone8,4":                               return "iPhone SE"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPhone12,1":                              return "iPhone 11"
            case "iPhone12,3":                              return "iPhone 11 Pro"
            case "iPhone12,5":                              return "iPhone 11 Pro Max"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad (3rd generation)"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad (4th generation)"
            case "iPad6,11", "iPad6,12":                    return "iPad (5th generation)"
            case "iPad7,5", "iPad7,6":                      return "iPad (6th generation)"
            case "iPad7,11", "iPad7,12":                    return "iPad (7th generation)"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad11,4", "iPad11,5":                    return "iPad Air (3rd generation)"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad mini 4"
            case "iPad11,1", "iPad11,2":                    return "iPad mini (5th generation)"
            case "iPad6,3", "iPad6,4":                      return "iPad Pro (9.7-inch)"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro (12.9-inch)"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro (10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad Pro (11-inch)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad Pro (12.9-inch) (3rd generation)"
            case "AppleTV5,3":                              return "Apple TV"
            case "AppleTV6,2":                              return "Apple TV 4K"
            case "AudioAccessory1,1":                       return "HomePod"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple TV 4"
            case "AppleTV6,2": return "Apple TV 4K"
            case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #endif
        }

        return mapToDevice(identifier: identifier)
    }()
}

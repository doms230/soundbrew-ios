//
//  AppDelegate.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/25/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved. applinks:soundbrew.page.link

import UIKit
import Parse
import NVActivityIndicatorView
import UserNotifications
import AppCenter
import AppCenterCrashes
import AppCenterAnalytics
import StoreKit
import Firebase
import Stripe
import GoogleSignIn
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PFUserAuthenticationDelegate, GIDSignInDelegate {
    func restoreAuthentication(withAuthData authData: [String : String]?) -> Bool {
        return true 
    }
    var window: UIWindow?
    let uiElement = UIElement()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UITabBar.appearance().barTintColor = .black
        UITabBar.appearance().tintColor = .white
        UITabBar.appearance().backgroundColor = .black
                        
        MSAppCenter.start("b023d479-f013-42e4-b5ea-dcb1e97fe204", withServices:[MSCrashes.self, MSAnalytics.self])
        
        GIDSignIn.sharedInstance().clientID = "510041293074-8agh8fcqoiqjh3f35glov6b16s5lvcl9.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().delegate = self

                
        FirebaseApp.configure()

        //usrname: testaccount
        //password: asdf
        let testStripeKey = "pk_test_0wWjINHvhtgzckFeNxkN7jA400SRMuoO6r"
        //let liveStripeKey = "pk_live_ZD56KwV1HfBk9kwDUOzdjjEc00u0dPBHk6"
        
        Stripe.setDefaultPublishableKey(testStripeKey)
        let config = STPPaymentConfiguration.shared()
      //  config.publishableKey = testStripeKey
        config.appleMerchantIdentifier = "merchant.com.soundbrew.soundbrew-artists"
        config.companyName = "Soundbrew, Inc."
        
        let configuration = ParseClientConfiguration {
            $0.applicationId = "A839D96FA14FCC48772EB62B99FA1"
            $0.clientKey = "2D4CFA43539F89EF57F4FA589BDCE"
            $0.server = "https://www.soundbrew.app/parse"
           // $0.server = "http://192.168.200.8:3000/parse"
        }
        Parse.initialize(with: configuration)
        
        PFUser.register(self, forAuthType: "apple")
        PFUser.register(self, forAuthType: "google")
        
        NVActivityIndicatorView.DEFAULT_TYPE = .lineScale
        NVActivityIndicatorView.DEFAULT_COLOR = Color().uicolorFromHex(0xa9c5d0)
        NVActivityIndicatorView.DEFAULT_BLOCKER_SIZE = CGSize(width: 60, height: 60)
        NVActivityIndicatorView.DEFAULT_BLOCKER_BACKGROUND_COLOR = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        registerForRemoteNotification()
        
        if let objectId = PFUser.current()?.objectId {
            Customer.shared.getCustomer(objectId)
            FileManager.default.clearTmpDirectory()
        } else {
            let newUserController = UIStoryboard(name: "NewUser", bundle: nil).instantiateViewController(withIdentifier: "welcome")
            window!.rootViewController = newUserController
        }        
        
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
            if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
                let url = userActivity.webpageURL!
                
                let pathComponents = url.pathComponents
                
                if url.host == "www.soundbrew.app" || url.host == "soundbrew.app" {
                    if pathComponents.contains("s") {
                       self.receivedPostId(url.lastPathComponent)

                    } else if pathComponents.contains("u") {
                        self.receivedUserId(url.lastPathComponent)
                    } else if pathComponents.contains("p") {
                        self.receivedPlaylistId(url.lastPathComponent)
                    } else {
                        self.receivedUsername(url.lastPathComponent)
                    }
                } else {
                //return handleDynamicLink(userActivity)
            }
        }
        
        return false
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let installation = PFInstallation.current()
        installation?.setDeviceTokenFrom(deviceToken)
        installation?.badge = 0
        installation?.saveEventually()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if application.applicationState == UIApplication.State.background {
            PFPush.handle(userInfo)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        PFPush.handle(notification.request.content.userInfo)
        completionHandler(.alert)
    }
    
    func registerForRemoteNotification() {
        let center  = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
            if granted && error == nil {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func receivedUserId(_ userId: String) {
        print(userId)
        self.uiElement.setUserDefault(userId, key: "receivedUserId")
        showMainViewController(1)
    }
    
    func receivedUsername(_ username: String) {
        self.uiElement.setUserDefault(username, key: "receivedUsername")
        showMainViewController(1)
    }
    
    func receivedPostId(_ soundId: String) {
        self.uiElement.setUserDefault(soundId, key: "receivedSoundId")
        showMainViewController(1)
    }
    
    func receivedPlaylistId(_ playlistId: String) {
        self.uiElement.setUserDefault(playlistId, key: "receivedPlaylistId")
        showMainViewController(1)
    }
    
    func showMainViewController(_ selectedIndex: Int) {
        let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "tabBar") as! UITabBarController
        tabBarController.selectedIndex = selectedIndex
        window!.rootViewController = tabBarController
    }
    
    //Gooogle
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
      return GIDSignIn.sharedInstance().handle(url)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
      if let error = error {
        if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
          print("The user has not signed in before or they have since signed out.")
        } else {
          print("\(error.localizedDescription)")
        }
        return
      }
        
        if let userId = user.userID, let idToken = user.authentication.idToken {
            PFUser.logInWithAuthType(inBackground: "google", authData: ["id": "\(userId)", "id_token": "\(idToken)"]).continueOnSuccessWith(block: {
                (ignored: BFTask!) -> AnyObject? in
               
                let parseUser = PFUser.current()
                let installation = PFInstallation.current()
                installation?["user"] = parseUser
                installation?["userId"] = parseUser?.objectId
                installation?.saveEventually()
                
                if let isNew = parseUser?.isNew, isNew, let givenName = user.profile.givenName, let email = user.profile.email {
                    if let imageURL = user.profile.imageURL(withDimension: 500) {
                        self.downloadImageAndUpdateUserInfo(givenName, email: email, imageURL: imageURL)
                    } else {
                        self.updateUserInfo(givenName, email: email, image: nil)
                    }
                } else {
                    if let userId = PFUser.current()?.objectId {
                        Customer.shared.getCustomer(userId)
                    }
                     self.uiElement.newRootView("Main", withIdentifier: "tabBar")
                }
                return AnyObject.self as AnyObject
            })
        }
    }
    
    func downloadImageAndUpdateUserInfo(_ givenName: String, email: String, imageURL: URL) {
        AF.download(imageURL).responseData { response in
            if let data = response.value, let newProfileImageFile = PFFileObject(name: "profile_ios.jpeg", data: data) {
                newProfileImageFile.saveInBackground {
                  (success: Bool, error: Error?) in
                    if let error = error?.localizedDescription {
                        print("dowloading Image error: \(error)")
                    }
                    if success {
                        self.updateUserInfo(givenName, email: email, image: newProfileImageFile)
                    } else {
                        self.updateUserInfo(givenName, email: email, image: nil)
                    }
                }
            }
        }
    }
    
    func updateUserInfo(_ name: String, email: String, image: PFFileObject?) {
        if let currentUserId = PFUser.current()?.objectId {
            let query = PFQuery(className: "_User")
            query.getObjectInBackground(withId: currentUserId) {
                (user: PFObject?, error: Error?) -> Void in
                if let error = error {
                    print(error)
                    
                } else if let user = user {
                    user["artistName"] = name
                    user["email"] = email
                    if let image = image {
                        user["userImage"] = image
                    }
                    user.saveEventually {
                        (success: Bool, error: Error?) in
                        self.uiElement.newRootView("Main", withIdentifier: "tabBar")
                    }
                }
            }
        }
    }
    
}

extension FileManager {
    func clearTmpDirectory() {
        do {
            let tmpDirURL = FileManager.default.temporaryDirectory
            let tmpDirectory = try contentsOfDirectory(atPath: tmpDirURL.path)
            try tmpDirectory.forEach { file in
                let fileUrl = tmpDirURL.appendingPathComponent(file)
                try removeItem(atPath: fileUrl.path)
            }
        } catch let error {
           print(error)
        }
    }
}

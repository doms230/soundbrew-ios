//
//  AppDelegate.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/25/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved. applinks:soundbrew.page.link

import UIKit
import Parse
import UserNotifications
import AppCenter
import AppCenterCrashes
import AppCenterAnalytics
import StoreKit
import Firebase
import Stripe
import GoogleSignIn

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
                
        FirebaseApp.configure()

        //usrname: testaccount
        //password: asdf
        //change publishableable key for creating a file on Account.Swift
        
        Stripe.setDefaultPublishableKey(self.uiElement.liveStripeKey)
        let config = STPPaymentConfiguration.shared()
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
        
        registerForRemoteNotification()
        
        if let objectId = PFUser.current()?.objectId {
            Customer.shared.getCurrentUserInfo(objectId)
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
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        //implemented in NewEmailViewController 
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

//
//  AppDelegate.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/25/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.

import UIKit
import Parse
import NVActivityIndicatorView
import UserNotifications
import AppCenter
import AppCenterCrashes
import StoreKit
import Firebase
import TwitterKit
import FacebookCore
import Stripe

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UITabBar.appearance().barTintColor = .white
        UITabBar.appearance().tintColor = Color().black()
        
        MSAppCenter.start("b023d479-f013-42e4-b5ea-dcb1e97fe204", withServices:[MSCrashes.self])
        
        FirebaseApp.configure()
        
        SDKApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        let config = STPPaymentConfiguration.shared()
        config.publishableKey = "pk_test_cD418dWcbEdrWlmXEGvSyrU200NEOsClw8"
        config.appleMerchantIdentifier = "merchant.com.soundbrew.soundbrew-artists"
        config.companyName = "Soundbrew Artists"
        
        let configuration = ParseClientConfiguration {
            $0.applicationId = "A839D96FA14FCC48772EB62B99FA1"
            $0.clientKey = "2D4CFA43539F89EF57F4FA589BDCE"
            $0.server = "https://www.soundbrew.app/parse"
        }
        Parse.initialize(with: configuration)

        NVActivityIndicatorView.DEFAULT_TYPE = .lineScale
        NVActivityIndicatorView.DEFAULT_COLOR = Color().uicolorFromHex(0xa9c5d0)
        NVActivityIndicatorView.DEFAULT_BLOCKER_SIZE = CGSize(width: 60, height: 60)
        NVActivityIndicatorView.DEFAULT_BLOCKER_BACKGROUND_COLOR = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        registerForRemoteNotification()
        
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        let handled = DynamicLinks.dynamicLinks().handleUniversalLink(userActivity.webpageURL!) { (dynamiclink, error) in
            if let error = error {
                print("dynamic link error: \(error.localizedDescription)")
                
            } else if let url = dynamiclink?.url {
                if let pathComponents = dynamiclink?.url?.pathComponents {
                    if pathComponents.contains("sound") {
                        self.playSound(url: url)
                        
                    } else if pathComponents.contains("profile") {
                        self.loadUserInfoFromCloud(url.lastPathComponent)
                    }
                }
            }
        }
        
        return handled
    }
    
    //called if user is opening for the first time
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        
        if url.absoluteString.starts(with: "soundbrew") {
            return application(app, open: url,
                               sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                               annotation: "")
            
        } else if url.absoluteString.starts(with: "fb") {
            return SDKApplicationDelegate.shared.application(app, open: url, options: options)
            
        } else {
            return TWTRTwitter.sharedInstance().application(app, open: url, options: options)
        }
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
            if let pathComponents = dynamicLink.url?.pathComponents {
                if pathComponents.contains("sound") {
                    self.playSound(url: url)
                    UIElement().setUserDefault("receivedSoundId", value: url.lastPathComponent)
                    
                } else if pathComponents.contains("profile") {
                    self.loadUserInfoFromCloud(url.lastPathComponent)
                }
            }
            
            return true
            
        } else {
            print("first open: couldn't open dynamic link")
        }
        return false
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        let installation = PFInstallation.current()
        installation?.badge = 0
        installation?.saveEventually()
        
        //doing this to insure that if ad needs to be shown, the ad is attached to the right view controller
        //won't show if ad is attached to view controller that isn't currently active...
        
        let player = Player.sharedInstance
        player.target = self.window?.rootViewController
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let installation = PFInstallation.current()
        installation?.setDeviceTokenFrom(deviceToken)
        installation?.saveEventually()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if application.applicationState == UIApplication.State.background {
            PFPush.handle(userInfo)
        }
    }
    
    @available(iOS 10.0, *)
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
    
    func playSound(url: URL) {
        let player = Player.sharedInstance
        let objectId = url.lastPathComponent
        player.loadDynamicLinkSound(objectId)
        showChooseTagsViewController()
    }
    
    func loadUserInfoFromCloud(_ userId: String) {
        UIElement().setUserDefault("receivedUserId", value: userId)
        showChooseTagsViewController()
    }
    
    func showChooseTagsViewController() {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "main")
        self.window?.rootViewController = initialViewController
        self.window?.makeKeyAndVisible()
    }
}


//
//  AppDelegate.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/25/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
// "${PODS_ROOT}/Fabric/run"
// $(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)

import UIKit
import Parse
import NVActivityIndicatorView
import UserNotifications
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import StoreKit
import Firebase
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UITabBar.appearance().barTintColor = .white
        UITabBar.appearance().tintColor = Color().black()
        
        MSAppCenter.start("b023d479-f013-42e4-b5ea-dcb1e97fe204", withServices:[MSAnalytics.self, MSCrashes.self])
        
        FirebaseApp.configure()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
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
        
        /*if PFUser.current() == nil {
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "welcome")
            window?.rootViewController = controller
            
        } else {
            print("called this")
        }*/
        
       // SKPaymentQueue.default().add(self)
       //Payment.shared.loadSubscriptionOptions()
        
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
        
        return application(app, open: url,
                           sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                           annotation: "")
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
            if let pathComponents = dynamicLink.url?.pathComponents {
                if pathComponents.contains("sound") {
                    self.playSound(url: url)
                    
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
}

extension AppDelegate: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue,
                      updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                handlePurchasingState(for: transaction, in: queue)
            case .purchased:
                handlePurchasedState(for: transaction, in: queue)
            case .restored:
                handleRestoredState(for: transaction, in: queue)
            case .failed:
                handleFailedState(for: transaction, in: queue)
            case .deferred:
                handleDeferredState(for: transaction, in: queue)
            }
        }
    }
    
    func handlePurchasingState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        print("User is attempting to purchase product id: \(transaction.payment.productIdentifier)")
    }
    
    func handlePurchasedState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        print("User purchased product id: \(transaction.payment.productIdentifier)")
        //queue.finishTransaction(transaction)
    }
    
    func handleRestoredState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        print("Purchase restored for product id: \(transaction.payment.productIdentifier)")
    }
    
    func handleFailedState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        print("Purchase failed for product id: \(transaction.payment.productIdentifier)")
    }
    
    func handleDeferredState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        print("Purchase deferred for product id: \(transaction.payment.productIdentifier)")
    }
    
    func playSound(url: URL) {
        let player = Player.sharedInstance
        let objectId = url.lastPathComponent
        player.loadDynamicLinkSound(objectId)
    }
    
    func loadUserInfoFromCloud(_ userId: String) {
        if let tabBarController = self.window?.rootViewController as? UITabBarController {
            UIElement().setUserDefault("receivedUserId", value: userId)
            let navigationController = tabBarController.selectedViewController as? UINavigationController
            let viewController = navigationController?.topViewController
            viewController!.performSegue(withIdentifier: "showProfile", sender: viewController)
        }
    }
}


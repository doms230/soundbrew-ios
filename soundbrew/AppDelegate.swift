//
//  AppDelegate.swift
//  soundbrew
//
//  Created by Dominic  Smith on 9/25/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import Firebase
import NVActivityIndicatorView

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UITabBar.appearance().barTintColor = Color().black()
        UITabBar.appearance().tintColor = .white

        //Parse
        let configuration = ParseClientConfiguration {
            $0.applicationId = "A839D96FA14FCC48772EB62B99FA1"
            $0.clientKey = "2D4CFA43539F89EF57F4FA589BDCE"
            $0.server = "https://soundbrew.herokuapp.com/parse"
        }
        Parse.initialize(with: configuration)
        
        //Google
        FirebaseApp.configure()
        GADMobileAds.configure(withApplicationID: "ca-app-pub-9150756002517285~9630230904")

        NVActivityIndicatorView.DEFAULT_TYPE = .ballScaleMultiple
        NVActivityIndicatorView.DEFAULT_COLOR = Color().primary()
        NVActivityIndicatorView.DEFAULT_BLOCKER_SIZE = CGSize(width: 60, height: 60)
        NVActivityIndicatorView.DEFAULT_BLOCKER_BACKGROUND_COLOR = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        return true
    }
}


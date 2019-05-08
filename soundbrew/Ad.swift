//
//  Ad.swift
//  soundbrew
//
//  Created by Dominic  Smith on 4/30/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import Foundation
import GoogleMobileAds

class Ad: NSObject, GADInterstitialDelegate {
    var player: Player!
    var interstitial: GADInterstitial!
    var secondsPlayedSinceLastAd = 0
    //let fifteenMinutesInSeconds = 5
    let fifteenMinutesInSeconds = 900
    
    init(player: Player!) {
        super.init()
        interstitial = createAndLoadInterstitial()
        self.player = player
        if let secondsPlayedSinceLastAd = UIElement().getUserDefault("secondsPlayedSinceLastAd") as? Int {
            self.secondsPlayedSinceLastAd = secondsPlayedSinceLastAd
        }
    }
    
    func createAndLoadInterstitial() -> GADInterstitial {
        let interstitial = GADInterstitial(adUnitID: "ca-app-pub-3940256099942544/4411468910")
        interstitial.delegate = self
        interstitial.load(GADRequest())
        return interstitial
    }

    func showAd(_ target: UIViewController) {
        if interstitial.isReady {
            interstitial.present(fromRootViewController: target)
            
        } else {
            let extraTimeForAdToLoad = 60
            secondsPlayedSinceLastAd = secondsPlayedSinceLastAd - extraTimeForAdToLoad
            player.play()
        }
    }
    
    /// Tells the delegate an ad request failed.
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print("interstitial:didFailToReceiveAdWithError: \(error.localizedDescription)")
        player.play()
        interstitial = createAndLoadInterstitial()
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        secondsPlayedSinceLastAd = 0
        UIElement().setUserDefault("secondsPlayedSinceLastAd", value: secondsPlayedSinceLastAd)
        player.play()
        interstitial = createAndLoadInterstitial()
    }
}
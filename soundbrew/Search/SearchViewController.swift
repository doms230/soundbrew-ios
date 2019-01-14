//
//  SearchViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 1/8/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class SearchViewController: ButtonBarPagerTabStripViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // change selected bar color
        settings.style.buttonBarBackgroundColor = .white
        settings.style.buttonBarItemBackgroundColor = .white
        settings.style.selectedBarBackgroundColor = Color().blue()
        settings.style.buttonBarItemFont = .boldSystemFont(ofSize: 14)
        settings.style.selectedBarHeight = 2.0
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarItemTitleColor = .black
        settings.style.buttonBarItemsShouldFillAvailableWidth = true
        settings.style.buttonBarLeftContentInset = 0
        settings.style.buttonBarRightContentInset = 0
        
        edgesForExtendedLayout = []
        //edgesForExtendedLayout makes navi and tab bar darker or shows what's behind... makes it no translucent
        self.navigationController?.navigationBar.isTranslucent = false
        self.tabBarController?.tabBar.isTranslucent = false
        
        changeCurrentIndexProgressive = { [weak self] (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = .black
            newCell?.label.textColor = Color().blue()
        }
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        
        let genreChild = TagsViewController(itemInfo: "Genre")
        let cityChild = TagsViewController(itemInfo: "City")
        let moodChild = TagsViewController(itemInfo: "Mood")
        let activityChild = TagsViewController(itemInfo: "Activity")
        let moreChild = TagsViewController(itemInfo: "More")
        return [genreChild, cityChild, moodChild, activityChild, moreChild]
    }
}

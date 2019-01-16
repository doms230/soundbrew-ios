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
        
        let filterButton = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(self.didPressFilterButton(_:)))
        self.navigationItem.rightBarButtonItem = filterButton
        
        // change selected bar color
        settings.style.buttonBarBackgroundColor = .white
        settings.style.buttonBarItemBackgroundColor = .white
        settings.style.selectedBarBackgroundColor = Color().blue()
        settings.style.buttonBarItemFont = UIFont(name: "\(UIElement().mainFont)-Bold", size: 20)!
        settings.style.selectedBarHeight = 1
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
        
        super.viewDidLoad()
    }
    
    @objc func didPressFilterButton(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "showTags", sender: self)
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let recentChild = MySoundsViewController(itemInfo: "Recent")
        let popularChild = MySoundsViewController(itemInfo: "Popular")
        return [recentChild, popularChild]
    }
}

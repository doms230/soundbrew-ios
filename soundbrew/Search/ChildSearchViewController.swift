//
//  ChildSearchViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 1/8/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class ChildSearchViewController: UIViewController, GridLayoutDelegate, UICollectionViewDataSource, IndicatorInfoProvider {
    
    var collectionView: UICollectionView!
    var gridLayout: GridLayout!
    let searchReuse = "searchReuse"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /*let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = itemInfo.title!*/
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        /*let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        layout.itemSize = CGSize(width: 100, height: 100)*/
        
        collectionView = UICollectionView(frame: view.frame)
        collectionView.dataSource = self
        //collectionView.delegate = self
        collectionView.register(MainCollectionViewCell.self, forCellWithReuseIdentifier: searchReuse)
        collectionView.backgroundColor = .white
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        collectionView.contentOffset = CGPoint(x: -10, y: -10)
        //self.view.addSubview(collectionView)
        
        gridLayout.delegate = self
        gridLayout.itemSpacing = 3
        gridLayout.fixedDivisionCount = 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 100
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: searchReuse, for: indexPath) as! MainCollectionViewCell
        
        return cell
    }
    
    //
    var itemInfo: IndicatorInfo = "View"
    
    init(itemInfo: IndicatorInfo) {
        self.itemInfo = itemInfo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }
    
    // MARK: - PrimeGridDelegate
    func scaleForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> UInt {
        return 1
        /*if(arrInstaBigCells.contains(indexPath.row) || (indexPath.row == 1)){
            return 2
        } else {
            return 1
        }*/
    }
    
    func itemFlexibleDimension(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, fixedDimension: CGFloat) -> CGFloat {
        return fixedDimension
    }
}

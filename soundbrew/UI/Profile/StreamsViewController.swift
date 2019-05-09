//
//  StreamsViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 5/6/19.
//  Copyright © 2019 Dominic  Smith. All rights reserved.
//

import UIKit
import Parse
import SnapKit

class StreamsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        loadStreams()
    }
    
    let color = Color()
    let uiElement = UIElement()
    
    lazy var streamTitle: UILabel = {
        let label = UILabel()
        label.text = "Streams Since Last Payout"
        label.textColor = color.black()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 20)
        return label
    }()
    
    lazy var streamExplanation: UILabel = {
        let label = UILabel()
        label.text = "A stream on Soundbrew is recorded when a listener plays your sound for 30 seconds or more. A stream does not equal a play. \n\n You earn $0.013 per stream. \n\n You're eligble for payout when you earn at-least $20 worth of streams or 1,538 streams. \n\n Contact support@soundbrew.app for any questions or concerns."
        label.textColor = color.black()
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 17)
        label.numberOfLines = 0
        return label
    }()
    
    lazy var streamCount: UILabel = {
        let label = UILabel()
        label.text = "Loading"
        label.textColor = color.black()
        label.font = UIFont(name: "\(uiElement.mainFont)-bold", size: 25)
        return label
    }()
    
    func loadStreams() {
        if let currentUserObjectId = PFUser.current()?.objectId {
            let query = PFQuery(className: "Payment")
            query.whereKey("userId", equalTo: currentUserObjectId)
            query.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) -> Void in
                if error != nil {
                    self.streamCount.text = "0"
                    
                } else if let object = object {
                    self.streamCount.text = "\(object["streamsSinceLastPayout"] as! Int)"
                }
            }
        }
    }
    
    func setUpUI() {
        self.view.addSubview(streamTitle)
        self.view.addSubview(streamExplanation)
        self.view.addSubview(streamCount)
        
        streamTitle.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        streamCount.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(streamTitle.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        streamExplanation.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(streamCount.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }

    }
}

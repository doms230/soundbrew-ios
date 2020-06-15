//
//  PlaylistTableViewCell.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/15/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit

class PlaylistTableViewCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        

    }
    
    ///////////
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
}

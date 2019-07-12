//
//  Tag.swift
//  soundbrew
//
//  Created by Dominic  Smith on 10/15/18.
//  Copyright © 2018 Dominic  Smith. All rights reserved.
//

import Foundation
import UIKit
import DeckTransition
import Parse

class Tag {
    var objectId: String!
    var name: String!
    var count: Int!
    var type: String?
    var isSelected: Bool!
    var image: String?
    
    init(objectId: String?, name: String!, count: Int!, isSelected: Bool!, type: String?, image: String?) {
        self.objectId = objectId
        self.name = name
        self.count = count
        self.isSelected = isSelected
        self.type = type
        self.image = image 
    }
    
    func cell(_ tableView: UITableView, reuse: String) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuse) as! ProfileTableViewCell
        cell.selectionStyle = .gray
        
        if let image = self.image {
            cell.profileImage.kf.setImage(with: URL(string: image))
            
        } else {
            if type == "artist" {
                loadArtistTagProfileImage(cell.profileImage, tag: self.name)
                
            } else {
               cell.profileImage.image = UIImage(named: "hashtag")
            }
        }
        
        cell.displayNameLabel.text = self.name 
        
        return cell
    }
    
    func loadArtistTagProfileImage(_ image: UIImageView, tag: String) {
        let query = PFQuery(className: "_User")
        query.whereKey("username", equalTo: tag)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if let object = object {
                if let imageFile = object["userImage"] as? PFFileObject {
                    image.kf.setImage(with: URL(string: imageFile.url!), placeholder: UIImage(named: "hashtag"))
                } else {
                    image.image = UIImage(named: "hashtag")
                }
                
            } else {
                image.image = UIImage(named: "hashtag")
            }
        }
    }
}

protocol TagDelegate {
    func receivedTags(_ chosenTags: Array<Tag>?)
}

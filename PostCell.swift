//
//  PostCell.swift
//  SocialPocket
//
//  Created by Danny Luong on 7/28/17.
//  Copyright © 2017 dnylng. All rights reserved.
//

import UIKit
import Firebase

class PostCell: UITableViewCell {

    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var postImg: UIImageView!
    @IBOutlet weak var caption: UITextView!
    @IBOutlet weak var likesLbl: UILabel!
    @IBOutlet weak var likeBtn: UIButton!
    
    // Post model data
    var post: Post!
    
    // Reference to the likes value
    var likesValRef: DatabaseReference!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Make the like button image aspect fit
        self.likeBtn.imageView?.contentMode = .scaleAspectFit
    }

    func configureCell(post: Post, img: UIImage? = nil) {
        likesValRef = DataService.ds.REF_CURRENT_USER.child("likes").child(post.postID)
        self.post = post
        self.caption.text = post.caption
        self.likesLbl.text = "\(post.likes)"
        
        // If image fully loaded then set it, otherwise download image (15 MB max size)
        if img != nil {
            self.postImg.image = img
        } else {
            let ref = Storage.storage().reference(forURL: post.imageUrl)
            ref.getData(maxSize: 15 * 1024 * 1024, completion: { (data, error) in
                if error != nil {
                    print("TEST: Unable to download image from Firebase storage")
                } else {
                    print("TEST: Image downloaded from Firebase storage")
                    
                    if let imgData = data {
                        if let img = UIImage(data: imgData) {
                            self.postImg.image = img
                            FeedVC.imageCache.setObject(img, forKey: post.imageUrl as NSString)
                        }
                    }
                }
            })
        }
        
        // When cell is configured, check if the post is liked by current user
        likesValRef.observeSingleEvent(of: .value, with: { (snapshot) in
            // If the post isn't liked = empty heart, if liked = filled heart
            if let _ = snapshot.value as? NSNull {
                self.likeBtn.setImage(UIImage(named: "empty-heart"), for: .normal)
            } else {
                self.likeBtn.setImage(UIImage(named: "filled-heart"), for: .normal)
            }
        })
    }
    
    // When like btn pressed, fill the heart and update like count, otherwise empty
    @IBAction func likeBtnPressed(_ sender: Any) {
        likesValRef.observeSingleEvent(of: .value, with: { (snapshot) in
            // If the post isn't liked = empty heart, if liked = filled heart
            if let _ = snapshot.value as? NSNull {
                self.likeBtn.setImage(UIImage(named: "filled-heart"), for: .normal)
                self.post.updateLikes(addLike: true)
                self.likesValRef.setValue(true)
            } else {
                self.likeBtn.setImage(UIImage(named: "empty-heart"), for: .normal)
                self.post.updateLikes(addLike: false)
                self.likesValRef.removeValue()
            }
        })
    }
    
}

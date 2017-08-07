//
//  FeedVC.swift
//  SocialPocket
//
//  Created by Danny Luong on 7/27/17.
//  Copyright © 2017 dnylng. All rights reserved.
//

import UIKit
import Firebase
import SwiftKeychainWrapper

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var posts = [Post]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        // On the look out for new posts
        DataService.ds.REF_POSTS.observe(.value, with: { (snapshot) in
            // Prints out each posts' info
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    print("SNAP: \(snap)")
                    
                    // If a post exists, create a post model and add that to an array
                    if let postData = snap.value as? Dictionary<String, AnyObject> {
                        let postID = snap.key
                        let post = Post(postID: postID, postData: postData)
                        self.posts.append(post)
                    }
                }
            }
            self.tableView.reloadData()
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // Number of posts will be the number of rows shown
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.row]
        print("TEST: \(post.caption)")
        
        return tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
    }
    
    @IBAction func signoutBtnPressed(_ sender: Any) {
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        }
        let _ = KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        do {
            try Auth.auth().signOut()
        } catch {
            print("Sign Out Error: \(error)")
        }
        print("Keychain removed successfully and signed out")
    }

}

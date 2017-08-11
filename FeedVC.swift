//
//  FeedVC.swift
//  SocialPocket
//
//  Created by Danny Luong on 7/27/17.
//  Copyright © 2017 dnylng. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import SwiftKeychainWrapper

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addImgBtn: RoundView!
    @IBOutlet weak var captionField: StyleTextField!
    
    var posts = [Post]()
    var imagePicker: UIImagePickerController!
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    var imageSelected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        captionField.delegate = self
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        // On the look out for new posts
        DataService.ds.REF_POSTS.observe(.value, with: { (snapshot) in
            // Clean the array of posts to avoid duplicates
            self.posts = []
            
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
    
    // Hide keyboard when user touches outside of the keyboard
    @IBAction func closeFeedKeyboard(_ sender: Any) {
        self.view.endEditing(true)
    }
    // User presses return key to remove keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        captionField.resignFirstResponder()
        return true
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // Number of posts will be the number of rows shown
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    // Configure cell information in the tableview
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as? PostCell {
            if let img = FeedVC.imageCache.object(forKey: post.imageUrl as NSString) {
                cell.configureCell(post: post, img: img)
                return cell
            } else {
                cell.configureCell(post: post)
                return cell
            }
        } else {
            return PostCell()
        }
    }
    
    // Once we've selected an image, get rid of the image picker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            addImgBtn.image = image
            imageSelected = true
        } else {
            print("TEST: A valid image wasn't selected for the imagePicker")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addImgBtnPressed(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func addPostBtnPressed(_ sender: Any) {
        // If conditions fail, then run code inside
        guard let caption = captionField.text, caption != "" else {
            print("TEST: Caption must be entered")
            return
        }
        
        guard let image = addImgBtn.image, imageSelected == true else {
            print("TEST: Image must be selected")
            return
        }
        
        if let imgData = UIImageJPEGRepresentation(image, 0.2) {
            // Create a unique id for image and tell the storage that it's of type jpeg
            let imgUid = NSUUID().uuidString
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            // Store the image in Firebase storage
            DataService.ds.REF_POST_IMAGES.child(imgUid).putData(imgData, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print("TEST: Unable to upload image to Firebase storage")
                } else {
                    print("TEST: Successfully uploaded image to Firebase storage")
                    if let downloadUrl = metadata?.downloadURL()?.absoluteString {
                        self.postToFirebase(imgUrl: downloadUrl)
                    }
                }
            }
        }
    }
    
    func postToFirebase(imgUrl: String) {
        let post: Dictionary<String, AnyObject> = [
            "caption": captionField.text as AnyObject,
            "imageUrl": imgUrl as AnyObject,
            "likes": 0 as AnyObject
        ]
        
        let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
        firebasePost.setValue(post)
        
        captionField.text = ""
        imageSelected = false
        addImgBtn.image = UIImage(named: "add-image")
        
        // Update the feed with the new post
        tableView.reloadData()
    }
    
    @IBAction func signoutBtnPressed(_ sender: Any) {
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        }
        
        GIDSignIn.sharedInstance().signOut()
        
        let _ = KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        do {
            try Auth.auth().signOut()
        } catch {
            print("Sign Out Error: \(error)")
        }
        print("Keychain removed successfully and signed out")
    }

}

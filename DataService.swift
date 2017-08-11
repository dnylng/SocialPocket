//
//  DataService.swift
//  SocialPocket
//
//  Created by Danny Luong on 7/28/17.
//  Copyright © 2017 dnylng. All rights reserved.
//

import Foundation
import Firebase
import SwiftKeychainWrapper

let DB_BASE = Database.database().reference()
let STORAGE_BASE = Storage.storage().reference()

class DataService {
    
    // Singleton class will implement a global instance of itself
    static let ds = DataService()
    
    // Stroage references
    private var _REF_POST_IMAGES = STORAGE_BASE.child("post-images")
    
    
    var REF_POST_IMAGES: StorageReference {
        return _REF_POST_IMAGES
    }
    
    // Database references
    private var _REF_BASE = DB_BASE
    private var _REF_POSTS = DB_BASE.child("posts")
    private var _REF_USERS = DB_BASE.child("users")
    
    var REF_BASE: DatabaseReference {
        return _REF_BASE
    }
    
    var REF_POSTS: DatabaseReference {
        return _REF_POSTS
    }
    
    var REF_USERS: DatabaseReference {
        return _REF_USERS
    }
    
    var REF_CURRENT_USER: DatabaseReference {
        let uid = KeychainWrapper.standard.string(forKey: KEY_UID)
        let user = REF_USERS.child(uid!)
        return user
    }
    
    func createFirebaseDBUser(uid: String, userData: Dictionary<String, String>) {
        // Firebase will automatically create UID if it doesn't exist
        REF_USERS.child(uid).updateChildValues(userData)
    }
    
}

//
//  ViewController.swift
//  SocialPocket
//
//  Created by Danny Luong on 7/25/17.
//  Copyright © 2017 dnylng. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn
import SwiftKeychainWrapper

class LoginVC: UIViewController, UITextFieldDelegate, GIDSignInDelegate, GIDSignInUIDelegate {

    @IBOutlet weak var emailField: StyleTextField!
    @IBOutlet weak var pwdField: StyleTextField!
    @IBOutlet weak var botConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up for moving text fields up
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        emailField.delegate = self
        pwdField.delegate = self
        
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Checking if there's already a keychain with the keyuid
        if let _ = KeychainWrapper.standard.string(forKey: KEY_UID) {
            performSegue(withIdentifier: "toFeed", sender: nil)
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            
            self.botConstraint.constant = keyboardFrame.height
            UIView.animate(withDuration: 0.25,
                           delay: TimeInterval(0),
                           options: UIViewAnimationOptions(rawValue: 7),
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
    
    // Hide keyboard when user touches outside of the keyboard
    @IBAction func closeLoginKeyboard(_ sender: Any) {
        self.view.endEditing(true)
    }

    // User presses return key to remove keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        emailField.resignFirstResponder()
        pwdField.resignFirstResponder()
        return true
    }
    
    // When keyboard is hidden, make sure bot constraint is 0.0
    func keyboardWillHide() {
        self.botConstraint.constant = 0.0
        UIView.animate(withDuration: 0.25,
                       delay: TimeInterval(0),
                       options: UIViewAnimationOptions(rawValue: 7),
                       animations: { self.view.layoutIfNeeded() },
                       completion: nil)
    }

    // Get access token based off of facebook auth
    @IBAction func facebookBtnPressed(_ sender: Any) {
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if error != nil {
                print("Unable to authenticate with Facebook! - \(error!)")
            } else if result?.isCancelled == true {
                print("User cancelled Facebook authentication")
            } else {
                print("Successfully authenticated with Facebook!")
                let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                self.firebaseAuthWithFB(credential)
            }
        }
    }
    
    @IBAction func googleBtnPressed(_ sender: Any) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    // Firebase authentication handling
    func firebaseAuthWithFB(_ credential: AuthCredential) {
        Auth.auth().signIn(with: credential) { (user, error) in
            if error != nil {
                print("Unable to authenticate with Firebase")
            } else {
                print("Successfully authenticated with Firebase")
                if let user = user {
                    let userData = ["provider": credential.provider]
                    self.completeLogin(uid: user.uid, userData: userData)
                }
            }
        }
    }
    
    // Firebase auth with google
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("TEST: Failed to authenticate with Google", error)
            return
        }
        print("TEST: Successfully authenticated with Google!", user)
        
        // Create user id/access token to sign into Firebase with
        guard let idToken = user.authentication.idToken else { return }
        guard let accessToken = user.authentication.accessToken else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        Auth.auth().signIn(with: credential) { (user, error) in
            if error != nil {
                print("Unable to authenticate to Firebase with Google")
            } else {
                print("Successfully authenticated to Firebase with Google")
                if let user = user {
                    let userData = ["provider": credential.provider]
                    self.completeLogin(uid: user.uid, userData: userData)
                    print("TEST: Google UID \(user.uid)")
                }
            }
        }
    }

    // Login handling using the email and pwd entered by user
    @IBAction func loginBtnPressed(_ sender: Any) {
        // If there's an email and pwd entered
        if let email = emailField.text, let pwd = pwdField.text {
            Auth.auth().signIn(withEmail: email, password: pwd, completion: { (user, error) in
                if error == nil {
                    print("Email user authenticated with Firebase")
                    if let user = user {
                        let userData = ["provider": user.providerID]
                        self.completeLogin(uid: user.uid, userData: userData)
                    }
                } else {
                    Auth.auth().createUser(withEmail: email, password: pwd, completion: { (user, error) in
                        if error != nil {
                            print("Unable to authenticate with Firebase using email")
                        } else {
                            print("Successfully authenticated with Firebase using email")
                            if let user = user {
                                let userData = ["provider": user.providerID]
                                self.completeLogin(uid: user.uid, userData: userData)
                            }
                        }
                    })
                }
            })
        }
    }
    
    // Save account to the keychain and segue
    func completeLogin(uid: String, userData: Dictionary<String, String>) {
        DataService.ds.createFirebaseDBUser(uid: uid, userData: userData)
        
        let keychainResult = KeychainWrapper.standard.set(uid, forKey: KEY_UID)
        performSegue(withIdentifier: "toFeed", sender: nil)
        print("Data saved to keychain! - \(keychainResult)")
    }
        
}


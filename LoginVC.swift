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
import SwiftKeychainWrapper

class LoginVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: StyleTextField!
    @IBOutlet weak var pwdField: StyleTextField!
    @IBOutlet weak var botConstraint: NSLayoutConstraint!
    
    var duration: TimeInterval!
    var animationCurve: UIViewAnimationOptions!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up for moving text fields up
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Checking if there's already a keychain with the keyuid
        if let _ = KeychainWrapper.standard.string(forKey: KEY_UID) {
            performSegue(withIdentifier: "toFeed", sender: nil)
        }
        
        emailField.delegate = self
        pwdField.delegate = self
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            
            // Animation calculations
            duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            animationCurve = UIViewAnimationOptions(rawValue: animationCurveRaw)
            
            self.botConstraint.constant = keyboardFrame.height
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
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
        UIView.animate(withDuration: duration,
                       delay: TimeInterval(0),
                       options: animationCurve,
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


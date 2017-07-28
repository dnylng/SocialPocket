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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

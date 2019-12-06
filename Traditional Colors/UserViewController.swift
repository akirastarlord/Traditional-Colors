//
//  UserViewController.swift
//  Traditional Colors
//
//  Created by yy的mac on 2019/11/28.
//  Copyright © 2019 yy的mac. All rights reserved.
//

import UIKit

import FirebaseUI

class UserViewController: UIViewController, FUIAuthDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var profileImage: UIImageView!
    
    var isLoggedIn: Bool = false
    
    var authUI = FUIAuth.defaultAuthUI()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* round the profile image */
        profileImage.layer.cornerRadius = 75.0
        profileImage.clipsToBounds = true
        
        
        /* FirebaseUI, authentication*/
        /* need to adopt FUIAuthDelegate protocol to receive callback */
        authUI?.delegate = self
        let authProviders: [FUIAuthProvider] = [FUIGoogleAuth()]
        authUI?.providers = authProviders
        
    }
    
    // MARK: - Google authentication handler method
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String?
        if authUI?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
            return true
        }
        // other URL handling goes here.
        return false
    }
    
    // MARK: - FUIAuthDelegate method
    /* called each time when user tries to sign in with Google */
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        if let user = authDataResult?.user {
            print(user)
        }
    }
    
    // MARK: - IBActions
    @IBAction func tappedSignIn(_ sender: UIButton) {
        /**
        // create a new UIAlertController
        let registerNew = UIAlertController(title: "Create an account", message: nil, preferredStyle: .alert)
        registerNew.addTextField()
        registerNew.addTextField()
        let submitRegistration = UIAlertAction(title: "Register", style: .default) { [unowned registerNew] _ in
            /* get the text field content, store in newsContent
                this instance only valid in this scope
                which is the ethereal time the "done" button is clicked
            */
            let emailField = registerNew.textFields![0]
            //emailField.placeholder = "Email"
            let pwdField = registerNew.textFields![1]
            //pwdField.placeholder = "Password"
            // if valid info entered
            if let emailAddr = emailField.text, let password = pwdField.text {
                self.authUI?.auth?.createUser(withEmail: emailAddr, password: password) { user, error in
                    if error == nil {
                    }
                }
            }
        }
        let cancelRegistration = UIAlertAction(title: "Cancel", style: .default)
        registerNew.addAction(cancelRegistration)
        registerNew.addAction(submitRegistration)
        // show the newNews AlertController
        present(registerNew, animated: true)
         */
        present(authUI?.authViewController() ?? UINavigationController(), animated: true) { }
    }
    
    
}

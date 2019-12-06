//
//  UserViewController.swift
//  Traditional Colors
//
//  Created by yy的mac on 2019/11/28.
//  Copyright © 2019 yy的mac. All rights reserved.
//

import UIKit

import FirebaseUI
import Firebase
import Kingfisher

class UserViewController: UIViewController, FUIAuthDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var colorCollection: UICollectionView!
    
    var uf = UserFamily.userFamily
    
    var authUI = FUIAuth.defaultAuthUI()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* round the profile image */
        profileImage.layer.cornerRadius = 75.0
        profileImage.clipsToBounds = true
        
        colorCollection.dataSource = self
        colorCollection.delegate = self
        
        /* FirebaseUI, authentication*/
        /* need to adopt FUIAuthDelegate protocol to receive callback */
        authUI?.delegate = self
        let authProviders: [FUIAuthProvider] = [FUIGoogleAuth()]
        authUI?.providers = authProviders
        
        updateUserProfileView(for: uf.currentUser())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.colorCollection.reloadData()
        }
    }
    
    /* update UI */
    /* similar to tableview.reloadData() */
    //TODO SOME DEBUG PRINTS NEED TO BE ERASED
    func updateUserProfileView(for user: User?) {
        if uf.isLoggedIn() {
            signInButton.isHidden = true
            signOutButton.isHidden = false
            colorCollection.isHidden = false
            guard let u = user else { return }
            let uRef = Database.database().reference().child("users").child(u.id!)
            uRef.observeSingleEvent(of: .value) { snapshot in
                if let userDict = snapshot.value as? [String: Any] {
                    if let n = userDict["name"] as? String {
                        self.userName.text = n
                    }
                    if let e = userDict["email"] as? String {
                        self.email.isHidden = false
                        self.email.text = e
                    }
                    if let p = userDict["photoURL"] as? String {
                        let url = URL(string: p)
                        self.profileImage.kf.setImage(with: url)
                    }
                }
            }
        }
        else {
            signInButton.isHidden = false
            signOutButton.isHidden = true
            colorCollection.isHidden = true
            userName.text = "Welcome!"
            email.isHidden = true
            profileImage.backgroundColor = .systemIndigo
        }
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
    /* called each time when completed signing in through Google */
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        if let user = authDataResult?.user {
            print("Logged user \(user.uid) in")
            
            // TODO RREFACTOR
            let fakeURef = UserFamily.userFamily.ref.child("users").child("_FAKEUSER")
            fakeURef.setValue(["id": "fakeID", "name": "FAKEUSERNAME"])
            fakeURef.removeValue()
            DispatchQueue.main.async {
                self.colorCollection.reloadData()
            }
            
            uf.registerUserFromGoogle(name: user.displayName ?? "", withID: user.uid,
            email: user.email, photoURL: user.photoURL)

            /* update view after register */
            DispatchQueue.main.async {
                self.signInButton.isHidden = true
                self.signOutButton.isHidden = false
                self.colorCollection.isHidden = false
                self.email.isHidden = false
                self.userName.text = user.displayName
                self.email.text = user.email
                if let url = user.photoURL {
                    self.profileImage.kf.setImage(with: url)
                }
            }
 
        }
    }
    
    // MARK: - Collection View methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let u = uf.currentUser() {
            return u.favoriteColors.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MiniColorCell", for: indexPath)
        if let u = uf.currentUser() {
            if let bg = cell.contentView.viewWithTag(1) {
                bg.backgroundColor = UIColor(hex: u.favoriteColors[indexPath.item].colorCode)
            }
            if let colorLabel = cell.contentView.viewWithTag(2) as? UILabel {
                colorLabel.text = u.favoriteColors[indexPath.item].name
            }
        }
        return cell
    }
    
    // MARK: - IBActions
    @IBAction func tappedSignIn(_ sender: UIButton) {
        present(authUI?.authViewController() ?? UINavigationController(), animated: true)
    }
    
    @IBAction func tappedSignOut(_ sender: UIButton) {
        do {
            try authUI?.signOut()
        } catch {
            print("error occurred in signing out")
            return
        }
        /* restore the default (unlogged in) view */
        signInButton.isHidden = false
        signOutButton.isHidden = true
        colorCollection.isHidden = true
        userName.text = "Welcome!"
        email.isHidden = true
        profileImage.image = nil
        profileImage.backgroundColor = .systemIndigo
        
        // TODO: REFACTOR
        let fakeURef = UserFamily.userFamily.ref.child("users").child("_FAKEUSER")
        fakeURef.setValue(["id": "fakeID", "name": "FAKEUSERNAME"])
        fakeURef.removeValue()
        
        print("logged out")
    }
    
    
}

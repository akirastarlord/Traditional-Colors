//
//  UserFamily.swift
//  Traditional Colors
//
//  Created by yy的mac on 2019/12/1.
//  Copyright © 2019 yy的mac. All rights reserved.
//


import Firebase

/* Singleton design
   Only one instance is created and shared across the app */
class UserFamily {
    
    /* singleton instance */
    static let userFamily = UserFamily()
    private var colors: [Color]?
    var users = [User]()
    
    var nextID: Int = 10000
    
    /* reference to Firebase Realtime Database */
    let ref = Database.database().reference()
    
    /* Sync users with database and keep observing state from initialization (launch of app) */
    private init() {
        
        /* snapshot of "users", snapshot.value is all data under path "users"
         each time data under root/users is changed
         this closure is notified and called */
        //ref.child("users").orderByKey()
        ref.child("users").observe(.value) { snapshot in
            //print(snapshot)
            //print(snapshot.value)
            
            if let userDicts = snapshot.value as? [String : [String : Any]] {
                var newUsersSet = [User]()
                for userDict in userDicts {
                    let actualUser = userDict.value
                    var newUser: User?
                    /* guarantee to create a new User */
                    if let name = actualUser["name"] as? String, let id = actualUser["id"] as? String {
                        newUser = User(name: name, id: id)
                    }
                    if let colors = self.colors {
                        if let favs = actualUser["favoriteColors"] as? [String : [String : String]] {
                            let favsSorted = favs.sorted(by: { $0.key < $1.key })
                            for fav in favsSorted {
                                /* found a matching Color */
                                if let c = colors.first(where: { $0.name == fav.value["name"] }) {
                                    //print("successfully matched colors")
                                    newUser!.favoriteColors.append(c)
                                }
                            }
                        }
                    }
                    newUsersSet.append(newUser!)
                }
                self.users = newUsersSet
                /*
                print("now there are \(self.users.count) users, they are:")
                for i in 0..<self.users.count {
                    print("\(self.users[i].name)  \(self.users[i].id)")
                }
                 */
                //print("yyz's favorite colors are")
                //let yyz = self.users.first(where: { $0.name == "Yiyang Zhang" })!
                //for f in yyz.favoriteColors { print(f.name) }
            }
            
            /* Authenticate sign in status, and get current user if any */
            // current firebase authenticated user
            
            /* End of snapshot observation section */
        }
        
        
        // TOIMPLEMENT - LOGGING OUT STATE OBSERVER
        /**
        Auth.auth().addStateDidChangeListener{ (auth, user) in
            if let user = user {
                "User \(user.uid) is signed in"
            }
            else {
                print("is user nil? \(user == nil)")
            }
        }
         */
    }
    
    /* Uncomment to read simple color forms from txt file */
    /**
    func readSimpleColorsFromFile() {
        let fileFullPath = Bundle.main.path(forResource: "ColorsInSimpleForm", ofType: "txt")
        do {
            let s = try String(contentsOfFile: fileFullPath!, encoding: .utf8)
            var lines = s.split(separator: "\n")
            for l in lines {
                var ss = l.split(separator: " ")
                let newC = Color(name: String(ss[0]), colorCode: String(ss[1]))
                colors?.append(newC)
            }
        } catch { print("Failed in reading simple-formatted colors") }
    }
     */
    
    func setColors(_ colors: [Color]) {
        self.colors = colors
    }
    
    func firebaseTest() {
        print("running firebase test")
        //registerUser(name: "yyz", withID: String(123))
    }
    
    func isLoggedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    func currentUser() -> User? {
        if let user = Auth.auth().currentUser {
            if let i = users.firstIndex(where: { $0.id == user.uid }) {
                return users[i]
            }
        }
        return nil
    }
    
    /* Register a user with his/her name
     associated with the next available ID */
    private func registerUserWithRandomID(name: String) {
        let newUserRef = ref.child("users").childByAutoId()
        let id = newUserRef.key ?? ""
        let newUser: [String : Any] = ["name": name, "id": id]
        newUserRef.setValue(newUser)
    }
    
    /* Register a user with his/her name and a provided ID
     ID is usually provided by an authentication provider */
    func registerUser(name: String, withID id: String) {
        /* if the user already exists, do not modify anything */
        let newUserRef = ref.child("users").child(id)
        newUserRef.observeSingleEvent(of: .value) { snapshot in
            if !snapshot.exists() {
                let newUser: [String : Any] = ["name": name, "id": id]
                newUserRef.setValue(newUser)
            }
        }
    }
    
    /* Register a user signed in through Google */
    func registerUserFromGoogle(name: String, withID id: String, email: String?, photoURL: URL?) {
        /* if the user already exists, do not modify anything */
        let newUserRef = ref.child("users").child(id)
        newUserRef.observeSingleEvent(of: .value) { snapshot in
            if !snapshot.exists() {
                let newUser: [String : Any] = ["name": name, "id": id]
                newUserRef.setValue(newUser)
                /* store email address if provided */
                if let email = email {
                    let emailRef = newUserRef.child("email")
                    emailRef.observeSingleEvent(of: .value) { snap in
                        if !snap.exists() { emailRef.setValue(email) }
                    }
                }
                /* store photoURL if provided */
                if let photoURL = photoURL {
                    let url = photoURL.absoluteString
                    let photoURLRef = newUserRef.child("photoURL")
                    photoURLRef.observeSingleEvent(of: .value) { snap in
                        if !snap.exists() { photoURLRef.setValue(url) }
                    }
                }
            }
        }
    }
    
}

//
//  UserFamily.swift
//  Traditional Colors
//
//  Created by yy的mac on 2019/12/1.
//  Copyright © 2019 yy的mac. All rights reserved.
//


import Firebase

class UserFamily {
    
    var users = [User]()
    
    var nextID: Int = 10000
    
    let ref = Database.database().reference()
    
    func userTest() {
        /* Default cases */
        /*
        let nilFirstName = User(firstName: nil, lastName: "A")
        print(nilFirstName.fullName)
        let nilLastName = User(firstName: "A", lastName: nil)
        print(nilLastName.fullName)
        let nilName = User(firstName: nil, lastName: nil)
        print(nilName.fullName)
        let emptyFirstName = User(firstName: "", lastName: "A")
        print(emptyFirstName.fullName)
        let emptyLastName = User(firstName: "b", lastName: "")
        print(emptyLastName.fullName)
        let emptyName = User(firstName: "", lastName: "")
        print(emptyName.fullName)
        
        /* Usual cases */
        let u1 = User(firstName: "A", lastName: "Ba")
        print(u1.fullName)
         */
    }
    
    func firebaseTest() {
        print("running firebase test")
        
        //registerUser(name: "Yui Aoyama")
        //registerUser(name: "Yiyang")
        
        /* snapshot of "users", snapshot.value is all data under "users".
         each time data under root/users is changed
         this closure is notified and called */
        ref.child("users").observe(.value) { snapshot in
            //print(snapshot)
            //print(snapshot.value)
            if let userDicts = snapshot.value as? [String : [String : Any]] {
                var newUsersSet = [User]()
                for userDict in userDicts {
                    let actualUser = userDict.value
                    if let name = actualUser["name"] as? String, let id = actualUser["id"] as? String {
                        newUsersSet.append(User(name: name, id: id))
                    }
                }
                self.users = newUsersSet
                print("now there are \(self.users.count) users")
                for i in 0..<self.users.count {
                    print(self.users[i].name!)
                }
            }
        }
    }
    
    /* Register a user with his/her name
     associated with the next available ID */
    private func registerUser(name: String) {
        let newUserRef = ref.child("users").childByAutoId()
        let id = newUserRef.key ?? ""
        let newUser: [String : Any] = ["name": name, "id": id, "favoriteColors": ["name": "", "colorCode": "", "hiragana": "", "romanji": ""]]
        newUserRef.setValue(newUser)
    }
    
}

//
//  User.swift
//  Traditional Colors
//
//  Created by yy的mac on 2019/12/1.
//  Copyright © 2019 yy的mac. All rights reserved.
//

import UIKit

class User {
    /*
    private var firstName: String?
    private var lastName: String?
     */
    var name: String?
    var id: String?
    
    // collection of user's favorite colors
    var favoriteColors: [Color]
    
    /*
    init(firstName: String? = nil, lastName: String? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        favoriteColors = [Color]()
    }
     */
    
    init(name: String? = nil, id: String? = nil) {
        self.name = name
        self.id = id
        favoriteColors = [Color]()
    }

    
    func liked(_ c: Color) {
        let i = favoriteColors.firstIndex(where: { $0.name == c.name })
        if i == nil {
            favoriteColors.append(c)
        }
    }
    
    /** true when successfully removing a color from the list
        false if the specified color to remove is not present in the list */
    func deLiked(_ c: Color) -> Bool {
        let i = favoriteColors.firstIndex(where: { $0.name == c.name })
        if let i = i {
            favoriteColors.remove(at: i)
            return true
        }
        return false
    }
    
}


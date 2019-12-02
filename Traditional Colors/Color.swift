//
//  Color.swift
//  WebParser
//
//  Created by yy的mac on 2019/11/23.
//  Copyright © 2019 yy的mac. All rights reserved.
//

import Foundation

class Color: Codable {
    let name: String
    var colorCode: String
    let hiragana: String?
    let romanji: String?

    
    var link: String? // default - nil
    
    var story: String? // default - nil
    
    var colorValue: ColorValue?
    
    init(name: String, colorCode: String, hiragana: String? = nil, romanji: String? = nil) {
        self.name = name
        self.colorCode = colorCode
        self.hiragana = hiragana
        self.romanji = romanji
        
    }
    
}


struct ColorValue: Codable {
    var r, g, b: Int?
    var c, m, y, k: Int?
    
    init(r: Int? = nil, g: Int? = nil, b: Int? = nil,
         c: Int? = nil, m: Int? = nil, y: Int? = nil, k: Int? = nil) {
        self.r = r
        self.g = g
        self.b = b
        self.c = c
        self.m = m
        self.y = y
        self.k = k
    }
    
    func rgbValid() -> Bool {
        return r != nil && g != nil && b != nil
    }
    
    func cmykValid() -> Bool {
        return c != nil && m != nil && y != nil && k != nil
    }
}

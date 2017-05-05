//
//  Audio.swift
//  KashlemerBLE
//
//  Created by Pavel Aristov on 04.05.17.
//  Copyright © 2017 aristovz. All rights reserved.
//

import Foundation

class Audio {
    var id: Int!
    var name: String!
    var url: String!
    var date: Date!
    var data: [AudioData]!
    
    init(id: Int, name: String, url: String, date: Date, data: [AudioData] = [AudioData]()) {
        self.id = id
        self.name = name
        self.url = url
        self.date = date
        self.data = data
    }
}

class AudioData {
    var id: Int!
    
    var pull: Double!
    
    var acx: Double!
    var acy: Double!
    var acz: Double!
    
    var tmp: Double!
    
    var gyx: Double!
    var gyy: Double!
    var gyz: Double!
    
    var audioID: Int!
    
    init(id: Int, pull: Double!, acx: Double, acy: Double, acz: Double, tmp: Double, gyx: Double, gyy: Double, gyz: Double, audioID: Int) {
        self.id = id
        
        self.pull = pull
        
        self.acx = acx
        self.acy = acy
        self.acz = acz
        
        self.tmp = tmp
        
        self.gyx = gyx
        self.gyy = gyy
        self.gyz = gyz
        
        self.audioID = audioID
    }
}

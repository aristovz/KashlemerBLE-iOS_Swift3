//
//  Audio.swift
//  KashlemerBLE
//
//  Created by Pavel Aristov on 04.05.17.
//  Copyright © 2017 aristovz. All rights reserved.
//

import Foundation
import RealmSwift

class Audio: Object {
    dynamic var id = 0
    dynamic var name: String!
    dynamic var url: String!
    dynamic var date: Date!
    
    let data = List<AudioData>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    var isCached: Bool {
        get {
            return !url.contains("auto.nk5.ru")
        }
    }
}

class AudioData: Object {
    dynamic var id = 0
    
    dynamic var audioAmpl: Double = 0.0
    
    dynamic var pull: Double = 0.0
    
    dynamic var acx: Double = 0.0
    dynamic var acy: Double = 0.0
    dynamic var acz: Double = 0.0
    
    dynamic var tmp: Double = 0.0
    
    dynamic var gyx: Double = 0.0
    dynamic var gyy: Double = 0.0
    dynamic var gyz: Double = 0.0
    
    dynamic var audioID: Int = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

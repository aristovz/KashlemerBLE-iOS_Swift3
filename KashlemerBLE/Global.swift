//
//  Global.swift
//  KashlemerBLE
//
//  Created by Pavel Aristov on 01.05.17.
//  Copyright © 2017 aristovz. All rights reserved.
//

import Foundation
import RealmSwift

class Global {
    
    var accessToken: String {
        get {
            return "f1e28a6924281ec81a9d57d174459f95b47e4f26";
        }
    }
    
    var urlPath: String {
            return "http://pavel.clashbyte.ru/"
    }
    
    class func incrementID(type: Object.Type) -> Int {
        return (realm.objects(type).max(ofProperty: "id") as Int? ?? 0) + 1
    }
}

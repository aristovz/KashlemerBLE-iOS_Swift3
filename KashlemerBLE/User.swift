//
//  User.swift
//  KashlemerBLE
//
//  Created by Pavel Aristov on 04.04.18.
//  Copyright © 2018 aristovz. All rights reserved.
//

import Foundation

enum UserSex: Int {
    case male, female
}

class User {
    let id: Int
    let name: String
    let surname: String
    var patronymic: String? = nil
    var birthday: Date? = nil
    var sex: UserSex = .male
    var weight: Double? = nil
    var height: Double? = nil
    var diagnosis: String? = nil
    
    var audios = [Audio]()
    
    init?(from map: [String: Any]) {
        if let id = map["id"] as? Int,
            let name = map["name"] as? String,
            let surname = map["surname"] as? String {
            
            self.id = id
            self.name = name
            self.surname = surname
            
            self.patronymic = map["patronymic"] as? String
            self.weight = map["weight"] as? Double
            self.height = map["height"] as? Double
            self.diagnosis = map["diagnosis"] as? String
            
            if let sexIndex = map["sex"] as? Int,
                let sex = UserSex(rawValue: sexIndex) {
                self.sex = sex
            }
            
            if let birthdayTS = map["birthday"] as? Int {
                self.birthday = Date(timeIntervalSince1970: TimeInterval(birthdayTS))
            }
        } else {
            print("Can't init User")
            return nil
        }
    }
}


//
//  API.swift
//  KashlemerBLE
//
//  Created by Pavel Aristov on 01.05.17.
//  Copyright © 2017 aristovz. All rights reserved.
//

import Foundation
import Alamofire

class API {
    class func uploadAudio(from url: URL, requestEnd: @escaping (Bool) -> ()) {
        
        let parameters = [
            "name": url.lastPathComponent
        ]
        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(url, withName: "file")
            for key in parameters.keys {
                multipartFormData.append(parameters[key]!.data(using: .utf8)!, withName: key)
            }
        }, to: "http://auto.nk5.ru/audio.uploadNewFile") { (result) in
            switch result {
            case .success(let upload, _, _) :
                upload.responseJSON { response in
                    //print(response.result.value)
                    requestEnd(true)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}


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
            "name": "\(Int(Date().timeIntervalSince1970)).m4a"//url.lastPathComponent
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
    
    class func uploadAudioWithData(from url: URL, with data: [String: [Double]], requestEnd: @escaping (Bool) -> ()) {
        
        do {
            //Convert to Data
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions.prettyPrinted)
            
            //Convert back to string. Usually only do this for debugging
            if let JSONString = String(data: jsonData, encoding: String.Encoding.utf8) {
                //print(JSONString)
        
                let parameters = [
                    "name": "\(Int(Date().timeIntervalSince1970)).m4a",//url.lastPathComponent
                    "data": JSONString
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
                            //print(response)
                            requestEnd(true)
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
        }
        catch { }
    }
    
    class func getAllAudio(needData: Bool = false, requestEnd: @escaping ([Audio]?, String?) -> ()) {
        var parameters: [String: Any]? = nil
        
        if needData {
            parameters = ["needData": "1"]
        }
        
        Alamofire.request("http://auto.nk5.ru/audio.getAll", method: .get, parameters: parameters).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                if let json = data as? [String: Any] {
                    if let audios = json["audios"] as? [[String: Any]] {
                        var resAudios = [Audio]()
                        for audio in audios {
                            if let id = audio["id"] as? Int,
                                let name = audio["name"] as? String,
                                let url = audio["url"] as? String,
                                let date = (audio["date"] as? String)?.dateFromISO8601 {
                                
                                let audioObject = Audio(id: id, name: name, url: url, date: date)
                                
                                if needData {
                                    if let data = audio["data"] as? [[String: Any]] {
                                        for row in data {
                                            if let id = row["id"] as? Int,
                                                let pull = row["pull"] as? Double,
                                                let acx = row["acx"] as? Double,
                                                let acy = row["acy"] as? Double,
                                                let acz = row["acz"] as? Double,
                                                let tmp = row["tmp"] as? Double,
                                                let gyx = row["gyx"] as? Double,
                                                let gyy = row["gyy"] as? Double,
                                                let gyz = row["gyz"] as? Double,
                                                let audioID = row["audioID"] as? Int {
                                                
                                                let data = AudioData(id: id, pull: pull, acx: acx, acy: acy, acz: acz, tmp: tmp, gyx: gyx, gyy: gyy, gyz: gyz, audioID: audioID)
                                                
                                                audioObject.data.append(data)
                                            }
                                        }
                                    }
                                }
                                
                                resAudios.append(audioObject)
                            }
                        }
                        requestEnd(resAudios, nil)
                    }
                    else {
                        requestEnd(nil, "Can't get audios")
                    }
                }
                else { requestEnd(nil, "Error parsing JSON") }
            case .failure(let error):
                requestEnd(nil, error.localizedDescription)
            }
        }
    }
    
    class func getDataByID(id: Int, requestEnd: @escaping ([AudioData]?, String?) -> ()) {
        
        Alamofire.request("http://auto.nk5.ru/audio.getAll", method: .get, parameters: ["id": id]).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                if let json = data as? [String: Any] {
                    if let data = json["audio"] as? [[String: Any]] {
                        var resData = [AudioData]()
                        
                        for row in data {
                            if let id = row["id"] as? Int,
                                let pull = row["pull"] as? Double,
                                let acx = row["acx"] as? Double,
                                let acy = row["acy"] as? Double,
                                let acz = row["acz"] as? Double,
                                let tmp = row["tmp"] as? Double,
                                let gyx = row["gyx"] as? Double,
                                let gyy = row["gyy"] as? Double,
                                let gyz = row["gyz"] as? Double,
                                let audioID = row["audioID"] as? Int {
                                
                                let data = AudioData(id: id, pull: pull, acx: acx, acy: acy, acz: acz, tmp: tmp, gyx: gyx, gyy: gyy, gyz: gyz, audioID: audioID)
                                
                                resData.append(data)
                            }
                        }
                        requestEnd(resData, nil)
                    }
                    else { requestEnd(nil, "Can't get data") }
                }
                else { requestEnd(nil, "Error parsing JSON") }
            case .failure(let error):
                print(error.localizedDescription)
                requestEnd(nil, error.localizedDescription)
            }
        }
    }

    class func delete(id: Int, requestEnd: @escaping (Bool?, String?) -> ()) {
        Alamofire.request("http://auto.nk5.ru/audio.delete", method: .post, parameters: ["id": id]).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                if let json = data as? [String: Any] {
                    if let result = json["result"] as? Bool {
                        requestEnd(result, nil)
                    }
                    else { requestEnd(nil, "Can't parsing result") }
                }
                else { requestEnd(nil, "Error parsing JSON") }
            case .failure(let error):
                print(error.localizedDescription)
                requestEnd(nil, error.localizedDescription)
            }
        }
    }
}

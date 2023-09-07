//
//  FlikerModel.swift
//  VirtualTourist
//
//  Created by  ashwaq marzouq on 30/10/1444 AH.
//

import Foundation

struct FlickerResponse: Codable {
    let photos : Photos
}

struct Photos : Codable {
    let perpage : Int
    let photo : [PhotoParse]
}

struct PhotoParse : Codable {
    let id : String
    let url_m : String

}



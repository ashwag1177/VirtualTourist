//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by  ashwaq marzouq on 30/10/1444 AH.
//

import Foundation

extension FlickrClient {
    
    struct Constants {
        static let ApiKey = "d8249530b4011808fe90cd3a7e6a5224"
        static let ApiScheme = "https"
        static let ApiHost = "api.flickr.com"
        static let ApiPath = "/services/rest"
    }
    
    struct ParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let Extras = "extras"
        static let SafeSearch = "safe_search"
        static let PhotosPerPage = "per_page"
        static let BoundingBox = "bbox"
    }
    
    struct ParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "d8249530b4011808fe90cd3a7e6a5224"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1"
        static let MediumURL = "url_m"
        static let UseSafeSearch = "1"
        static let PhotosPerPage = "30"
    }
    
    static let SearchBBoxHalfWidth = 0.2
    static let SearchBBoxHalfHeight = 0.2
    static let SearchLatRange = (-90.0, 90.0)
    static let SearchLonRange = (-180.0, 180.0)

}

//
//  Constants.swift
//  Virtual Tourist
//
//  Created by Humberto Aquino on 4/20/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import CoreLocation

extension TravelLocationsViewController {    
    struct UI {
        static let MinimumPressDuration:NSTimeInterval = 2
    }    
}

extension CoreDataStackManager {
    struct Constants {
        static let ModelName = "Model"
        static let ModelExtension = "momd"
        static let SQLiteFilename = "VirtualTourist.sqlite"
        static let ImagesDirectory = "images"
    }
}


extension FlickrImageDownloadManager {
    
    struct Queue {
        static let DownloadQueueMaxConcurrentOperationCount = 3
    }
    
    struct Pagination {
        static let TotalPhotosPerPage = 21 // 3 columns * 7 rows    
    }
    
    struct Methods {
        static let Search = "flickr.photos.search"
    }
    
    struct URLs {
        static let BaseURL = "https://api.flickr.com/services/rest/"
    }
    
    struct ParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let Extras = "extras"
        static let Format = "format"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let Page = "page"
        static let PerPage = "per_page"
        static let NoJSONCallback = "nojsoncallback"
    }
    
    struct ParameterValues {
        static let URLM = "url_m"
        static let JSON = "json"
        static let Pages = "pages"
        static let NoJSONCallback = 1
    }
    
    struct ResponseKeys {
        static let Photos = "photos"
        static let Photo = "photo"
        static let Pages = "pages"
        
    }
    
    // Builds a parameters dictionary for searching using latitude unsing pagination.
    // Obs.: Is caller's responsability to provide correct page and perPage values
    // https://www.flickr.com/services/api/flickr.photos.search.html
    func locationImagePaginatedSearch(coordinates: CLLocationCoordinate2D, page: Int, perPage total: Int) -> [String: AnyObject] {
        var mutableParameters = baseSearchParameters()
        
        mutableParameters.setValue(coordinates.latitude, forKey: ParameterKeys.Latitude)
        mutableParameters.setValue(coordinates.longitude, forKey: ParameterKeys.Longitude)
        mutableParameters.setValue(page, forKey: ParameterKeys.Page)
        mutableParameters.setValue(total, forKey: ParameterKeys.PerPage)
        
        let parameters: NSDictionary = mutableParameters
        
        return parameters as! [String: AnyObject]
    }
    
    // Basic utility function to build a mutable dictionary to use to create a complete parameters
    // dictionary to use in Flickr requests
    func baseSearchParameters() -> NSMutableDictionary {
        var result = [
            ParameterKeys.Method: Methods.Search,
            ParameterKeys.APIKey: Config.Flickr.APIKey,
            ParameterKeys.Extras: ParameterValues.URLM,
            ParameterKeys.Format: ParameterValues.JSON,
            ParameterKeys.NoJSONCallback: ParameterValues.NoJSONCallback
        ] as NSMutableDictionary
        return result
    }
    
    
}
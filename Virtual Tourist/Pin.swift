//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Humberto Aquino on 4/21/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

@objc(Pin)

class Pin: NSManagedObject {
    
    static let ModelName = "Pin"
    static let InitialPageNumber = 0
    
    struct Keys {
        static let Longitude = "longitude"
        static let Latitude = "latitude"
        static let CurrentPage = "currentPage"
        static let TotalPages = "totalPages"
    }
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var currentPage: Int
    @NSManaged var totalPages: Int
    @NSManaged var photos: [Photo]?
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName(Pin.ModelName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude] as! Double
        
        if let currentPage = dictionary[Keys.CurrentPage] as? Int {
            self.currentPage = currentPage
        } else {
            self.currentPage = 1
        }
        
        if let totalPages = dictionary[Keys.TotalPages] as? Int {
            self.totalPages = totalPages
        } else {
            self.totalPages = 0
        }
    }

}

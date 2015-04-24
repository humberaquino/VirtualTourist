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
import MapKit

@objc(Pin)


// Represents a Pin in the map that a virutal tourist visits
// It holds a list of photos of that place
class Pin: NSManagedObject, MKAnnotation {
    
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
    @NSManaged var photos: [Photo]?
    
    // List of places where the pin has been :)
    @NSManaged var history: [Pin]?
    
    // Info to use on Flickr to know what is the next page to get when
    // the user asks for a "New collection"
    @NSManaged var currentPage: Int
    @NSManaged var totalPages: Int
    
    @NSManaged var pendingDownloads: Int
    
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
        
        pendingDownloads = 0
    }
    
    func appendHistory(history: PinHistory) {
        history.pin = self
        
        latitude = history.latitude
        longitude = history.longitude
    }
    
    func decreasePendingDownloads() {
        pendingDownloads--
    }
    
    override var description: String {
        return "Pin: \(latitude), \(longitude)"
    }        
    
    // MARK - MKAnnotation
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
    }
    
    var title: String = "View album"
    
    var subtitle: String? = nil

    
}

//
//  PinHistory.swift
//  Virtual Tourist
//
//  Created by Humberto Aquino on 4/23/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import CoreData

@objc(PinHistory)

// The pin can currently be placed at some point but can also be moved.
// This class represents one of those events.
class PinHistory: NSManagedObject {
    
    static let ModelName = "PinHistory"
    
    struct Keys {
        static let Longitude = "longitude"
        static let Latitude = "latitude"
    }
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var placedOn: NSDate
    @NSManaged var pin: Pin?
        
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName(PinHistory.ModelName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude] as! Double
        placedOn = NSDate()
    }
    
    override var description: String {
        return "Pin: \(latitude), \(longitude). On: \(placedOn)"
    }
    
    
}
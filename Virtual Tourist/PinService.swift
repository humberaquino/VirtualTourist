//
//  PinService.swift
//  Virtual Tourist
//
//  Created by Humberto Aquino on 4/23/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

// Service layer for Pin methods
class PinService {
    
    let sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    
    func addCurrentAsHistory(pin: Pin) {
        
        let dictionary: [String: AnyObject] = [
            PinHistory.Keys.Latitude: pin.latitude,
            PinHistory.Keys.Longitude: pin.longitude
        ]
        
        let pinHistory = PinHistory(dictionary: dictionary, context: sharedContext)
        
        pin.appendHistory(pinHistory)
        
    }
}
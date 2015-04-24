//
//  PhotoService.swift
//  Virtual Tourist
//
//  Created by Humberto Aquino on 4/23/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import CoreData

// Service layer for Photo methods
class PhotoService {
 
    lazy var sharedContext: NSManagedObjectContext! = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    // Delete all pin's photos and then save
    func deletePinPhotosAndSave(pin: Pin) {
        if let photos = pin.photos {
            for photo in photos {
                deletePhoto(photo)
            }
        }
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    // Delete one photo and save
    func deletePhotoAndSave(photo: Photo) {
        deletePhoto(photo)
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    // Only delete the photo
    func deletePhoto(photo: Photo) {
        photo.pin = nil
        sharedContext.deleteObject(photo)
    }
}
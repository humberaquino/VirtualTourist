//
//  PhotoService.swift
//  Virtual Tourist
//
//  Created by Humberto Aquino on 4/23/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation

// Service layer for Photo methods
class PhotoService {
 
    let sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    
    func deletePinPhotosAndSave(pin: Pin) {
        if let photos = pin.photos {
            for photo in photos {
                deletePhoto(photo)
            }
        }
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    
    func deletePhotoAndSave(photo: Photo) {
        deletePhoto(photo)
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func deletePhoto(photo: Photo) {
        photo.pin = nil
        sharedContext.deleteObject(photo)
    }
}
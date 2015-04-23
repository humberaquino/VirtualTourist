//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Humberto Aquino on 4/21/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)

class Photo: NSManagedObject {
    
    static let ModelName = "Photo"
    
    struct Keys {
        static let Id = "id"
        static let ImageFilename = "imageFilename"
        static let ImageURL = "imageURL"
        static let ImageState = "imageState"
    }
    
    struct State {
        static let New = "new"
        static let Ready = "ready"
        static let Failure = "failure"
    }
    
    @NSManaged var imageFilename: String?
    @NSManaged var imageURL: String?
    @NSManaged var imageState: String?
    @NSManaged var pin: Pin?
    
    var imagePath: String? {
        if let imageFilename = imageFilename {
            return CoreDataStackManager.sharedInstance().pathForfilename(imageFilename)
        } else {
            return nil
        }
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName(Photo.ModelName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        imageFilename = dictionary[Keys.ImageFilename] as? String
        imageURL = dictionary[Keys.ImageURL] as? String
        
        if let imageState = dictionary[Keys.ImageState] as? String {
            self.imageState = imageState
        } else {
            // start as new
            imageState = State.New
        }
    }
    
    override func prepareForDeletion() {
        // Delete file if possible
        if let imagePath = self.imagePath {
            var deleteError: NSError? = nil
            if !NSFileManager.defaultManager().removeItemAtPath(imagePath, error: &deleteError) {
                if let deleteError = deleteError {
                    println("Could not delete file: \(imagePath). Error: \(deleteError.localizedDescription)")
                } else {
                    println("Could not delete file: \(imagePath)")
                }
            }
        }
    }
    
    override var description: String {
        if let imageFilename = imageFilename {
            return "Image \(imageState!): \(imageFilename)"
        } else {
            return "Image \(imageState!)"
        }
    }
    
}

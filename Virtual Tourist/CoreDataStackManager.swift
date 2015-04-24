//
//  CoreDataStackManager.swift
//  Virtual Tourist
//
//  Created by Humberto Aquino on 4/21/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStackManager {    
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if let context = self.managedObjectContext {
            var error: NSError? = nil
            if context.hasChanges && !context.save(&error) {
                println("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }
    
    // MARK: - Core Data stack
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        
        println("Initializing the managed object context property")
        
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        println("Initializing the persistent store coodinator")
        
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentDirectory.URLByAppendingPathComponent(Constants.SQLiteFilename)
        
        var error: NSError? = nil
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            let userInfo: [NSObject : AnyObject] = [
                NSLocalizedDescriptionKey: "Failed to initialize the application's saved data",
                NSLocalizedFailureReasonErrorKey: "There was an error creating or loading the application's saved data.",
                NSUnderlyingErrorKey: error!
            ]
            
            error = NSError(domain: ErrorManager.CoreData.Domain, code: ErrorManager.CoreData.PersistentStoreCoordiantorInitialization, userInfo: userInfo)
            
            println("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional.
        // It is a fatal error for the application not to be able to find and load its model.
        println("Initializing the managed object model")
        
        let modelURL = NSBundle.mainBundle().URLForResource(Constants.ModelName, withExtension: Constants.ModelExtension)!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var imagesDocumentDirectory: NSURL = {
        let imagesDirectory = self.applicationDocumentDirectory.URLByAppendingPathComponent(Constants.ImagesDirectory)
        let imageDirectoryPath = imagesDirectory.path!
        
        var isDirectory: ObjCBool = ObjCBool(false)
        if NSFileManager.defaultManager().fileExistsAtPath(imageDirectoryPath, isDirectory: &isDirectory) {
            // File exits
            if !isDirectory {
                println("The intended images directory is actually a file: \(imagesDirectory)")
                abort()
            }
            // Success. Directory exists.
        } else {
            // File does not exist. Create a directory
            var error: NSError? = nil
            if NSFileManager.defaultManager().createDirectoryAtPath(imageDirectoryPath, withIntermediateDirectories: false, attributes: nil, error: &error) {
                // success
                println("Images directory created: \(imagesDirectory)")
            } else {
                println("Error while trying to create the intended images directory: \(imagesDirectory)")
                if let error = error {
                    println("Error: \(error.localizedDescription)")
                    abort()
                }
            }
        }
        
        
        return imagesDirectory
    }()
    
    lazy var applicationDocumentDirectory: NSURL = {
        println("Initializing the application document directory")
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls.first as! NSURL
    }()
    
    // MARK: utils
    
    func pathForfilename(filename: String) -> String? {
        let imagesDirecotory = CoreDataStackManager.sharedInstance().imagesDocumentDirectory
        let imagePathURL = imagesDirecotory.URLByAppendingPathComponent(filename)
        return imagePathURL.path
    }
    
    // MARK: Shared instance
    
    class func sharedInstance() -> CoreDataStackManager {
        struct Static {
            static let instance = CoreDataStackManager()
        }
        
        return Static.instance
    }

}

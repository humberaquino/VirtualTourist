//
//  ErrorManager.swift
//  Virtual Tourist
//
//  Created by Humberto Aquino on 4/21/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation

struct ErrorManager {
    struct CoreData {
        static let Domain = "CoreData"
        // Error while trying to initialize the PersistentStoreCoordiantor
        // Hint: Check the Core data stack
        static let PersistentStoreCoordiantorInitialization = 100
    }
}
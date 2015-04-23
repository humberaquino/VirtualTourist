//
//  Config.swift
//  Virtual Tourist
//
//  Created by Humberto Aquino on 4/21/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation


struct Config {
    
    struct Flickr {
        static let APIKey = "3750001d397e0298142561bed8bcfb23"
        static let BatchRequestSize = 21
    }
    
    struct Network {        
        // Amount of seconds after a request timeouts
        static let RequestTimeoutSeconds: NSTimeInterval = 30
    }
    
}
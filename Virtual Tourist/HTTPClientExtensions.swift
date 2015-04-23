//
//  HTTPClientExtensions.swift
//  OnTheMap
//
//  Created by Humberto Aquino on 4/17/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation

// MARK: - JSON Utils

extension HTTPClient {
    
    class func dictionaryToData(dictionary: NSDictionary, inout error: NSError?) -> NSData! {
        let json: AnyObject = dictionary as AnyObject
        var dataError: NSError? = nil
        if let data = NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions.allZeros, error: &dataError) {
            // Success
            return data
        } else {
            // Error while converting to NSData
            error = dataError
            return nil
        }
    }
    
    // Helper: Given raw JSON, return a usable Foundation object
    class func dataToDictionary(data: NSData, inout error: NSError?) -> NSDictionary! {
        var jsonError: NSError? = nil
        
        // Parse the NSData to NSDictionary
        if let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &jsonError) as? NSDictionary {
            if let existingError = jsonError {
                // Error while trying to parse the JSON
                error = existingError
                return nil
            }
            // Success
            return parsedResult
        } else {
            // Can't convert to NSDictionary
            error = ErrorUtils.errorForJSONParsingToDictionary(data)
            return nil
        }
        
    }
    
    class func jsonGETHeaders(headers: [String: String]?) -> [String: String] {
        var moreHeaders: [String: String] = [
            "Content-Type":  "application/json"
        ]
        
        // Add JSON headers
        if var existingHeaders = headers {
            moreHeaders.merge(existingHeaders)
        }
        
        return moreHeaders
    }
    
    class func jsonPOSTHeaders(headers: [String: String]?) -> [String: String] {
        
        var moreHeaders: [String: String] = [
            "Accept": "application/json"
        ]
        
        moreHeaders = jsonGETHeaders(moreHeaders)
        
        // Add JSON headers
        if var existingHeaders = headers {
            moreHeaders.merge(existingHeaders)
        }
        
        return moreHeaders
    }
}

// MARK: - Helpers

extension HTTPClient {
    
    // Helper: Substitute the key for the value that is contained within the method name
    class func subtituteKeyInMethod(method: String, key: String, value: String) -> String? {
        if method.rangeOfString("{\(key)}") != nil {
            return method.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
        } else {
            return nil
        }
    }
    
    // Helper: Given a dictionary of parameters, convert to a string for a url
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* FIX: Replace spaces with '+' */
            let replaceSpaceValue = stringValue.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
            
            /* Append it */
            urlVars += [key + "=" + "\(replaceSpaceValue)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
}
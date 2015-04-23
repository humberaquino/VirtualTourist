//
//  HTTPClient.swift
//  OnTheMap
//
//  Created by Humberto Aquino on 4/11/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation

// A "generic HTTP client" (at least for what this project currently needs) used by Udacity's and Parse's clients
class HTTPClient: NSObject {
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        // Override the timeout
        session.configuration.timeoutIntervalForRequest = Config.Network.RequestTimeoutSeconds
        super.init()
    }
    
    // MARK: -
    
    // MARK: POST JSON/NSDictionary based
    // All methods are JSON/NSDictionary based, which means that they receive and return NSDictionary objects
    // for the caller to handle it the way they need    
    
    
    // POST Task method with a header dictionary and using JSON
    func jsonTaskForPOSTMethod(baseURL: String, method: String, parameters: [String : AnyObject]?, headers: [String: String]?, body: NSDictionary, taskCompleteHandler: (jsonResponse: NSDictionary!, response: NSURLResponse!, error: NSError!) -> Void) -> NSURLSessionDataTask! {
        
        let jsonPOSTHeaders = HTTPClient.jsonPOSTHeaders(headers)
        
        // Convert the NSDictioanry to NSData
        var jsonError: NSError? = nil
        if let data = HTTPClient.dictionaryToData(body, error: &jsonError) {

            // JSON Body is valid. Let's proceed to do the POST request
            let task = taskForPOSTMethod(baseURL, method: method, parameters: parameters, headers: jsonPOSTHeaders, body: data, taskCompleteHandler: { (data, response, error) -> Void in
                // POST Complete
                if let existingError = error {
                    // Error: During POST
                    taskCompleteHandler(jsonResponse: nil, response: response, error: existingError)
                    return
                }
                
                // Convert NSData to NSDictionary
                var dataError: NSError? = nil
                if let json = HTTPClient.dataToDictionary(data, error: &dataError) {
                    // Success
                    taskCompleteHandler(jsonResponse: json, response: response, error: nil)
                } else {
                    // Error while parsing json response
                    taskCompleteHandler(jsonResponse: nil, response: response, error: dataError)
                }
            })
            
            return task
        } else {
            // Error while converting the body JSON NSDictionary to NSData
            taskCompleteHandler(jsonResponse: nil, response: nil, error: jsonError)
            return nil
        }
    }
    
    
    // MARK: POST NSData based
    // All methods are NSData based, which means that they receive and return NSData objects for the caller to
    // handle the way they need
    
    
    // The most generic POST task method
    func taskForPOSTMethod(baseURL: String, method: String, parameters: [String : AnyObject]?, headers: [String: String]?, body: NSData, taskCompleteHandler: (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void) -> NSURLSessionDataTask {
        
        // Build the URL and configure the request
        var urlString = baseURL + method
        
        // Concat the parameters if necesarry
        if let existingParameters = parameters {
            urlString += HTTPClient.escapedParameters(existingParameters)
        }
        
        // Build the Request
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.HTTPBody = body
        
        // Add headers if necesary
        if let existingHeaders = headers {
            for (key, value) in existingHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Create the task
        let task = session.dataTaskWithRequest(request, completionHandler: taskCompleteHandler)
        
        // Start the request
        task.resume()
        
        return task
    }
    
    // MARK: -
    
    // MARK: PUT JSON/NSDictionary based
    // All methods are JSON/NSDictionary based, which means that they receive and return NSDictionary objects
    // for the caller to handle it the way they need
    
    // PUT Task method with a header dictionary and using JSON
    func jsonTaskForPUTMethod(baseURL: String, method: String, parameters: [String : AnyObject]?, headers: [String: String]?, body: NSDictionary, taskCompleteHandler: (jsonResponse: NSDictionary!, response: NSURLResponse!, error: NSError!) -> Void) -> NSURLSessionDataTask! {
        
        let jsonPOSTHeaders = HTTPClient.jsonPOSTHeaders(headers)
        
        // Convert the NSDictioanry to NSData
        var jsonError: NSError? = nil
        if let data = HTTPClient.dictionaryToData(body, error: &jsonError) {
            
            // JSON Body is valid. Let's proceed to do the PUT request
            let task = taskForPUTMethod(baseURL, method: method, parameters: parameters, headers: jsonPOSTHeaders, body: data, taskCompleteHandler: { (data, response, error) -> Void in
                // POST Complete
                if let existingError = error {
                    // Error: During PUT
                    taskCompleteHandler(jsonResponse: nil, response: response, error: existingError)
                    return
                }
                
                // Convert NSData to NSDictionary
                var dataError: NSError? = nil
                if let json = HTTPClient.dataToDictionary(data, error: &dataError) {
                    // Success
                    taskCompleteHandler(jsonResponse: json, response: response, error: nil)
                } else {
                    // Error while parsing json response
                    taskCompleteHandler(jsonResponse: nil, response: response, error: dataError)
                }
            })
            
            return task
        } else {
            // Error while converting the body JSON NSDictionary to NSData
            taskCompleteHandler(jsonResponse: nil, response: nil, error: jsonError)
            return nil
        }
    }
    
    
    // MARK: PUT NSData based
    // All methods are NSData based, which means that they receive and return NSData objects for the caller to
    // handle the way they need
    
    // The most generic PUT task method
    func taskForPUTMethod(baseURL: String, method: String, parameters: [String : AnyObject]?, headers: [String: String]?, body: NSData, taskCompleteHandler: (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void) -> NSURLSessionDataTask {
        
        // Build the URL and configure the request
        var urlString = baseURL + method
        
        // Concat the parameters if necesarry
        if let existingParameters = parameters {
            urlString += HTTPClient.escapedParameters(existingParameters)
        }
        
        // Build the Request
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "PUT"
        request.HTTPBody = body
        
        // Add headers if necesary
        if let existingHeaders = headers {
            for (key, value) in existingHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Create the task
        let task = session.dataTaskWithRequest(request, completionHandler: taskCompleteHandler)
        
        // Start the request
        task.resume()
        
        return task
    }
    
    // MARK: -
    
    // MARK: GET JSON/NSDictionary based
    // All methods are JSON/NSDictionary based, which means that they receive and return NSDictionary objects
    // for the caller to handle it the way they need
    
    
    func jsonTaskForGETMethod(baseURL: String, parameters: [String : AnyObject]?, taskCompleteHandler: (jsonResponse: NSDictionary!, response: NSURLResponse!, error: NSError!) -> Void) -> NSURLSessionDataTask {
        return jsonTaskForGETMethod(baseURL, method: "", parameters: parameters, headers: nil, taskCompleteHandler: taskCompleteHandler)
    }
    
    // GET Task method with a header dictionary
    func jsonTaskForGETMethod(baseURL: String, method: String, parameters: [String : AnyObject]?, headers: [String: String]?, taskCompleteHandler: (jsonResponse: NSDictionary!, response: NSURLResponse!, error: NSError!) -> Void) -> NSURLSessionDataTask {
        
        let jsonGETHeaders = HTTPClient.jsonGETHeaders(headers)
        
        let task = taskForGETMethod(baseURL, method: method, parameters: parameters, headers: jsonGETHeaders, taskCompleteHandler: { (data, response, error) -> Void in
            if let existingError = error {
                // Error: GET failed
                taskCompleteHandler(jsonResponse: nil, response: response, error: error)
                return
            }
            // Parse the data response
            var jsonError: NSError? = nil
            if let json = HTTPClient.dataToDictionary(data, error: &jsonError) {
                // Success: parsing complete
                taskCompleteHandler(jsonResponse: json, response: response, error: nil)
            } else {
                // Error: Could not parse
                taskCompleteHandler(jsonResponse: nil, response: response, error: jsonError)
            }
        })
        
        // Just return the task. It's already started
        return task
    }
    
    
    // MARK: GET NSData based
    // All methods are NSData based, which means that they receive and return NSData objects for the caller to
    // handle it the way they need
    
    
    // The most generic GET task method
    func taskForGETMethod(baseURL: String, method: String, parameters: [String : AnyObject]?, headers: [String: String]?, taskCompleteHandler: (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void) -> NSURLSessionDataTask {
        
        // Build the URL and configure the request
        var urlString = baseURL + method
        
        // Concat the parameters if necesarry
        if let existingParameters = parameters {
            urlString += HTTPClient.escapedParameters(existingParameters)
        }
        
        // Build the URL and the Request
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        
        // Add headers to the request if necesary
        if let existingHeaders = headers {
            for (key, value) in existingHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Create the task
        let task = session.dataTaskWithRequest(request, completionHandler: taskCompleteHandler)
        
        // Start the request
        task.resume()
        
        return task
    }
    
    // Singleton definition
    // MARK: Shared instance
    
    class func sharedInstance() -> HTTPClient {
        struct Static {
            static let instance = HTTPClient()
        }
        
        return Static.instance
    }
}



//
//  ErrorUtils.swift
//  OnTheMap
//
//  Created by Humberto Aquino on 4/14/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation

// Error utils for the App
class ErrorUtils {
    
    class func errorForJSONParsingToDictionary(data: NSData?) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data to a JSON dictionary"]
        return  NSError(domain: ErrorDomains.ServerError, code: ServerErrorCodes.JSONParsingError, userInfo: userInfo)
    }
    
    class func errorForJSONInterpreting(json: NSDictionary?) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : "Could not interpret json: \(json)"]
        return  NSError(domain: ErrorDomains.ServerError, code: ServerErrorCodes.JSONParsingError, userInfo: userInfo)
    }
    
    class func errorLoginFailureWith(message: String) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : message]
        return  NSError(domain: ErrorDomains.ClientError, code: ClientErrorCodes.InvalidCredentials, userInfo: userInfo)
    }
    
    class func errorUnexpectedWith(message: String) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : message]
        return  NSError(domain: ErrorDomains.ServerError, code: ServerErrorCodes.UnexpectedError, userInfo: userInfo)
    }

    class func errorToTuple(error: NSError) -> (String, String) {
        let msg = error.localizedDescription
        
        if error.domain == ErrorDomains.ClientError {
            switch error.code {
            case ClientErrorCodes.InvalidCredentials:
                return ("Invalid credentials", msg)
            case ClientErrorCodes.JSONParsingError:
                return ("JSON parsing error", msg)
            default:
                return ("Unexpected client error", msg)
            }
        } else if error.domain == ErrorDomains.ServerError {
            switch error.code {
            case ServerErrorCodes.JSONParsingError:
                return ("JSON parsing error", msg)
            default:
                return ("Unexpected server error", msg)
            }
        } else {
            if error.domain == "NSURLErrorDomain" {
                // Ref: http://nshipster.com/nserror/
                return ("Error trying to connect to the Internet", msg)
            } else {
                // System errors
                return ("Unexpected error", msg)
            }
        }
    }
}

extension ErrorUtils {

    struct ErrorDomains {
        static let ClientError = "ClientError"
        static let ServerError = "ServerError"
    }
    
    struct ClientErrorCodes {
        static let UnexpectedError = 1
        static let JSONParsingError = 2
        static let InvalidCredentials = 3
    }
    
    struct ServerErrorCodes {
        static let UnexpectedError = 1
        static let JSONParsingError = 2
        static let SkipDataError = 3
        static let UdacityJSONParsingError = 4
    }
}
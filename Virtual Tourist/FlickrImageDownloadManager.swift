//
//  FlickrImageDownloadManager.swift
//  Virtual Tourist
//
//  Created by Humberto Aquino on 4/21/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData

// Sinfleton used to download images from Flickr and save them into Core Data
class FlickrImageDownloadManager: NSObject {
    
    let httpClient = HTTPClient.sharedInstance()
    
    // This operation queue is used to download the images using NSData to prevent
    // Freezing the Main queue
    let downloadQueue = NSOperationQueue()
    
    lazy var sharedContext: NSManagedObjectContext! = {
       return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    override init() {
        super.init()
        downloadQueue.maxConcurrentOperationCount = Queue.DownloadQueueMaxConcurrentOperationCount
    }
    
    // MARK: - Fetch methods
    
    // Fetch a page of images for a pin location
    func fetchInitialPhotosForPin(pin: Pin, completionHandler:((totalFetched: Int?, error: NSError?) -> Void)) {
        
        // 1. Fetch photos of the location
        let page = pin.currentPage + 1
        let total = Pagination.TotalPhotosPerPage
        let coordinate = pin.coordinate
        
        // We get the JSON info to know what urls we need to download
        fetchPhotosJSONForLocation(coordinate, fromPage: page, total: total) {
            (json, error) in
            if let error = error {
                // Error during fetch
                self.performOnMainQueue {
                    completionHandler(totalFetched: nil, error: error)
                }
                return
            }
            
            var jsonError: NSError? = nil
            
            // 2. Parse the JSON to get photo urls
            var result = self.parsePhotos(json!, error: &jsonError)
            if let jsonError = jsonError {
                self.performOnMainQueue {
                    completionHandler(totalFetched: nil, error: error)
                }
                return
            }
            
            // 3. Create 21 (or the amount fetched) entities of Photos with the url of the image and the state: New
            let totalPhotos = result!.photoURLs.count
            for url in result!.photoURLs {
                let dictionary = [
                    Photo.Keys.ImageURL: url
                ]
                let photo = Photo(dictionary: dictionary, context: CoreDataStackManager.sharedInstance().managedObjectContext!)
                photo.pin = pin
            }
            
            // 4. Save the page number and the pages total in the Pin
            let totalPages = result!.pages
            if page >= totalPages {
                pin.currentPage = Pin.InitialPageNumber
            } else {
                pin.currentPage = page
            }
            pin.totalPages = result!.pages
            
            // 5. Save on main queue
            self.performOnMainQueue {
                pin.pendingDownloads = totalPhotos
                CoreDataStackManager.sharedInstance().saveContext()
                
                // The Photos are created and associated with the pin.
                // Call the caller to let them know that we know how much photos
                // we need to download
                completionHandler(totalFetched: totalPhotos, error: nil)
                
                // 6. Start the download of the images, if necesary
                self.downloadPinImages(pin)
            }
        }
    }
    
    // Do a paginated search of images using coordinate. The result is the JSON unalterated
    func fetchPhotosJSONForLocation(coordinate: CLLocationCoordinate2D, fromPage page: Int, total: Int, completionHandler:((json: NSDictionary?, error: NSError?) -> Void)) {
        
        let parameters = locationImagePaginatedSearch(coordinate, page: page, perPage: total)
        
        httpClient.jsonTaskForGETMethod(URLs.BaseURL, parameters: parameters) { (jsonResponse, response, error) -> Void in
            if let error = error {
                // Error in the GET request
                completionHandler(json: nil, error: error)
                return
            }
            // Success
            completionHandler(json: jsonResponse, error: nil)
        }
    }
    
    
    // MARK: - Downloading
    
    // Initiates the download of all the photos of the pin parameter
    func downloadPinImages(pin: Pin) {
        if let photos = pin.photos {
            if photos.count > 0 {
                downloadQueue.addOperationWithBlock {
                    for photo in photos {
                        self.downloadAndSavePhoto(photo)
                    }
                }
                return
            }
        }
        
        println("Pin does not have photos")
    }
    
    
    // Download a single photo and save it's data when done
    // This method should be performed on the download Queue
    func downloadAndSavePhoto(photo: Photo) {
        // Do it in another queue
        
        if photo.imageState == Photo.State.Ready {
            println("Image ready")
            return
        }
        
        if let url = NSURL(string: photo.imageURL!) {
            let timestamp = NSDate().timestampIntervalInMilliseconsSince1970()
            let postfixFilename = obtainPhotoFilename(url)
            let filename = "\(timestamp)_\(postfixFilename)"
            
            println("Downloading image: \(filename)")
            
            if let imageData = NSData(contentsOfURL: url) {      
                
                let imagePath = CoreDataStackManager.sharedInstance().pathForfilename(filename)!
                
                if imageData.writeToFile(imagePath, atomically: true) {
                    
                    photo.imageFilename = filename
                    photo.imageState = Photo.State.Ready
                    
                    self.performOnMainQueue {
                        if let pin = photo.pin {
                            pin.decreasePendingDownloads()
                        } else {
                            println("Photo downloaded without a pin")
                            abort()
                        }
                        // Save photo and pin count
                        CoreDataStackManager.sharedInstance().saveContext()
                        println("Saved: \(filename)")                  
                        
                    }
                } else {
                    // Could not save file
                    println("Could not save image to: \(imagePath)")
                }
            } else {
                println("Could not download image: \(url)")
            }
            
        } else {
            println("No valid url to download: \(photo.imageURL!)")
        }
    }
    
    // MARK: - Utilities
    
    func obtainPhotoFilename(photoURL: NSURL) -> String {
        let components = photoURL.pathComponents as! [String]
        return components.last!
    }
    
    // MARK: - Shared instance
    
    class func sharedInstance() -> FlickrImageDownloadManager {
        struct Static {
            static let instance = FlickrImageDownloadManager()
        }
        
        return Static.instance
    }
}


// MARK: - JSON utilities

extension FlickrImageDownloadManager {

    // Based on the search result, navigate the JSON and get the list of URLs to download
    // and the amount of pages according to Flickr
    func parsePhotos(json: NSDictionary, inout error: NSError?) -> (photoURLs:[String], pages: Int)? {
        if let photoInfo = json[ResponseKeys.Photos] as? NSDictionary {
            if let pages = photoInfo[ParameterValues.Pages] as? Int {
                
                if let photoList = photoInfo[ResponseKeys.Photo] as? NSArray {
                    var result:[String] = [String]()
                    for item in photoList {
                        if let url = item[ParameterValues.URLM] as? String {
                            result.append(url)
                        }
                    }
                    return (result, pages)
                }
            }
        }
        
        error = ErrorUtils.errorForJSONInterpreting(json)
        return nil
    }
    
}


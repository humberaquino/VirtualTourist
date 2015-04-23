//
//  TravelLocationsViewController.swift
//  Virtual Tourist
//
//  Created by Humberto Aquino on 4/20/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    // Map region keys for NSUserDefaults
    let MapSavedRegionExists = "map.savedRegionExists"
    let MapCenterLatitudeKey = "map.center.latitude"
    let MapCenterLongitudeKey = "map.center.longitude"
    let MapSpanLatitudeDeltaKey = "map.span.latitudeDelta"
    let MapSpanLongitudeDeltaKey = "map.span.longitudeDelta"
    
    // Identifier keys
    let LocationPinIdentifier = "LocationPinIdentifier"
    
    // Segues identifiers
    let ViewLocationImagesIdentifier = "ViewLocationImagesIdentifier"
    
    @IBOutlet weak var mapView: MKMapView!
    
    var tapRecognizer: UILongPressGestureRecognizer!
    
    var sharedContext: NSManagedObjectContext!
    
    var selectedPin: Pin!
    
    let photoService = PhotoService()
    let pinService = PinService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Core Data
        sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
        
        // Delegate setup
        mapView.delegate = self
        
        // Initialize Long press gesture recognizer to add pins to the map
        tapRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        tapRecognizer.minimumPressDuration = UI.MinimumPressDuration
        
        // Load previous map state
        loadPersistedMapViewRegion()
        
        // Load pins
//        loadAllPinLocations()
        
        var error: NSError?
        fetchedResultsController.performFetch(&error)
        
        if let error = error {
            println("Error performing initial fetch: \(error)")
        }
        
        configureAnnotations()
    }
    
    func configureAnnotations() {
        let annotations = mapView.annotations
        mapView.removeAnnotations(annotations)
        mapView.addAnnotations(fetchedResultsController.fetchedObjects)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mapView.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mapView.removeGestureRecognizer(tapRecognizer)
    }
    
    
    // MARK: - UILongPressGestureRecognizer
    
    func handleLongPress(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state != UIGestureRecognizerState.Began {
            return
        }
        
        let touchPoint = gestureRecognizer.locationInView(mapView)
        let touchMapCoordiantes = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        // TODO: Add anotation
        println("Create pin: \(touchMapCoordiantes)")
        
        
        addNewPinToMap(touchMapCoordiantes)
        
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var annotationView:MKPinAnnotationView! = mapView.dequeueReusableAnnotationViewWithIdentifier(LocationPinIdentifier) as? MKPinAnnotationView
        
        if annotationView != nil {
            annotationView.annotation = annotation
        } else {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: LocationPinIdentifier)
            annotationView.draggable = true
            annotationView.animatesDrop = true
            annotationView.canShowCallout = true
        }
        
        let detailButton: UIButton = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
        annotationView.rightCalloutAccessoryView = detailButton
        
        configurePinColor(pinAnnotationView: annotationView)
        
        return annotationView
    }
    
    func configurePinColor(pinAnnotationView view: MKPinAnnotationView) {
        
        let pin = view.annotation as! Pin
        var defaultColor: MKPinAnnotationColor = MKPinAnnotationColor.Green
        
        if pin.pendingDownloads > 0 {
             if pin.pendingDownloads < 10 {
                defaultColor = MKPinAnnotationColor.Purple
            } else {
                defaultColor = MKPinAnnotationColor.Red
            }
        }
        
        view.pinColor = defaultColor
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!,
        didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
            if newState == MKAnnotationViewDragState.Ending {
                let pin = view.annotation as! Pin
                
                if pin.pendingDownloads > 0 {
                    showMessageWithTitle("Operation not permited", message: "Can't change the pin's location while it is downloading images. Please wait until it turns green and try again.")
                } else {
                    // Add a pin history, update current pin and delete all the old photos. The save
                    pinService.addCurrentAsHistory(pin)
                    photoService.deletePinPhotosAndSave(pin)
                    
                    // Now we can start downloading the photos of the new location
                    downloadPhotosForPin(pin)
                    
//                    let pinAnnotationView = view as! MKPinAnnotationView
//                    configurePinColor(pinAnnotationView: pinAnnotationView)
                }
                
            }
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        if control == view.rightCalloutAccessoryView {
            let annotation = view.annotation as! Pin
            selectedPin = annotation
            performSegueWithIdentifier(ViewLocationImagesIdentifier, sender: self)
        }
    }
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        persistMapViewRegion(mapView.region)
    }
    
    // Mark: - Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == ViewLocationImagesIdentifier {
            let navigationController = segue.destinationViewController as! UINavigationController
            let destination = navigationController.viewControllers[0] as! PhotoAlbumViewController
            destination.selectedPin = selectedPin
        }
    }
    
    
    // MARK: - Persistense
    
    // MARK: Core Data
    
//    func loadAllPinLocations() {
//        
//        let request = NSFetchRequest(entityName: Pin.ModelName)
//        
//        var fetchError: NSError? = nil
//        var result = sharedContext.executeFetchRequest(request, error: &fetchError) as? [Pin]
//        if let error = fetchError {
//            // Error during fetch
//            // TODO: Show alert
//            return
//        }
//        // Add all fetched pins to the map
//        for pin in result! {
//            addExistingPinAnnotationToMap(pin)
//        }
//    }
    
    func addNewPinToMap(coordinate: CLLocationCoordinate2D) {        
        let dict = [
            Pin.Keys.Latitude: coordinate.latitude,
            Pin.Keys.Longitude: coordinate.longitude
        ]
        
        // Save new pin
        let pin = Pin(dictionary: dict, context: sharedContext)
        CoreDataStackManager.sharedInstance().saveContext()
        
//        addExistingPinAnnotationToMap(pin)
        
        downloadPhotosForPin(pin)
        
    }
    
    func downloadPhotosForPin(pin: Pin) {
        FlickrImageDownloadManager.sharedInstance().fetchInitialPhotosForPin(pin, completionHandler: { (totalFetched, error) -> Void in
            println("Initial fetch complete: \(totalFetched!)")
        })
    }
    
//    func addPinAnnotationToMap(pin: Pin) {
//        // Add an annotation whr the long tap was placed
//        let annotation = TouristPinAnnotation(pin: pin)
//        annotation.title = "View album"
//        mapView.addAnnotation(annotation)
//    }
    
    //////////////////////////
    // MARK: - Fetched Results Controller Delegate
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
//        insertedIndexPaths = [NSIndexPath]()
//        deletedIndexPaths = [NSIndexPath]()
//        updatedIndexPaths = [NSIndexPath]()
        
        println("in controllerWillChangeContent")
    }
    
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch (type) {
        case NSFetchedResultsChangeType.Insert:
            let annotation = anObject as! Pin
            annotation.title = "View Album (\(annotation.history!.count))"
            mapView.addAnnotation(annotation)
            break;
        case NSFetchedResultsChangeType.Delete:
            let annotation = anObject as! Pin
            self.mapView.removeAnnotation(annotation)
            break;
        case NSFetchedResultsChangeType.Update:

            let annotation = anObject as! Pin
            
//            configurePinColor
            
            
//            self.mapView.removeAnnotation(annotation)
//            annotation.title = "View Album \(annotation.pendingDownloads)"
//            self.mapView.addAnnotation(annotation)
            annotation.title = "View Album (\(annotation.history!.count))"
            let annotationView = mapView.viewForAnnotation(annotation) as! MKPinAnnotationView
            configurePinColor(pinAnnotationView: annotationView)
            
            break;
        case NSFetchedResultsChangeType.Move:
            // do nothing
            break;
            
        default:
            break;
        }
    }
    //////////////////////
    
    
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: Pin.ModelName)
        
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    // MARK: NSUserDefaults
    
    // Saves a region to NSUserDefaults
    func persistMapViewRegion(region: MKCoordinateRegion) {
        let userDetaults = NSUserDefaults.standardUserDefaults()
        
        userDetaults.setDouble(region.center.latitude, forKey: MapCenterLatitudeKey)
        userDetaults.setDouble(region.center.longitude, forKey: MapCenterLongitudeKey)
        userDetaults.setDouble(region.span.latitudeDelta, forKey: MapSpanLatitudeDeltaKey)
        userDetaults.setDouble(region.span.longitudeDelta, forKey: MapSpanLongitudeDeltaKey)
        userDetaults.setBool(true, forKey: MapSavedRegionExists)
    }
    
    
    // Load the saved region if exists in NSUserData
    func loadPersistedMapViewRegion() {
        let userDetaults = NSUserDefaults.standardUserDefaults()

        let savedRegionExists = userDetaults.boolForKey(MapSavedRegionExists)
        
        if (savedRegionExists) {
            let latitude = userDetaults.doubleForKey(MapCenterLatitudeKey)
            let longitude = userDetaults.doubleForKey(MapCenterLongitudeKey)
            let latitudeDelta = userDetaults.doubleForKey(MapSpanLatitudeDeltaKey)
            let longitudeDelta = userDetaults.doubleForKey(MapSpanLongitudeDeltaKey)
            
            
            mapView.region.center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            mapView.region.span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        }
        
    }
    
}
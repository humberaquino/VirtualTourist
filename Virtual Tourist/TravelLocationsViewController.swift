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
    
    // Helper variable to know which pin to view the album
    var selectedPin: Pin!
    
    let photoService = PhotoService()
    let pinService = PinService()
    
    
    // MARK: - View life cycle
    
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
        
        // Do the initial fetch
        var error: NSError?
        fetchedResultsController.performFetch(&error)
        
        if let error = error {
            println("Error performing initial fetch: \(error)")
        }
        
        configureAnnotations()
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
            annotationView.animatesDrop = true
            annotationView.canShowCallout = true
            annotationView.draggable = false
        }
        
        let detailButton: UIButton = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
        annotationView.rightCalloutAccessoryView = detailButton
        
        configurePinColor(pinAnnotationView: annotationView)
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!,
        didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
            let pin = view.annotation as! Pin

            if newState == MKAnnotationViewDragState.Ending {
                if pin.pendingDownloads == 0 {
                    // Add a pin history, update current pin and delete all the old photos. The save
                    pinService.addCurrentAsHistory(pin)
                    photoService.deletePinPhotosAndSave(pin)
                    
                    // Mark the dragged pin as red
                    let pinAnnotationView = view as! MKPinAnnotationView
                    pinAnnotationView.pinColor = MKPinAnnotationColor.Red
                    
                    // Now we can start downloading the photos of the new location
                    downloadPhotosForPin(pin)
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
    
    func configurePinColor(pinAnnotationView view: MKPinAnnotationView) {
        
        let pin = view.annotation as! Pin
        var defaultColor: MKPinAnnotationColor = MKPinAnnotationColor.Green
        
        if pin.pendingDownloads == -1 {
            defaultColor = MKPinAnnotationColor.Red
            view.draggable = false
        } else if pin.pendingDownloads == 0 {
            view.pinColor = MKPinAnnotationColor.Green
            view.draggable = true
        } else {
            if pin.pendingDownloads < 10 {
                 view.pinColor = MKPinAnnotationColor.Purple
            } else {
                 view.pinColor = MKPinAnnotationColor.Red
            }
            // Prevent dragging
            view.draggable = false
        }
        
        
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
    
    func addNewPinToMap(coordinate: CLLocationCoordinate2D) {        
        let dict = [
            Pin.Keys.Latitude: coordinate.latitude,
            Pin.Keys.Longitude: coordinate.longitude
        ]
        
        // Save new pin
        let pin = Pin(dictionary: dict, context: sharedContext)
        CoreDataStackManager.sharedInstance().saveContext()
        
        downloadPhotosForPin(pin)
    }
    
    func downloadPhotosForPin(pin: Pin) {
        FlickrImageDownloadManager.sharedInstance().fetchInitialPhotosForPin(pin, completionHandler: { (totalFetched, error) -> Void in
            println("Initial fetch complete: \(totalFetched!)")
        })
    }

    // MARK: - NSFetchedResultsControllerDelegate
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        let pin = anObject as! Pin
        
        switch (type) {
        case NSFetchedResultsChangeType.Insert:
            insertAnnotation(pin)
            break;
        case NSFetchedResultsChangeType.Delete:
            removeAnnotation(pin)
            break;
        case NSFetchedResultsChangeType.Update:
            updateAnnotation(pin)
            break;
        case NSFetchedResultsChangeType.Move:
            // do nothing
            break;
            
        default:
            break;
        }
    }
    
    // MARK: - Utilities
    
    func insertAnnotation(pin: Pin) {
        setupPinTitle(pin)
        mapView.addAnnotation(pin)
    }
    
    func updateAnnotation(pin: Pin) {
        setupPinTitle(pin)
        let annotationView = mapView.viewForAnnotation(pin) as! MKPinAnnotationView
        configurePinColor(pinAnnotationView: annotationView)
    }
    
    func removeAnnotation(pin: Pin) {
        mapView.removeAnnotation(pin)
    }
    
    func setupPinTitle(pin: Pin) {
        var title = "View Album"
        if let history = pin.history {
            if history.count > 1 {
                title += " (\(history.count))"
            }
        }
        
        pin.title = title
    }
    
    func showDraggingNotAllowedMessage() {
        showMessageWithTitle("Operation not permited", message: "Can't change the pin's location while it is downloading images. Please wait until it turns green and try again.")
    }
    
    // Utility method to start a fresh mapview
    func configureAnnotations() {
        let annotations = mapView.annotations
        mapView.removeAnnotations(annotations)
        mapView.addAnnotations(fetchedResultsController.fetchedObjects)
    }
    
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
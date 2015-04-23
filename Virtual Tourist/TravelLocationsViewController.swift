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

class TravelLocationsViewController: UIViewController, MKMapViewDelegate {
    
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
        loadAllPinLocations()
        
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
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!,
        didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
            if newState == MKAnnotationViewDragState.Ending {
                let pinAnnotation = view.annotation as! TouristPinAnnotation
                
                pinAnnotation.syncAnnotationCoordinatesToPin()
                
                photoService.deletePinPhotosAndSave(pinAnnotation.pin)
                
                downloadPhotosForPin(pinAnnotation.pin)
            }
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        if control == view.rightCalloutAccessoryView {
            let annotation = view.annotation as! TouristPinAnnotation
            selectedPin = annotation.pin
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
    
    func loadAllPinLocations() {
        
        let request = NSFetchRequest(entityName: Pin.ModelName)
        
        var fetchError: NSError? = nil
        var result = sharedContext.executeFetchRequest(request, error: &fetchError) as? [Pin]
        if let error = fetchError {
            // Error during fetch
            // TODO: Show alert
            return
        }
        // Add all fetched pins to the map
        for pin in result! {
            addExistingPinAnnotationToMap(pin)
        }
    }
    
    func addNewPinToMap(coordinate: CLLocationCoordinate2D) {        
        let dict = [
            Pin.Keys.Latitude: coordinate.latitude,
            Pin.Keys.Longitude: coordinate.longitude
        ]
        
        // Save new pin
        let pin = Pin(dictionary: dict, context: sharedContext)
        CoreDataStackManager.sharedInstance().saveContext()
        
        addExistingPinAnnotationToMap(pin)
        
        downloadPhotosForPin(pin)
        
    }
    
    func downloadPhotosForPin(pin: Pin) {
        FlickrImageDownloadManager.sharedInstance().fetchInitialPhotosForPin(pin, completionHandler: { (totalFetched, error) -> Void in
            println("Initial fetch complete: \(totalFetched!)")
        })
    }
    
    func addExistingPinAnnotationToMap(pin: Pin) {
        // Add an annotation whr the long tap was placed
        let annotation = TouristPinAnnotation(pin: pin)
        annotation.title = "View album"
        mapView.addAnnotation(annotation)
    }
    
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
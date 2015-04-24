//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Humberto Aquino on 4/21/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit


// View controller to display the photo album
class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    let NoPhotosAtLocation = "No photos at current location"
    
    let PhotoCell = "PhotoCell"
    let LocationSpanValue = 0.004
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var collectionCenteredLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    
    var selectedPin: Pin!
    
    // Service layer to interact with Core Data and the photos
    let photoService = PhotoService()
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start the fetched results controller
        var error: NSError?
        fetchedResultsController.performFetch(&error)
        
        if let error = error {
            println("Error performing initial fetch: \(error)")
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        enableNewCollectionButtonIfPossible()
        
        if !selectedPinHasPhotos() {
            displayCenteredLabel(NoPhotosAtLocation)
        } else {
            hideCenteredLabel()
        }
       
        mapView.removeAnnotations(mapView.annotations)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        setupSelectedPinOnMap()

    }
    
   
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        
        println("Number of cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhotoCell, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        // Delete image
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        photoService.deletePhotoAndSave(photo)
        

    }
    
    func configureCell(cell: PhotoCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if let imageFilename = photo.imageFilename {
            let imagePath = CoreDataStackManager.sharedInstance().imagesDocumentDirectory.URLByAppendingPathComponent(imageFilename)

            cell.imageView.image = UIImage(contentsOfFile: imagePath.path!)
            cell.activityIndicator.stopAnimating()
        } else {
            if photo.imageState == Photo.State.Failure {
                println("Download failed")
            } else {
                // Image not downloaded yet
                cell.activityIndicator.startAnimating()
                cell.imageView.image = nil
            }
        }
    }
    

    
    
    // MARK: - Actions
    
    @IBAction func newCollectionAction(sender: UIBarButtonItem) {
        
        println("Clear current photo list")
        
        newCollectionButton.enabled = false
        
        if let photos = selectedPin.photos {
            if photos.count > 0 {

                self.displayCenteredLabel("Downloading photos...")                
                
                for photo in photos {
                    photo.pin = nil
                }
                // Persist
                CoreDataStackManager.sharedInstance().saveContext()
            }
        }
        
        // Get a new Colleciton for the pin
        FlickrImageDownloadManager.sharedInstance().fetchInitialPhotosForPin(selectedPin, completionHandler: { (totalFetched, error) -> Void in
            if let error = error {
                self.showMessageWithTitle("Download error", message: "\(error.localizedDescription). Please try again in a few minutes")
                self.markAsNoPhotosAtLocation()
                return
            }
            
            if totalFetched == 0 {
                self.markAsNoPhotosAtLocation()
                return
            } else {
                self.hideCenteredLabel()
                println("Initial fetch complete: \(totalFetched!)")
            }
        })
        
    }
    
    // MARK: - Utilities
    
    func markAsNoPhotosAtLocation() {
        self.displayCenteredLabel(self.NoPhotosAtLocation)
        self.newCollectionButton.enabled = true
    }
    
    func enableNewCollectionButtonIfPossible() {
        newCollectionButton.enabled = selectedPinAllPhotosDownloaded()
    }
    
    // Display a text in the centered label. Used for message about the collection
    func displayCenteredLabel(message: String) {
        collectionCenteredLabel.alpha = 0
        collectionCenteredLabel.text = message
        self.collectionCenteredLabel.hidden = false
        
        UIView.animateWithDuration(0.8, animations: { () -> Void in
            self.collectionCenteredLabel.alpha = 1
        })
    }
    
    func hideCenteredLabel() {        
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            self.collectionCenteredLabel.alpha = 0
        }) { (success) -> Void in
            self.collectionCenteredLabel.hidden = true
        }
    }
    
    // true in case al photos are downloaded for a pin. If it doesn't have photos also returns true
    func selectedPinAllPhotosDownloaded() -> Bool {
        if selectedPinHasPhotos() {
            if let photos = selectedPin.photos {
                for photo in photos {
                    if photo.imageState == Photo.State.New  {
                        return false
                    }
                }
            }
        }
        return true
    }
    
    func selectedPinHasPhotos() -> Bool {
        if let photos = selectedPin.photos {
            if photos.count > 0 {
                // At least one
                return true
            }
        }
        return false
    }
    
    func setupSelectedPinOnMap() {
        mapView.addAnnotation(selectedPin)
        let span = MKCoordinateSpan(latitudeDelta: LocationSpanValue, longitudeDelta: LocationSpanValue)
        let region = MKCoordinateRegion(center: selectedPin.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: Photo.ModelName)
        
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.selectedPin)
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
}
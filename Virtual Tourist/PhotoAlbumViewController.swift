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

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    let NoPhotosAtLocation = "No photos at current location"
    
    let PhotoCell = "PhotoCell"
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var collectionCenteredLabel: UILabel!
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    
    var selectedPin: Pin!
    
    let photoService = PhotoService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start the fetched results controller
        var error: NSError?
        fetchedResultsController.performFetch(&error)
        
        if let error = error {
            println("Error performing initial fetch: \(error)")
        }
        
//        // TODO: Remove
//        let fetchRequest = NSFetchRequest(entityName: Photo.ModelName)
//        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.selectedPin)
//        let results = sharedContext.executeFetchRequest(fetchRequest, error: &error) as! [Photo]
//        if let error = error {
//            println("Error performing fetch: \(error)")
//            return
//        }
//        
//        for photo in results {
//            println("results: \(photo)")
//        }
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
//        self.collectionView.reloadData()
        
        enableNewCollectionButtonIfPossible()
        
        if !selectedPinHasPhotos() {
            displayCenteredLabel(NoPhotosAtLocation)
        } else {
            hideCenteredLabel()
        }
       
    }
    
    
    
    
    // MARK: UICollectionViewDataSource
    
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
    
  
    // MARK: - Fetched Results Controller Delegate
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        println("in controllerWillChangeContent")
    }
    
    // The second method may be called multiple times, once for each Color object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            println("Insert an item")
            // Here we are noting that a new Color instance has been added to Core Data. We remember its index path
            // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
            // the index path that we want in this case
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            println("Delete an item")
            // Here we are noting that a Color instance has been deleted from Core Data. We keep remember its index path
            // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
            // value that we want in this case.
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            println("Update an item.")
            // We don't expect Color instances to change after they are created. But Core Data would
            // notify us of changes if any occured. This can be useful if you want to respond to changes
            // that come about after data is downloaded. For example, when an images is downloaded from
            // Flickr in the Virtual Tourist app
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            println("Move an item. We don't expect to see this in this app.")
            break
        default:
            break
        }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        println("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: { (success) in
                if self.updatedIndexPaths.count > 0 || self.insertedIndexPaths.count > 0 {
                    self.enableNewCollectionButtonIfPossible()
                }
            })
        
    }

    
    // MARK: - Configure Cell
    
    func configureCell(cell: PhotoCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if let imageFilename = photo.imageFilename {
            let imagePath = CoreDataStackManager.sharedInstance().imagesDocumentDirectory.URLByAppendingPathComponent(imageFilename)

            // TODO: Add error checking for absolute string
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
    
    // MARK: - NSFetchedResultsController
    

    
    
//    func enableNewCollectionButtonIfPossible() {
//
//        if selectedPinAllPhotosDownloaded() {
//            newCollectionButton.enabled = true
//        }
//        
////        if selectedIndexes.count > 0 {
////            newCollectionButton.title = "Remove selected photos"
////        } else {
////            newCollectionButton.title = "Clear all"
////        }
//    }
    
    
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
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: Photo.ModelName)
        
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.selectedPin)
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
}
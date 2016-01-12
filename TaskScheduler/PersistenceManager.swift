//
//  PersistenceManager.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 12/29/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import Foundation
import CoreData
import JSQCoreDataKit

// A delegate for controllers to conform to to get
// updates about data changes from this class
protocol PersistenceManagerDelegate: class {
    // Called whenever the underlying data changes
    func persitenceManagerDataChanged()
}

class PersistenceManager: NSObject {
    static let sharedInstance = PersistenceManager()
    
    private var delegates: [PersistenceManagerDelegate]
    private var latestUser: User?
    var coreDataStack: CoreDataStack?
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let model = CoreDataModel(name: "TaskScheduler", bundle: NSBundle(identifier: "com.boztalay.TaskScheduler")!)
        self.coreDataStack = CoreDataStack(model: model)
        
        let fetchRequest = NSFetchRequest(entityName: "User")
        // NSFetchRequest requires at least one sort descriptor
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sunAvailableWorkTime", ascending: true)]
        fetchRequest.includesSubentities = true
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.coreDataStack!.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        self.subscribeToDataSaves()
        
        return controller
    }()
    
    // Called whenever the underlying data gets saved
    func handleManagedObjectContextDidSave(notification: NSNotification) {
        updateLatestUser()
        
        for delegate in self.delegates {
            dispatch_async(dispatch_get_main_queue()) {
                // Calling this in the main queue to avoid updating the UI on
                // a different thread, might need to change in the future so that
                // delegates handle this themselves in a more precise fashion. But
                // for now, I haven't noticed any performance issues.
                delegate.persitenceManagerDataChanged()
            }
        }
    }

    private func subscribeToDataSaves() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleManagedObjectContextDidSave:"), name: NSManagedObjectContextDidSaveNotification, object: self.coreDataStack!.managedObjectContext)
    }
    
    override init() {
        self.delegates = []

        super.init()

        updateLatestUser()
    }
    
    // Updates the latest user object by fetching whatever is
    // on the disk, could make self.latestUser nil
    private func updateLatestUser() {
        try! fetchedResultsController.performFetch()
        if let fetchedObjects = self.fetchedResultsController.fetchedObjects {
            if fetchedObjects.count > 0 {
                self.latestUser = fetchedObjects[0] as? User
                return
            }
        }
        
        // If the fetched results controller didn't find anything, set
        // latestUser to nil to reflect that (if, for some reason, there
        // was a stored User, then it disappeared)
        self.latestUser = nil
    }

    func getLatestUserData() -> User? {
        return self.latestUser
    }
    
    // Adds a delegate to the list of delegates
    // Note that this checks for duplicates
    func addDelegate(newDelegate: PersistenceManagerDelegate) {
        if self.delegates.indexOf({ $0 === newDelegate}) == nil {
            self.delegates.append(newDelegate)
        }
    }
    
    // Removes the given delegate from the list of delegates
    // Doesn't do anything if the delegate is not in the list
    func removeDelegate(delegateToRemove: PersistenceManagerDelegate) {
        if let index = self.delegates.indexOf({ $0 === delegateToRemove }) {
            self.delegates.removeAtIndex(index)
        }
    }
    
    // Saves the context to disk and waits for completion
    // Returns whether or not the save was successful
    func saveDataAndWait() -> Bool {
        let saveResult = saveContextAndWait(self.coreDataStack!.managedObjectContext)
        return saveResult.success
    }
    
    // Deletes the given objects from the context
    func deleteStoredObjects<T: NSManagedObject>(objectsToDelete: [T]) {
        deleteObjects(objectsToDelete, inContext: self.coreDataStack!.managedObjectContext)
    }
}

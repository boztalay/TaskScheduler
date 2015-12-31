//
//  PersistenceController.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 12/29/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import Foundation
import CoreData
import JSQCoreDataKit

protocol PersistenceControllerDelegate : class {
    func persitenceControllerDataChanged()
}

class PersistenceController {

    static let sharedInstance = PersistenceController()
    
    private var delegates: [PersistenceControllerDelegate]
    private var latestUser: User?
    private var coreDataStack: CoreDataStack?
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let model = CoreDataModel(name: "TaskScheduler", bundle: NSBundle(identifier: "com.boztalay.TaskScheduler")!)
        self.coreDataStack = CoreDataStack(model: model)
        
        let fetchRequest = NSFetchRequest(entityName: "User")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sunAvailableWorkTime", ascending: true)]
        fetchRequest.includesSubentities = true
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.coreDataStack!.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        self.subscribeToDataSaves()
        
        return controller
    }()
    
    private func handleManagedObjectContextDidSave(notification: NSNotification) {
        updateLatestUser()
        
        for delegate in self.delegates {
            delegate.persitenceControllerDataChanged()
        }
    }
    
    private func subscribeToDataSaves() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleManagedObjectContextDidSave:"), name: NSManagedObjectContextDidSaveNotification, object: self.coreDataStack!.managedObjectContext)
    }
    
    init() {
        self.delegates = []
        
        try! fetchedResultsController.performFetch()
        updateLatestUser()
    }
    
    private func updateLatestUser() {
        if let fetchedObjects = self.fetchedResultsController.fetchedObjects {
            if fetchedObjects.count > 0 {
                self.latestUser = fetchedObjects[0] as? User
            }
        }
    }
    
    func getLatestUserData() -> User? {
        return self.latestUser
    }
    
    func addDelegate(newDelegate: PersistenceControllerDelegate) {
        self.delegates.append(newDelegate)
    }
    
    func removeDelegate(delegateToRemove: PersistenceControllerDelegate) {
        if let index = self.delegates.indexOf({ $0 === delegateToRemove }) {
            self.delegates.removeAtIndex(index)
        }
    }
}

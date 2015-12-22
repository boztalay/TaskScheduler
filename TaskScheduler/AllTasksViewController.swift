//
//  AllTasksViewController.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 12/21/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit
import CoreData
import JSQCoreDataKit

class AllTasksViewController: UITableViewController, UITabBarControllerDelegate {
    
    var coreDataStack: CoreDataStack?
    var user: User?
    var sortedTasks: [Task]?
    
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
    
    func handleManagedObjectContextDidSave(notification: NSNotification) {
        self.reloadTasks()
    }
    
    func subscribeToDataSaves() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleManagedObjectContextDidSave:"), name: NSManagedObjectContextDidSaveNotification, object: self.coreDataStack!.managedObjectContext)
    }
    
    func unsubscribeFromDataSaves() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.tableView.allowsMultipleSelectionDuringEditing = false
        self.tabBarController?.delegate = self
        
        try! fetchedResultsController.performFetch()
        
        self.reloadTasks()
    }
    
    func reloadTasks() {
        if let fetchedObjects = self.fetchedResultsController.fetchedObjects {
            if fetchedObjects.count > 0 {
                self.user = fetchedObjects[0] as? User
            }
        }
        
        self.sortedTasks = self.user?.tasksArray.sort() { $0.dueDate.compare($1.dueDate) == .OrderedAscending }
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sortedTasks = self.sortedTasks {
            return sortedTasks.count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TaskCell", forIndexPath: indexPath) as! TaskTableViewCell
        
        let task = self.sortedTasks![indexPath.row]
        cell.setTask(task)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("AllTasksToEditTask", sender: self.sortedTasks![indexPath.row])
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the task

            let taskToDelete = [self.sortedTasks![indexPath.row]]
            deleteObjects(taskToDelete, inContext: self.coreDataStack!.managedObjectContext)
            
            // Save the context
            
            let saveResult = saveContextAndWait(self.coreDataStack!.managedObjectContext)
            if !saveResult.success {
                print("Couldn't save the context: \(saveResult.error)")
            }
        }
    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        self.tableView.setEditing(false, animated: true)
    }
    
    @IBAction func addButtonPressed(sender: AnyObject) {
        self.performSegueWithIdentifier("AllTasksToNewTask", sender: nil)
        self.tableView.setEditing(false, animated: true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navigationController = segue.destinationViewController as? UINavigationController
        
        if segue.identifier == "AllTasksToNewTask" || segue.identifier == "AllTasksToEditTask" {
            let editTaskViewController: EditTaskViewController
            if let navigationController = navigationController {
                editTaskViewController = navigationController.viewControllers.first as! EditTaskViewController
            } else {
                editTaskViewController = segue.destinationViewController as! EditTaskViewController
            }
            
            editTaskViewController.task = sender as? Task
            editTaskViewController.user = self.user
            editTaskViewController.coreDataStack = coreDataStack
        }
    }
}

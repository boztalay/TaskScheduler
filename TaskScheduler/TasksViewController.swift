//
//  TasksViewController.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/18/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit
import CoreData
import JSQCoreDataKit

class TasksViewController: UITableViewController, UITabBarControllerDelegate, SchedulerDelegate, SetupViewControllerDelegate {
    
    var coreDataStack: CoreDataStack?
    var user: User?
    var scheduler: Scheduler?
    
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
    
    func handleManagedObjectContextDidChange(notification: NSNotification) {
        self.refreshSchedule()
    }
    
    func subscribeToDataSaves() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleManagedObjectContextDidChange:"), name: NSManagedObjectContextDidSaveNotification, object: self.coreDataStack!.managedObjectContext)
    }
    
    func unsubscribeFromDataSaves() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.tableView.allowsMultipleSelectionDuringEditing = false
        
        self.tabBarController?.delegate = self
        
        self.fetchOrCreateUser()
    }
    
    func fetchOrCreateUser() {
        try! fetchedResultsController.performFetch()
        
        if fetchedResultsController.fetchedObjects?.count <= 0 {
            self.performSegueWithIdentifier("TasksToSetup", sender: nil)
        } else {
            // Need to do this manually on the first fetch because controllerDidChangeContent
            // only gets called for subsequent changes
            self.refreshSchedule()
        }
    }
    
    func refreshSchedule() {
        if let fetchedObjects = self.fetchedResultsController.fetchedObjects {
            if fetchedObjects.count > 0 {
                self.user = fetchedObjects[0] as? User
                self.scheduler = Scheduler(user: self.user!, coreDataStack: self.coreDataStack!)
                self.scheduler!.delegate = self
                self.scheduler!.scheduleTasksForUser()
            }
        }
    }
    
    func setupComplete(workSchedule: AvailableWorkSchedule) {
        self.user = User(context: self.coreDataStack!.managedObjectContext)
        self.user!.scheduleWorkTime(workSchedule)
        saveContext(self.coreDataStack!.managedObjectContext) { (result) -> Void in
            if !result.success {
                print("Couldn't save the context: \(result.error)")
            } else {
                
            }
        }
    }
    
    func scheduleStarted() {
        print("Schedule started")
        self.unsubscribeFromDataSaves()
    }
    
    func scheduleCompleted(status: ScheduleStatus) {
        if status == ScheduleStatus.Failed {
            print("Schedule failed")
        } else {
            print("Schedule success")
            self.tableView.reloadData()
        }
        self.subscribeToDataSaves()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let user = self.user {
            return user.tasksArray.count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Task Cell", forIndexPath: indexPath) as! TaskTableViewCell
        
        let task = self.user!.tasksArray[indexPath.row]
        cell.setTask(task)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("TasksToEditTask", sender: self.fetchedResultsController.fetchedObjects![indexPath.row])
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the task
            
            let taskToDelete = [self.fetchedResultsController.fetchedObjects![indexPath.row] as! Task]
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
        self.performSegueWithIdentifier("TasksToNewTask", sender: nil)
        self.tableView.setEditing(false, animated: true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navigationController = segue.destinationViewController as? UINavigationController
        
        if segue.identifier == "TasksToNewTask" || segue.identifier == "TasksToNewTask" {
            let editTaskViewController: EditTaskViewController
            if let navigationController = navigationController {
                editTaskViewController = navigationController.viewControllers.first as! EditTaskViewController
            } else {
                editTaskViewController = segue.destinationViewController as! EditTaskViewController
            }
        
            editTaskViewController.task = sender as? Task
            editTaskViewController.user = self.user
            editTaskViewController.coreDataStack = coreDataStack
        } else if segue.identifier == "TasksToSetup" {
            let setupViewController = navigationController!.viewControllers.first as! SetupViewController
            setupViewController.delegate = self
        }
    }
}

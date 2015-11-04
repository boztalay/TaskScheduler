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
    
    func handleManagedObjectContextDidSave(notification: NSNotification) {
        self.refreshSchedule()
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
        
        self.fetchOrCreateUser()
    }
    
    func fetchOrCreateUser() {
        try! fetchedResultsController.performFetch()
        
        if fetchedResultsController.fetchedObjects?.count <= 0 {
            self.performSegueWithIdentifier("TasksToSetup", sender: nil)
        } else {
            // Need to do this manually on the first fetch
            self.refreshSchedule()
        }
    }
    
    func refreshSchedule() {
        try! fetchedResultsController.performFetch()
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
        
        let saveResult = saveContextAndWait(self.coreDataStack!.managedObjectContext)
        if !saveResult.success {
            print("Couldn't save the context: \(saveResult.error)")
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
            printTasks()
            self.tableView.reloadData()
        }
        self.subscribeToDataSaves()
    }
    
    func printTasks() {
        print("\(self.user!.todayWorkDay().date)")
        for workSession in self.user!.todayWorkDay().workSessionsArray {
            print("- \(workSession.parentTask.title) for \(workSession.amountOfWork) on \(workSession.dayScheduledOn.date)")
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let user = self.user {
            return user.todayWorkDay().workSessionsArray.count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Task Cell", forIndexPath: indexPath) as! WorkSessionTableViewCell
        
        let workSession = self.user!.todayWorkDay().workSessionsArray[indexPath.row]
        cell.setWorkSession(workSession)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("TasksToEditTask", sender: self.user!.todayWorkDay().workSessionsArray[indexPath.row].parentTask)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the work session's task
            
            let workSession = self.user!.todayWorkDay().workSessionsArray[indexPath.row]
            let taskToDelete = [workSession.parentTask]
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
        
        if segue.identifier == "TasksToNewTask" || segue.identifier == "TasksToEditTask" {
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

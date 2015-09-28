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

class TasksViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var coreDataStack: CoreDataStack?
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let model = CoreDataModel(name: "TaskScheduler", bundle: NSBundle(identifier: "com.boztalay.TaskScheduler")!)
        self.coreDataStack = CoreDataStack(model: model)
        
        let fetchRequest = NSFetchRequest(entityName: "Task")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: false)]
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.coreDataStack!.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        
        return controller
    }()
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        try! fetchedResultsController.performFetch()
        
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fetchedObjects = self.fetchedResultsController.fetchedObjects {
            return fetchedObjects.count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Task Cell", forIndexPath: indexPath) as! TaskTableViewCell
        
        let task = self.fetchedResultsController.fetchedObjects![indexPath.row] as! Task
        cell.setTask(task)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("TasksToEditTask", sender: self.fetchedResultsController.fetchedObjects![indexPath.row])
    }

    @IBAction func addButtonPressed(sender: AnyObject) {
        self.performSegueWithIdentifier("TasksToNewTask", sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navigationController = segue.destinationViewController as? UINavigationController
        let editTaskViewController: EditTaskViewController
        
        if let navigationController = navigationController {
            editTaskViewController = navigationController.viewControllers.first as! EditTaskViewController
        } else {
            editTaskViewController = segue.destinationViewController as! EditTaskViewController
        }
        
        if segue.identifier == "TasksToEditTask" {
            editTaskViewController.task = sender as? Task!
        }
        
        editTaskViewController.coreDataStack = coreDataStack
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

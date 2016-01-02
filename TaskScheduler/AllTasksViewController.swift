//
//  AllTasksViewController.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 12/21/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

class AllTasksViewController: UITableViewController, UITabBarControllerDelegate, PersistenceControllerDelegate {
    
    let persistenceController = PersistenceController.sharedInstance
    
    var user: User?
    var sortedTasks: [Task]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.persistenceController.addDelegate(self)
        
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.tableView.allowsMultipleSelectionDuringEditing = false
        self.tabBarController?.delegate = self
        
        self.reloadTasks()
    }
    
    func persitenceControllerDataChanged() {
        self.reloadTasks()
    }
    
    func reloadTasks() {
        self.user = self.persistenceController.getLatestUserData()
        
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
            self.persistenceController.deleteStoredObjects(taskToDelete)
            
            // Save the context
            
            if !self.persistenceController.saveDataAndWait() {
                print("Couldn't save the data")
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
        }
    }
}

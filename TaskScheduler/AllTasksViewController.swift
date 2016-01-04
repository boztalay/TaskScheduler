//
//  AllTasksViewController.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 12/21/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

class AllTasksViewController: UITableViewController, PersistenceControllerDelegate, CellSlideActionManagerDelegate {
    
    let persistenceController = PersistenceController.sharedInstance
    let cellSlideActionManager = CellSlideActionManager()
    
    var user: User?
    var currentTasks: [Task]?
    var pastTasks: [Task]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.persistenceController.addDelegate(self)
        
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.tableView.allowsMultipleSelectionDuringEditing = false
        self.tableView.registerNib(GenericTaskTableViewCell.Nib, forCellReuseIdentifier: GenericTaskTableViewCell.ReuseIdentifier)
        
        self.cellSlideActionManager.delegate = self
        
        self.reloadTasks()
    }
    
    func persitenceControllerDataChanged() {
        self.reloadTasks()
    }
    
    func reloadTasks() {
        self.user = self.persistenceController.getLatestUserData()
        
        self.currentTasks = self.user?.tasksArray.filter({ !$0.isDueInPast })
        self.pastTasks = self.user?.tasksArray.filter({ $0.isDueInPast })
        
        self.currentTasks!.sortInPlace({ $0.priority > $1.priority })
        self.currentTasks!.sortInPlace({ $0.workEstimate > $1.workEstimate })
        self.currentTasks!.sortInPlace({ $0.dueDate.compare($1.dueDate) == .OrderedAscending })
        
        self.pastTasks!.sortInPlace({ $0.priority > $1.priority })
        self.pastTasks!.sortInPlace({ $0.workEstimate > $1.workEstimate })
        self.pastTasks!.sortInPlace({ $0.dueDate.compare($1.dueDate) == .OrderedDescending })
        
        self.tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if let currentTasks = self.currentTasks {
                return currentTasks.count
            }
        } else if section == 1 {
            if let pastTasks = self.pastTasks {
                return pastTasks.count
            }
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Current Tasks"
        } else if section == 1  {
            return "Past Tasks"
        } else {
            return "ERROR"
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(GenericTaskTableViewCell.ReuseIdentifier, forIndexPath: indexPath) as! GenericTaskTableViewCell
        var task: Task
        
        if indexPath.section == 0 {
            task = self.currentTasks![indexPath.row]
        } else {
            task = self.pastTasks![indexPath.row]
        }
        
        cell.setFromTask(task)
        
        if task.isComplete {
            self.cellSlideActionManager.addMarkIncompleteAndDeleteSlideActionsToCell(cell)
        } else {
            self.cellSlideActionManager.addMarkCompleteAndDeleteSlideActionsToCell(cell)
        }
        
        return cell
    }
    
    func cellSlideMarkCompleteActionTriggered(tableView: UITableView, indexPath: NSIndexPath) {
        var task: Task
        if indexPath.section == 0 {
            task = self.currentTasks![indexPath.row]
        } else {
            task = self.pastTasks![indexPath.row]
        }
        
        task.isComplete = true
        
        // Save the context
        if !self.persistenceController.saveDataAndWait() {
            print("Couldn't save the data")
        }
    }
    
    func cellSlideMarkIncompleteActionTriggered(tableView: UITableView, indexPath: NSIndexPath) {
        var task: Task
        if indexPath.section == 0 {
            task = self.currentTasks![indexPath.row]
        } else {
            task = self.pastTasks![indexPath.row]
        }
        
        if task.workLeftToDo == 0.0 {
            self.showIncreaseEstimateAlertForTask(task)
        } else {
            task.isComplete = false
            
            // Save the context
            if !self.persistenceController.saveDataAndWait() {
                print("Couldn't save the data")
            }
        }
    }
    
    private func showIncreaseEstimateAlertForTask(task: Task) {
        let alert = UIAlertController(title: "Increase Estimate", message: "Looks like there's no more work to be done on this task, please enter how much you'd like to increase the work estimate by to mark it as incomplete:", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addTextFieldWithConfigurationHandler({ (textField: UITextField!) in
            textField.placeholder = "Work Estimate Increase"
            textField.keyboardType = .NumbersAndPunctuation
        })

        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default) { (action: UIAlertAction) in
            let textField = alert.textFields![0]

            if let text = textField.text {
                let number = NSNumberFormatter().numberFromString(text)
                if number != nil && number!.floatValue > 0.0 {
                    task.workEstimate += number!.floatValue
                    task.isComplete = false
                    
                    // Save the context
                    if !self.persistenceController.saveDataAndWait() {
                        print("Couldn't save the data")
                    }
                    
                    return
                }
            }
        
            let badInputAlert = UIAlertController(title: "Invalid Input", message: "The work estimate increase has to be a number greater than zero!", preferredStyle: UIAlertControllerStyle.Alert)
            badInputAlert.addAction(UIAlertAction(title: "Whoops, sorry", style: .Cancel, handler: nil))
            self.presentViewController(badInputAlert, animated: true, completion: nil)
        })

        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func cellSlideDeleteActionTriggered(tableView: UITableView, indexPath: NSIndexPath) {
        // Delete the task
        var task: Task
        if indexPath.section == 0 {
            task = self.currentTasks![indexPath.row]
        } else {
            task = self.pastTasks![indexPath.row]
        }
        self.persistenceController.deleteStoredObjects([task])
        
        // Save the context
        if !self.persistenceController.saveDataAndWait() {
            print("Couldn't save the data")
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var task: Task
        if indexPath.section == 0 {
            task = self.currentTasks![indexPath.row]
        } else {
            task = self.pastTasks![indexPath.row]
        }
        
        self.performSegueWithIdentifier("AllTasksToEditTask", sender: task)
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

//
//  AllTasksViewController.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 12/21/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

class AllTasksViewController: UITableViewController, PersistenceManagerDelegate, CellSlideActionManagerDelegate {
    
    // A struct to hold some constants for setting up the table view
    struct TableSectionInfo {
        static let NumSections = 2
        
        static let CurrentSectionIndex = 0
        static let CurrentSectionHeader = "Current Tasks"
        
        static let PastSectionIndex = 1
        static let PastSectionHeader = "Past Tasks"
    }
    
    // A struct to hold some segue identifiers
    struct SegueIdentifiers {
        static let AllTasksToSetup = "AllTasksToSetup"
        static let AllTasksToNewTask = "AllTasksToNewTask"
        static let AllTasksToEditTask = "AllTasksToEditTask"
    }
    
    let persistenceController = PersistenceManager.sharedInstance
    let cellSlideActionManager = CellSlideActionManager()
    
    var user: User?
    var currentTasks: [Task]?
    var pastTasks: [Task]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.persistenceController.addDelegate(self)
        self.cellSlideActionManager.delegate = self
        
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.tableView.allowsMultipleSelectionDuringEditing = false
        self.tableView.registerNib(GenericTaskTableViewCell.Nib, forCellReuseIdentifier: GenericTaskTableViewCell.ReuseIdentifier)
        
        self.reloadTasks()
    }

    func reloadTasks() {
        self.user = self.persistenceController.getLatestUserData()
        
        self.currentTasks = self.user?.tasksArray.filter({ !$0.isDueInPast })
        self.currentTasks = self.sortTasksForDisplay(self.currentTasks!, dateOrder: .OrderedAscending)
        
        self.pastTasks = self.user?.tasksArray.filter({ $0.isDueInPast })
        self.pastTasks = self.sortTasksForDisplay(self.pastTasks!, dateOrder: .OrderedDescending)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
    
    private func sortTasksForDisplay(tasks: [Task], dateOrder: NSComparisonResult) -> [Task] {
        // Sorts so that workEstimate is within priority, which is within due date
        var tasksToSort = tasks.sort({ $0.workEstimate > $1.workEstimate })
        tasksToSort.sortInPlace({ $0.priority > $1.priority })
        tasksToSort.sortInPlace({ $0.dueDate.compare($1.dueDate) == dateOrder })
        
        return tasksToSort
    }
    
    func persistenceManagerDataChanged() {
        self.reloadTasks()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableSectionInfo.NumSections
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == TableSectionInfo.CurrentSectionIndex {
            if let currentTasks = self.currentTasks {
                return currentTasks.count
            }
        } else if section == TableSectionInfo.PastSectionIndex {
            if let pastTasks = self.pastTasks {
                return pastTasks.count
            }
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == TableSectionInfo.CurrentSectionIndex {
            return TableSectionInfo.CurrentSectionHeader
        } else if section == TableSectionInfo.PastSectionIndex  {
            return TableSectionInfo.PastSectionHeader
        } else {
            return "ERROR"
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(GenericTaskTableViewCell.ReuseIdentifier, forIndexPath: indexPath) as! GenericTaskTableViewCell

        let task = self.getTaskForIndexPath(indexPath)
        cell.setFromTask(task)
        
        if task.isComplete {
            self.cellSlideActionManager.addMarkIncompleteAndDeleteSlideActionsToCell(cell)
        } else {
            self.cellSlideActionManager.addMarkCompleteAndDeleteSlideActionsToCell(cell)
        }
        
        return cell
    }
    
    func cellSlideMarkCompleteActionTriggered(tableView: UITableView, indexPath: NSIndexPath) {
        let task = self.getTaskForIndexPath(indexPath)
        task.isComplete = true

        try! self.persistenceController.saveDataAndWait()
    }
    
    func cellSlideMarkIncompleteActionTriggered(tableView: UITableView, indexPath: NSIndexPath) {
        let task = self.getTaskForIndexPath(indexPath)
        
        if task.workLeftToDo == 0.0 {
            self.showIncreaseEstimateAlertForTask(task)
        } else {
            task.isComplete = false
            try! self.persistenceController.saveDataAndWait()
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

                    try! self.persistenceController.saveDataAndWait()
                    return
                }
            }
        
            let badInputAlert = UIAlertController(title: "Invalid Input", message: "The work estimate increase has to be a number greater than zero!", preferredStyle: UIAlertControllerStyle.Alert)
            badInputAlert.addAction(UIAlertAction(title: "Whoops, sorry", style: .Cancel, handler: nil))
            
            dispatch_async(dispatch_get_main_queue()) {
                self.presentViewController(badInputAlert, animated: true, completion: nil)
            }
        })

        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func cellSlideDeleteActionTriggered(tableView: UITableView, indexPath: NSIndexPath) {
        let task = self.getTaskForIndexPath(indexPath)
        self.persistenceController.deleteStoredObjects([task])
        
        try! self.persistenceController.saveDataAndWait()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let task = self.getTaskForIndexPath(indexPath)
        
        if task.isComplete {
            let alert = UIAlertController(title: "Task Completed", message: "Sorry, you can't edit tasks that are marked as compeleted.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Bummer", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        } else {
            self.performSegueWithIdentifier(SegueIdentifiers.AllTasksToEditTask, sender: task)
        }
    }
    
    private func getTaskForIndexPath(indexPath: NSIndexPath) -> Task {
        if indexPath.section == TableSectionInfo.CurrentSectionIndex {
            return self.currentTasks![indexPath.row]
        } else {
            return self.pastTasks![indexPath.row]
        }
    }
    
    @IBAction func addButtonPressed(sender: AnyObject) {
        self.performSegueWithIdentifier(SegueIdentifiers.AllTasksToNewTask, sender: nil)
        self.tableView.setEditing(false, animated: true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navigationController = segue.destinationViewController as? UINavigationController
        
        if segue.identifier == SegueIdentifiers.AllTasksToNewTask || segue.identifier == SegueIdentifiers.AllTasksToEditTask {
            // Depending on how we're getting to the EditTaskViewController,
            // we need to get it from different places (whether it's being
            // pushed or is a modal)

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

//
//  TodaysWorkViewController.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/18/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

class TodaysWorkViewController: UITableViewController, SchedulerDelegate, PersistenceManagerDelegate, CellSlideActionManagerDelegate {
    
    let persistenceController = PersistenceManager.sharedInstance
    let cellSlideActionManager = CellSlideActionManager()

    var user: User?
    var scheduler: Scheduler?
    var incompleteWorkSessions: [TaskWorkSession]?
    var completeWorkSessions: [TaskWorkSession]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.persistenceController.addDelegate(self)
        
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.tableView.allowsMultipleSelectionDuringEditing = false
        self.tableView.registerNib(GenericTaskTableViewCell.Nib, forCellReuseIdentifier: GenericTaskTableViewCell.ReuseIdentifier)
        
        self.cellSlideActionManager.delegate = self
        
        self.fetchOrCreateUser()
    }
    
    func persitenceManagerDataChanged() {
        self.refreshSchedule()
    }
    
    func fetchOrCreateUser() {
        if self.persistenceController.getLatestUserData() == nil {
            self.performSegueWithIdentifier("TasksToSetup", sender: nil)
        } else {
            // Need to do this manually on the first fetch
            self.refreshSchedule()
        }
    }
    
    func refreshSchedule() {
        if let user = self.persistenceController.getLatestUserData() {
            self.user = user
            self.scheduler = Scheduler(user: self.user!)
            self.scheduler!.delegate = self
            self.scheduler!.scheduleTasksForUser()
        }
    }
    
    func scheduleStarted() {
        self.persistenceController.removeDelegate(self)
    }
    
    func scheduleCompleted(status: ScheduleStatus) {
        if status == ScheduleStatus.Failed {
            print("Schedule failed")
        } else {
            self.incompleteWorkSessions = self.user?.todayWorkDay().workSessionsArray.filter({ !$0.hasBeenCompleted})
            self.completeWorkSessions = self.user?.todayWorkDay().workSessionsArray.filter({ $0.hasBeenCompleted})
            
            // Sort so that the highest priority, due-earliest, longest tasks are first
            
            self.incompleteWorkSessions!.sortInPlace({ $0.amountOfWork > $1.amountOfWork })
            self.incompleteWorkSessions!.sortInPlace({ $0.parentTask.dueDate.compare($1.parentTask.dueDate) == .OrderedAscending })
            self.incompleteWorkSessions!.sortInPlace({ $0.parentTask.priority > $1.parentTask.priority })
            
            self.completeWorkSessions!.sortInPlace({ $0.amountOfWork > $1.amountOfWork })
            self.completeWorkSessions!.sortInPlace({ $0.parentTask.dueDate.compare($1.parentTask.dueDate) == .OrderedAscending })
            self.completeWorkSessions!.sortInPlace({ $0.parentTask.priority > $1.parentTask.priority })
            
            self.tableView.reloadData()
        }
        
        self.persistenceController.addDelegate(self)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if let incompleteWorkSessions = self.incompleteWorkSessions {
                return incompleteWorkSessions.count
            }
        } else if section == 1 {
            if let completeWorkSessions = self.completeWorkSessions {
                return completeWorkSessions.count
            }
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Incomplete"
        } else if section == 1  {
            return "Complete"
        } else {
            return "ERROR"
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(GenericTaskTableViewCell.ReuseIdentifier, forIndexPath: indexPath) as! GenericTaskTableViewCell
        var workSession: TaskWorkSession
        
        if indexPath.section == 0 {
            workSession = self.incompleteWorkSessions![indexPath.row]
            self.cellSlideActionManager.addMarkCompleteAndDeleteSlideActionsToCell(cell)
        } else {
            workSession = self.completeWorkSessions![indexPath.row]
            self.cellSlideActionManager.addMarkIncompleteSlideActionToCell(cell)
        }
        
        cell.setFromWorkSession(workSession)
        
        return cell
    }
    
    func cellSlideMarkCompleteActionTriggered(tableView: UITableView, indexPath: NSIndexPath) {
        let workSession = self.incompleteWorkSessions![indexPath.row]
        workSession.hasBeenCompleted = true
        
        self.updateCompletionStatusOfParentTaskOfWorkSession(workSession)
        
        // Save the context
        if !self.persistenceController.saveDataAndWait() {
            print("Couldn't save the data")
        }
    }

    func cellSlideMarkIncompleteActionTriggered(tableView: UITableView, indexPath: NSIndexPath) {
        let workSession = self.completeWorkSessions![indexPath.row]
        workSession.hasBeenCompleted = false
        
        self.updateCompletionStatusOfParentTaskOfWorkSession(workSession)
        
        // Save the context
        if !self.persistenceController.saveDataAndWait() {
            print("Couldn't save the data")
        }
    }
    
    private func updateCompletionStatusOfParentTaskOfWorkSession(workSession: TaskWorkSession) {
        if workSession.parentTask.workLeftToDo == 0.0 {
            workSession.parentTask.isComplete = true
        } else {
            workSession.parentTask.isComplete = false
        }
    }

    func cellSlideDeleteActionTriggered(tableView: UITableView, indexPath: NSIndexPath) {
        // Delete the work session's task
        let workSession = self.incompleteWorkSessions![indexPath.row]
        let taskToDelete = [workSession.parentTask]
        self.persistenceController.deleteStoredObjects(taskToDelete)
        
        // Save the context
        if !self.persistenceController.saveDataAndWait() {
            print("Couldn't save the data")
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var workSession: TaskWorkSession
        if indexPath.section == 0 {
            workSession = self.incompleteWorkSessions![indexPath.row]
        } else {
            workSession = self.completeWorkSessions![indexPath.row]
        }
        
        if workSession.parentTask.isComplete {
            let alert = UIAlertController(title: "Task Completed", message: "Sorry, you can't edit tasks that are marked as compeleted.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Bummer", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        } else {
            self.performSegueWithIdentifier("TasksToEditTask", sender: workSession.parentTask)
        }
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
        } else if segue.identifier == "TasksToSetup" {
            let settingsViewController = navigationController!.viewControllers.first as! SettingsViewController
            settingsViewController.isSettingUp = true
        }
    }
}

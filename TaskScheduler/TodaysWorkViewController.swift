//
//  TodaysWorkViewController.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/18/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

class TodaysWorkViewController: UITableViewController, SchedulerDelegate, PersistenceManagerDelegate, CellSlideActionManagerDelegate {
    
    // A struct to hold some constants for setting up the table view
    struct TableSectionInfo {
        static let NumSections = 2
        
        static let IncompleteSectionIndex = 0
        static let IncompleteSectionHeader = "Incomplete"
        
        static let CompleteSectionIndex = 1
        static let CompleteSectionHeader = "Complete"
    }
    
    // A struct to hold some segue identifiers
    struct SegueIdentifiers {
        static let TasksToSetup = "TasksToSetup"
        static let TasksToNewTask = "TasksToNewTask"
        static let TasksToEditTask = "TasksToEditTask"
    }
    
    let persistenceController = PersistenceManager.sharedInstance
    let cellSlideActionManager = CellSlideActionManager()

    var user: User?
    var scheduler: Scheduler?
    var incompleteWorkSessions: [TaskWorkSession]?
    var completeWorkSessions: [TaskWorkSession]?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.persistenceController.addDelegate(self)
        self.cellSlideActionManager.delegate = self

        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.tableView.allowsMultipleSelectionDuringEditing = false
        self.tableView.registerNib(GenericTaskTableViewCell.Nib, forCellReuseIdentifier: GenericTaskTableViewCell.ReuseIdentifier)

        self.fetchOrCreateUser()
    }
    
    func fetchOrCreateUser() {
        if self.persistenceController.getLatestUserData() == nil {
            self.performSegueWithIdentifier(SegueIdentifiers.TasksToSetup, sender: nil)
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
            self.scheduler!.scheduleTasks()
        }
    }
    
    func persistenceManagerDataChanged() {
        self.refreshSchedule()
    }
    
    func scheduleStarted() {
        // To avoid endless schedulings, stop being a
        // PersistenceControllerDelegate during the schedule
        self.persistenceController.removeDelegate(self)
    }
    
    func scheduleCompleted(status: ScheduleStatus) {
        if status == ScheduleStatus.Failed {
            let alert = UIAlertController(title: "Scheduling Failed", message: "Uh oh, the scheduling failed! This should never happen.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Yikes!", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            self.updateWorkSessions()
        }
        
        // Now that the scheduling is over, we can listen
        // for updates to the underlying data
        self.persistenceController.addDelegate(self)
    }
    
    private func updateWorkSessions() {
        let todayWorkDay = self.user?.todayWorkDay()
        
        self.incompleteWorkSessions = todayWorkDay!.workSessionsArray.filter({ !$0.hasBeenCompleted })
        self.incompleteWorkSessions = self.sortWorkSessionsForDisplay(self.incompleteWorkSessions!)
        
        self.completeWorkSessions = todayWorkDay!.workSessionsArray.filter({ $0.hasBeenCompleted })
        self.completeWorkSessions = self.sortWorkSessionsForDisplay(self.completeWorkSessions!)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
    
    private func sortWorkSessionsForDisplay(workSessions: [TaskWorkSession]) -> [TaskWorkSession] {
        // Sort so that the highest priority, due-earliest, longest tasks are first
        var workSessionsToSort = workSessions.sort({ $0.amountOfWork > $1.amountOfWork })
        workSessionsToSort.sortInPlace({ $0.parentTask.dueDate.compare($1.parentTask.dueDate) == .OrderedAscending })
        workSessionsToSort.sortInPlace({ $0.parentTask.priority > $1.parentTask.priority })

        return workSessionsToSort
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableSectionInfo.NumSections
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == TableSectionInfo.IncompleteSectionIndex {
            if let incompleteWorkSessions = self.incompleteWorkSessions {
                return incompleteWorkSessions.count
            }
        } else if section == TableSectionInfo.CompleteSectionIndex {
            if let completeWorkSessions = self.completeWorkSessions {
                return completeWorkSessions.count
            }
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == TableSectionInfo.IncompleteSectionIndex {
            return TableSectionInfo.IncompleteSectionHeader
        } else if section == TableSectionInfo.CompleteSectionIndex  {
            return TableSectionInfo.CompleteSectionHeader
        } else {
            return "ERROR"
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(GenericTaskTableViewCell.ReuseIdentifier, forIndexPath: indexPath) as! GenericTaskTableViewCell
        var workSession: TaskWorkSession
        
        if indexPath.section == TableSectionInfo.IncompleteSectionIndex {
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
        try! self.persistenceController.saveDataAndWait()
    }

    func cellSlideMarkIncompleteActionTriggered(tableView: UITableView, indexPath: NSIndexPath) {
        let workSession = self.completeWorkSessions![indexPath.row]
        workSession.hasBeenCompleted = false
        
        self.updateCompletionStatusOfParentTaskOfWorkSession(workSession)
        try! self.persistenceController.saveDataAndWait()
    }
    
    private func updateCompletionStatusOfParentTaskOfWorkSession(workSession: TaskWorkSession) {
        if workSession.parentTask.workLeftToDo == 0.0 {
            workSession.parentTask.isComplete = true
        } else {
            workSession.parentTask.isComplete = false
        }
    }

    func cellSlideDeleteActionTriggered(tableView: UITableView, indexPath: NSIndexPath) {
        let workSession = self.incompleteWorkSessions![indexPath.row]
        let taskToDelete = [workSession.parentTask]
        self.persistenceController.deleteStoredObjects(taskToDelete)

        try! self.persistenceController.saveDataAndWait()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var workSession: TaskWorkSession
        if indexPath.section == TableSectionInfo.IncompleteSectionIndex {
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
            self.performSegueWithIdentifier(SegueIdentifiers.TasksToEditTask, sender: workSession.parentTask)
        }
    }

    @IBAction func addButtonPressed(sender: AnyObject) {
        self.performSegueWithIdentifier(SegueIdentifiers.TasksToNewTask, sender: nil)
        self.tableView.setEditing(false, animated: true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navigationController = segue.destinationViewController as? UINavigationController
        
        if segue.identifier == SegueIdentifiers.TasksToNewTask || segue.identifier == SegueIdentifiers.TasksToEditTask {
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
        } else if segue.identifier == SegueIdentifiers.TasksToSetup {
            let settingsViewController = navigationController!.viewControllers.first as! SettingsViewController
            settingsViewController.isSettingUp = true
        }
    }
}

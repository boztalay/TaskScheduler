//
//  TodaysWorkViewController.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/18/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

class TodaysWorkViewController: UITableViewController, SchedulerDelegate, PersistenceControllerDelegate {
    
    let persistenceController = PersistenceController.sharedInstance

    var user: User?
    var scheduler: Scheduler?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.persistenceController.addDelegate(self)
        
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.tableView.allowsMultipleSelectionDuringEditing = false
        
        self.fetchOrCreateUser()
    }
    
    func persitenceControllerDataChanged() {
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
        print("Schedule started")
        self.persistenceController.removeDelegate(self)
    }
    
    func scheduleCompleted(status: ScheduleStatus) {
        if status == ScheduleStatus.Failed {
            print("Schedule failed")
        } else {
            print("Schedule success")
            printTasks()
            self.tableView.reloadData()
        }
        
        self.persistenceController.addDelegate(self)
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
        let cell = tableView.dequeueReusableCellWithIdentifier("WorkSessionCell", forIndexPath: indexPath) as! WorkSessionTableViewCell
        
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
            self.persistenceController.deleteStoredObjects(taskToDelete)
            
            // Save the context
            
            if !self.persistenceController.saveDataAndWait() {
                print("Couldn't save the data")
            }
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

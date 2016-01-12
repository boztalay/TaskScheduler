//
//  ScheduleConfirmationViewController.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 1/2/16.
//  Copyright © 2016 Ben Oztalay. All rights reserved.
//

import UIKit

protocol WorkScheduleConfirmationDelegate {
    // Called when the user is done confirming the
    // changes to their work schedule
    func workScheduleConfirmationComplete()
}

class WorkScheduleConfirmationViewController: UITableViewController {

    var user: User?
    var delegate: WorkScheduleConfirmationDelegate?
    
    var workDaysToConfirm: [WorkDay] = []
    var workDayConfirmations: [Bool] = []
    
    static var dateFormatter: NSDateFormatter = {
        let newDateFormatter = NSDateFormatter()
        newDateFormatter.dateFormat = "EEE MMM d, yyyy"
        return newDateFormatter
    }()
    
    override func viewDidLoad() {
        // Find all of the work days that the user needs
        // to review and confirm, and sort them by date

        for workDay in self.user!.workDaysNotInPast {
            let workAvailableInNewSchedule = try! self.user!.totalAvailableWorkOnDate(workDay.date)

            if workDay.totalAvailableWork != workAvailableInNewSchedule {
                self.workDaysToConfirm.append(workDay)
                self.workDayConfirmations.append(true)
            }
        }
        
        self.workDaysToConfirm.sortInPlace() {
            return ($0.date.compare($1.date) == .OrderedAscending)
        }
        
        // Then, display them
        
        self.tableView.reloadData()
    }
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func doneButtonPressed(sender: AnyObject) {
        // Go through all of the days and see if the user confirmed
        // the change, applying the new schedule where appropriate

        for (workDay, isConfirmed) in zip(self.workDaysToConfirm, self.workDayConfirmations) {
            if isConfirmed {
                let workAvailableInNewSchedule = try! self.user!.totalAvailableWorkOnDate(workDay.date)
                workDay.totalAvailableWork = workAvailableInNewSchedule
            }
        }
        
        // Then let the delegate know and exit
        
        self.delegate?.workScheduleConfirmationComplete()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Unchecked days will keep old schedule"
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workDaysToConfirm.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("WorkDayConfirmationCell", forIndexPath: indexPath)

        let workDay = self.workDaysToConfirm[indexPath.row]
        let dateString = WorkScheduleConfirmationViewController.dateFormatter.stringFromDate(workDay.date)
        let workAvailableInNewSchedule = try! self.user!.totalAvailableWorkOnDate(workDay.date)
        cell.textLabel!.text = "\(dateString)\t(\(workDay.totalAvailableWork) hours to \(workAvailableInNewSchedule))"
        
        self.setCheckAccessoryAccordingToBool(cell, shouldBeChecked: self.workDayConfirmations[indexPath.row])
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.workDayConfirmations[indexPath.row] = !self.workDayConfirmations[indexPath.row]
        
        let cell = self.tableView.cellForRowAtIndexPath(indexPath)!
        self.setCheckAccessoryAccordingToBool(cell, shouldBeChecked: self.workDayConfirmations[indexPath.row])
        
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    private func setCheckAccessoryAccordingToBool(cell: UITableViewCell, shouldBeChecked: Bool) {
        if shouldBeChecked {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
    }
}

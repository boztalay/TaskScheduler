//
//  Scheduler.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 10/14/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import Foundation
import JSQCoreDataKit

enum ScheduleStatus: ErrorType {
    case Succeeded, Failed
}

protocol SchedulerDelegate {
    func scheduleStarted()
    func scheduleCompleted(status: ScheduleStatus)
}

class Scheduler {
    
    let persistenceController = PersistenceManager.sharedInstance
    
    private var user: User
    var delegate: SchedulerDelegate?
    
    init(user: User) {
        self.user = user
    }
    
    func scheduleTasksForUser() {
        delegate?.scheduleStarted()
        
        self.persistenceController.coreDataStack!.managedObjectContext.performBlock() {
            do {
                try self.actuallyScheduleTasksForUser()
                self.persistenceController.saveDataAndWait()
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate?.scheduleCompleted(ScheduleStatus.Succeeded)
                }
            } catch {
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate?.scheduleCompleted(ScheduleStatus.Failed)
                }
            }
        }
    }
    
    private func actuallyScheduleTasksForUser() throws {
        // First of all, get a list of tasks that are elegible to be scheduled
        // and reset them appropriately. Tasks that are eleigible are: not
        // marked as compelete, due in the future, have work left to do.
        
        // TODO make this whole resetting/removing incomplete work days thing less weird
        
        let tasksToSchedule = user.outstandingTasks
        var workSessionsToDelete: [TaskWorkSession] = []
        for task in tasksToSchedule {
            task.isDropped = false
            workSessionsToDelete.appendContentsOf(task.removeIncompleteWorkSessions())
        }
        
        // Delete the now-orphaned work sessions
        self.persistenceController.deleteStoredObjects(workSessionsToDelete)
        
        // Then, reset all of the workdays
        user.resetWorkDays()
        
        // If there aren't any outstanding tasks to schedule, bounce
        if tasksToSchedule.count == 0 {
            return
        }
        
        // Sort outstanding tasks by due date
        let tasksSortedByDueDate = tasksToSchedule.sort() { $0.dueDate.compare($1.dueDate) == .OrderedAscending }
        
        // Go through all of the due dates, seeing if all of the tasks due on or before
        // the given date are schedulable. If not, drop the longest, low priority tasks
        // in that interval until it is schedulable. This maximizes the number of tasks
        // that get done.
        
        let lastDueDate = tasksSortedByDueDate.last!.dueDate
        var currentDueDate = DateUtils.tomorrowDay() // Start with due date tomorrow
        
        while currentDueDate.compare(lastDueDate) != .OrderedDescending {
            let workTimeAvailable = user.availableWorkTimeBetweenNowAnd(date: currentDueDate)
            let estimatedWork = user.workToDoBetweenNowAnd(date: currentDueDate)
            
            if estimatedWork > workTimeAvailable {
                // This due date isn't schedulable, drop tasks
                var workDropped: Float = 0.0
                
                // First get a list of tasks due on or before the current date
                var tasksDue = tasksToSchedule.filter({ $0.dueDate.compare(currentDueDate) != .OrderedDescending })
                
                // Then sort that list of tasks by estimated work, then in reverse by priority
                tasksDue.sortInPlace({ $0.workEstimate > $1.workEstimate })
                tasksDue.sortInPlace({ $0.priority < $1.priority })
                
                // Now go through the tasks and drop them until it's schedulable
                for task in tasksDue {
                    workDropped += task.workEstimate
                    task.isDropped = true
                    
                    if (estimatedWork - workDropped) <= workTimeAvailable {
                        break
                    }
                }
            }
            
            currentDueDate = currentDueDate.dateByAddingTimeInterval(24 * 60 * 60)
        }
        
        // Goals/rules of scheduling:
        //      Tasks are scheduled to be completed the day before they're due
        //      All tasks meet their deadlines (we know there's enough working time once we get here)
        //      Tasks are started as late as possible, with low priority tasks scheduled later than high priority tasks
        //      Long tasks can be split over several days
        
        // Sort the tasks so that the latest, shortest, lowest-priority tasks are first
        
        var sortedTasks = tasksToSchedule.filter({ !$0.isDropped }).sort({ $0.workEstimate < $1.workEstimate })
        sortedTasks.sortInPlace({ $0.priority < $1.priority })
        sortedTasks.sortInPlace({ $0.dueDate.compare($1.dueDate) == .OrderedDescending })
        
        // Schedule them tasks
        
        for task in sortedTasks {
            var dayToScheduleOn: WorkDay?
            
            // Try to find the latest day before the task's due date
            // that has available work
            var currentDay = user.workDayBeforeDay(user.workDayForDate(task.dueDate))
            while currentDay.date.compare(DateUtils.todayDay()) != .OrderedAscending {
                if currentDay.workLeftToBeScheduled > 0.0 {
                    dayToScheduleOn = currentDay
                    break
                }
                currentDay = user.workDayBeforeDay(currentDay)
            }
            
            // If it still can't be scheduled, something is wrong
            let confirmedDayToScheduleOn = dayToScheduleOn!
            
            // Otherwise, schedule the task, splitting it up as needed
            
            currentDay = confirmedDayToScheduleOn
            while task.workNotScheduled > 0.0 && currentDay.date.compare(DateUtils.todayDay()) != .OrderedAscending {
                let workForNewWorkSession = min(currentDay.workLeftToBeScheduled, task.workNotScheduled)
                if workForNewWorkSession > 0.0 {
                    task.addWorkSession(currentDay, amountOfWork: workForNewWorkSession)
                }
                
                currentDay = user.workDayBeforeDay(currentDay)
            }
            
            // If we get here and the task still hasn't been totally scheduled, something is wrong
            if task.workNotScheduled > 0.0 {
                throw ScheduleStatus.Failed
            }
        }
    }
}
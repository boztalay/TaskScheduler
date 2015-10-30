//
//  Scheduler.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 10/14/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import Foundation

enum ScheduleStatus: ErrorType {
    case Succeeded, Failed
}

protocol SchedulerDelegate {
    func scheduleStarted()
    func scheduleCompleted(status: ScheduleStatus)
}

class Scheduler {
    private var user: User
    var delegate: SchedulerDelegate?
    
    private var queue: dispatch_queue_t
    
    init(user: User) {
        self.user = user
        self.queue = dispatch_queue_create("com.boztalay.TaskScheduler.Scheduler", DISPATCH_QUEUE_SERIAL)
    }
    
    func scheduleTasksForUser() {
        delegate?.scheduleStarted()
        
        dispatch_async(self.queue) {
            do {
                try self.actuallyScheduleTasksForUser()
                self.delegate?.scheduleCompleted(ScheduleStatus.Succeeded)
            } catch {
                self.delegate?.scheduleCompleted(ScheduleStatus.Failed)
            }
        }
    }
    
    private func actuallyScheduleTasksForUser() throws {
        // First of all, get a list of tasks that are elegible to be scheduled
        // and reset them appropriately. Tasks that are eleigible are: not
        // marked as compelete, due in the future, have work left to do.
        
        let tasksToSchedule = user.outstandingTasks
        for task in tasksToSchedule {
            task.dropped = false
            task.resetWorkSessions()
        }
        
        // Then, reset all of the workdays
        user.resetWorkDays()
        
        // If there aren't any outstanding tasks to schedule, bounce
        if tasksToSchedule.count == 0 {
            return
        }
        
        // And sort outstanding tasks by due date
        let tasksSortedByDueDate = tasksToSchedule.sort() { $0.dueDate.compare($1.dueDate) == .OrderedAscending }
        
        // Go through all of the due dates, seeing if all of the tasks due on or before
        // the given date are schedulable. If not, drop the longest, low priority tasks
        // in that interval until it is schedulable. This maximizes the number of tasks
        // that get done.
        
        let lastDueDate = tasksSortedByDueDate.last!.dueDate
        var currentDueDate = DateUtils.dateByAddingDay(DateUtils.todayDay()) // Start with due date tomorrow
        
        while currentDueDate.compare(lastDueDate) != .OrderedDescending {
            let workTimeAvailable = user.availableWorkTimeBetweenNowAnd(date: currentDueDate)
            let estimatedWork = user.workToDoBetweenNowAnd(date: currentDueDate)
            
            if estimatedWork > workTimeAvailable {
                // This due date isn't schedulable, drop tasks
                var workDropped: Float = 0.0
                
                // First get a list of tasks due on or before the current date
                var tasksDue = user.tasksArray.filter({ $0.dueDate.compare(currentDueDate) != .OrderedDescending })
                
                // Then sort that list of tasks by estimated work, then in reverse by priority
                tasksDue.sortInPlace({ $0.workEstimate > $1.workEstimate })
                tasksDue.sortInPlace({ $0.priority < $1.priority })
                
                // Now go through the tasks and drop them until it's schedulable
                for task in tasksDue {
                    workDropped += task.workEstimate
                    task.dropped = true
                    
                    if (estimatedWork - workDropped) <= workTimeAvailable {
                        break
                    }
                }
            }
            
            currentDueDate = currentDueDate.dateByAddingTimeInterval(24 * 60 * 60)
        }
        
        // Goals/rules of scheduling:
        //      Tasks are scheduled to be completed the day before they're due (unless the only day left is its due date)
        //      All tasks meet their deadlines (we know there's enough working time once we get here)
        //      Tasks are started as late as possible, with low priority tasks scheduled later than high priority tasks
        //      Long tasks can be split over several days
        
        // Sort the tasks so that the latest, shortest, lowest-priority tasks are first
        
        var sortedTasks = user.notDroppedTasks.sort({ $0.workEstimate < $1.workEstimate })
        sortedTasks.sortInPlace({ $0.priority < $1.priority })
        sortedTasks.sortInPlace({ $0.dueDate.compare($1.dueDate) == .OrderedDescending })
        
        // Schedule them tasks
        
        for task in sortedTasks {
            var dayToScheduleOn: WorkDay?
            
            // First try to find the latest day before the task's due date
            // that has available work
            var currentDay = user.workDayBeforeDay(user.workDayForDate(task.dueDate))
            while currentDay.date.compare(DateUtils.todayDay()) != .OrderedAscending {
                if currentDay.workLeftToBeScheduled > 0.0 {
                    dayToScheduleOn = currentDay
                    break
                }
                currentDay = user.workDayBeforeDay(currentDay)
            }
            
            // If that didn't work, check the task's due date
            if dayToScheduleOn == nil {
                let day = user.workDayForDate(task.dueDate)
                if day.workLeftToBeScheduled > 0.0 {
                    dayToScheduleOn = day
                }
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
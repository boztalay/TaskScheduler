//
//  Scheduler.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 10/14/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import Foundation
import JSQCoreDataKit

// Goals/rules of scheduling:
//      If there's too much work to do, drop lower priority, longer tasks first
//      Tasks are scheduled to be completed the day before they're due
//      All tasks meet their deadlines
//      Tasks are started as late as possible, with low priority tasks scheduled later than high priority tasks
//      Long tasks can be split over several days

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
    
    func scheduleTasks() {
        delegate?.scheduleStarted()
        
        self.persistenceController.coreDataStack!.managedObjectContext.performBlock() {
            do {
                try self.actuallyScheduleTasks()
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
    
    private func actuallyScheduleTasks() throws {
        let tasksToSchedule = self.prepareUserAndGetTasksToSchedule()
        self.dropTasksAsNeededFromList(tasksToSchedule)
        try self.scheduleRemainingTasksInList(tasksToSchedule)
    }
    
    private func prepareUserAndGetTasksToSchedule() -> [Task] {
        let tasksToSchedule = user.outstandingTasks

        let workSessionsToDelete = self.prepareTasksAndGetWorkSessionsToDelete(tasksToSchedule)
        self.persistenceController.deleteStoredObjects(workSessionsToDelete)
        
        self.prepareWorkDays(self.user.workDaysArray)
        
        return tasksToSchedule
    }
    
    private func prepareTasksAndGetWorkSessionsToDelete(tasksToSchedule: [Task]) -> [TaskWorkSession] {
        var workSessionsToDelete: [TaskWorkSession] = []
        
        for task in tasksToSchedule {
            task.isDropped = false
            workSessionsToDelete.appendContentsOf(task.removeIncompleteWorkSessions())
        }
        
        return workSessionsToDelete
    }
    
    private func prepareWorkDays(workDays: [WorkDay]) {
        for workDay in workDays {
            workDay.removeIncompleteWorkSessions()
        }
    }
    
    private func dropTasksAsNeededFromList(tasksToSchedule: [Task]) {
        let tasksSortedByDueDate = tasksToSchedule.sort({ $0.dueDate.compare($1.dueDate) == .OrderedAscending })
        
        let lastDueDate = tasksSortedByDueDate.last!.dueDate
        var currentDueDate = DateUtils.tomorrowDay()
        
        while currentDueDate.compare(lastDueDate) != .OrderedDescending {
            self.dropTasksAsNeededFromList(tasksToSchedule, dueOn: currentDueDate)
            currentDueDate = DateUtils.dateByAddingDay(currentDueDate)
        }
    }
    
    private func dropTasksAsNeededFromList(tasksToSchedule: [Task], dueOn currentDueDate: NSDate) {
        let workTimeAvailable = user.availableWorkTimeBetweenNowAnd(date: currentDueDate)
        let estimatedWork = user.workToDoBetweenNowAnd(date: currentDueDate)
        
        if estimatedWork > workTimeAvailable {
            let tasksDue = tasksToSchedule.filter({ $0.dueDate.compare(currentDueDate) != .OrderedDescending })
            self.dropTasksFromList(tasksDue, forHoursOfWork: (estimatedWork - workTimeAvailable))
        }
    }
    
    private func dropTasksFromList(var tasksToDropFrom: [Task], forHoursOfWork hoursToDrop: Float) {
        tasksToDropFrom.sortInPlace({ $0.workEstimate > $1.workEstimate })
        tasksToDropFrom.sortInPlace({ $0.priority < $1.priority })

        var workDropped: Float = 0.0
        for task in tasksToDropFrom {
            workDropped += task.workEstimate
            task.isDropped = true
            
            if workDropped >= hoursToDrop {
                break
            }
        }
    }
    
    private func scheduleRemainingTasksInList(tasksToSchedule: [Task]) throws {
        let sortedTasks = self.sortTasksListForScheduling(tasksToSchedule)

        for task in sortedTasks {
            let dayToScheduleOn = self.findLatestDayToStartSchedulingTaskOn(task)
            if dayToScheduleOn == nil {
                throw ScheduleStatus.Failed
            }

            self.scheduleTask(task, startingOnDay: dayToScheduleOn)
            if task.workNotScheduled > 0.0 {
                throw ScheduleStatus.Failed
            }
        }
    }
    
    private func sortTasksListForScheduling(tasksToSchedule: [Task]) -> [Task] {
        var sortedTasks = tasksToSchedule.filter({ !$0.isDropped })
        
        sortedTasks.sortInPlace({ $0.workEstimate < $1.workEstimate })
        sortedTasks.sortInPlace({ $0.priority < $1.priority })
        sortedTasks.sortInPlace({ $0.dueDate.compare($1.dueDate) == .OrderedDescending })
        
        return sortedTasks
    }
    
    private func findLatestDayToStartSchedulingTaskOn(task: Task) -> WorkDay? {
        var dayToScheduleOn: WorkDay?
        var currentDay = user.workDayBeforeDay(user.workDayForDate(task.dueDate))
        
        while currentDay.date.compare(DateUtils.todayDay()) != .OrderedAscending {
            if currentDay.workLeftToBeScheduled > 0.0 {
                dayToScheduleOn = currentDay
                break
            }
            currentDay = user.workDayBeforeDay(currentDay)
        }
        
        return dayToScheduleOn
    }
    
    private func scheduleTask(task: Task, startingOnDay dayToScheduleOn: WorkDay?) {
        var currentDay = dayToScheduleOn!

        while task.workNotScheduled > 0.0 && currentDay.date.compare(DateUtils.todayDay()) != .OrderedAscending {
            let workForNewWorkSession = min(currentDay.workLeftToBeScheduled, task.workNotScheduled)
            if workForNewWorkSession > 0.0 {
                task.addWorkSession(currentDay, amountOfWork: workForNewWorkSession)
            }
            
            currentDay = user.workDayBeforeDay(currentDay)
        }
    }
}
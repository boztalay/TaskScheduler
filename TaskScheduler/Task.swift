//
//  Task.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/28/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import Foundation
import CoreData

enum TaskError: ErrorType {
    case WorkSessionDoesntBelong
}

class Task: NSManagedObject {
    // The CoreData entity name to use for this class
    static var entityName = "Task"
    
    // The user that owns this task
    @NSManaged var parentUser: User
    
    // The title or name of the task
    @NSManaged var title: String

    // The day that the task is due on
    @NSManaged var dueDate: NSDate

    // Higher integers are higher priority
    @NSManaged var priorityNum: NSNumber

    // The number of hours the task will take
    @NSManaged var workEstimateNum: NSNumber

    // A set of TaskWorkSessions
    @NSManaged var workSessions: NSSet

    // Whether or not the task has been dropped
    // This should only ever be set by the scheduler
    @NSManaged var isDroppedNum: NSNumber

    // If this is set, the task is done, regardless
    // of how much work is left. Can be set by the user.
    @NSManaged var isCompleteNum: NSNumber
    
    // A convenience accessor for priorityNum
    var priority: Int {
        set(newPriority) {
            self.priorityNum = NSNumber(integer: newPriority)
        }
        get {
            return self.priorityNum.integerValue
        }
    }
    
    // A convenience accessor for workEstimateNum
    var workEstimate: Float {
        set(newEstimate) {
            self.workEstimateNum = NSNumber(float: newEstimate)
        }
        get {
            return self.workEstimateNum.floatValue
        }
    }
    
    // A convenience accessor for droppedNum
    var isDropped: Bool {
        set(newDropped) {
            self.isDroppedNum = NSNumber(bool: newDropped)
        }
        get {
            return self.isDroppedNum.boolValue
        }
    }
    
    // A convenience accessor for isCompleteNum
    var isComplete: Bool {
        set(newComplete) {
            self.isCompleteNum = NSNumber(bool: newComplete)
        }
        get {
            return self.isCompleteNum.boolValue
        }
    }
    
    // An unordered array of all of the TaskWorkSessions
    var workSessionsArray: [TaskWorkSession] {
        return Array(self.workSessions as! Set<TaskWorkSession>)
    }
    
    // The number of hours of work that have been scheduled
    // in TaskWorkSessions
    var workScheduled: Float {
        return self.workSessionsArray.map({ $0.amountOfWork }).reduce(0.0, combine: +)
    }
    
    // The number of hours of work that have not yet been
    // scheduled in TaskWorkSessions
    var workNotScheduled: Float {
        return self.workEstimate - self.workScheduled
    }
    
    // The number of hours of work on the task that have been
    // completed (summing up the completed work sessions)
    var workCompleted: Float {
        return self.workSessionsArray.filter({ $0.hasBeenCompleted }).map({ $0.amountOfWork }).reduce(0.0, combine: +)
    }
    
    // The number of hours of work on the task have still
    // have to be completed
    var workLeftToDo: Float {
        return self.workEstimate - self.workCompleted
    }
    
    // Whether or not the task is due in the past
    var isDueInPast: Bool {
        return (self.dueDate.compare(DateUtils.todayDay()) == .OrderedAscending)
    }
    
    // Creates a new task and inserts it into the context
    convenience init(context: NSManagedObjectContext, title: String, dueDate: NSDate, priority: Int, workEstimate: Float) {
        let entity = NSEntityDescription.entityForName(Task.entityName, inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.title = title
        self.dueDate = dueDate
        self.priority = priority
        self.workEstimate = workEstimate
        self.isDropped = false
        self.isComplete = false
    }
    
    
    // Whether or not the task is due on or before the given date
    func isDueOnOrBefore(date: NSDate) -> Bool {
        return (self.dueDate.compare(date) != .OrderedDescending)
    }
    
    // Adds the given TaskWorkSession to this task
    func addWorkSession(workSession: TaskWorkSession) {
        self.workSessions = self.workSessions.setByAddingObject(workSession)
    }
    
    // Makes a new TaskWorkSession with the given amount of work
    // and adds it to this task and the given day to schedule it on
    func addWorkSession(dayScheduledOn: WorkDay, amountOfWork: Float) {
        let workSession = TaskWorkSession(context: self.managedObjectContext!, parentTask: self, dayScheduledOn: dayScheduledOn, amountOfWork: amountOfWork)
        self.addWorkSession(workSession)
        dayScheduledOn.addWorkSession(workSession)
    }
    
    // Marks the given TaskWorkSession as complete, then checks
    // if there's any more work to do on the task. If not, it
    // marks the task as complete.
    // Throws a TaskError.WorkSesssionDoesntBelong if the given
    // work session isn't for the task.
    func markWorkSessionAsComplete(workSession: TaskWorkSession) throws {
        if workSession.parentTask === self {
            workSession.hasBeenCompleted = true
            if self.workCompleted >= self.workLeftToDo {
                self.isComplete = true
            }
        } else {
            throw TaskError.WorkSessionDoesntBelong
        }
    }
    
    // Removes all of the incomplete work sessions from this task and returns them
    func resetWorkSessions() -> [TaskWorkSession] {
        let incompleteWorkSessions = self.workSessionsArray.filter({ !$0.hasBeenCompleted })
        self.workSessions = NSMutableSet.init(array: self.workSessionsArray.filter({ $0.hasBeenCompleted }))
        
        return incompleteWorkSessions
    }
}

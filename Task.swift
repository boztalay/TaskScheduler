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
    
    // The title or name of the task
    @NSManaged var title: String

    // The day that the task is due on
    @NSManaged var dueDate: NSDate

    // Higher integers are higher priority
    @NSManaged var priority: Int

    // A category for the task
    @NSManaged var type: String

    // The number of hours the task will take
    @NSManaged var workEstimate: Float

    // A set of TaskWorkSessions
    @NSManaged var workSessions: NSMutableSet

    // Whether or not the task has been dropped
    // This should only ever be set by the scheduler
    @NSManaged var dropped: Bool

    // If this is set, the task is done, regardless
    // of how much work is left. Can be set
    // by the user.
    @NSManaged var isComplete: Bool
    
    // An unordered array of all of the TaskWorkSessions
    var workSessionsArray: [TaskWorkSession] {
        return self.workSessions.allObjects as! [TaskWorkSession]
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
    init(context: NSManagedObjectContext, title: String, dueDate: NSDate, priority: Int, type: String, workEstimate: Float) {
        let entity = NSEntityDescription.entityForName(Task.entityName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.title = title
        self.dueDate = dueDate
        self.priority = priority
        self.type = type
        self.workEstimate = workEstimate
        self.dropped = false
        self.isComplete = false
    }
    
    // Makes a new TaskWorkSession with the given amount of work
    // and adds it to this task and the given day to schedule it on
    func addWorkSession(dayScheduledOn: WorkDay, amountOfWork: Float) {
        let workSession = TaskWorkSession(context: self.managedObjectContext!, parentTask: self, dayScheduledOn: dayScheduledOn, amountOfWork: amountOfWork)
        self.workSessions.addObject(workSession)
        dayScheduledOn.workSessions.addObject(workSession)
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
    
    // Removes all of the incomplete work sessions from this task
    func resetWorkSessions() {
        self.workSessions = NSMutableSet.init(array: self.workSessionsArray.filter({ $0.hasBeenCompleted }))
    }
}
